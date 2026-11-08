" GFM Specification: 0.29-gfm (2019-04-06)
" https://github.github.com/gfm/


setlocal comments=
set formatoptions=tcroqln
setlocal formatoptions-=c
setlocal formatoptions+=r

" GFM Spec 4. Leaf blocks {{{1
" 4.2 ATX headings {{{2
" s:set_markdown_header(level) {{{3
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

nnoremap <buffer> <Leader>mh0 :<C-u>call <SID>set_markdown_header(0)<CR>
nnoremap <buffer> <Leader>mh1 :<C-u>call <SID>set_markdown_header(1)<CR>
nnoremap <buffer> <Leader>mh2 :<C-u>call <SID>set_markdown_header(2)<CR>
nnoremap <buffer> <Leader>mh3 :<C-u>call <SID>set_markdown_header(3)<CR>
nnoremap <buffer> <Leader>mh4 :<C-u>call <SID>set_markdown_header(4)<CR>
nnoremap <buffer> <Leader>mh5 :<C-u>call <SID>set_markdown_header(5)<CR>
nnoremap <buffer> <Leader>mh6 :<C-u>call <SID>set_markdown_header(6)<CR>

" 4.5 Fenced code blocks {{{3
" constants {{{3
let s:CODE_BLOCK_MARKER = '```'

" s:insert_code_block() {{{3
function! s:insert_code_block() range
  call append(a:firstline - 1, s:CODE_BLOCK_MARKER)
  call append(a:lastline + 1, s:CODE_BLOCK_MARKER)

  call cursor(a:firstline + 1, 1)
endfunction

nnoremap <buffer> <Leader>mc :<C-u>call <SID>insert_code_block()<CR>
xnoremap <buffer> <Leader>mc :call <SID>insert_code_block()<CR>

" 4.10 Tables (extension) {{{2
" s:table_format() {{{3
function! s:table_format(...) range
  if s:is_table_line(line('.'))
    call s:format_table()
    return
  endif

  if a:0 == 2
    let l:start = min([a:1, a:2])
    let l:end = max([a:1, a:2])
  else
    let l:start = line('.')
    let l:end = line('.')
  endif

  if s:is_csv_range(l:start, l:end)
    call s:convert_csv_table(l:start, l:end)
    call cursor(l:start, 1)
    call s:format_table()
  else
    call s:create_table(l:start, l:end)
  endif
endfunction

" s:is_table_line() {{{3
function! s:is_table_line(lnum)
  return getline(a:lnum) =~# '^\s*|'
endfunction

" s:is_csv_line() {{{3
function! s:is_csv_line(lnum)
  return getline(a:lnum) =~# ','
endfunction

" s:is_csv_range() {{{3
function! s:is_csv_range(start, end)
  for l:lnum in range(a:start, a:end)
    if !s:is_csv_line(l:lnum)
      return 0
    endif
  endfor

  return 1
endfunction

" s:find_csv_range() {{{3
function! s:find_csv_range(lnum)
  let l:start = a:lnum
  let l:end = a:lnum

  " Find the first CSV line.
  while l:start > 1 && s:is_csv_line(l:start - 1)
    let l:start -= 1
  endwhile

  " Find the last CSV line.
  while l:end < line('$') && s:is_csv_line(l:end + 1)
    let l:end += 1
  endwhile

  return [l:start, l:end]
endfunction

" s:convert_csv_table() {{{3
function! s:convert_csv_table(start, end)
  let l:lines = getline(a:start, a:end)
  let l:table = []

  for l:line in l:lines
    let l:line = substitute(l:line, '\s*,\s*', ' | ', 'g')
    call add(l:table, '| ' . l:line . ' |')
  endfor

  " Insert a centered alignment row after the first row.
  let l:column_count = len(split(l:lines[0], ',', 1))
  let l:separator = repeat([':--:'], l:column_count)
  call insert(l:table, '|' . join(l:separator, '|') . '|', 1)

  " Add an empty data row when only one row is selected.
  if len(l:lines) == 1
    call add(l:table, '|' . join(repeat([''], l:column_count), '|') . '|')
  endif

  " Replace only the specified range.
  call setline(a:start, l:table[0])

  if len(l:table) > 1
    call append(a:start, l:table[1:])
  endif

  " Delete only the original lines that were replaced.
  if a:end > a:start
    call deletebufline('%',
          \ a:start + len(l:table),
          \ a:start + len(l:table) + a:end - a:start - 1)
  endif
endfunction

" s:create_table() {{{3
function! s:create_table(start, end)
  let l:lines = getline(a:start, a:end)

  " An empty line creates an empty table.
  if len(l:lines) == 1 && empty(trim(l:lines[0]))
    let l:lines = ['', '']
  endif

  let l:width = 0
  for l:line in l:lines
    let l:width = max([
          \ l:width,
          \ strdisplaywidth(l:line),
          \ ])
  endfor

  " Ensure a minimum separator width of 3.
  let l:width = max([3, l:width])

  let l:table = [
        \ '| ' . l:lines[0] . repeat(' ', l:width - strdisplaywidth(l:lines[0])) . ' |',
        \ '| :' . repeat('-', l:width - 2) . ': |',
        \ ]

  if len(l:lines) == 1
    call add(l:table, '| ' . repeat(' ', l:width) . ' |')
  else
    for l:line in l:lines[1:]
      call add(l:table,
            \ '| ' . l:line . repeat(' ', l:width - strdisplaywidth(l:line)) . ' |')
    endfor
  endif

  call setline(a:start, l:table[0])
  call append(a:start, l:table[1:])

  if a:end > a:start
    call deletebufline('%',
          \ a:start + len(l:table),
          \ a:end + len(l:table) - 1)
  endif

  call cursor(a:start, 1)
endfunction

"s:format_table() {{{3
function! s:format_table()
  let l:lnum = line('.')
  let l:start = l:lnum
  let l:end = l:lnum

  " Find the first table line.
  while l:start > 1 && s:is_table_line(l:start - 1)
    let l:start -= 1
  endwhile

  " Find the last table line.
  while l:end < line('$') && s:is_table_line(l:end + 1)
    let l:end += 1
  endwhile

  let l:lines = getline(l:start, l:end)
  let l:rows = []
  let l:alignments = []
  let l:widths = []

  " Parse rows and determine column widths.
  for l:line in l:lines
    let l:line = substitute(l:line, '^\s*|\s*', '', '')
    let l:line = substitute(l:line, '\s*|$', '', '')
    let l:cells = split(l:line, '|', 1)
    let l:cells = map(l:cells, 'trim(v:val)')

    if s:is_separator_row(l:cells)
      let l:alignments = map(copy(l:cells), 's:get_alignment(v:val)')
      call add(l:rows, {'separator': 1, 'cells': l:cells})
    else
      call add(l:rows, {'separator': 0, 'cells': l:cells})

      for l:i in range(len(l:cells))
        if len(l:widths) <= l:i
          call add(l:widths, 0)
        endif

        let l:widths[l:i] = max([
              \ l:widths[l:i],
              \ strdisplaywidth(l:cells[l:i]),
              \ ])
      endfor
    endif
  endfor

  let l:column_count = len(l:widths)

  if l:column_count == 0
    return
  endif

  " Ensure every row has the same number of columns.
  for l:row in l:rows
    while len(l:row.cells) < l:column_count
      call add(l:row.cells, '')
    endwhile
  endfor

  " Ensure the separator has enough room for alignment markers.
  for l:i in range(l:column_count)
    let l:alignment = get(l:alignments, l:i, 'none')
    let l:min_width = l:alignment ==# 'center' ? 4 : 3
    let l:widths[l:i] = max([l:min_width, l:widths[l:i]])
  endfor

  " Format rows.
  let l:formatted = []

  for l:row in l:rows
    let l:cells = []

    for l:i in range(l:column_count)
      let l:width = l:widths[l:i]

      if l:row.separator
        let l:alignment = get(l:alignments, l:i, 'none')
        let l:hyphens = repeat('-', max([1, l:width - (l:alignment ==# 'center' ? 2 : l:alignment ==# 'none' ? 0 : 1)]))

        if l:alignment ==# 'left'
          let l:cell = ':' . l:hyphens
        elseif l:alignment ==# 'right'
          let l:cell = l:hyphens . ':'
        elseif l:alignment ==# 'center'
          let l:cell = ':' . l:hyphens . ':'
        else
          let l:cell = repeat('-', l:width)
        endif
      else
        let l:cell = l:row.cells[l:i]
        let l:cell .= repeat(' ', l:width - strdisplaywidth(l:cell))
      endif

      call add(l:cells, ' ' . l:cell . ' ')
    endfor

    call add(l:formatted, '|' . join(l:cells, '|') . '|')
  endfor

  call setline(l:start, l:formatted)
  call cursor(l:lnum, 1)
endfunction

" s:is_separator_row() {{{3
function! s:is_separator_row(cells)
  return !empty(a:cells)
        \ && empty(filter(copy(a:cells), 'v:val !~# "^:*-\\+:*$"'))
endfunction

" s:get_alignment() {{{3
function! s:get_alignment(cell)
  let l:left = a:cell =~# '^:'
  let l:right = a:cell =~# ':$'

  if l:left && l:right
    return 'center'
  elseif l:left
    return 'left'
  elseif l:right
    return 'right'
  endif

  return 'none'
endfunction

" s:add_table_column() {{{3
function! s:add_table_column(side)
  if !s:is_table_line(line('.'))
    return
  endif

  let l:lnum = line('.')
  let l:prefix = strpart(getline('.'), 0, col('.') - 1)
  let l:column = max([
        \ 0,
        \ count(split(l:prefix, '\zs'), '|') - 1,
        \ ])

  call s:format_table()

  let l:start = l:lnum
  let l:end = l:lnum

  while l:start > 1 && s:is_table_line(l:start - 1)
    let l:start -= 1
  endwhile

  while l:end < line('$') && s:is_table_line(l:end + 1)
    let l:end += 1
  endwhile

  let l:lines = getline(l:start, l:end)
  let l:formatted = []
  let l:insert_column = 0

  for l:line in l:lines
    let l:line = substitute(l:line, '^\s*|\s*', '', '')
    let l:line = substitute(l:line, '\s*|$', '', '')
    let l:cells = split(l:line, '|', 1)
    let l:cells = map(l:cells, 'trim(v:val)')

    let l:insert_at = a:side ==# 'left'
          \ ? l:column
          \ : l:column + 1
    let l:insert_at = min([l:insert_at, len(l:cells)])

    let l:insert_column = l:insert_at

    if s:is_separator_row(l:cells)
      call insert(l:cells, ':--:', l:insert_at)
    else
      call insert(l:cells, '', l:insert_at)
    endif

    call add(l:formatted, '|' . join(l:cells, '|') . '|')
  endfor

  call setline(l:start, l:formatted[0])
  if len(l:formatted) > 1
    call setline(l:start + 1, l:formatted[1:])
  endif

  call cursor(l:lnum, 1)
  call s:format_table()

  " Move the cursor to the first cell of the inserted column.
  let l:header = getline(l:start)
  let l:column_start = 1

  for l:i in range(l:insert_column)
    let l:separator = stridx(l:header, '|', l:column_start)
    let l:column_start = l:separator + 1
  endfor

  call cursor(l:start, l:column_start + 2)
endfunction

" mappings {{{3
nnoremap <buffer> <Leader>mf :<C-u>call <SID>table_format()<CR>
xnoremap <buffer> <Leader>mf :<C-u>call <SID>table_format(line("'<"), line("'>"))<CR>

nnoremap <buffer> <Leader>mar :<C-u>call <SID>add_table_column('right')<CR>
nnoremap <buffer> <Leader>mal :<C-u>call <SID>add_table_column('left')<CR>

" GFM Spec 5. Container blocks {{{1
" 5.1 Block quotes {{{2
" local options {{{3
setlocal comments+=n:>

" 5.2 List items {{{2
" local options {{{3
setlocal comments+=b:*,b:-,b:+

" s:markdown_list_marker() {{{3
function! s:markdown_list_marker(lnum, offset) abort
  let l:line = getline(a:lnum)
  let l:match = matchlist(l:line, '^\s*\(\d\+\)\([.)]\)\s\+')

  if empty(l:match)
    return ''
  endif

  return max([1, str2nr(l:match[1]) + a:offset]) . l:match[2] . ' '
endfunction

inoremap <buffer> <expr> <CR> "\<CR>\<C-r>=<SID>markdown_list_marker(line('.') - 1, 1)<CR>"
nnoremap <buffer> <expr> o "o\<C-r>=<SID>markdown_list_marker(line('.') - 1, 1)<CR>"
nnoremap <buffer> <expr> O "O\<C-r>=<SID>markdown_list_marker(line('.') + 1, -1)<CR>"

" s:renumber_markdown_list() {{{3
function! s:renumber_markdown_list(start_from_one) range
  let l:counters = {}
  let l:delimiters = {}

  for l:lnum in range(a:firstline, a:lastline)
    let l:line = getline(l:lnum)
    let l:match = matchlist(l:line, '^\(\s*\)\(\d\+\)\([.)]\)\s*')

    if !empty(l:match)
      let l:indent = indent(l:lnum)
      let l:key = string(l:indent)

      " Reset counters and delimiters for deeper indentation levels.
      for l:key_to_remove in keys(l:counters)
        if str2nr(l:key_to_remove) > l:indent
          call remove(l:counters, l:key_to_remove)
          call remove(l:delimiters, l:key_to_remove)
        endif
      endfor

      " Initialize the counter and delimiter for the current level.
      if has_key(l:counters, l:key)
        let l:counters[l:key] += 1
      else
        let l:counters[l:key] = a:start_from_one
              \ ? 1
              \ : str2nr(l:match[2])
        let l:delimiters[l:key] = l:match[3]
      endif

      call setline(
            \ l:lnum,
            \ l:match[1] . l:counters[l:key] . l:delimiters[l:key] . ' ' .
            \ strpart(l:line, strlen(l:match[0]))
            \ )
    endif
  endfor
endfunction

xnoremap <buffer> <Leader>mr :<C-u>'<,'>call <SID>renumber_markdown_list(0)<CR>
xnoremap <buffer> <Leader>mr1 :<C-u>'<,'>call <SID>renumber_markdown_list(1)<CR>

" 5.3 Task list items (extension) {{{2
" s:markdown_todo_marker() {{{3
function! s:markdown_todo_marker(lnum) abort
  let l:line = getline(a:lnum)

  if l:line !~# '^\s*-\s\+\[[ x]\]'
    return ''
  endif

  return '[ ] '
endfunction

inoremap <buffer> <expr> <CR> "\<CR>\<C-r>=<SID>markdown_list_marker(line('.') - 1, 1) . <SID>markdown_todo_marker(line('.') - 1)<CR>"
nnoremap <buffer> <expr> o "o\<C-r>=<SID>markdown_list_marker(line('.') - 1, 1) . <SID>markdown_todo_marker(line('.') - 1)<CR>"
nnoremap <buffer> <expr> O "O\<C-r>=<SID>markdown_list_marker(line('.') + 1, -1) . <SID>markdown_todo_marker(line('.') + 1)<CR>"

" s:toggle_markdown_todo() {{{3
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

nnoremap <buffer> <Leader>mt :<C-u>call <SID>toggle_markdown_todo(line('.'), line('.'))<CR>
xnoremap <buffer> <Leader>mt :<C-u>call <SID>toggle_markdown_todo(line("'<"), line("'>"))<CR>

" s:set_todo() {{{3
function! s:set_todo(done) range
  for l:lnum in range(a:firstline, a:lastline)
    let l:line = getline(l:lnum)

    if l:line =~# '^\s*-\s*\[[ x]\]'
      let l:mark = a:done ? 'x' : ' '
      let l:line = substitute(
            \ l:line,
            \ '^\(\s*-\s*\)\[[ x]\]',
            \ '\1[' . l:mark . ']',
            \ '')
      call setline(l:lnum, l:line)
    endif
  endfor
endfunction

nnoremap <Leader>mx :<C-u>call <SID>set_todo(1)<CR>
nnoremap <Leader>m<Space> :<C-u>call <SID>set_todo(0)<CR>
xnoremap <Leader>mx :<C-u>'<,'>call <SID>set_todo(1)<CR>
xnoremap <Leader>m<Space> :<C-u>'<,'>call <SID>set_todo(0)<CR>

" GFM Spec 6. Inlines {{{1
" 6.4 Emphasis and strong emphasis {{{2
" constants {{{3
let s:EMPHASIS_BOLD = "**"
let s:EMPHASIS_ITALIC = "_"

" s:wrap_text_char() {{{3
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

" s:wrap_text_line() {{{3
function! s:wrap_text_line(start, end, wrapper) abort
  let l:start_line = a:start[1]
  let l:end_line = a:end[1]
  let l:lines = getline(l:start_line, l:end_line)

  let l:lines[0] = a:wrapper . l:lines[0]
  let l:lines[-1] .= a:wrapper

  call setline(l:start_line, l:lines)
endfunction

" s:wrap_text_block() {{{3
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

" s:wrap_text() {{{3
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

" s:wrap_text_visual() {{{3
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

" s:set_markdown_bold() {{{3
function! s:set_markdown_bold(type) abort
  call s:wrap_text(a:type, s:EMPHASIS_BOLD)
endfunction

" s:set_markdown_bold_visual() {{{3
function! s:set_markdown_bold_visual() abort
  call s:wrap_text_visual(s:EMPHASIS_BOLD)
endfunction

" s:set_markdown_italic() {{{3
function! s:set_markdown_italic(type) abort
  call s:wrap_text(a:type, s:EMPHASIS_ITALIC)
endfunction

" s:set_markdown_italic_visual() {{{3
function! s:set_markdown_italic_visual() abort
  call s:wrap_text_visual(s:EMPHASIS_ITALIC)
endfunction

" s:remove_markdown_emphasis() {{{3
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

nnoremap <buffer> <Leader>mb :<C-u>set operatorfunc=<SID>set_markdown_bold<CR>g@
xnoremap <buffer> <Leader>mb :<C-u>call <SID>set_markdown_bold_visual()<CR>

nnoremap <buffer> <Leader>mi :<C-u>set operatorfunc=<SID>set_markdown_italic<CR>g@
xnoremap <buffer> <Leader>mi :<C-u>call <SID>set_markdown_italic_visual()<CR>

nnoremap <buffer> <Leader>mu :<C-u>call <SID>remove_markdown_emphasis()<CR>

" 6.6 Links {{{2
" s:get_clipboard_url() {{{3
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

" s:get_url_title() {{{3
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

" s:insert_markdown_link() {{{3
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

" s:insert_markdown_link_with_title() {{{3
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

nnoremap <buffer> <Leader>ml :<C-u>call <SID>insert_markdown_link()<CR>
nnoremap <buffer> <Leader>mll :<C-u>call <SID>insert_markdown_link_with_title()<CR>

" {{{1 Custom features
" {{{2 Completion

" Markdown_complete() {{{3
function! Markdown_complete()
  call complete(col('.'), [
        \ {'word': '1. ', 'menu': 'order list'},
        \ {'word': '- ', 'menu': 'unorder list'},
        \ {'word': '[]()', 'menu': 'link'}
        \ ])
  return ''
endfunction

inoremap <f5> <C-r>=Markdown_complete()<CR>

" Modeline {{{1
" vim:set ts=8 sts=2 sw=2 tw=0:
" vim:set foldmethod=marker:
