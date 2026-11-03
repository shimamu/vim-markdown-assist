set formatoptions=tcroqln
set comments=b:*,b:-,b:+,n:>,b:1.

let s:EMPHASIS_BOLD = "**"
let s:EMPHASIS_ITALIC = "*"
let s:INSERT = "i"
let s:APPEND = "a"
let s:HEADERS_REGEXP = '\v^(#|.+\n(\=+|-+)$)'
let s:HEADER_LINE_REGEXP = '\v^.+\n(\=+|-+)$'
let s:NEXT = 1
let s:PREV = -1

function! s:set_markdown_header(level)
  if a:level < 0 || a:level > 6
    return
  endif

  let l:line = getline('.')

  " Remove existing header marks
  let l:line = substitute(l:line, '^#\+\s*', '', '')

  " Add specified number of header marks
  if a:level > 0
    let l:line = repeat('#', a:level) . ' ' . l:line
  endif

  call setline('.', l:line)
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

function! Markdown_complete()
    call complete(col('.'), [
                \ {'word': '1. ', 'menu': 'order list'},
                \ {'word': '- ', 'menu': 'unorder list'},
                \ {'word': '[]()', 'menu': 'link'}
                \ ])
    return ''
endfunction

inoremap <f5> <C-r>=Markdown_Complete()<CR>
command! ClearMarkdownHeader call s:set_markdown_header(0)
command! MarkdownHeader1 call s:set_markdown_header(1)
command! MarkdownHeader2 call s:set_markdown_header(2)
command! MarkdownHeader3 call s:set_markdown_header(3)
command! MarkdownHeader4 call s:set_markdown_header(4)
command! MarkdownHeader5 call s:set_markdown_header(5)
command! MarkdownHeader6 call s:set_markdown_header(6)
command! MarkdownBold call s:markdown_emphasis(s:EMPHASIS_BOLD)
command! MarkdownItalic call s:markdown_emphasis(s:EMPHASIS_ITALIC)
command! InsertMarkdownLink call s:markdown_link(s:INSERT)
command! AppendMarkdownLink call s:markdown_link(s:APPEND)
command! MoveToNextMarkdownHeader call s:move_to_markdown_header(s:NEXT)
command! MoveToPrevMarkdownHeader call s:move_to_markdown_header(s:PREV)
command! MarkdownTableFormat call s:table_format()

nnoremap <silent> <C-m>h0 :ClearMarkdownHeader<CR>
nnoremap <silent> <C-m>h1 :MarkdownHeader1<CR>
nnoremap <silent> <C-m>h2 :MarkdownHeader2<CR>
nnoremap <silent> <C-m>h3 :MarkdownHeader3<CR>
nnoremap <silent> <C-m>h4 :MarkdownHeader4<CR>
nnoremap <silent> <C-m>h5 :MarkdownHeader5<CR>
nnoremap <silent> <C-m>h6 :MarkdownHeader6<CR>
nnoremap <silent> <C-m>il :InsertMarkdownLink<CR>
nnoremap <silent> <C-m>al :AppendMarkdownLink<CR>

inoremap <expr> <C-f> Markdown_link_str()
inoremap <f5> <C-r>=Markdown_complete()<CR>
