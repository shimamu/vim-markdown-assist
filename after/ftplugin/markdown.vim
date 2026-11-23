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
" feat: heading insertion (normal mode) {{{3
" s:md_insert_heading(level) {{{4
function! s:md_insert_heading(level) abort
  if a:level < 1 || a:level > 6
    return
  endif

  let l:line = getline('.')

  " Remove existing header marks
  let l:line = substitute(l:line, '^#\+\s*', '', '')

  " Add specified number of header marks
  let l:line = repeat('#', a:level) . ' ' . l:line

  call setline('.', l:line)
endfunction

nnoremap <buffer> <Leader>mhi1 :<C-u>call <SID>md_insert_heading(1)<CR>
nnoremap <buffer> <Leader>mhi2 :<C-u>call <SID>md_insert_heading(2)<CR>
nnoremap <buffer> <Leader>mhi3 :<C-u>call <SID>md_insert_heading(3)<CR>
nnoremap <buffer> <Leader>mhi4 :<C-u>call <SID>md_insert_heading(4)<CR>
nnoremap <buffer> <Leader>mhi5 :<C-u>call <SID>md_insert_heading(5)<CR>
nnoremap <buffer> <Leader>mhi6 :<C-u>call <SID>md_insert_heading(6)<CR>

" feat: heading unwrapping (normal mode) {{{3
" s:md_unwrap_heading() {{{4
function! s:md_unwrap_heading() abort
  let l:line = getline('.')
  let l:line = substitute(l:line, '^#\+\s*', '', '')
  call setline('.', l:line)
endfunction

nnoremap <buffer> <Leader>mhu :<C-u>call <SID>md_unwrap_heading()<CR>

" 4.5 Fenced code blocks {{{2
" feat: fenced code block wrapping (normal/visual mode) {{{3
" constants {{{4
const s:MD_FENCED_CODE_BLOCK = '```'

" s:md_wrap_fenced_code_block() {{{4
function! s:md_wrap_fenced_code_block(start, end) abort
  call append(a:start - 1, s:MD_FENCED_CODE_BLOCK)
  call append(a:end + 1, s:MD_FENCED_CODE_BLOCK)

  call cursor(a:start + 1, 1)
endfunction

nnoremap <buffer> <Leader>mfw :<C-u>call <SID>md_wrap_fenced_code_block(line('.'), line('.'))<CR>
xnoremap <buffer> <Leader>mfw :<C-u>call <SID>md_wrap_fenced_code_block(line("'<"), line("'>"))<CR>

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
    let l:start_lnum = min([a:1, a:2])
    let l:end_lnum = max([a:1, a:2])
  else
    let l:start_lnum = line('.')
    let l:end_lnum = line('.')
  endif

  call s:convert_csv_to_table(l:start_lnum, l:end_lnum)
  call cursor(l:start_lnum, 1)
  call s:format_table()
endfunction

nnoremap <buffer> <Leader>mtf :<C-u>call <SID>md_table_convert()<CR>
xnoremap <buffer> <Leader>mtf :<C-u>call <SID>md_table_convert(line("'<"), line("'>"))<CR>

" s:is_table_line() {{{4
function! s:is_table_line(lnum)
  return getline(a:lnum) =~# '^\s*|'
endfunction

" s:convert_csv_to_table() {{{4
function! s:convert_csv_to_table(start_lnum, end_lnum)
  let l:lines = getline(a:start_lnum, a:end_lnum)
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

  call s:replace_lines(a:start_lnum, a:end_lnum, l:table)
endfunction

"s:build_table_row() {{{4
function! s:build_table_row(cells)
  return '|' . join(a:cells, '|') . '|'
endfunction

" s:replace_lines() {{{4
function! s:replace_lines(start_lnum, end_lnum, lines)
  call append(a:start_lnum - 1, a:lines)
  call deletebufline('%',
        \ a:start_lnum + len(a:lines),
        \ a:start_lnum + len(a:lines) + a:end_lnum - a:start_lnum)
endfunction

"s:format_table() {{{4
function! s:format_table()
  let l:lnum = line('.')

  let [l:start_lnum, l:end_lnum] = s:get_table_range(l:lnum)

  let l:lines = getline(l:start_lnum, l:end_lnum)
  let l:rows = []
  let l:alignments = []
  let l:column_widths = []

  " Parse rows and determine column widths.
  for l:line in l:lines
    let l:cells = s:parse_table_row(l:line)

    if s:is_separator_row(l:cells)
      let l:alignments = map(copy(l:cells), 's:get_alignment(v:val)')
      call add(l:rows, {'separator': 1, 'cells': l:cells})
    else
      call add(l:rows, {'separator': 0, 'cells': l:cells})

      for l:i in range(len(l:cells))
        if len(l:column_widths) <= l:i
          call add(l:column_widths, 0)
        endif

        let l:column_widths[l:i] = max([
              \ l:column_widths[l:i],
              \ strdisplaywidth(l:cells[l:i]),
              \ ])
      endfor
    endif
  endfor

  let l:column_count = len(l:column_widths)

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
    let l:column_widths[l:i] = max([l:min_width, l:column_widths[l:i]])
  endfor

  " Format rows.
  let l:formatted = []

  for l:row in l:rows
    let l:cells = []

    for l:i in range(l:column_count)
      let l:column_width = l:column_widths[l:i]

      if l:row.separator
        let l:alignment = get(l:alignments, l:i, s:MD_ALIGNMENT_NONE)
        let l:colon_count = count(split(l:alignment, '\zs'), ':')
        let l:hyphens = repeat('-', max([1, l:column_width - l:colon_count]))

        if l:alignment ==# s:MD_ALIGNMENT_LEFT
          let l:cell = ':' . l:hyphens
        elseif l:alignment ==# s:MD_ALIGNMENT_RIGHT
          let l:cell = l:hyphens . ':'
        elseif l:alignment ==# s:MD_ALIGNMENT_CENTER
          let l:cell = ':' . l:hyphens . ':'
        else
          let l:cell = repeat('-', l:column_width)
        endif
      else
        let l:cell = l:row.cells[l:i]
        let l:cell .= repeat(' ', l:column_width - strdisplaywidth(l:cell))
      endif

      call add(l:cells, ' ' . l:cell . ' ')
    endfor

    call add(l:formatted, s:build_table_row(l:cells))
  endfor

  call setline(l:start_lnum, l:formatted)
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
  let l:start_lnum = a:lnum
  let l:end_lnum = a:lnum

  while l:start_lnum > 1 && s:is_table_line(l:start_lnum - 1)
    let l:start_lnum -= 1
  endwhile

  while l:end_lnum < line('$') && s:is_table_line(l:end_lnum + 1)
    let l:end_lnum += 1
  endwhile

  return [l:start_lnum, l:end_lnum]
endfunction

" s:is_separator_row() {{{4
function! s:is_separator_row(cells)
  return !empty(a:cells)
        \ && empty(filter(copy(a:cells), 'v:val !~# "^:*-\\+:*$"'))
endfunction

" s:get_alignment() {{{4
function! s:get_alignment(cell)
  let l:is_left = a:cell =~# '^:'
  let l:is_right = a:cell =~# ':$'

  if l:is_left && l:is_right
    return s:MD_ALIGNMENT_CENTER
  elseif l:is_left
    return s:MD_ALIGNMENT_LEFT
  elseif l:is_right
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
  let l:column_idx = max([
        \ 0,
        \ count(split(l:prefix, '\zs'), '|') - 1,
        \ ])

  " Fill missing cells before adding a column.
  call s:format_table()

  let [l:start_lnum, l:end_lnum] = s:get_table_range(l:lnum)

  let l:lines = getline(l:start_lnum, l:end_lnum)
  let l:formatted = []
  let l:insert_column_idx = a:side ==# s:MD_ALIGNMENT_LEFT
        \ ? l:column_idx
        \ : l:column_idx + 1

  for l:line in l:lines
    let l:cells = s:parse_table_row(l:line)

    let l:cell = s:is_separator_row(l:cells)
          \ ? s:MD_ALIGNMENT_CENTER
          \ : ''
    call insert(l:cells, l:cell, l:insert_column_idx)

    call add(l:formatted, s:build_table_row(l:cells))
  endfor

  call s:replace_lines(l:start_lnum, l:end_lnum, l:formatted)

  call cursor(l:lnum, 1)
  call s:format_table()

  " Move the cursor to the first cell of the inserted column.
  let l:header_line = getline(l:start_lnum)
  let l:separator_col = 1

  for l:i in range(l:insert_column_idx)
    let l:separator_col = stridx(l:header_line, '|', l:separator_col) + 1
  endfor

  call cursor(l:start_lnum, l:separator_col + 2)
endfunction

execute 'nnoremap <buffer> <Leader>mtal :<C-u>call <SID>md_table_add_column(' . string(s:MD_ALIGNMENT_RIGHT) . ')<CR>'
execute 'nnoremap <buffer> <Leader>mtah :<C-u>call <SID>md_table_add_column(' . string(s:MD_ALIGNMENT_LEFT) . ')<CR>'

" GFM Spec 5. Container blocks {{{1
" 5.1 Block quotes {{{2
" feat: block quote continuation {{{3
" local options {{{4
setlocal comments+=n:>

" feat: block quote insertion (normal/visual mode) {{{3
function! s:md_insert_block_quote() range abort
  for l:lnum in range(a:firstline, a:lastline)
    call setline(l:lnum, '> ' . getline(l:lnum))
  endfor
endfunction

nnoremap <buffer> <Leader>mqi :<C-u>call <SID>md_insert_block_quote()<CR>
xnoremap <buffer> <Leader>mqi :call <SID>md_insert_block_quote()<CR>

" feat: block quote formatting (normal/visual mode) {{{3
" s:md_format_block_quote() {{{4
function! s:md_format_block_quote() range abort
  for l:lnum in range(a:firstline, a:lastline)
    let l:line = getline(l:lnum)

    if l:line =~# '^ \{4}'
      continue
    endif

    let l:match = matchlist(l:line, '^ \{0,3}\(\(>[ \t]*\)*>[ \t]\?\)\(.*\)$')

    if empty(l:match)
      continue
    endif

    let l:quote_markers = l:match[1]
    let l:text = l:match[3]

    if l:quote_markers !~# '>'
      continue
    endif

    let l:quote_count = count(l:quote_markers, '>')
    let l:markers = join(repeat(['>'], l:quote_count), ' ')

    call setline(l:lnum, l:markers . ' ' . l:text)
  endfor
endfunction

nnoremap <buffer> <Leader>mqf :<C-u>call <SID>md_format_block_quote()<CR>
xnoremap <buffer> <Leader>mqf :<C-u>'<,'>call <SID>md_format_block_quote()<CR>

" feat: block quote unwrapping (normal/visual mode) {{{3
" s:md_unwrap_block_quote() {{{4
function! s:md_unwrap_block_quote() range abort
  call s:remove_block_quote_markers(0, a:firstline, a:lastline)
endfunction

nnoremap <buffer> <Leader>mqu :<C-u>call <SID>md_unwrap_block_quote()<CR>
xnoremap <buffer> <Leader>mqu :<C-u>'<,'>call <SID>md_unwrap_block_quote()<CR>

" s:remove_block_quote_markers() {{{4
function! s:remove_block_quote_markers(delete_all, start_lnum, end_lnum) abort
  for l:lnum in range(a:start_lnum, a:end_lnum)
    let l:line = getline(l:lnum)
    let l:match = matchlist(l:line, '^\( \{0,3}\)>[ \t]\?')

    if empty(l:match)
      continue
    endif

    let l:removal_len = strlen(l:match[0])

    if a:delete_all
      let l:match = matchlist(l:line, '^\( \{0,3}\)\(>[ \t]*\)*>[ \t]\?')
      let l:removal_len = strlen(l:match[0])
    endif

    call setline(l:lnum, strpart(l:line, l:removal_len))
  endfor
endfunction

" feat: block quote deletion (normal/visual mode) {{{3
" s:md_delete_block_quote() {{{4
function! s:md_delete_block_quote() range abort
  call s:remove_block_quote_markers(1, a:firstline, a:lastline)
endfunction

nnoremap <buffer> <Leader>mqd :<C-u>call <SID>md_delete_block_quote()<CR>
xnoremap <buffer> <Leader>mqd :<C-u>'<,'>call <SID>md_delete_block_quote()<CR>

" 5.2 List items {{{2
" feat: bullet list items continuation {{{3
" local options {{{4
setlocal comments+=b:*,b:-,b:+

" feat: bullet list items insertion (normal/visual mode) {{{3
" s:md_insert_bullet_list_items() {{{4
function! s:md_insert_bullet_list_items(visual_mode, ignore_indent) range abort
  call s:insert_list_items(
        \ a:firstline,
        \ a:lastline,
        \ '- ',
        \ a:visual_mode,
        \ a:ignore_indent)
endfunction

nnoremap <buffer> <Leader>mli :<C-u>call <SID>md_insert_bullet_list_items(0, 0)<CR>
xnoremap <buffer> <Leader>mli :<C-u>'<,'>call <SID>md_insert_bullet_list_items(1, 0)<CR>

xnoremap <buffer> <Leader>mlI :<C-u>'<,'>call <SID>md_insert_bullet_list_items(1, 1)<CR>

" s:insert_list_items() {{{4
function! s:insert_list_items(start_lnum, end_lnum, marker, visual_mode, ignore_indent) abort
  let l:base_indent = -1
  let l:base_indent_str = ''

  for l:lnum in range(a:start_lnum, a:end_lnum)
    let l:line = getline(l:lnum)

    " Skip blank lines.
    if l:line =~# '^\s*$'
      continue
    endif

    if a:visual_mode
      if a:ignore_indent
        let l:indent = matchstr(l:line, '^\s*')
      else
        " Get the indentation of the first non-blank line.
        if l:base_indent < 0
          let l:base_indent = indent(l:lnum)
          let l:base_indent_str = matchstr(l:line, '^\s*')
        endif

        let l:indent = indent(l:lnum)

        " Stop when reaching a shallower indentation level.
        if l:indent < l:base_indent
          break
        endif

        " Skip lines with deeper indentation.
        if l:indent > l:base_indent
          continue
        endif

        let l:indent = l:base_indent_str
      endif
    else
      let l:indent = matchstr(l:line, '^\s*')

      if l:lnum > 1 && indent(l:lnum) <= indent(l:lnum - 1)
        let l:indent = s:get_previous_list_item_indent(l:lnum)
      endif
    endif

    if a:marker ==# '- [ ] '
      " Skip existing task list items and ordered list items.
      if l:line =~# '^\s*[-*+]\s\+\[[ xX]\]\%(\s\|$\)'
            \ || l:line =~# '^\s*\d\+[.)]\%(\s\|$\)'
        continue
      endif

      " Remove leading indentation and an existing bullet list marker.
      let l:text = substitute(l:line, '^\s*\%([-*+]\s\+\)\?', '', '')
    else
      " Skip existing list markers.
      if l:line =~# '^\s*\%([-*+]\s\+\|\d\+[.)]\s*\)'
        continue
      endif

      let l:text = substitute(l:line, '^\s*', '', '')
    endif

    call setline(l:lnum, l:indent . a:marker . l:text)
  endfor
endfunction

" s:get_previous_list_item_indent() {{{4
function! s:get_previous_list_item_indent(lnum) abort
  let l:target_indent = indent(a:lnum)

  for l:lnum in reverse(range(1, a:lnum - 1))
    let l:line = getline(l:lnum)

    if l:line =~# '^\s*$'
      break
    endif

    if l:line =~# '^\s*[-*+]\s\+'
          \ || l:line =~# '^\s*\d\+[.)]\s\+'
      if indent(l:lnum) <= l:target_indent
        return matchstr(l:line, '^\s*')
      endif
    endif
  endfor

  return matchstr(getline(a:lnum), '^\s*')
endfunction

" feat: bullet list items formatting (normal/visual mode) {{{3
" s:md_format_bullet_list_markers() {{{4
function! s:md_format_bullet_list_markers(force_dash) range abort
  let l:indent_group_markers = {}

  for l:lnum in range(a:firstline, a:lastline)
    let l:line = getline(l:lnum)
    let l:match = matchlist(l:line, '^\(\s*\)\([*+-]\)\s\+')

    if !empty(l:match)
      let l:marker = l:match[2]
      let l:indent = indent(l:lnum)
      let l:indent_key = string(l:indent)

      let l:indent_group_markers = s:md_update_indent_group_marker(
            \ l:indent_group_markers,
            \ l:indent,
            \ a:force_dash ? '-' : l:marker)

      let l:new_marker = l:indent_group_markers[l:indent_key]

      if l:marker !=# l:new_marker
        call setline(
              \ l:lnum,
              \ substitute(
              \   l:line,
              \   '^\(\s*\)[*+-]',
              \   '\1' . l:new_marker,
              \   ''))
      endif
    endif
  endfor
endfunction

nnoremap <buffer> <Leader>mlF :<C-u>call <SID>md_format_bullet_list_markers(1)<CR>

xnoremap <buffer> <Leader>mlf :<C-u>'<,'>call <SID>md_format_bullet_list_markers(0)<CR>
xnoremap <buffer> <Leader>mlF :<C-u>'<,'>call <SID>md_format_bullet_list_markers(1)<CR>

"s:md_update_indent_group_marker() {{{4
function! s:md_update_indent_group_marker(indent_group_markers, indent, marker) abort
  let l:indent_key = string(a:indent)

  " Reset markers for deeper indentation levels.
  for l:existing_indent_key in keys(a:indent_group_markers)
    if str2nr(l:existing_indent_key) > a:indent
      call remove(a:indent_group_markers, l:existing_indent_key)
    endif
  endfor

  " Initialize the marker for the current group.
  if !has_key(a:indent_group_markers, l:indent_key)
    let a:indent_group_markers[l:indent_key] = a:marker
  endif

  return a:indent_group_markers
endfunction

" feat: bullet list items deletion (normal/visual mode) {{{3
" s:md_delete_bullet_list_items() {{{4
function! s:md_delete_bullet_list_items() range abort
  call s:remove_bullet_list_markers(a:firstline, a:lastline)
endfunction

nnoremap <buffer> <Leader>mld :<C-u>call <SID>md_delete_bullet_list_items()<CR>
xnoremap <buffer> <Leader>mld :<C-u>'<,'>call <SID>md_delete_bullet_list_items()<CR>

" s:remove_bullet_list_markers() {{{4
function! s:remove_bullet_list_markers(start_lnum, end_lnum) abort
  for l:lnum in range(a:start_lnum, a:end_lnum)
    let l:line = getline(l:lnum)
    let l:match = matchlist(l:line, '^\(\s*\)[-*+]\s\+')

    if empty(l:match)
      continue
    endif

    let l:text = strpart(l:line, strlen(l:match[0]))

    if l:text =~# '^\[[ xX]\]\%([ \t]\|$\)'
      continue
    endif

    let l:indent_str = l:match[1]

    call setline(l:lnum, l:indent_str . l:text)
  endfor
endfunction

" feat: ordered list items continuation {{{3
" s:md_continue_list_item() {{{4
function! s:md_continue_list_item(lnum, offset) abort
  let l:result = s:continue_ordered_list_item(a:lnum, a:offset)
  let l:result .= s:continue_task_list_item(a:lnum)
  return l:result
endfunction

inoremap <buffer> <expr> <CR> "\<CR>\<C-r>=<SID>md_continue_list_item(line('.') - 1, 1)<CR>"
nnoremap <buffer> <expr> o "o\<C-r>=<SID>md_continue_list_item(line('.') - 1, 1)<CR>"
nnoremap <buffer> <expr> O "O\<C-r>=<SID>md_continue_list_item(line('.') + 1, -1)<CR>"

" s:continue_ordered_list_item() {{{4
function! s:continue_ordered_list_item(lnum, offset) abort
  let l:line = getline(a:lnum)
  let l:match = matchlist(l:line, '^\s*\(\d\+\)\([.)]\)\s\+')

  if empty(l:match)
    return ''
  endif

  return max([1, str2nr(l:match[1]) + a:offset]) . l:match[2] . ' '
endfunction

" feat: ordered list items insertion (normal/visual mode) {{{3
" s:md_insert_ordered_list_items() {{{4
function! s:md_insert_ordered_list_items(visual_mode, ignore_indent) range abort
  call s:insert_list_items(
        \ a:firstline,
        \ a:lastline,
        \ '1. ',
        \ a:visual_mode,
        \ a:ignore_indent)

  call s:renumber_ordered_list_items(1, a:firstline, a:lastline)
endfunction

nnoremap <buffer> <Leader>moi :<C-u>call <SID>md_insert_ordered_list_items(0, 0)<CR>

xnoremap <buffer> <Leader>moi :<C-u>'<,'>call <SID>md_insert_ordered_list_items(1, 0)<CR>
xnoremap <buffer> <Leader>moI :<C-u>'<,'>call <SID>md_insert_ordered_list_items(1, 1)<CR>

" s:renumber_ordered_list_items() {{{4
function! s:renumber_ordered_list_items(start_from_one, start_lnum, end_lnum) abort
  let l:ordered_list_counters = {}

  for l:lnum in range(a:start_lnum, a:end_lnum)
    let l:line = getline(l:lnum)
    let l:match = matchlist(l:line, '^\(\s*\)\(\d\+\)\([.)]\)\s*')

    if !empty(l:match)
      let l:indent_str = l:match[1]
      let l:number = l:match[2]
      let l:delimiter = l:match[3]
      let l:list_marker = l:match[0]

      let l:indent = indent(l:lnum)
      let l:indent_key = string(l:indent)

      " Reset counters for deeper indentation levels.
      for l:existing_indent_key in keys(l:ordered_list_counters)
        if str2nr(l:existing_indent_key) > l:indent
          call remove(l:ordered_list_counters, l:existing_indent_key)
        endif
      endfor

      " Initialize or increment the counter for the current level.
      if has_key(l:ordered_list_counters, l:indent_key)
        let l:ordered_list_counters[l:indent_key] += 1
      else
        let l:ordered_list_counters[l:indent_key] =
              \ l:lnum == a:start_lnum && a:start_from_one
              \ ? 1
              \ : (l:indent > 0 ? 1 : str2nr(l:number))
      endif

      call setline(
            \ l:lnum,
            \ l:indent_str . l:ordered_list_counters[l:indent_key] . l:delimiter . ' ' .
            \ strpart(l:line, strlen(l:list_marker))
            \ )
    endif
  endfor
endfunction

" feat: ordered list items formatting (normal/visual mode) {{{3
" s:md_format_ordered_list_delimiters() {{{4
function! s:md_format_ordered_list_delimiters(force_dot) range abort
  let l:indent_group_delimiters = {}

  for l:lnum in range(a:firstline, a:lastline)
    let l:line = getline(l:lnum)
    let l:match = matchlist(l:line, '^\(\s*\)\(\d\+\)\([.)]\)\s*')

    if !empty(l:match)
      let l:indent_str = l:match[1]
      let l:number = l:match[2]
      let l:delimiter = l:match[3]
      let l:list_marker = l:match[0]

      let l:indent = indent(l:lnum)
      let l:indent_key = string(l:indent)

      let l:indent_group_delimiters = s:md_update_indent_group_marker(
            \ l:indent_group_delimiters,
            \ l:indent,
            \ a:force_dot ? '.' : l:delimiter)

      let l:new_delimiter = l:indent_group_delimiters[l:indent_key]

      if l:delimiter !=# l:new_delimiter
        call setline(
              \ l:lnum,
              \ l:indent_str . l:number . l:new_delimiter . ' ' .
              \ strpart(l:line, strlen(l:list_marker))
              \ )
      endif
    endif
  endfor
endfunction

nnoremap <buffer> <Leader>moF :<C-u>call <SID>md_format_ordered_list_delimiters(1)<CR>

xnoremap <buffer> <Leader>mof :<C-u>'<,'>call <SID>md_format_ordered_list_delimiters(0)<CR>
xnoremap <buffer> <Leader>moF :<C-u>'<,'>call <SID>md_format_ordered_list_delimiters(1)<CR>

" feat: ordered list items renumbering (visual mode) {{{3
" s:md_renumber_ordered_list_items() {{{4
function! s:md_renumber_ordered_list_items(start_from_one) range abort
  call s:renumber_ordered_list_items(
        \ a:start_from_one, a:firstline, a:lastline
        \ )
endfunction

xnoremap <buffer> <Leader>mon :<C-u>'<,'>call <SID>md_renumber_ordered_list_items(0)<CR>
xnoremap <buffer> <Leader>moN :<C-u>'<,'>call <SID>md_renumber_ordered_list_items(1)<CR>

" feat: ordered list items deletion (normal/visual mode) {{{3
" s:md_delete_ordered_list_items() {{{4
function! s:md_delete_ordered_list_items() range abort
  call s:remove_ordered_list_markers(a:firstline, a:lastline)
endfunction

nnoremap <buffer> <Leader>mod :<C-u>call <SID>md_delete_ordered_list_items()<CR>
xnoremap <buffer> <Leader>mod :<C-u>'<,'>call <SID>md_delete_ordered_list_items()<CR>

" s:remove_ordered_list_markers() {{{4
function! s:remove_ordered_list_markers(start_lnum, end_lnum) abort
  for l:lnum in range(a:start_lnum, a:end_lnum)
    let l:line = getline(l:lnum)
    let l:match = matchlist(l:line, '^\(\s*\)\d\+[.)]\s\+')

    if empty(l:match)
      continue
    endif

    let l:indent_str = l:match[1]
    let l:text = strpart(l:line, strlen(l:match[0]))

    call setline(l:lnum, l:indent_str . l:text)
  endfor
endfunction

" feat: line wrapping {{{3
" s:md_format_line_wrapping() {{{4
function! s:md_format_line_wrapping() abort
  if mode(1) =~# '^i'
    return s:format_line_wrapping_in_insert_mode()
  endif

  return s:format_line_wrapping_in_normal_or_visual_mode()
endfunction

setlocal formatexpr=<SID>md_format_line_wrapping()

" s:format_line_wrapping_in_insert_mode() {{{4
function! s:format_line_wrapping_in_insert_mode() abort
  let l:line = getline(v:lnum)

  " Split the line at the cursor position.
  let l:prefix = strpart(l:line, 0, col('.') - 1)
  let l:suffix = strpart(l:line, col('.') - 1)

  let l:match = matchlist(
        \ l:prefix,
        \ '^\(\s*\)\([-*+]\s\+\(\[[ xX]\]\s\+\)\?\)\(.*\)$')

  if empty(l:match)
    return 1
  endif

  let l:indent = l:match[1]
  let l:marker = l:match[2]
  let l:text = l:match[4]
  let l:continuation_indent =
        \ l:indent . repeat(' ', strdisplaywidth(l:marker))

  " Calculate the available text width.
  let l:textwidth = max([
        \ 1,
        \ &l:textwidth - strdisplaywidth(l:indent . l:marker)
        \ ])

  " Calculate the display width before the cursor.
  let l:prefix_width = strdisplaywidth(l:prefix)

  " Do not wrap while inserting consecutive whitespace.
  if v:char =~# '^[ \t]$'
    return 0
  endif

  " Determine the wrapping position.
  if l:prefix_width > &l:textwidth
    let l:break_byte = strlen(l:text)
  elseif strdisplaywidth(v:char) == 2
    let l:break_byte = strlen(l:text)
  elseif !empty(l:text)
        \ && strdisplaywidth(strcharpart(
        \ l:text, strchars(l:text) - 1, 1)) == 2
    let l:break_byte = strlen(l:text)
  else
    " Find the last word boundary and double-width character.
    let l:word_boundary = -1
    let l:double_width_boundary = -1
    let l:width = 0

    for l:i in range(0, strchars(l:text) - 1)
      let l:char = strcharpart(l:text, l:i, 1)
      let l:char_width = strdisplaywidth(l:char, l:width)

      if l:width + l:char_width > l:textwidth
        break
      endif

      if l:char =~# '^[ \t]$'
        let l:word_boundary =
              \ strlen(strcharpart(l:text, 0, l:i))
      endif

      if l:char_width == 2
        let l:double_width_boundary =
              \ strlen(strcharpart(l:text, 0, l:i + 1))
      endif

      let l:width += l:char_width
    endfor

    let l:break_byte = max([
          \ l:word_boundary,
          \ l:double_width_boundary
          \ ])

    if l:break_byte < 0
      return 0
    endif
  endif

  " Build the continuation line.
  let l:first_line = strpart(l:text, 0, l:break_byte)
  let l:second_line = strpart(l:text, l:break_byte) . l:suffix

  " Remove trailing whitespace from the first line.
  let l:first_line = substitute(l:first_line, '[ \t]\+$', '', '')

  " Remove leading whitespace from the continuation line.
  let l:second_line = substitute(l:second_line, '^[ \t]\+', '', '')

  " Replace the current line and insert the continuation line.
  call setline(v:lnum, l:indent . l:marker . l:first_line)
  call append(v:lnum, l:continuation_indent . l:second_line)

  " Restore the cursor position on the continuation line.
  let l:cursor_offset_col = strdisplaywidth(strpart(l:text, l:break_byte + 1))
  let l:cursor_col =
        \ strdisplaywidth(l:continuation_indent) + l:cursor_offset_col + 1

  call cursor(v:lnum + 1, l:cursor_col)

  return 0
endfunction

" s:format_line_wrapping_in_normal_or_visual_mode() {{{4
function! s:format_line_wrapping_in_normal_or_visual_mode()
  let l:start_lnum = v:lnum
  let l:end_lnum = l:start_lnum + v:count - 1
  let l:lines = getline(l:start_lnum, l:end_lnum)
  let l:format_blocks = []
  let l:line_idx = 0

  " Group lines into formatting blocks.
  while l:line_idx < len(l:lines)
    if s:is_blank_line(l:lines[l:line_idx])
      let l:line_idx += 1
      continue
    endif

    let l:block_start_idx = l:line_idx
    let l:is_list_item = l:lines[l:line_idx]
          \ =~# '^\s*[-*+]\s\+\%(\[[ xX]\]\s\+\)\?'

    " Find the end of the current block.
    let l:line_idx += 1
    while l:line_idx < len(l:lines)
      if s:is_blank_line(l:lines[l:line_idx])
        break
      endif

      if l:lines[l:line_idx] =~# '^\s*[-*+]\s\+\%(\[[ xX]\]\s\+\)\?'
        break
      endif

      let l:line_idx += 1
    endwhile

    call add(l:format_blocks, {
          \ 'start_lnum': l:start_lnum + l:block_start_idx,
          \ 'end_lnum': l:start_lnum + l:line_idx - 1,
          \ 'is_list_item': l:is_list_item
          \ })
  endwhile

  " Record the original range before formatting.
  let l:buffer_line_count = line('$')
  let l:last_block_end_lnum = empty(l:format_blocks)
        \ ? 0
        \ : l:format_blocks[-1].end_lnum

  " Format blocks from bottom to top.
  for l:block in reverse(l:format_blocks)
    if l:block.is_list_item
      call s:format_list_item_wrapping(
            \ l:block.start_lnum, l:block.end_lnum)
    else
      call s:format_text_wrapping(
            \ l:block.start_lnum, l:block.end_lnum)
    endif
  endfor

  " Restore cursor position to the last formatted line.
  if l:last_block_end_lnum > 0
    let l:formatted_end_lnum =
          \ l:last_block_end_lnum + (line('$') - l:buffer_line_count)

    call cursor(l:formatted_end_lnum, 1)
    normal! ^
  endif

  return 0
endfunction

" s:is_blank_line() {{{4
function! s:is_blank_line(line) abort
  return a:line =~# '^\s*$'
endfunction

" s:format_list_item_wrapping() {{{4
function! s:format_list_item_wrapping(start_lnum, end_lnum) abort
  let l:lines = getline(a:start_lnum, a:end_lnum)
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

  " Remove the list marker and indentation.
  let l:lines[0] = l:match[4]

  for l:i in range(1, len(l:lines) - 1)
    let l:lines[l:i] = substitute(
          \ l:lines[l:i],
          \ '^' . escape(l:continuation_indent, '\'),
          \ '', '')
  endfor

  call setline(a:start_lnum, l:lines)

  " Temporarily disable formatexpr and adjust textwidth.
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

  " Record the total buffer line count before formatting.
  let l:buffer_line_count = line('$')

  try
    " Run the default formatting on the current item.
    call cursor(a:start_lnum, 1)

    if a:end_lnum > a:start_lnum
      execute 'normal! V' . (a:end_lnum - a:start_lnum) . 'jgq'
    else
      normal! Vgq
    endif
  finally
    let &l:formatexpr = l:formatexpr
    let &l:textwidth = l:textwidth
  endtry

  " Calculate the formatted range.
  let l:formatted_end_lnum =
        \ a:end_lnum + (line('$') - l:buffer_line_count)

  " Restore the list marker and indentation.
  let l:lines = getline(a:start_lnum, l:formatted_end_lnum)

  let l:lines[0] = l:indent . l:marker . l:lines[0]
  for l:i in range(1, len(l:lines) - 1)
    let l:lines[l:i] = l:continuation_indent . l:lines[l:i]
  endfor

  call setline(a:start_lnum, l:lines)
endfunction

" s:format_text_wrapping() {{{4
function! s:format_text_wrapping(start_lnum, end_lnum) abort
  let l:formatexpr = &l:formatexpr

  setlocal formatexpr=

  try
    call cursor(a:start_lnum, 1)

    if a:end_lnum > a:start_lnum
      execute 'normal! V' . (a:end_lnum - a:start_lnum) . 'jgq'
    else
      normal! Vgq
    endif
  finally
    let &l:formatexpr = l:formatexpr
  endtry
endfunction

" 5.3 Task list items (extension) {{{2
" feat: task list items continuation {{{3
" s:continue_task_list_item() {{{4
function! s:continue_task_list_item(lnum) abort
  let l:line = getline(a:lnum)

  if l:line !~# '^\s*-\s\+\[[ x]\]'
    return ''
  endif

  return '[ ] '
endfunction

" feat: task list items insertion (normal/visual mode) {{{3
"s:md_insert_task_list_items() {{{4
function! s:md_insert_task_list_items(visual_mode, ignore_indent) range abort
  call s:insert_list_items(
        \ a:firstline,
        \ a:lastline,
        \ '- [ ] ',
        \ a:visual_mode,
        \ a:ignore_indent)
endfunction

nnoremap <buffer> <Leader>mki :<C-u>call <SID>md_insert_task_list_items(0, 0)<CR>
xnoremap <buffer> <Leader>mki :<C-u>'<,'>call <SID>md_insert_task_list_items(1, 0)<CR>
xnoremap <buffer> <Leader>mkI :<C-u>'<,'>call <SID>md_insert_task_list_items(1, 1)<CR>

" feat: task list items state setting (normal/visual mode) {{{3
" s:md_set_task_list_items_state() {{{4
function! s:md_set_task_list_items_state(is_done) range abort
  let l:mark = a:is_done ? 'x' : ' '

  for l:lnum in range(a:firstline, a:lastline)
    let l:line = getline(l:lnum)

    call setline(
          \ l:lnum,
          \ s:set_task_list_item_state(l:line, l:mark))
  endfor
endfunction

nnoremap <buffer> <Leader>mkk :<C-u>call <SID>md_set_task_list_items_state(1)<CR>
xnoremap <buffer> <Leader>mkk :<C-u>'<,'>call <SID>md_set_task_list_items_state(1)<CR>

nnoremap <buffer> <Leader>mk<Space> :<C-u>call <SID>md_set_task_list_items_state(0)<CR>
xnoremap <buffer> <Leader>mk<Space> :<C-u>'<,'>call <SID>md_set_task_list_items_state(0)<CR>

" s:set_task_list_item_state() {{{4
function! s:set_task_list_item_state(line, mark) abort
  if a:line =~# '^\s*-\s*\[[ xX]\]'
    return substitute(
          \ a:line,
          \ '^\(\s*-\s*\)\[[ xX]\]',
          \ '\1[' . a:mark . ']',
          \ '')
  endif

  return a:line
endfunction

" feat: task list items state toggling (normal/visual mode) {{{3
" s:md_toggle_task_list_items_state() {{{4
function! s:md_toggle_task_list_items_state() range abort
  for l:lnum in range(a:firstline, a:lastline)
    let l:line = getline(l:lnum)
    let l:mark = l:line =~# '^\s*-\s\+\[ \]' ? 'x' : ' '

    call setline(
          \ l:lnum,
          \ s:set_task_list_item_state(l:line, l:mark))
  endfor
endfunction

nnoremap <buffer> <Leader>mkt :<C-u>call <SID>md_toggle_task_list_items_state()<CR>
xnoremap <buffer> <Leader>mkt :<C-u>'<,'>call <SID>md_toggle_task_list_items_state()<CR>

" feat: task list items unwrapping (normal/visual mode) {{{3
" s:md_unwrap_task_list_items() {{{4
function! s:md_unwrap_task_list_items() range abort
  call s:remove_task_list_markers(0, a:firstline, a:lastline)
endfunction

nnoremap <buffer> <Leader>mku :<C-u>call <SID>md_unwrap_task_list_items()<CR>
xnoremap <buffer> <Leader>mku :<C-u>'<,'>call <SID>md_unwrap_task_list_items()<CR>

" s:remove_task_list_markers() {{{4
function! s:remove_task_list_markers(delete_bullet, start_lnum, end_lnum) abort
  for l:lnum in range(a:start_lnum, a:end_lnum)
    let l:line = getline(l:lnum)
    let l:match = matchlist(
          \ l:line,
          \ '^\(\s*\)\([-*+]\s\+\)\(\[[ xX]\]\s\+\)')

    if empty(l:match)
      continue
    endif

    let l:indent_str = l:match[1]
    let l:bullet = a:delete_bullet ? '' : l:match[2]
    let l:text = strpart(l:line, strlen(l:match[0]))

    call setline(l:lnum, l:indent_str . l:bullet . l:text)
  endfor
endfunction

" feat: task list items deletion (normal/visual mode) {{{3
" s:md_delete_task_list_items() {{{4
function! s:md_delete_task_list_items() range abort
  call s:remove_task_list_markers(1, a:firstline, a:lastline)
endfunction

nnoremap <buffer> <Leader>mkd :<C-u>call <SID>md_delete_task_list_items()<CR>
xnoremap <buffer> <Leader>mkd :<C-u>'<,'>call <SID>md_delete_task_list_items()<CR>

" GFM Spec 6. Inlines {{{1
" 6.3 Code spans {{{2
" feat: code span wrapping (normal/visual mode) {{{3
" constants {{{4
let s:MD_CODE_SPAN = {
      \ 'start': '`',
      \ 'end': '`',
      \ }

" s:md_wrap_code_span() {{{4
function! s:md_wrap_code_span(type) abort
  call s:wrap_text_in_normal_mode(a:type, s:MD_CODE_SPAN)
endfunction

nnoremap <buffer> <Leader>mcw :<C-u>set operatorfunc=<SID>md_wrap_code_span<CR>g@

" s:md_wrap_code_span_visual() {{{4
function! s:md_wrap_code_span_visual() abort
  call s:wrap_text_in_visual_mode(s:MD_CODE_SPAN)
endfunction

xnoremap <buffer> <Leader>mcw :<C-u>call <SID>md_wrap_code_span_visual()<CR>

" s:wrap_text_in_normal_mode() {{{4
function! s:wrap_text_in_normal_mode(type, wrapper) abort
  let l:start_pos = getpos("'[")
  let l:end_pos = getpos("']")

  if a:type ==# 'char'
    call s:wrap_text_char(l:start_pos, l:end_pos, a:wrapper)
  elseif a:type ==# 'line'
    call s:wrap_text_line(l:start_pos, l:end_pos, a:wrapper)
  elseif a:type ==# 'block'
    call s:wrap_text_block(l:start_pos, l:end_pos, a:wrapper)
  endif
endfunction

" s:wrap_text_char() {{{4
function! s:wrap_text_char(start_pos, end_pos, wrapper) abort
  let l:start_lnum = a:start_pos[1]
  let l:start_col = a:start_pos[2]
  let l:end_lnum = a:end_pos[1]
  let l:end_col = a:end_pos[2]

  let l:start_line = getline(l:start_lnum)
  let l:end_line = getline(l:end_lnum)

  " Get the byte length of the last character.
  let l:end_char = matchstr(strpart(l:end_line, l:end_col - 1), '^.')
  let l:end_byte = l:end_col - 1 + strlen(l:end_char)

  if l:start_lnum == l:end_lnum
    let l:new_line = s:insert_wrapper(
          \ l:start_line, l:start_col - 1, l:end_byte, a:wrapper, 'both')

    call setline(l:start_lnum, l:new_line)
  else
    let l:new_lines = getline(l:start_lnum, l:end_lnum)

    let l:new_lines[0] = s:insert_wrapper(
          \ l:start_line, l:start_col - 1, strlen(l:start_line), a:wrapper, 'start')

    let l:new_lines[-1] = s:insert_wrapper(
          \ l:end_line, 0, l:end_byte, a:wrapper, 'end')

    call setline(l:start_lnum, l:new_lines)
  endif
endfunction

" s:insert_wrapper() {{{4
function! s:insert_wrapper(line, start_byte, end_byte, wrapper, mode) abort
  let l:prefix = strpart(a:line, 0, a:start_byte)
  let l:middle = strpart(a:line, a:start_byte, a:end_byte - a:start_byte)
  let l:suffix = strpart(a:line, a:end_byte)

  if a:mode ==# 'start'
    return l:prefix . a:wrapper.start . l:middle . l:suffix
  elseif a:mode ==# 'end'
    return l:prefix . l:middle . a:wrapper.end . l:suffix
  elseif a:mode ==# 'both'
    return l:prefix . a:wrapper.start . l:middle . a:wrapper.end . l:suffix
  endif

  return a:line
endfunction

" s:wrap_text_line() {{{4
function! s:wrap_text_line(start_pos, end_pos, wrapper) abort
  let l:start_lnum = a:start_pos[1]
  let l:end_lnum = a:end_pos[1]
  let l:lines = getline(l:start_lnum, l:end_lnum)

  let l:lines[0] = a:wrapper.start . l:lines[0]
  let l:lines[-1] .= a:wrapper.end

  call setline(l:start_lnum, l:lines)
endfunction

" s:wrap_text_block() {{{4
function! s:wrap_text_block(start_pos, end_pos, wrapper) abort
  let l:start_lnum = a:start_pos[1]
  let l:end_lnum = a:end_pos[1]

  let l:start_vcol = virtcol("'<")
  let l:end_vcol = virtcol("'>")

  if l:start_vcol > l:end_vcol
    let [l:start_vcol, l:end_vcol] = [l:end_vcol, l:start_vcol]
  endif

  let l:new_lines = getline(l:start_lnum, l:end_lnum)

  for l:line_idx in range(len(l:new_lines))
    let l:line = l:new_lines[l:line_idx]
    let l:line_lnum = l:start_lnum + l:line_idx

    let l:start_col = virtcol2col(0, l:line_lnum, l:start_vcol)
    let l:end_col = virtcol2col(0, l:line_lnum, l:end_vcol)

    if l:start_col == 0
      continue
    endif

    let l:last_char = matchstr(strpart(l:line, l:end_col - 1), '^.')
    let l:end_byte = l:end_col - 1 + strlen(l:last_char)

    let l:new_lines[l:line_idx] = s:insert_wrapper(
          \ l:line, l:start_col - 1, l:end_byte, a:wrapper, 'both')
  endfor

  call setline(l:start_lnum, l:new_lines)
endfunction

" s:wrap_text_in_visual_mode() {{{4
function! s:wrap_text_in_visual_mode(wrapper) abort
  let l:start_pos = getpos("'<")
  let l:end_pos = getpos("'>")
  let l:mode = visualmode()

  if l:mode ==# "\<C-V>"
    call s:wrap_text_block(l:start_pos, l:end_pos, a:wrapper)
  elseif l:mode ==# 'V'
    call s:wrap_text_line(l:start_pos, l:end_pos, a:wrapper)
  else
    call s:wrap_text_char(l:start_pos, l:end_pos, a:wrapper)
  endif
endfunction

" feat: code span unwrapping (normal mode) {{{3
" s:md_unwrap_code_span() {{{4
function! s:md_unwrap_code_span() abort
  call s:unwrap_wrappers([s:MD_CODE_SPAN])
endfunction

nnoremap <buffer> <Leader>mcu :<C-u>call <SID>md_unwrap_code_span()<CR>

" s:unwrap_wrappers() {{{4
function! s:unwrap_wrappers(wrappers) abort
  let l:line = getline('.')
  let l:col = col('.')
  let l:nearest_start_byte = -1
  let l:nearest_end_byte = -1
  let l:nearest_wrapper = ''

  for l:wrapper in a:wrappers
    let l:wrapper_len = strlen(l:wrapper)
    let l:start_byte = strridx(strpart(l:line, 0, l:col - 1), l:wrapper)
    let l:end_byte = stridx(l:line, l:wrapper, l:col - 1)

    if l:start_byte < 0 || l:end_byte < 0
      continue
    endif

    " Select the closest wrapper pair.
    if l:nearest_start_byte < 0 || l:start_byte > l:nearest_start_byte
      let l:nearest_start_byte = l:start_byte
      let l:nearest_end_byte = l:end_byte
      let l:nearest_wrapper = l:wrapper
    endif
  endfor

  if l:nearest_start_byte < 0
    return
  endif

  let l:wrapper_len = strlen(l:nearest_wrapper)

  let l:new_line = strpart(l:line, 0, l:nearest_start_byte)
        \ . strpart(l:line, l:nearest_start_byte + l:wrapper_len,
        \   l:nearest_end_byte - l:nearest_start_byte - l:wrapper_len)
        \ . strpart(l:line, l:nearest_end_byte + l:wrapper_len)

  call setline('.', l:new_line)
endfunction

" 6.4 Emphasis and strong emphasis {{{2
" feat: bold text wrapping (normal/visual mode) {{{3
" constants {{{4
let s:MD_EMPHASIS_BOLD = {
      \ 'start': '**',
      \ 'end': '**',
      \ }

" s:md_wrap_bold() {{{4
function! s:md_wrap_bold(type) abort
  call s:wrap_text_in_normal_mode(a:type, s:MD_EMPHASIS_BOLD)
endfunction

nnoremap <buffer> <Leader>mbw :<C-u>set operatorfunc=<SID>md_wrap_bold<CR>g@

" s:md_wrap_bold_visual() {{{4
function! s:md_wrap_bold_visual() abort
  call s:wrap_text_in_visual_mode(s:MD_EMPHASIS_BOLD)
endfunction

xnoremap <buffer> <Leader>mbw :<C-u>call <SID>md_wrap_bold_visual()<CR>

" feat: bold text unwrapping (normal mode) {{{3
" s:md_unwrap_bold() {{{4
function! s:md_unwrap_bold() abort
  call s:unwrap_wrappers([s:MD_EMPHASIS_BOLD])
endfunction

nnoremap <buffer> <Leader>mbu :<C-u>call <SID>md_unwrap_bold()<CR>

" feat: italic text wrapping (normal/visual mode) {{{3
" constants {{{4
let s:MD_EMPHASIS_ITALIC = {
      \ 'start': '_',
      \ 'end': '_',
      \ }

" s:md_wrap_italic() {{{4
function! s:md_wrap_italic(type) abort
  call s:wrap_text_in_normal_mode(a:type, s:MD_EMPHASIS_ITALIC)
endfunction

nnoremap <buffer> <Leader>miw :<C-u>set operatorfunc=<SID>md_wrap_italic<CR>g@

" s:md_wrap_italic_visual() {{{4
function! s:md_wrap_italic_visual() abort
  call s:wrap_text_in_visual_mode(s:MD_EMPHASIS_ITALIC)
endfunction

xnoremap <buffer> <Leader>miw :<C-u>call <SID>md_wrap_italic_visual()<CR>

" feat: italic text unwrapping (normal mode) {{{3
" s:md_unwrap_italic() {{{4
function! s:md_unwrap_italic() abort
  call s:unwrap_wrappers([s:MD_EMPHASIS_ITALIC])
endfunction

nnoremap <buffer> <Leader>miu :<C-u>call <SID>md_unwrap_italic()<CR>

" feat: nearest Markdown wrapper unwrapping (normal mode) {{{3
" constants {{{4
const s:MD_UNWRAP_WRAPPERS = [
      \ s:MD_EMPHASIS_BOLD,
      \ s:MD_EMPHASIS_ITALIC,
      \ s:MD_CODE_SPAN,
      \ ]

" s:md_unwrap() {{{4
function! s:md_unwrap_nearest() abort
  call s:unwrap_wrappers(s:MD_UNWRAP_WRAPPERS)
endfunction

nnoremap <buffer> <Leader>mwu :<C-u>call <SID>md_unwrap_nearest()<CR>

" 6.6 Links {{{2
" feat: link insertion (normal mode) {{{3
" s:md_insert_link() {{{4
function! s:md_insert_link(after_cursor) abort
  let l:url = s:get_clipboard_url()
  call s:insert_link(l:url, '', a:after_cursor)
endfunction

nnoremap <buffer> <Leader>mai :<C-u>call <SID>md_insert_link(0)<CR>

" s:get_clipboard_url() {{{4
function! s:get_clipboard_url()
  if executable('wl-paste')
    let l:url = system('wl-paste --no-newline')
  elseif has('clipboard')
    let l:url = getreg('+')
  else
    return ''
  endif

  let l:url = trim(l:url)

  if !s:is_valid_url(l:url)
    return ''
  endif

  return l:url
endfunction

" s:is_valid_url() {{{4
function! s:is_valid_url(url) abort
  let l:matches = s:find_url(a:url)

  return l:matches[1] == 0 && l:matches[2] == strlen(a:url)
endfunction

" s:find_url() {{{4
function! s:find_url(text) abort
  return matchstrpos(a:text, '\vhttps?://[A-Za-z0-9._~:/?#\[\]@!$&''()*+,;=%-]+')
endfunction

" s:insert_link() {{{4
function! s:insert_link(url, title, after_cursor) abort
  let l:link = s:create_link(a:url, a:title)
  let l:line = getline('.')
  let l:col = col('.') + (a:after_cursor ? 1 : 0)

  call setline('.', s:insert_text_at(l:line, l:link, l:col))

  " Move cursor to the end of the link text
  call cursor(line('.'), l:col + strlen(a:title) + 1)
endfunction

" s:create_link() {{{4
function! s:create_link(url, title) abort
  return '[' . a:title . '](' . a:url . ')'
endfunction

" s:insert_text_at() {{{4
function! s:insert_text_at(line, text, col) abort
  return strpart(a:line, 0, a:col - 1)
        \ . a:text . strpart(a:line, a:col - 1)
endfunction

" feat: link insertion after cursor (normal mode) {{{3
nnoremap <buffer> <Leader>maa :<C-u>call <SID>md_insert_link(1)<CR>

" feat: link insertion with title (normal mode) {{{3
" s:md_insert_link_with_title() {{{4
function! s:md_insert_link_with_title(after_cursor) abort
  let l:url = s:get_clipboard_url()
  let l:title = empty(l:url) ? '' : s:get_url_title(l:url)

  call s:insert_link(l:url, l:title, a:after_cursor)
endfunction

nnoremap <buffer> <Leader>maI :<C-u>call <SID>md_insert_link_with_title(0)<CR>

" feat: link insertion with title after cursor (normal mode) {{{3
nnoremap <buffer> <Leader>maA :<C-u>call <SID>md_insert_link_with_title(1)<CR>

" s:get_url_title() {{{4
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

" feat: link insertion from register (normal mode) {{{3
" s:md_insert_link_from_register() {{{4
function! s:md_insert_link_from_register(after_cursor, with_title) abort
  let l:url = s:get_register_url(v:register)
  let l:title = a:with_title && !empty(l:url)
        \ ? s:get_url_title(l:url)
        \ : ''

  call s:insert_link(l:url, l:title, a:after_cursor)
endfunction

nnoremap <buffer> <Leader>mapp :<C-u>call <SID>md_insert_link_from_register(0, 0)<CR>

" s:get_register_url() {{{4
function! s:get_register_url(register) abort
  let l:url = trim(getreg(a:register))

  if !s:is_valid_url(l:url)
    return ''
  endif

  return l:url
endfunction

" feat: link insertion from register after cursor (normal mode) {{{3
nnoremap <buffer> <Leader>maPP :<C-u>call <SID>md_insert_link_from_register(1, 0)<CR>

" feat: link insertion from register with title (normal mode) {{{3
nnoremap <buffer> <Leader>map :<C-u>call <SID>md_insert_link_from_register(0, 1)<CR>

" feat: link insertion from register with title after cursor (normal mode) {{{3
nnoremap <buffer> <Leader>maP :<C-u>call <SID>md_insert_link_from_register(1, 1)<CR>

" feat: link replacement of URL under cursor (normal mode) {{{3
" s:md_replace_url_under_cursor_with_link() {{{4
function! s:md_replace_url_under_cursor_with_link(with_title) abort
  let l:parts = s:split_line_at_url_under_cursor()

  if empty(l:parts)
    return
  endif

  call s:replace_url_with_link(line('.'), l:parts, a:with_title)
endfunction

nnoremap <buffer> <Leader>mar :<C-u>call <SID>md_replace_url_under_cursor_with_link(0)<CR>

" s:split_line_at_url_under_cursor() {{{4
function! s:split_line_at_url_under_cursor() abort
  let l:line = getline('.')
  let l:matches = s:find_url(l:line)

  if l:matches[1] < 0
    return {}
  endif

  let l:start_col = l:matches[1] + 1
  let l:end_col = l:matches[2]
  let l:url = l:matches[0]

  " Check whether the cursor is inside the URL
  if col('.') < l:start_col || col('.') > l:end_col
    return {}
  endif

  return {
        \ 'prefix': strpart(l:line, 0, l:matches[1]),
        \ 'url': l:url,
        \ 'suffix': strpart(l:line, l:matches[2]),
        \ }
endfunction

" s:replace_url_with_link() {{{4
function! s:replace_url_with_link(lnum, parts, with_title) abort
  let l:title = a:with_title ? s:get_url_title(a:parts.url) : ''
  let l:link = s:create_link(a:parts.url, l:title)
  let l:line = a:parts.prefix . l:link . a:parts.suffix

  call setline(a:lnum, l:line)

  " Move cursor to the end of the link text
  let l:col = strlen(a:parts.prefix) + strlen(l:title) + 2
  call cursor(a:lnum, l:col)
endfunction

" feat: link replacement of URL under cursor with title (normal mode) {{{3
nnoremap <buffer> <Leader>maR :<C-u>call <SID>md_replace_url_under_cursor_with_link(1)<CR>

" feat: link replacement of selected URL (visual mode) {{{3
" s:md_replace_selected_url_with_link() {{{4
function! s:md_replace_selected_url_with_link(with_title) abort
  let l:parts = s:get_selected_url()

  " test
  if empty(l:parts)
    return
  endif

  let l:lnum = getpos("'<")[1]
  call s:replace_url_with_link(l:lnum, l:parts, a:with_title)
endfunction

xnoremap <buffer> <Leader>mar :<C-u>call <SID>md_replace_selected_url_with_link(0)<CR>
xnoremap <buffer> <Leader>maR :<C-u>call <SID>md_replace_selected_url_with_link(1)<CR>

" s:get_selected_url() {{{4
function! s:get_selected_url() abort
  let l:start = getpos("'<")
  let l:end = getpos("'>")

  " Only support single-line selections
  if l:start[1] != l:end[1]
    return {}
  endif

  let l:line = getline(l:start[1])
  let l:start_col = l:start[2]
  let l:end_col = l:end[2]

  let l:url = strpart(l:line, l:start_col - 1, l:end_col - l:start_col + 1)

  " Check whether the selected text is a URL
  if !s:is_valid_url(l:url)
    return {}
  endif

  return {
        \ 'prefix': strpart(l:line, 0, l:start_col - 1),
        \ 'url': l:url,
        \ 'suffix': strpart(l:line, l:end_col),
        \ }
endfunction

" feat: link text wrapping (normal mode) {{{3
" s:md_wrap_link_text_in_normal_mode() {{{4
function! s:md_wrap_link_text_in_normal_mode(type) abort
  call s:wrap_link_text_in_normal_mode(a:type, 0)
endfunction

nnoremap <buffer> <Leader>maw :<C-u>set operatorfunc=<SID>md_wrap_link_text_in_normal_mode<CR>g@

" s:wrap_link_text_in_normal_mode() {{{4
function! s:wrap_link_text_in_normal_mode(type, with_url) abort
  let l:wrapper = s:create_link_wrapper(a:with_url)
  call s:wrap_text_in_normal_mode(a:type, l:wrapper)
endfunction

" s:create_link_wrapper() {{{4
function! s:create_link_wrapper(with_url) abort
  let l:url = a:with_url ? s:get_clipboard_url() : ''

  return {
        \ 'start': '[',
        \ 'end': '](' . l:url . ')',
        \ }
endfunction

" feat: link text wrapping (visual mode) {{{3
" s:md_wrap_link_text_in_visual_mode() {{{4
function! s:md_wrap_link_text_in_visual_mode() abort
  call s:wrap_link_text_in_visual_mode(0)
endfunction

xnoremap <buffer> <Leader>maw :<C-u>call <SID>md_wrap_link_text_in_visual_mode()<CR>

" s:wrap_link_text_in_visual_mode() {{{4
function! s:wrap_link_text_in_visual_mode(with_url) abort
  let l:wrapper = s:create_link_wrapper(a:with_url)
  call s:wrap_text_in_visual_mode(l:wrapper)
endfunction

" feat: link text wrapping with URL (normal mode) {{{3
" s:md_wrap_link_text_with_url_in_normal_mode() {{{4
function! s:md_wrap_link_text_with_url_in_normal_mode(type) abort
  call s:wrap_link_text_in_normal_mode(a:type, 1)
endfunction

nnoremap <buffer> <Leader>maW :<C-u>set operatorfunc=<SID>md_wrap_link_text_with_url_in_normal_mode<CR>g@

" feat: link text wrapping with URL (visual mode) {{{3
" s:md_wrap_link_text_with_url_in_visual_mode() {{{4
function! s:md_wrap_link_text_with_url_in_visual_mode() abort
  call s:wrap_link_text_in_visual_mode(1)
endfunction

xnoremap <buffer> <Leader>maW :<C-u>call <SID>md_wrap_link_text_with_url_in_visual_mode()<CR>

" Modeline {{{1
" vim:set ts=8 sts=2 sw=2 tw=0:
" vim:set foldmethod=marker:
