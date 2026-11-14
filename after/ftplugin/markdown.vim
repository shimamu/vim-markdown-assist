" GFM Specification: 0.29-gfm (2019-04-06)
" https://github.github.com/gfm/

" Global options {{{1
" Table formatting {{{2
" Minimum cell width {{{3
if !exists('g:MD_TABLE_CELL_MIN_WIDTH')
  let g:MD_TABLE_CELL_MIN_WIDTH = 0
endif

" Local options {{{1
" Automatic formatting {{{2
" Comment leader {{{3
setlocal comments=

" Continue comments on Enter {{{3
setlocal formatoptions+=r

" Continue comments with o and O {{{3
setlocal formatoptions+=o

" Numbered list formatting {{{3
setlocal formatoptions+=n

" GFM Spec 4. Leaf blocks {{{1
" 4.2 ATX headings {{{2
" feat: header insertion and modification (normal mode) {{{3
" s:md_set_header(level) {{{4
function! s:md_set_header(level) abort
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

nnoremap <buffer> <Leader>mh1 :<C-u>call <SID>md_set_header(1)<CR>
nnoremap <buffer> <Leader>mh2 :<C-u>call <SID>md_set_header(2)<CR>
nnoremap <buffer> <Leader>mh3 :<C-u>call <SID>md_set_header(3)<CR>
nnoremap <buffer> <Leader>mh4 :<C-u>call <SID>md_set_header(4)<CR>
nnoremap <buffer> <Leader>mh5 :<C-u>call <SID>md_set_header(5)<CR>
nnoremap <buffer> <Leader>mh6 :<C-u>call <SID>md_set_header(6)<CR>
nnoremap <buffer> <Leader>mh0 :<C-u>call <SID>md_set_header(0)<CR>

" 4.5 Fenced code blocks {{{2
" feat: fenced code block wrapping (visual mode) {{{3
" constants {{{4
let s:CODE_BLOCK_MARKER = '```'

" s:md_wrap_code_block() {{{4
function! s:md_wrap_code_block() range
  call append(a:firstline - 1, s:CODE_BLOCK_MARKER)
  call append(a:lastline + 1, s:CODE_BLOCK_MARKER)

  call cursor(a:firstline + 1, 1)
endfunction

xnoremap <buffer> <Leader>mc :call <SID>md_wrap_code_block()<CR>

" 4.10 Tables (extension) {{{2
" feat: convert text and CSV to Markdown table and format it (normal/visual mode) {{{3
" constants {{{4
const s:MD_ALIGNMENT_LEFT = ':-'
const s:MD_ALIGNMENT_CENTER = ':-:'
const s:MD_ALIGNMENT_RIGHT = '-:'
const s:MD_ALIGNMENT_NONE = '-'

" s:md_table_convert() {{{4
function! s:md_table_convert(...) range
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

  call s:convert_csv_to_table(l:start, l:end)
  call cursor(l:start, 1)
  call s:format_table()
endfunction

nnoremap <buffer> <Leader>mf :<C-u>call <SID>md_table_convert()<CR>
xnoremap <buffer> <Leader>mf :<C-u>call <SID>md_table_convert(line("'<"), line("'>"))<CR>

" s:is_table_line() {{{4
function! s:is_table_line(lnum)
  return getline(a:lnum) =~# '^\s*|'
endfunction

" s:convert_csv_to_table() {{{4
function! s:convert_csv_to_table(start, end)
  let l:lines = getline(a:start, a:end)
  let l:table = []

  for l:line in l:lines
    let l:line = substitute(l:line, '\s*,\s*', ' | ', 'g')
    call add(l:table, '| ' . l:line . ' |')
  endfor

  " Insert a centered alignment row after the first row.
  let l:column_count = len(split(l:lines[0], ',', 1))
  let l:separator = repeat([s:MD_ALIGNMENT_CENTER], l:column_count)
  call insert(l:table, s:build_table_row(l:separator), 1)

  " Add an empty data row when only one row is selected.
  if len(l:lines) == 1
    let l:blank_cells = repeat([''], l:column_count)
    call add(l:table, s:build_table_row(l:blank_cells))
  endif

  call s:replace_lines(a:start, a:end, l:table)
endfunction

"s:build_table_row() {{{4
function! s:build_table_row(cells)
  return '|' . join(a:cells, '|') . '|'
endfunction

" s:replace_lines() {{{4
function! s:replace_lines(start, end, lines)
  call append(a:start - 1, a:lines)
  call deletebufline('%',
        \ a:start + len(a:lines),
        \ a:start + len(a:lines) + a:end - a:start)
endfunction

"s:format_table() {{{4
function! s:format_table()
  let l:lnum = line('.')

  let [l:start, l:end] = s:get_table_range(line('.'))

  let l:lines = getline(l:start, l:end)
  let l:rows = []
  let l:alignments = []
  let l:widths = []

  " Parse rows and determine column widths.
  for l:line in l:lines
    let l:cells = s:parse_table_row(l:line)

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
    let l:alignment = get(l:alignments, l:i, s:MD_ALIGNMENT_NONE)
    let l:min_width = max([len(l:alignment), g:MD_TABLE_CELL_MIN_WIDTH])
    let l:widths[l:i] = max([l:min_width, l:widths[l:i]])
  endfor

  " Format rows.
  let l:formatted = []

  for l:row in l:rows
    let l:cells = []

    for l:i in range(l:column_count)
      let l:width = l:widths[l:i]

      if l:row.separator
        let l:alignment = get(l:alignments, l:i, s:MD_ALIGNMENT_NONE)
        let l:colon_count = count(split(l:alignment, '\zs'), ':')
        let l:hyphens = repeat('-', max([1, l:width - l:colon_count]))

        if l:alignment ==# s:MD_ALIGNMENT_LEFT
          let l:cell = ':' . l:hyphens
        elseif l:alignment ==# s:MD_ALIGNMENT_RIGHT
          let l:cell = l:hyphens . ':'
        elseif l:alignment ==# s:MD_ALIGNMENT_CENTER
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

    call add(l:formatted, s:build_table_row(l:cells))
  endfor

  call setline(l:start, l:formatted)
  call cursor(l:lnum, 1)
endfunction

"s:parse_table_row() {{{4
function! s:parse_table_row(line)
  let l:line = substitute(a:line, '^\s*|\s*', '', '')
  let l:line = substitute(l:line, '\s*|$', '', '')
  let l:cells = split(l:line, '|', 1)

  return map(l:cells, 'trim(v:val)')
endfunction

" s:get_table_range() {{{4
function! s:get_table_range(lnum)
  let l:start = a:lnum
  let l:end = a:lnum

  while l:start > 1 && s:is_table_line(l:start - 1)
    let l:start -= 1
  endwhile

  while l:end < line('$') && s:is_table_line(l:end + 1)
    let l:end += 1
  endwhile

  return [l:start, l:end]
endfunction

" s:is_separator_row() {{{4
function! s:is_separator_row(cells)
  return !empty(a:cells)
        \ && empty(filter(copy(a:cells), 'v:val !~# "^:*-\\+:*$"'))
endfunction

" s:get_alignment() {{{4
function! s:get_alignment(cell)
  let l:left = a:cell =~# '^:'
  let l:right = a:cell =~# ':$'

  if l:left && l:right
    return s:MD_ALIGNMENT_CENTER
  elseif l:left
    return s:MD_ALIGNMENT_LEFT
  elseif l:right
    return s:MD_ALIGNMENT_RIGHT
  endif

  return s:MD_ALIGNMENT_NONE
endfunction

" feat: table column insertion (normal mode) {{{3
" s:md_table_add_column() {{{4
function! s:md_table_add_column(side)
  if !s:is_table_line(line('.'))
    return
  endif

  let l:lnum = line('.')
  let l:prefix = strpart(getline('.'), 0, col('.') - 1)
  let l:column = max([
        \ 0,
        \ count(split(l:prefix, '\zs'), '|') - 1,
        \ ])

  " Fill missing cells before adding a column.
  call s:format_table()

  let [l:start, l:end] = s:get_table_range(l:lnum)

  let l:lines = getline(l:start, l:end)
  let l:formatted = []
  let l:insert_column = a:side ==# s:MD_ALIGNMENT_LEFT
        \ ? l:column
        \ : l:column + 1

  for l:line in l:lines
    let l:cells = s:parse_table_row(l:line)

    let l:cell = s:is_separator_row(l:cells)
          \ ? s:MD_ALIGNMENT_CENTER
          \ : ''
    call insert(l:cells, l:cell, l:insert_column)

    call add(l:formatted, s:build_table_row(l:cells))
  endfor

  call s:replace_lines(l:start, l:end, l:formatted)

  call cursor(l:lnum, 1)
  call s:format_table()

  " Move the cursor to the first cell of the inserted column.
  let l:header = getline(l:start)
  let l:separator_col = 1

  for l:i in range(l:insert_column)
    let l:separator_col = stridx(l:header, '|', l:separator_col) + 1
  endfor

  call cursor(l:start, l:separator_col + 2)
endfunction

execute 'nnoremap <buffer> <Leader>mar :<C-u>call <SID>md_table_add_column(' . string(s:MD_ALIGNMENT_RIGHT) . ')<CR>'
execute 'nnoremap <buffer> <Leader>mal :<C-u>call <SID>md_table_add_column(' . string(s:MD_ALIGNMENT_LEFT) . ')<CR>'

" GFM Spec 5. Container blocks {{{1
" 5.1 Block quotes {{{2
" feat: block quote continuation {{{3
" local options {{{4
setlocal comments+=n:>

" 5.2 List items {{{2
" feat: bullet list continuation {{{3
" local options {{{4
setlocal comments+=b:*,b:-,b:+

" feat: ordered list continuation {{{3
" s:md_continue_list() {{{4
function! s:md_continue_list(lnum, offset) abort
  let l:result = s:continue_ordered_list(a:lnum, a:offset)
  let l:result .= s:continue_task_list(a:lnum)
  return l:result
endfunction

inoremap <buffer> <expr> <CR> "\<CR>\<C-r>=<SID>md_continue_list(line('.') - 1, 1)<CR>"
nnoremap <buffer> <expr> o "o\<C-r>=<SID>md_continue_list(line('.') - 1, 1)<CR>"
nnoremap <buffer> <expr> O "O\<C-r>=<SID>md_continue_list(line('.') + 1, -1)<CR>"

" s:continue_ordered_list() {{{4
function! s:continue_ordered_list(lnum, offset) abort
  let l:line = getline(a:lnum)
  let l:match = matchlist(l:line, '^\s*\(\d\+\)\([.)]\)\s\+')

  if empty(l:match)
    return ''
  endif

  return max([1, str2nr(l:match[1]) + a:offset]) . l:match[2] . ' '
endfunction

" feat: ordered list renumbering {{{3
" s:md_renumber_ordered_list() {{{4
function! s:md_renumber_ordered_list(start_from_one) range
  let l:counters = {}
  let l:delimiters = {}

  for l:lnum in range(a:firstline, a:lastline)
    let l:line = getline(l:lnum)
    let l:match = matchlist(l:line, '^\(\s*\)\(\d\+\)\([.)]\)\s*')

    if !empty(l:match)
      let l:indent = indent(l:lnum)
      let l:indent_key = string(l:indent)

      " Reset counters and delimiters for deeper indentation levels.
      for l:existing_indent_key in keys(l:counters)
        if str2nr(l:existing_indent_key) > l:indent
          call remove(l:counters, l:existing_indent_key)
          call remove(l:delimiters, l:existing_indent_key)
        endif
      endfor

      " Initialize the counter and delimiter for the current level.
      if has_key(l:counters, l:indent_key)
        let l:counters[l:indent_key] += 1
      else
        let l:counters[l:indent_key] = a:start_from_one
              \ ? 1
              \ : str2nr(l:match[2])
        let l:delimiters[l:indent_key] = l:match[3]
      endif

      call setline(
            \ l:lnum,
            \ l:match[1] . l:counters[l:indent_key] . l:delimiters[l:indent_key] . ' ' .
            \ strpart(l:line, strlen(l:match[0]))
            \ )
    endif
  endfor
endfunction

xnoremap <buffer> <Leader>mr :<C-u>'<,'>call <SID>md_renumber_ordered_list(0)<CR>
xnoremap <buffer> <Leader>mr1 :<C-u>'<,'>call <SID>md_renumber_ordered_list(1)<CR>

" feat: line wrapping {{{3
" s:md_format_line_wrapping() {{{4
function! s:md_format_line_wrapping() abort
  let l:start = v:lnum
  let l:end = l:start + v:count - 1
  let l:lines = getline(l:start, l:end)
  let l:format_blocks = []
  let l:i = 0

  " Group lines into formatting blocks
  while l:i < len(l:lines)
    if call s:is_blank_line(l:lines[l:i])
      let l:i += 1
      continue
    endif

    let l:block_start = l:i
    let l:is_list = l:lines[l:i]
          \ =~# '^\s*[-*+]\s\+\%(\[[ xX]\]\s\+\)\?'

    let l:i += 1

    while l:i < len(l:lines)
      if call s:is_blank_line(l:lines[l:i])
        break
      endif

      if l:lines[l:i] =~# '^\s*[-*+]\s\+\%(\[[ xX]\]\s\+\)\?'
        break
      endif

      let l:i += 1
    endwhile

    call add(l:format_blocks, {
          \ 'start': l:start + l:block_start,
          \ 'end': l:start + l:i - 1,
          \ 'is_list': l:is_list
          \ })
  endwhile

  " Format blocks from bottom to top
  for l:block in reverse(l:format_blocks)
    if l:block.is_list
      call s:format_list_item_wrapping(l:block.start, l:block.end)
    else
      call s:format_text_wrapping(l:block.start, l:block.end)
    endif
  endfor

  return 0
endfunction

setlocal formatexpr=<SID>md_format_line_wrapping()

" s:is_blank_line() {{{4
function! s:is_blank_line(line) abort
  return a:line =~# '^\s*$'
endfunction

" s:format_list_item_wrapping() {{{4
function! s:format_list_item_wrapping(start, end) abort
  let l:lines = getline(a:start, a:end)
  let l:match = matchlist(
        \ l:lines[0],
        \ '^\(\s*\)\([-*+]\s\+\(\[[ xX]\]\s\+\)\?\)\(.*\)$')

  if empty(l:match)
    return
  endif

  let l:indent = l:match[1]
  let l:marker = l:match[2]
  let l:continuation_indent =
        \ l:indent . repeat(' ', strdisplaywidth(l:marker))

  " Remove the list marker and indentation
  let l:lines[0] = l:match[4]

  for l:i in range(1, len(l:lines) - 1)
    let l:lines[l:i] = substitute(
          \ l:lines[l:i],
          \ '^' . escape(l:continuation_indent, '\'),
          \ '', '')
  endfor

  call setline(a:start, l:lines)

  " Temporarily disable formatexpr and adjust textwidth
  let l:formatexpr = &l:formatexpr
  let l:textwidth = &l:textwidth

  if l:textwidth > 0
    let &l:textwidth = max([
          \ 1,
          \ l:textwidth
          \ - strdisplaywidth(l:indent . l:marker)
          \ ])
  endif

  setlocal formatexpr=

  " Record the line count before formatting
  let l:line_count = line('$')

  try
    " Run the default formatting on the current item
    call cursor(a:start, 1)

    if a:end > a:start
      execute 'normal! V' . (a:end - a:start) . 'jgq'
    else
      normal! Vgq
    endif
  finally
    let &l:formatexpr = l:formatexpr
    let &l:textwidth = l:textwidth
  endtry

  " Calculate the formatted range
  let l:formatted_end = a:end + (line('$') - l:line_count)

  " Restore the list marker and indentation
  let l:lines = getline(a:start, l:formatted_end)

  let l:lines[0] = l:indent . l:marker . l:lines[0]

  for l:i in range(1, len(l:lines) - 1)
    if l:lines[l:i] !~# '^\s*$'
      let l:lines[l:i] = l:continuation_indent . l:lines[l:i]
    endif
  endfor

  call setline(a:start, l:lines)
endfunction

" s:format_text_wrapping() {{{4
function! s:format_text_wrapping(start, end) abort
  let l:formatexpr = &l:formatexpr

  setlocal formatexpr=

  try
    call cursor(a:start, 1)

    if a:end > a:start
      execute 'normal! V' . (a:end - a:start) . 'jgq'
    else
      normal! Vgq
    endif
  finally
    let &l:formatexpr = l:formatexpr
  endtry
endfunction

" 5.3 Task list items (extension) {{{2
" feat: task list continuation {{{3
" s:continue_task_list() {{{4
function! s:continue_task_list(lnum) abort
  let l:line = getline(a:lnum)

  if l:line !~# '^\s*-\s\+\[[ x]\]'
    return ''
  endif

  return '[ ] '
endfunction

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
" 6.3 Code spans {{{2
" constants {{{3
let s:CODE_SPAN = "`"

" s:set_markdown_code() {{{3
function! s:set_markdown_code(type) abort
  call s:wrap_text(a:type, s:CODE_SPAN)
endfunction

nnoremap <buffer> <Leader>mc :<C-u>set operatorfunc=<SID>set_markdown_code<CR>g@

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

nnoremap <buffer> <Leader>mb :<C-u>set operatorfunc=<SID>set_markdown_bold<CR>g@

" s:set_markdown_bold_visual() {{{3
function! s:set_markdown_bold_visual() abort
  call s:wrap_text_visual(s:EMPHASIS_BOLD)
endfunction

xnoremap <buffer> <Leader>mb :<C-u>call <SID>set_markdown_bold_visual()<CR>

" s:set_markdown_italic() {{{3
function! s:set_markdown_italic(type) abort
  call s:wrap_text(a:type, s:EMPHASIS_ITALIC)
endfunction

nnoremap <buffer> <Leader>mi :<C-u>set operatorfunc=<SID>set_markdown_italic<CR>g@

" s:set_markdown_italic_visual() {{{3
function! s:set_markdown_italic_visual() abort
  call s:wrap_text_visual(s:EMPHASIS_ITALIC)
endfunction

xnoremap <buffer> <Leader>mi :<C-u>call <SID>set_markdown_italic_visual()<CR>

" s:remove_markdown_wrapper() {{{3
function! s:remove_markdown_wrapper() abort
  let l:line = getline('.')
  let l:col = col('.')
  let l:nearest_start = -1
  let l:nearest_end = -1
  let l:nearest_wrapper = ''

  for l:wrapper in [s:CODE_SPAN, s:EMPHASIS_BOLD, s:EMPHASIS_ITALIC]
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

nnoremap <buffer> <Leader>mu :<C-u>call <SID>remove_markdown_wrapper()<CR>

" 6.6 Links {{{2
" s:get_clipboard_url() {{{3
function! s:get_clipboard_url()
  if executable('wl-paste')
    let l:url = system('wl-paste --no-newline')
  elseif has('clipboard')
    let l:url = getreg('+')
  else
    return ''
  endif

  let l:url = trim(l:url)

  if l:url !~# '^https\?://'
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
  let l:title = empty(l:url) ? '' : s:get_url_title(l:url)
  let l:link = '[' . l:title . '](' . l:url . ')'
  let l:line = getline('.')
  let l:col = col('.')

  call setline('.', strpart(l:line, 0, l:col - 1)
        \ . l:link . strpart(l:line, l:col - 1))

  call cursor(line('.'), l:col + strlen(l:title) + 1)
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
