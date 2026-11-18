vim9script
g:SessionLoad = 1
if &cp | set nocp | endif
var cpo_save: string
cpo_save = &cpo
set cpo&vim
inoremap <silent> <Plug>(ale_complete) :ALEComplete
legacy inoremap <silent> <expr> <BS> lexima#expand('<BS>', 'i')
inoremap <silent> <C-J> =IMState('FixMode')
nnoremap <silent>   o
map , <Plug>(clever-f-repeat-back)
map ; <Plug>(clever-f-repeat-forward)
omap F <Plug>(clever-f-F)
xmap F <Plug>(clever-f-F)
nmap F <Plug>(clever-f-F)
omap T <Plug>(clever-f-T)
xmap T <Plug>(clever-f-T)
nmap T <Plug>(clever-f-T)
omap f <Plug>(clever-f-f)
xmap f <Plug>(clever-f-f)
nmap f <Plug>(clever-f-f)
xmap gx <Plug>(open-word-under-cursor)
nmap gx <Plug>(open-word-under-cursor)
nmap gcu <Plug>Commentary<Plug>Commentary
nmap gcc <Plug>CommentaryLine
omap gc <Plug>Commentary
nmap gc <Plug>Commentary
xmap gc <Plug>Commentary
omap t <Plug>(clever-f-t)
xmap t <Plug>(clever-f-t)
nmap t <Plug>(clever-f-t)
xnoremap <Plug>(open-word-under-cursor) <ScriptCmd>vim9.Open(getregion(getpos('v'), getpos('.'), { type: mode() })->join())
nnoremap <Plug>(open-word-under-cursor) <ScriptCmd>vim9.Open(GetWordUnderCursor())
nmap <silent> <Plug>CommentaryUndo :echoerr "Change your <Plug>CommentaryUndo map to <Plug>Commentary<Plug>Commentary"
nnoremap <silent> <Plug>(ale_info_preview) :ALEInfo -preview
nnoremap <silent> <Plug>(ale_info_clipboard) :ALEInfo -clipboard
nnoremap <silent> <Plug>(ale_info_echo) :ALEInfo -echo
nnoremap <silent> <Plug>(ale_info) :ALEInfo
nnoremap <silent> <Plug>(ale_repeat_selection) :ALERepeatSelection
nnoremap <silent> <Plug>(ale_code_action) :ALECodeAction
nnoremap <silent> <Plug>(ale_filerename) :ALEFileRename
nnoremap <silent> <Plug>(ale_rename) :ALERename
nnoremap <silent> <Plug>(ale_import) :ALEImport
nnoremap <silent> <Plug>(ale_documentation) :ALEDocumentation
nnoremap <silent> <Plug>(ale_hover) :ALEHover
nnoremap <silent> <Plug>(ale_find_references) :ALEFindReferences
nnoremap <silent> <Plug>(ale_go_to_implementation_in_vsplit) :ALEGoToImplementation -vsplit
nnoremap <silent> <Plug>(ale_go_to_implementation_in_split) :ALEGoToImplementation -split
nnoremap <silent> <Plug>(ale_go_to_implementation_in_tab) :ALEGoToImplementation -tab
nnoremap <silent> <Plug>(ale_go_to_implementation) :ALEGoToImplementation
nnoremap <silent> <Plug>(ale_go_to_type_definition_in_vsplit) :ALEGoToTypeDefinition -vsplit
nnoremap <silent> <Plug>(ale_go_to_type_definition_in_split) :ALEGoToTypeDefinition -split
nnoremap <silent> <Plug>(ale_go_to_type_definition_in_tab) :ALEGoToTypeDefinition -tab
nnoremap <silent> <Plug>(ale_go_to_type_definition) :ALEGoToTypeDefinition
nnoremap <silent> <Plug>(ale_go_to_definition_in_vsplit) :ALEGoToDefinition -vsplit
nnoremap <silent> <Plug>(ale_go_to_definition_in_split) :ALEGoToDefinition -split
nnoremap <silent> <Plug>(ale_go_to_definition_in_tab) :ALEGoToDefinition -tab
nnoremap <silent> <Plug>(ale_go_to_definition) :ALEGoToDefinition
nnoremap <silent> <Plug>(ale_fix) :ALEFix
nnoremap <silent> <Plug>(ale_detail) :ALEDetail
nnoremap <silent> <Plug>(ale_lint) :ALELint
nnoremap <silent> <Plug>(ale_reset_buffer) :ALEResetBuffer
nnoremap <silent> <Plug>(ale_disable_buffer) :ALEDisableBuffer
nnoremap <silent> <Plug>(ale_enable_buffer) :ALEEnableBuffer
nnoremap <silent> <Plug>(ale_toggle_buffer) :ALEToggleBuffer
nnoremap <silent> <Plug>(ale_reset) :ALEReset
nnoremap <silent> <Plug>(ale_disable) :ALEDisable
nnoremap <silent> <Plug>(ale_enable) :ALEEnable
nnoremap <silent> <Plug>(ale_toggle) :ALEToggle
nnoremap <silent> <Plug>(ale_last) :ALELast
nnoremap <silent> <Plug>(ale_first) :ALEFirst
nnoremap <silent> <Plug>(ale_next_wrap_warning) :ALENext -wrap -warning
nnoremap <silent> <Plug>(ale_next_warning) :ALENext -warning
nnoremap <silent> <Plug>(ale_next_wrap_error) :ALENext -wrap -error
nnoremap <silent> <Plug>(ale_next_error) :ALENext -error
nnoremap <silent> <Plug>(ale_next_wrap) :ALENextWrap
nnoremap <silent> <Plug>(ale_next) :ALENext
nnoremap <silent> <Plug>(ale_previous_wrap_warning) :ALEPrevious -wrap -warning
nnoremap <silent> <Plug>(ale_previous_warning) :ALEPrevious -warning
nnoremap <silent> <Plug>(ale_previous_wrap_error) :ALEPrevious -wrap -error
nnoremap <silent> <Plug>(ale_previous_error) :ALEPrevious -error
nnoremap <silent> <Plug>(ale_previous_wrap) :ALEPreviousWrap
nnoremap <silent> <Plug>(ale_previous) :ALEPrevious
legacy noremap <silent> <expr> <Plug>(clever-f-repeat-back) clever_f#repeat(1)
legacy noremap <silent> <expr> <Plug>(clever-f-repeat-forward) clever_f#repeat(0)
legacy noremap <silent> <expr> <Plug>(clever-f-reset) clever_f#reset()
legacy noremap <silent> <expr> <Plug>(clever-f-T) clever_f#find_with('T')
legacy noremap <silent> <expr> <Plug>(clever-f-t) clever_f#find_with('t')
legacy noremap <silent> <expr> <Plug>(clever-f-F) clever_f#find_with('F')
legacy noremap <silent> <expr> <Plug>(clever-f-f) clever_f#find_with('f')
xnoremap <silent> <Plug>(openbrowser-smart-search) :call openbrowser#_keymap_smart_search('v')
nnoremap <silent> <Plug>(openbrowser-smart-search) :call openbrowser#_keymap_smart_search('n')
xnoremap <silent> <Plug>(openbrowser-search) :call openbrowser#_keymap_search('v')
nnoremap <silent> <Plug>(openbrowser-search) :call openbrowser#_keymap_search('n')
xnoremap <silent> <Plug>(openbrowser-open-incognito) :call openbrowser#_keymap_open('v', 0, ['--incognito'])
nnoremap <silent> <Plug>(openbrowser-open-incognito) :call openbrowser#_keymap_open('n', 0, ['--incognito'])
xnoremap <silent> <Plug>(openbrowser-open) :call openbrowser#_keymap_open('v')
nnoremap <silent> <Plug>(openbrowser-open) :call openbrowser#_keymap_open('n')
vnoremap <C-C> :w !wl-copy
nnoremap <silent> <C-L> :noh
nmap <F8> :TagbarToggle
legacy inoremap <silent> <expr>  lexima#expand('<CR>', 'i')
inoremap  
legacy inoremap <silent> <expr>   lexima#expand('<SPACE>', 'i')
legacy inoremap <silent> <expr> " lexima#expand('"', 'i')
legacy inoremap <silent> <expr> ' lexima#expand('''', 'i')
legacy inoremap <silent> <expr> ( lexima#expand('(', 'i')
legacy inoremap <silent> <expr> ) lexima#expand(')', 'i')
legacy inoremap <silent> <expr> [ lexima#expand('[', 'i')
legacy inoremap <silent> <expr> ] lexima#expand(']', 'i')
legacy inoremap <silent> <expr> ` lexima#expand('`', 'i')
legacy inoremap <silent> <expr> { lexima#expand('{', 'i')
legacy inoremap <silent> <expr> } lexima#expand('}', 'i')
abbr cooklecurry@ cooklecurry@gmail.com
&cpo = cpo_save
legacy set ambiwidth=double
set autoindent
legacy set background=dark
legacy set directory=~/.vim/swap//,.,~/tmp,/var/tmp,/tmp
legacy set display=truncate
set expandtab
legacy set fileencodings=iso-2022-jp,euc-jp,sjis,utf-8
legacy set formatoptions=tcqmM
legacy set guicursor=n-v-c:block,o:hor50,i-ci:hor15,r-cr:hor30,sm:block,a:blinkon0
set helplang=ja
set history=50
set hlsearch
set ignorecase
set incsearch
set langnoremap
set nolangremap
set laststatus=2
legacy set listchars=tab:|\ ,extends:<,trail:-,eol:$
legacy set nrformats=bin,hex
legacy set runtimepath=~/.vim,~/.vim/plugged/tabular,~/.vim/plugged/previm,~/.vim/plugged/open-browser.vim,~/.vim/plugged/vim-markdown-assist,~/.vim/plugged/lightline.vim,~/.vim/plugged/im_control.vim,~/.vim/plugged/fcitx.vim,~/.vim/plugged/nerdtree,~/.vim/plugged/tagbar,~/.vim/plugged/webapi-vim,~/.vim/plugged/clever-f.vim,~/.vim/plugged/lexima.vim,~/.vim/plugged/vim-monokai,~/.vim/plugged/vim-autoformat,~/.vim/plugged/ale,~/.vim/plugged/vim-commentary,~/.vim/plugged/vim-fugitive,/usr/share/vim/vimfiles,/usr/share/vim/vim92,/usr/share/vim/vim92/pack/dist/opt/netrw,/usr/share/vim/vimfiles/after,~/.vim/plugged/tabular/after,~/.vim/plugged/vim-markdown-assist/after,~/.vim/after
set scrolloff=5
set shiftwidth=2
set showmatch
set smartcase
legacy set tabline=%!lightline#tabline()
set tabstop=2
set textwidth=100
set title
set ttimeout
set ttimeoutlen=100
legacy set viminfo='20,\"50
import autoload '/usr/share/vim/vim92/autoload/dist/ft.vim'
import autoload '/usr/share/vim/vim92/autoload/dist/vim9.vim'
import autoload '/usr/share/vim/vim92/autoload/dist/vimindent.vim'
const so_save: number = &g:so | const siso_save: number = &g:siso | setg so=0 siso=0 | setl so=-1 siso=-1
v:this_session = expand("<sfile>:p")
doautoall SessionLoadPre
var save_splitbelow: bool
var save_splitright: bool
var save_winminheight: number
var save_winminwidth: number
var wipebuf: number = -1
var shortmess_save: string
silent only
silent tabonly
cd ~/project/vim-markdown-assist
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  wipebuf = bufnr('%')
endif
set shortmess+=aoO
badd +0 after/ftplugin/markdown.vim
argglobal
:%argdel
:$argadd after/ftplugin/markdown.vim
edit after/ftplugin/markdown.vim
save_splitbelow = &splitbelow
save_splitright = &splitright
set splitbelow splitright
wincmd _ | wincmd |
split
:1wincmd k
wincmd w
&splitbelow = save_splitbelow
&splitright = save_splitright
wincmd t
save_winminheight = &winminheight
save_winminwidth = &winminwidth
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
exe ':1resize ' .. ((&lines * 42 + 27) / 55)
exe ':2resize ' .. ((&lines * 10 + 27) / 55)
argglobal
noremap <buffer> <silent> = :Autoformat
xnoremap <buffer> <silent> [" :exe "normal! gv"|call search('\%(^\s*".*\n\)\%(^\s*"\)\@!', "bW")
nnoremap <buffer> <silent> [" :call search('\%(^\s*".*\n\)\%(^\s*"\)\@!', "bW")
xnoremap <buffer> <silent> [] m':exe "normal! gv"|call search('^\s*end\(f\%[unction]\|\(export\s\+\)\?def\)\>', "bW")
nnoremap <buffer> <silent> [] m':call search('^\s*end\(f\%[unction]\|\(export\s\+\)\?def\)\>', "bW")
xnoremap <buffer> <silent> [[ m':exe "normal! gv"|call search('^\s*\(fu\%[nction]\|\(export\s\+\)\?def\)\>', "bW")
nnoremap <buffer> <silent> [[ m':call search('^\s*\(fu\%[nction]\|\(export\s\+\)\?def\)\>', "bW")
xnoremap <buffer> <silent> ]" :exe "normal! gv"|call search('\%(^\s*".*\n\)\@<!\%(^\s*"\)', "W")
nnoremap <buffer> <silent> ]" :call search('\%(^\s*".*\n\)\@<!\%(^\s*"\)', "W")
xnoremap <buffer> <silent> ][ m':exe "normal! gv"|call search('^\s*end\(f\%[unction]\|\(export\s\+\)\?def\)\>', "W")
nnoremap <buffer> <silent> ][ m':call search('^\s*end\(f\%[unction]\|\(export\s\+\)\?def\)\>', "W")
xnoremap <buffer> <silent> ]] m':exe "normal! gv"|call search('^\s*\(fu\%[nction]\|\(export\s\+\)\?def\)\>', "W")
nnoremap <buffer> <silent> ]] m':call search('^\s*\(fu\%[nction]\|\(export\s\+\)\?def\)\>', "W")
nnoremap <buffer> <silent> gf :call vimgoto#Find('gF')
cpo_save = &cpo
set cpo&vim
nnoremap <buffer> <silent> <C-W>gf :call vimgoto#Find("\<C-W>gF")
nnoremap <buffer> <silent> <C-W>f :call vimgoto#Find("\<C-W>F")
inoremap <buffer> <nowait> <silent>  =lexima#insmode#escape()
&cpo = cpo_save
setlocal keymap=
setlocal noarabic
setlocal autoindent
legacy setlocal backupcopy=
setlocal balloonexpr=
setlocal nobinary
setlocal nobreakindent
setlocal breakindentopt=
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),0],:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinscopedecls=public,protected,private
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
legacy setlocal comments=sO:\"\ -,mO:\"\ \ ,eO:\"\",:\"\\\ ,:\"
legacy setlocal commentstring=\"%s
setlocal complete=.,w,b,u,t,i
setlocal completefunc=
setlocal completeopt=
setlocal concealcursor=
setlocal conceallevel=0
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
set cursorline
setlocal cursorline
setlocal cursorlineopt=both
legacy setlocal define=\\v^\\s*export\\s*(def|const|var|final)
setlocal dictionary=
setlocal nodiff
setlocal diffanchors=
legacy setlocal equalprg=
setlocal errorformat=
setlocal eventignorewin=
setlocal expandtab
if &filetype != 'vim'
legacy setlocal filetype=vim
endif
setlocal fillchars=
setlocal findfunc=
setlocal fixendofline
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=0
setlocal foldmarker={{{,}}}
setlocal foldmethod=marker
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
legacy setlocal formatoptions=mMcroql
setlocal formatprg=
setlocal grepformat=
setlocal grepprg=
setlocal iminsert=0
setlocal imsearch=-1
legacy setlocal include=\\v^\\s*import\\s*(autoload)?
setlocal includeexpr=
setlocal indentexpr=g:VimIndent()
setlocal indentkeys=0{,0},0),0],!^F,o,O,e,=endif,=enddef,=endfu,=endfor,=endwh,=endtry,=endclass,=endinterface,=endenum,=},=else,=cat,=finall,=END,0\\,0=\"\\\ ,0=#\\\ 
setlocal noinfercase
legacy setlocal iskeyword=@,48-57,_,192-255,#
legacy setlocal keywordprg=:VimKeywordPrg
setlocal lhistory=10
setlocal nolinebreak
setlocal nolisp
setlocal lispoptions=
setlocal lispwords=
set list
setlocal list
legacy setlocal listchars=
setlocal makeencoding=
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
legacy setlocal nrformats=bin,hex
set number
setlocal number
setlocal numberwidth=4
legacy setlocal omnifunc=vimcomplete#Complete
legacy setlocal path=.,,,pack/**,runtime/**,autoload/**,colors/**,compiler/**,ftplugin/**,indent/**,keymap/**,macros/**,plugin/**,syntax/**,after/**,python/**
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norelativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal scrolloff=-1
setlocal scrolloffpad=-1
setlocal shiftwidth=2
setlocal noshortname
setlocal showbreak=
setlocal sidescrolloff=-1
setlocal signcolumn=auto
setlocal nosmartindent
setlocal nosmoothscroll
setlocal softtabstop=2
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal spelloptions=
legacy setlocal statusline=%{lightline#link()}%#LightlineLeft_inactive_0#%(\ %t\ %)%#LightlineLeft_inactive_0_1#%#LightlineMiddle_inactive#%=%#LightlineRight_inactive_1_2#%#LightlineRight_inactive_1#%(\ %3p%%\ %)%#LightlineRight_inactive_0_1#%#LightlineRight_inactive_0#%(\ %3l:%-2c\ %)
setlocal statuslineopt=
setlocal suffixesadd=
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'vim'
legacy setlocal syntax=vim
endif
setlocal tabstop=8
legacy setlocal tagcase=
setlocal tagfunc=
setlocal tags=
setlocal termwinkey=
setlocal termwinscroll=10000
setlocal termwinsize=
setlocal textwidth=0
setlocal thesaurus=
setlocal thesaurusfunc=
setlocal noundofile
setlocal undolevels=-123456
setlocal varsofttabstop=
setlocal vartabstop=
setlocal virtualedit=
setlocal wincolor=
setlocal nowinfixbuf
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal winhighlight=
set nowrap
setlocal nowrap
setlocal wrapmargin=0
:25
sil! normal! zo
:26
sil! normal! zo
:27
sil! normal! zo
:28
sil! normal! zo
:352
sil! normal! zo
:702
sil! normal! zo
:715
sil! normal! zo
:716
sil! normal! zo
:774
sil! normal! zo
:774
sil! normal! zc
{
  var l: number = 47 - ((21 * winheight(0) + 21) / 42)
  if l < 1 | l = 1 | endif
  keepjumps exe ":" .. l
  normal! zt
  keepjumps :47
  normal! 02|
}
wincmd w
argglobal
enew
balt after/ftplugin/markdown.vim
noremap <buffer> <silent> = :Autoformat
setlocal keymap=
setlocal noarabic
setlocal autoindent
setlocal backupcopy=
setlocal balloonexpr=
setlocal nobinary
setlocal nobreakindent
setlocal breakindentopt=
setlocal bufhidden=hide
setlocal buflisted
setlocal buftype=quickfix
setlocal nocindent
setlocal cinkeys=0{,0},0),0],:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinscopedecls=public,protected,private
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=s1:/*,mb:*,ex:*/,://,b:#,:%,:XCOMM,n:>,fb:-
setlocal commentstring=/*\ %s\ */
setlocal complete=.,w,b,u,t,i
setlocal completefunc=
setlocal completeopt=
setlocal concealcursor=
setlocal conceallevel=0
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
set cursorline
setlocal cursorline
setlocal cursorlineopt=both
setlocal define=
setlocal dictionary=
setlocal nodiff
setlocal diffanchors=
setlocal equalprg=
setlocal errorformat=
setlocal eventignorewin=
setlocal expandtab
if &filetype != 'qf'
setlocal filetype=qf
endif
setlocal fillchars=
setlocal findfunc=
setlocal fixendofline
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=0
setlocal foldmarker={{{,}}}
setlocal foldmethod=manual
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
legacy setlocal formatoptions=tcqmM
setlocal formatprg=
setlocal grepformat=
setlocal grepprg=
setlocal iminsert=0
setlocal imsearch=-1
setlocal include=
setlocal includeexpr=
setlocal indentexpr=
setlocal indentkeys=0{,0},0),0],:,0#,!^F,o,O,e
setlocal noinfercase
legacy setlocal iskeyword=@,48-57,_,192-255
setlocal keywordprg=
setlocal lhistory=10
setlocal nolinebreak
setlocal nolisp
setlocal lispoptions=
setlocal lispwords=
set list
setlocal list
legacy setlocal listchars=
setlocal makeencoding=
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal nomodifiable
legacy setlocal nrformats=bin,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norelativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal scrolloff=-1
setlocal scrolloffpad=-1
setlocal shiftwidth=2
setlocal noshortname
setlocal showbreak=
setlocal sidescrolloff=-1
setlocal signcolumn=auto
setlocal nosmartindent
setlocal nosmoothscroll
setlocal softtabstop=0
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal spelloptions=
legacy setlocal statusline=%{lightline#link()}%#LightlineLeft_active_0#%(\ %{lightline#mode()}\ %)%{((&paste))?\"|\":\"\"}%(\ %{&paste?\"PASTE\":\"\"}\ %)%#LightlineLeft_active_0_1#%#LightlineLeft_active_1#%(\ %R\ %)%{(&readonly)&&(1||(&modified||!&modifiable)||FixModeStatus()!=#\"\")?\"|\":\"\"}%(\ %t\ %)%{((&modified||!&modifiable)||FixModeStatus()!=#\"\")?\"|\":\"\"}%(\ %M\ %)%{(&modified||!&modifiable)&&(FixModeStatus()!=#\"\")?\"|\":\"\"}%(\ %{FixModeStatus()}\ %)%#LightlineLeft_active_1_2#%#LightlineMiddle_active#%=%#LightlineRight_active_2_3#%#LightlineRight_active_2#%(\ %{&ff}\ %)%{(1||1)?\"|\":\"\"}%(\ %{&fenc!=#\"\"?&fenc:&enc}\ %)%{(1)?\"|\":\"\"}%(\ %{&ft!=#\"\"?&ft:\"no\ ft\"}\ %)%#LightlineRight_active_1_2#%#LightlineRight_active_1#%(\ %3p%%\ %)%#LightlineRight_active_0_1#%#LightlineRight_active_0#%(\ %{FixColumnStatus()}\ %)
setlocal statuslineopt=
setlocal suffixesadd=
setlocal noswapfile
setlocal synmaxcol=3000
if &syntax != 'qf'
legacy setlocal syntax=qf
endif
setlocal tabstop=2
setlocal tagcase=
setlocal tagfunc=
setlocal tags=
setlocal termwinkey=
setlocal termwinscroll=10000
setlocal termwinsize=
setlocal textwidth=100
setlocal thesaurus=
setlocal thesaurusfunc=
setlocal noundofile
setlocal undolevels=-123456
setlocal varsofttabstop=
setlocal vartabstop=
setlocal virtualedit=
setlocal wincolor=
setlocal nowinfixbuf
setlocal winfixheight
setlocal nowinfixwidth
setlocal winhighlight=
set nowrap
setlocal nowrap
setlocal wrapmargin=0
wincmd w
:2wincmd w
exe ':1resize ' .. ((&lines * 42 + 27) / 55)
exe ':2resize ' .. ((&lines * 10 + 27) / 55)
tabnext 1
if wipebuf != -1 && len(win_findbuf(wipebuf)) == 0
  silent exe 'bwipe ' .. wipebuf
endif
&winheight = max([1, save_winminheight])
&winwidth = max([20, save_winminwidth])
set shortmess=filnxtToOS
&winminheight = save_winminheight
&winminwidth = save_winminwidth
var sx: string = expand("<sfile>:p:r") .. "x.vim"
if filereadable(sx)
  exe "source " .. fnameescape(sx)
endif
&g:so = so_save | &g:siso = siso_save
doautoall SessionLoadPost
unlet g:SessionLoad
# vim: set ft=vim :
