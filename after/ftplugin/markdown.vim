set formatoptions=tcroqln
set comments=b:*,b:-,b:+,n:>,b:1.

let s:EMPHASIS_BOLD = "**"
let s:EMPHASIS_ITALIC = "_"
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

function! s:wrap_text_char(start, end, wrapper) abort
  let l:start_line_no = a:start[1]
  let l:start_col = a:start[2]
  let l:end_line_no = a:end[1]
  let l:end_col = a:end[2]

  let l:first_line = getline(l:start_line_no)
  let l:last_line = getline(l:end_line_no)

  " Get the byte length of the last character.
  let l:last_char = matchstr(strpart(l:last_line, l:end_col - 1), '^.')
  let l:end_byte = l:end_col - 1 + strlen(l:last_char)

  if l:start_line_no == l:end_line_no
    let l:new_line = strpart(l:first_line, 0, l:start_col - 1)
          \ . a:wrapper
          \ . strpart(l:first_line, l:start_col - 1, l:end_byte - l:start_col + 1)
          \ . a:wrapper
          \ . strpart(l:first_line, l:end_byte)

    call setline(l:start_line_no, l:new_line)
  else
    let l:new_lines = getline(l:start_line_no, l:end_line_no)

    let l:new_lines[0] = strpart(l:first_line, 0, l:start_col - 1)
          \ . a:wrapper
          \ . strpart(l:first_line, l:start_col - 1)

    let l:new_lines[-1] = strpart(l:last_line, 0, l:end_byte)
          \ . a:wrapper
          \ . strpart(l:last_line, l:end_byte)

    call setline(l:start_line_no, l:new_lines)
  endif
endfunction

function! s:wrap_text_line(start, end, wrapper) abort
  let l:start_line = a:start[1]
  let l:end_line = a:end[1]
  let l:lines = getline(l:start_line, l:end_line)

  let l:lines[0] = a:wrapper . l:lines[0]
  let l:lines[-1] .= a:wrapper

  call setline(l:start_line, l:lines)
endfunction

function! s:wrap_text_block(start, end, wrapper) abort
  let l:start_line_no = a:start[1]
  let l:end_line_no = a:end[1]

  let l:start_vcol = virtcol("'<")
  let l:end_vcol = virtcol("'>")

  if l:start_vcol > l:end_vcol
    let [l:start_vcol, l:end_vcol] = [l:end_vcol, l:start_vcol]
  endif

  let l:new_lines = getline(l:start_line_no, l:end_line_no)

  for l:i in range(len(l:new_lines))
    let l:line = l:new_lines[l:i]
    let l:line_no = l:start_line_no + l:i

    let l:start_col = virtcol2col(0, l:line_no, l:start_vcol)
    let l:end_col = virtcol2col(0, l:line_no, l:end_vcol)

    if l:start_col == 0
      continue
    endif

    if l:end_col == 0
      let l:end_byte = strlen(l:line)
    else
      let l:last_char = matchstr(strpart(l:line, l:end_col - 1), '^.')
      let l:end_byte = l:end_col - 1 + strlen(l:last_char)
    endif

    let l:new_lines[l:i] = strpart(l:line, 0, l:start_col - 1)
          \ . a:wrapper
          \ . strpart(l:line, l:start_col - 1, l:end_byte - l:start_col + 1)
          \ . a:wrapper
          \ . strpart(l:line, l:end_byte)
  endfor

  call setline(l:start_line_no, l:new_lines)
endfunction

function! s:wrap_text(type, wrapper) abort
  let l:start = getpos("'[")
  let l:end = getpos("']")

  if a:type ==# 'char'
    call s:wrap_text_char(l:start, l:end, a:wrapper)
  elseif a:type ==# 'line'
    call s:wrap_text_line(l:start, l:end, a:wrapper)
  elseif a:type ==# 'block'
    call s:wrap_text_block(l:start, l:end, a:wrapper)
  endif
endfunction

function! s:wrap_text_visual(wrapper) abort
  let l:start = getpos("'<")
  let l:end = getpos("'>")
  let l:mode = visualmode()

  if l:mode ==# "\<C-V>"
    call s:wrap_text_block(l:start, l:end, a:wrapper)
  elseif l:mode ==# 'V'
    call s:wrap_text_line(l:start, l:end, a:wrapper)
  else
    call s:wrap_text_char(l:start, l:end, a:wrapper)
  endif
endfunction

function! s:set_markdown_bold(type) abort
  call s:wrap_text(a:type, s:EMPHASIS_BOLD)
endfunction

function! s:set_markdown_bold_visual() abort
  call s:wrap_text_visual(s:EMPHASIS_BOLD)
endfunction

function! s:set_markdown_italic(type) abort
  call s:wrap_text(a:type, s:EMPHASIS_ITALIC)
endfunction

function! s:set_markdown_italic_visual() abort
  call s:wrap_text_visual(s:EMPHASIS_ITALIC)
endfunction

function! s:remove_markdown_emphasis() abort
  let l:line = getline('.')
  let l:col = col('.')
  let l:nearest_start = -1
  let l:nearest_end = -1
  let l:nearest_wrapper = ''

  for l:wrapper in [s:EMPHASIS_BOLD, s:EMPHASIS_ITALIC]
    let l:wrapper_len = strlen(l:wrapper)
    let l:start = strridx(strpart(l:line, 0, l:col - 1), l:wrapper)
    let l:end = stridx(l:line, l:wrapper, l:col - 1)

    if l:start < 0 || l:end < 0
      continue
    endif

    " Select the closest wrapper pair.
    if l:nearest_start < 0 || l:start > l:nearest_start
      let l:nearest_start = l:start
      let l:nearest_end = l:end
      let l:nearest_wrapper = l:wrapper
    endif
  endfor

  if l:nearest_start < 0
    return
  endif

  let l:wrapper_len = strlen(l:nearest_wrapper)

  let l:new_line = strpart(l:line, 0, l:nearest_start)
        \ . strpart(l:line, l:nearest_start + l:wrapper_len,
        \ l:nearest_end - l:nearest_start - l:wrapper_len)
        \ . strpart(l:line, l:nearest_end + l:wrapper_len)

  call setline('.', l:new_line)
endfunction

function! s:renumber_markdown_list() range
  let l:counters = {}

  for l:lnum in range(a:firstline, a:lastline)
    let l:line = getline(l:lnum)
    let l:match = matchlist(l:line, '^\(\s*\)\(\d\+\)[.)]\s*')

    if !empty(l:match)
      let l:indent = indent(l:lnum)
      let l:key = string(l:indent)

      " Reset counters for deeper indentation levels.
      for l:key_to_remove in keys(l:counters)
        if str2nr(l:key_to_remove) > l:indent
          call remove(l:counters, l:key_to_remove)
        endif
      endfor

      " Increment the counter for the current indentation level.
      if has_key(l:counters, l:key)
        let l:counters[l:key] += 1
      else
        let l:counters[l:key] = 1
      endif

      call setline(
            \ l:lnum,
            \ l:match[1] . l:counters[l:key] . '. ' .
            \ strpart(l:line, strlen(l:match[0]))
            \ )
    endif
  endfor
endfunction

function! s:get_clipboard_url()
  if executable('wl-paste')
    let l:url = system('wl-paste --no-newline')
  elseif has('clipboard')
    let l:url = getreg('+')
  else
    echoerr 'Clipboard is not available'
    return ''
  endif

  let l:url = trim(l:url)

  if l:url !~# '^https\?://'
    echoerr 'Clipboard does not contain a valid URL'
    return ''
  endif

  return l:url
endfunction

function! s:get_url_title(url)
  try
    let l:dom = webapi#html#parseURL(a:url)
    let l:title = l:dom.find('title')

    if empty(l:title)
      return ''
    endif

    return trim(l:title.value())
  catch
    echohl WarningMsg
    echomsg 'Failed to get page title: ' . v:exception
    echohl None
    return ''
  endtry
endfunction

function! s:insert_markdown_link()
  let l:url = s:get_clipboard_url()

  if empty(l:url)
    return
  endif

  let l:link = '[](' . l:url . ')'
  let l:line = getline('.')
  let l:col = col('.')

  call setline('.', strpart(l:line, 0, l:col - 1)
        \ . l:link . strpart(l:line, l:col - 1))

  " Move cursor inside link text
  call cursor(line('.'), l:col + 1)
endfunction

function! s:insert_markdown_link_with_title()
  let l:url = s:get_clipboard_url()

  if empty(l:url)
    return
  endif

  let l:title = s:get_url_title(l:url)

  if empty(l:title)
    echoerr 'Failed to retrieve page title'
    return
  endif

  let l:link = '[' . l:title . '](' . l:url . ')'
  let l:line = getline('.')
  let l:col = col('.')

  call setline('.', strpart(l:line, 0, l:col - 1)
        \ . l:link . strpart(l:line, l:col - 1))

  call cursor(line('.'), l:col + strlen(l:link))
endfunction

function! s:toggle_markdown_todo(start, end) abort
  for l:lnum in range(a:start, a:end)
    let l:line = getline(l:lnum)

    if l:line =~# '^\s*-\s\+\[ \]'
      let l:line = substitute(l:line, '\[ \]', '[x]', '')
    elseif l:line =~# '^\s*-\s\+\[x\]'
      let l:line = substitute(l:line, '\[x\]', '[ ]', '')
    else
      let l:line = substitute(
            \ l:line,
            \ '^\(\s*\)-\s\+',
            \ '\1- [ ] ',
            \ ''
            \ )

      if l:line !~# '^\s*-\s\+\[ \]'
        let l:line = substitute(l:line, '^\(\s*\)', '\1- [ ] ', '')
      endif
    endif

    call setline(l:lnum, l:line)
  endfor
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

setlocal comments=nb:-\ [\ ],nb:-\ [x],b:-,b:1.
setlocal formatoptions-=c
setlocal formatoptions+=r

let mapleader = "\<Space>"

inoremap <f5> <C-r>=Markdown_Complete()<CR>


let s:markdown_mappings = [
      \ {
      \   'group': 'Header',
      \   'mode': 'n',
      \   'key': '<Leader>mh0',
      \   'description': 'Remove heading',
      \   'rhs': ':<C-u>call <SID>set_markdown_header(0)<CR>',
      \ },
      \ {
      \   'group': 'Header',
      \   'mode': 'n',
      \   'key': '<Leader>mh1',
      \   'description': 'Set heading level 1',
      \   'rhs': ':<C-u>call <SID>set_markdown_header(1)<CR>',
      \ },
      \ {
      \   'group': 'Header',
      \   'mode': 'n',
      \   'key': '<Leader>mh2',
      \   'description': 'Set heading level 2',
      \   'rhs': ':<C-u>call <SID>set_markdown_header(2)<CR>',
      \ },
      \ {
      \   'group': 'Header',
      \   'mode': 'n',
      \   'key': '<Leader>mh3',
      \   'description': 'Set heading level 3',
      \   'rhs': ':<C-u>call <SID>set_markdown_header(3)<CR>',
      \ },
      \ {
      \   'group': 'Header',
      \   'mode': 'n',
      \   'key': '<Leader>mh4',
      \   'description': 'Set heading level 4',
      \   'rhs': ':<C-u>call <SID>set_markdown_header(4)<CR>',
      \ },
      \ {
      \   'group': 'Header',
      \   'mode': 'n',
      \   'key': '<Leader>mh5',
      \   'description': 'Set heading level 5',
      \   'rhs': ':<C-u>call <SID>set_markdown_header(5)<CR>',
      \ },
      \ {
      \   'group': 'Header',
      \   'mode': 'n',
      \   'key': '<Leader>mh6',
      \   'description': 'Set heading level 6',
      \   'rhs': ':<C-u>call <SID>set_markdown_header(6)<CR>',
      \ },
      \ {
      \   'group': 'Text decoration',
      \   'mode': 'n',
      \   'key': '<Leader>mb',
      \   'description': 'Apply bold formatting',
      \   'rhs': ':<C-U>set operatorfunc=<SID>set_markdown_bold<CR>g@',
      \ },
      \ {
      \   'group': 'Text decoration',
      \   'mode': 'x',
      \   'key': '<Leader>mb',
      \   'description': 'Apply bold formatting to selection',
      \   'rhs': ':<C-U>call <SID>set_markdown_bold_visual()<CR>',
      \ },
      \ {
      \   'group': 'Text decoration',
      \   'mode': 'n',
      \   'key': '<Leader>mi',
      \   'description': 'Apply italic formatting',
      \   'rhs': ':<C-U>set operatorfunc=<SID>set_markdown_italic<CR>g@',
      \ },
      \ {
      \   'group': 'Text decoration',
      \   'mode': 'x',
      \   'key': '<Leader>mi',
      \   'description': 'Apply italic formatting to selection',
      \   'rhs': ':<C-U>call <SID>set_markdown_italic_visual()<CR>',
      \ },
      \ {
      \   'group': 'Text decoration',
      \   'mode': 'n',
      \   'key': '<Leader>mu',
      \   'description': 'Remove emphasis at cursor',
      \   'rhs': ':<C-u>call <SID>remove_markdown_emphasis()<CR>',
      \ },
      \ {
      \   'group': 'List',
      \   'mode': 'x',
      \   'key': '<Leader>mr',
      \   'description': 'Renumber ordered list',
      \   'rhs': ':<C-u>''<,''>call <SID>renumber_markdown_list()<CR>',
      \ },
      \ {
      \   'group': 'Link',
      \   'mode': 'n',
      \   'key': '<Leader>ml',
      \   'description': 'Insert Markdown link',
      \   'rhs': ':<C-u>call <SID>insert_markdown_link()<CR>',
      \ },
      \ {
      \   'group': 'Link',
      \   'mode': 'n',
      \   'key': '<Leader>mll',
      \   'description': 'Insert Markdown link with title',
      \   'rhs': ':<C-u>call <SID>insert_markdown_link_with_title()<CR>',
      \ },
      \ {
      \   'group': 'List',
      \   'mode': 'n',
      \   'key': '<Leader>mt',
      \   'description': 'Toggle task list marker',
      \   'rhs': ':<C-u>call <SID>toggle_markdown_todo(line(''.''), line(''.''))<CR>',
      \ },
      \ {
      \   'group': 'List',
      \   'mode': 'x',
      \   'key': '<Leader>mt',
      \   'description': 'Toggle task list markers in selection',
      \   'rhs': ':<C-u>call <SID>toggle_markdown_todo(line("''<"), line("''>"))<CR>',
      \ },
      \ ]

function! s:define_markdown_mappings() abort
  for l:item in s:markdown_mappings
    execute l:item.mode .
          \ 'noremap <silent> ' .
          \ l:item.key . ' ' . l:item.rhs
  endfor
endfunction

call s:define_markdown_mappings()

function! s:show_markdown_help() abort
  let l:lines = ['Markdown mappings', '']

  let l:current_group = ''

  for l:item in s:markdown_mappings
    if l:current_group !=# l:item.group
      if !empty(l:current_group)
        call add(l:lines, '')
      endif

      let l:current_group = l:item.group
      call add(l:lines, l:current_group)
    endif

    call add(l:lines, printf(
      \ '  %-18s %s (%s)',
      \ l:item.key,
      \ l:item.description,
      \ l:item.mode ==# 'x' ? 'Visual mode' : 'Normal mode'))
  endfor

  call popup_create(l:lines, {
        \ 'title': ' Markdown Help ',
        \ 'padding': [1, 2, 1, 2],
        \ 'border': [],
        \ 'mapping': 1,
        \ 'filter': 'popup_filter_menu',
        \ })
endfunction

nnoremap <silent> <Leader>mh :<C-u>call <SID>show_markdown_help()<CR>


command! MoveToNextMarkdownHeader call s:move_to_markdown_header(s:NEXT)
command! MoveToPrevMarkdownHeader call s:move_to_markdown_header(s:PREV)
command! MarkdownTableFormat call s:table_format()

inoremap <f5> <C-r>=Markdown_complete()<CR>
