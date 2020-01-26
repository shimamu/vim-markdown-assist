set formatoptions=tcroqln
set comments=b:*,b:-,b:+,n:>,b:1.

let s:HEADER_LINE_1 = "="
let s:HEADER_LINE_2 = "-"
let s:EMPHASIS_BOLD = "**"
let s:EMPHASIS_ITALIC = "*"
let s:INSERT = "i"
let s:APPEND = "a"
let s:HEADERS_REGEXP = '\v^(#|.+\n(\=+|-+)$)'
let s:HEADER_LINE_REGEXP = '\v^.+\n(\=+|-+)$'
let s:NEXT = 1
let s:PREV = -1

function! s:is_on_header_line_area(mark)
    if s:is_next_line_on_header_line(a:mark)
        return 1
    elseif s:is_current_line_on_header_line(a:mark)
        return 1
    endif
endfunction

function! s:remarkdown_all_header_line()
    let l:pos = getpos('.')
    execute ":normal gg"
    call s:remarkdown_header_line()
    while search(s:HEADER_LINE_REGEXP, "W") > 0
        call s:remarkdown_header_line()
    endwhile

    call setpos('.', l:pos)
endfunction

function! s:remarkdown_header_line()
    let s:marks = [s:HEADER_LINE_1, s:HEADER_LINE_2]
    for l:mark in s:marks
        if s:is_on_header_line_area(l:mark)
            call s:markdown_header_line(l:mark)
        endif
    endfor
endfunction

function! s:markdown_header_line(mark)
    if s:is_current_line_on_header_line(a:mark)
        let cols = s:prev_line_cols()
    else
        let cols = s:current_line_cols()
        if s:is_next_line_on_header_line(a:mark)
            call cursor(line(".") + 1, col("."))
        else
            execute ":normal o"
        endif
    endif
    call s:print_header_line(cols, a:mark)
endfunction

function! s:print_header_line(cols, mark)
    execute ":normal 0D" . a:cols . "i" . a:mark
    execute ":normal 0"
endfunction

function! s:is_current_line_on_header_line(mark)
    let line = getline(".")
    return s:is_on_header_line(line, a:mark)
endfunction

function! s:is_next_line_on_header_line(mark)
    let line = getline(line(".") + 1)
    return s:is_on_header_line(line, a:mark)
endfunction

function! s:is_on_header_line(line, mark)
    return a:line =~ "^" . a:mark . "\\+$"
endfunction

function! s:current_line_cols()
    let line = getline(".")
    return s:line_cols(line)
endfunction

function! s:prev_line_cols()
    let line = getline(line(".") - 1)
    return s:line_cols(line)
endfunction

function! s:line_cols(line)
    let byte_size = strlen(a:line)
    let char_count = s:str_count(a:line)
    return char_count + (byte_size - char_count) / 2
endfunction

function! s:str_count(str)
    return strlen(substitute(a:str, ".", "x", "g"))
endfunction

function! s:markdown_emphasis(mark)
    execute ":'<,'>s/\\%V\\(.\\+\\%V.\\)/" . a:mark . "\\1" . a:mark . "/g"
    execute ":normal `>"
    call cursor(line("."), col(".") + strlen(a:mark) * 2)
endfunction

function! Markdown_link_str()
    let l:url = @+
    let l:title = s:get_title_from_url(l:url)
    return "[" . l:title . "](" . l:url . ")"
endfunction

function! s:markdown_link(position)
    execute ":normal " . a:position . Markdown_link_str()
endfunction

function! s:get_title_from_url(url)
    try
        let l:res = webapi#html#parseURL(a:url)
        let l:dom = l:res.find("title")
        let l:title = l:dom.child[0]
        return l:title
    catch
        echo "Can't get title from clipboard."
    endtry
endfunction

function! s:move_to_markdown_header(direction)
    let l:search_option = 'W'
    if a:direction ==# s:PREV
        let l:search_option .= 'b'
    endif
    if search(s:HEADERS_REGEXP, l:search_option) == 0
        echo 'no next header'
    endif
endfunction

function! s:table_format()
    let l:pos = getpos('.')
    normal! {
    " Search instead of `normal! j` because of the table at beginning of file edge case.
    call search('|')
    normal! j
    " Remove everything that is not a pipe, colon or hyphen next to a colon othewise
    " well formated tables would grow because of addition of 2 spaces on the separator
    " line by Tabularize /|.
    let l:flags = (&gdefault ? '' : 'g')
    execute 's/\(:\@<!-:\@!\|[^|:-]\)//e' . l:flags
    execute 's/--/-/e' . l:flags
    Tabularize /|
    " Move colons for alignment to left or right side of the cell.
    execute 's/:\( \+\)|/\1:|/e' . l:flags
    execute 's/|\( \+\):/|:\1/e' . l:flags
    execute 's/ /-/' . l:flags
    call setpos('.', l:pos)
endfunction

command! MarkdownHeaderLine1 call s:markdown_header_line(s:HEADER_LINE_1)
command! MarkdownHeaderLine2 call s:markdown_header_line(s:HEADER_LINE_2)
command! ReMarkdownHeaderLine call s:remarkdown_all_header_line()
command! MarkdownBold call s:markdown_emphasis(s:EMPHASIS_BOLD)
command! MarkdownItalic call s:markdown_emphasis(s:EMPHASIS_ITALIC)
command! InsertMarkdownLink call s:markdown_link(s:INSERT)
command! AppendMarkdownLink call s:markdown_link(s:APPEND)
command! MoveToNextMarkdownHeader call s:move_to_markdown_header(s:NEXT)
command! MoveToPrevMarkdownHeader call s:move_to_markdown_header(s:PREV)
command! MarkdownTableFormat call s:table_format()

nnoremap <silent> <C-m>h1 :MarkdownHeaderLine1<CR>
nnoremap <silent> <C-m>h2 :MarkdownHeaderLine2<CR>
nnoremap <silent> <C-m>r :ReMarkdownHeaderLine<CR>
nnoremap <silent> <C-m>il :InsertMarkdownLink<CR>
nnoremap <silent> <C-m>al :AppendMarkdownLink<CR>

inoremap <expr> <C-f> Markdown_link_str()
