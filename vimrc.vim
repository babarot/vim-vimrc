" View directory {{{2
call s:mkdir('$HOME/.vim/view')
set viewdir=~/.vim/view
set viewoptions-=options
set viewoptions+=slash,unix
augroup view-file
  autocmd!
  autocmd BufLeave * if expand('%') !=# '' && &buftype ==# ''
        \ | mkview
        \ | endif
  autocmd BufReadPost * if !exists('b:view_loaded') &&
        \   expand('%') !=# '' && &buftype ==# ''
        \ | silent! loadview
        \ | let b:view_loaded = 1
        \ | endif
  autocmd VimLeave * call map(split(glob(&viewdir . '/*'), "\n"), 'delete(v:val)')
augroup END

" Automatically save and restore window size {{{2
augroup vim-save-window
  autocmd!
  autocmd VimLeavePre * call s:save_window()
  function! s:save_window()
    let options = [
          \ 'set columns=' . &columns,
          \ 'set lines=' . &lines,
          \ 'winpos ' . getwinposx() . ' ' . getwinposy(),
          \ ]
    call writefile(options, g:save_window_file)
  endfunction
augroup END
let g:save_window_file = expand('$HOME/.vimwinpos')
if s:vimrc_save_window_position
  if filereadable(g:save_window_file)
    execute 'source' g:save_window_file
  endif
endif

" Loading divided files {{{2
let g:local_vimrc = expand('~/.vimrc.local')
if filereadable(g:local_vimrc)
  execute 'source' g:local_vimrc
endif

set encoding=utf-8
set fileencodings=utf-8,iso-2022-jp,euc-jp,sjis,utf-8
set fileformats=unix,dos,mac

" Copy and paste helper {{{2
"nnoremap <silent>[Space]c :<C-u>call <SID>copipe_mode()<CR>
"function! s:copipe_mode()
"  if !exists('b:copipe_term_save')
"    let b:copipe_term_save = {
"          \     'number': &l:number,
"          \     'relativenumber': &relativenumber,
"          \     'foldcolumn': &foldcolumn,
"          \     'wrap': &wrap,
"          \     'list': &list,
"          \     'showbreak': &showbreak
"          \ }
"    setlocal foldcolumn=0
"    setlocal nonumber
"    setlocal norelativenumber
"    setlocal wrap
"    setlocal nolist
"    set showbreak=
"  else
"    let &l:foldcolumn = b:copipe_term_save['foldcolumn']
"    let &l:number = b:copipe_term_save['number']
"    let &l:relativenumber = b:copipe_term_save['relativenumber']
"    let &l:wrap = b:copipe_term_save['wrap']
"    let &l:list = b:copipe_term_save['list']
"    let &showbreak = b:copipe_term_save['showbreak']
"
"    unlet b:copipe_term_save
"  endif
"endfunction
"}}}
function! GetTildaPath(tail) "{{{2
  return a:tail ? expand('%:h:~') : expand('%:~')
endfunction

" Make tabpages
command! -nargs=? TabNew call s:tabnew(<q-args>)

" func s:tabnew() {{{2
function! s:tabnew(num)
  let num = empty(a:num) ? 1 : a:num
  for i in range(1, num)
    tabnew
  endfor
endfunction

" func s:toggle_variable() {{{2
function! s:toggle_variable(variable_name)
  if eval(a:variable_name)
    execute 'let' a:variable_name . ' = 0'
  else
    execute 'let' a:variable_name . ' = 1'
  endif
  echo printf('%s = %s', a:variable_name, eval(a:variable_name))
endfunction

" func s:confirm() {{{2
function! s:confirm(msg)
  return input(printf('%s [y/N]: ', a:msg)) =~? '^y\%[es]$'
endfunction

" func s:get_dir_separator() {{{2
function! s:get_dir_separator()
  return fnamemodify('.', ':p')[-1 :]
endfunction

" func s:escape_filename() {{{2
function! s:escape_filename(fname)
  let esc_filename_chars = ' *?[{`$%#"|!<>();&' . "'\t\n"
  if exists("*fnameescape")
    return fnameescape(a:fname)
  else
    return escape(a:fname, esc_filename_chars)
  endif
endfunction

" QuickLook for mac {{{2
if s:is_mac && executable("qlmanage")
  command! -nargs=? -complete=file QuickLook call s:quicklook(<f-args>)
  function! s:quicklook(...)
    let file = a:0 ? expand(a:1) : expand('%:p')
    if !s:has(file)
      echo printf('%s: No such file or directory', file)
      return 0
    endif
    call system(printf('qlmanage -p %s >& /dev/null', shellescape(file)))
  endfunction
endif

" func s:has() {{{2
" @params string
" @return bool
"
function! s:has(path)
  let save_wildignore = &wildignore
  setlocal wildignore=
  let path = glob(simplify(a:path))
  let &wildignore = save_wildignore
  if exists("*s:escape_filename")
    let path = s:escape_filename(path)
  endif
  return empty(path) ? s:false : s:true
endfunction


if s:vimrc_goback_to_eof2bof == s:true
  function! s:up(key)
    if line(".") == 1
      return ":call cursor(line('$'), col('.'))\<CR>"
    else
      return a:key
    endif
  endfunction 
  function! s:down(key)
    if line(".") == line("$")
      return ":call cursor(1, col('.'))\<CR>"
    else
      return a:key
    endif
  endfunction
  nnoremap <expr><silent> k <SID>up("gk")
  nnoremap <expr><silent> j <SID>down("gj")
endif
" Move cursor between beginning of line and end of line
"nnoremap <silent><Tab>   :<C-u>call <SID>move_left_center_right()<CR>
"nnoremap <silent><S-Tab> :<C-u>call <SID>move_left_center_right(1)<CR>

" func s:move_left_center_right() {{{2
" @params ...
" @return -
"
function! s:move_left_center_right(...)
  let curr_pos = getpos('.')
  let curr_line_len = len(getline('.'))
  let curr_pos[3] = 0
  let c = curr_pos[2]
  if 0 <= c && c < (curr_line_len / 3 * 1)
    if a:0 > 0
      let curr_pos[2] = curr_line_len
    else
      let curr_pos[2] = curr_line_len / 2
    endif
  elseif (curr_line_len / 3 * 1) <= c && c < (curr_line_len / 3 * 2)
    if a:0 > 0
      let curr_pos[2] = 0
    else
      let curr_pos[2] = curr_line_len
    endif
  else
    if a:0 > 0
      let curr_pos[2] = curr_line_len / 2
    else
      let curr_pos[2] = 0
    endif
  endif
  call setpos('.',curr_pos)
endfunction


" Tabpages mappings
nnoremap <silent> <C-t>L  :<C-u>call <SID>move_tabpage("right")<CR>
nnoremap <silent> <C-t>H  :<C-u>call <SID>move_tabpage("left")<CR>
nnoremap <silent> <C-t>dh :<C-u>call <SID>close_all_left_tabpages()<CR>
nnoremap <silent> <C-t>dl :<C-u>call <SID>close_all_right_tabpages()<CR>
" func s:move_tabpage() {{{2
" @params string
" @return -
"
function! s:move_tabpage(dir)
  if a:dir == "right"
    let num = tabpagenr()
  elseif a:dir == "left"
    let num = tabpagenr() - 2
  endif
  if num >= 0
    execute "tabmove" num
  endif
endfunction

" func s:close_all_right_tabpages() {{{2
" @params -
" @return -
"
function! s:close_all_right_tabpages()
  let current_tabnr = tabpagenr()
  let last_tabnr = tabpagenr("$")
  let num_close = last_tabnr - current_tabnr
  let i = 0
  while i < num_close
    execute "tabclose " . (current_tabnr + 1)
    let i = i + 1
  endwhile
endfunction

" func s:close_all_left_tabpages() {{{2
" @params -
" @return -
"
function! s:close_all_left_tabpages()
  let current_tabnr = tabpagenr()
  let num_close = current_tabnr - 1
  let i = 0
  while i < num_close
    execute "tabclose 1"
    let i = i + 1
  endwhile
endfunction


" Open new buffer or scratch buffer with bang.
command! -bang -nargs=? -complete=file BufNew call <SID>bufnew(<q-args>, <q-bang>)

" func s:smart_execute() {{{2
" @params string
" @return -
"
function! s:smart_execute(expr)
  let wininfo = winsaveview()
  execute a:expr
  call winrestview(wininfo)
endfunction

" Open the buffer again with tabpages
command! -nargs=? -complete=buffer ROT call <SID>recycle_open('tabedit', empty(<q-args>) ? expand('#') : expand(<q-args>))

" Open again with tabpages
command! -nargs=? Tab call s:tabdrop(<q-args>)

" func s:smart_bchange() {{{2
" func s:tabdrop() {{{2
" @params string
" @return -
"
function! s:tabdrop(target)
  let target = empty(a:target) ? expand('%:p') : bufname(a:target + 0)
  if !empty(target) && bufexists(target) && buflisted(target)
    execute 'tabedit' target
  else
    call s:warning("Could not tabedit")
  endif
endfunction

" @params string, string
" @return -
"
function! s:bufnew(buf, bang)
  let buf = empty(a:buf) ? '' : a:buf
  execute "new" buf | only
  if !empty(a:bang)
    let bufname = empty(buf) ? '[Scratch]' : buf
    setlocal bufhidden=unload
    setlocal nobuflisted
    setlocal buftype=nofile
    setlocal noswapfile
    silent file `=bufname`
  endif
endfunction

" Wipeout all buffers
command! -nargs=0 AllBwipeout call s:all_buffers_bwipeout()
" func s:all_buffers_bwipeout() {{{2
" @params -
" @return -
"
function! s:all_buffers_bwipeout()
  for i in range(1, bufnr('$'))
    if bufexists(i) && buflisted(i)
      execute 'bwipeout' i
    endif
  endfor
endfunction

function! Scouter(file, ...) "{{{2
  " Measure fighting power of Vim!
  " :echo len(readfile($MYVIMRC))
  let pat = '^\s*$\|^\s*"'
  let lines = readfile(a:file)
  if !a:0 || !a:1
    let lines = split(substitute(join(lines, "\n"), '\n\s*\\', '', 'g'), "\n")
  endif
  return len(filter(lines,'v:val !~ pat'))
endfunction

" Measure fighting strength of Vim.
command! -bar -bang -nargs=? -complete=file Scouter echo Scouter(empty(<q-args>) ? $MYVIMRC : expand(<q-args>), <bang>0)

" Plugin: {{{1
function! s:neobundled(bundle)
  return s:bundled(a:bundle) && neobundle#tap(a:bundle)
endfunction

" template
" username/vim-plugin {\{{2
" if s:neobundled('vim-plugin')
"   call neobundle#config({
"         \   "lazy" : 1,
"         \   "depends" : [
"         \     "username1/vim-plugin1",
"         \     "username2/vim-plugin2",
"         \   ],
"         \   "autoload" : {
"         \     "commands" : [ "Cmd" ],
"         \   }
"         \ })
" 
"   " Options
"   let g:config_variable = 1
"   " Commands
"   command! MyCmd call s:mycmd()
"   " Mappings
"   nnoremap
" 
"   call neobundle#untap()
" endif

" b4b4r07/mru.vim {{{2
if s:neobundled('mru.vim')
  call neobundle#config({
        \   "lazy" : 0,
        \   "autoload" : {
        \     "commands" : [ "MRU", "Mru" ],
        \   }
        \ })

  " Options
  let MRU_Use_Alt_useopen = 1
  let MRU_Window_Height   = &lines / 2
  let MRU_Max_Entries     = 100
  let MRU_Use_CursorLine  = 1
  " Commands
  " Mappings
  nnoremap <silent> [Space]j :<C-u>MRU<CR>
  vnoremap <silent> [Space]j <Esc><Esc>:<C-u>MRU<CR>

  call neobundle#untap()
endif

" b4b4r07/vim-sunset {{{2
if s:neobundled('vim-sunset')
  call neobundle#config({
        \   "gui" : 1
        \ })

  " Options
  let g:sunset_latitude = 35.67
  let g:sunset_longitude = 139.8
  let g:sunset_utc_offset = 9
  " Commands
  " Mappings

  call neobundle#untap()
endif

" b4b4r07/vim-ezoe {{{2
if s:neobundled('vim-ezoe')
  call neobundle#config({
        \   "lazy" : 1,
        \   "depends" : [ "mattn/webapi-vim" ],
        \   "autoload" : {
        \     "commands" : [ "Ezoe" ],
        \   }
        \ })

  " Options
  " Commands
  " Mappings

  call neobundle#untap()
endif

" b4b4r07/vim-buftabs {{{2
if s:neobundled('vim-buftabs')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "commands" : [
        \       "BuftabsEnable",
        \       "BuftabsDisable",
        \       "BuftabsToggle",
        \     ],
        \   }
        \ })

  " Options
  let g:buftabs_in_statusline   = 1
  let g:buftabs_in_cmdline      = 0
  let g:buftabs_only_basename   = 1
  let g:buftabs_marker_start    = "["
  let g:buftabs_marker_end      = "]"
  let g:buftabs_separator       = "#"
  let g:buftabs_marker_modified = "+"
  let g:buftabs_active_highlight_group = "Visual"
  let g:buftabs_statusline_highlight_group = 'BlackWhite'
  " Commands
  " Mappings

  call neobundle#untap()
endif

" b4b4r07/vim-autocdls {{{2
if s:neobundled('vim-autocdls')

  " Options
  let g:autocdls_autols_enabled = 1
  let g:autocdls_set_cmdheight = 2
  let g:autocdls_show_filecounter = 1
  let g:autocdls_show_pwd = 0
  let g:autocdls_alter_letter = 1
  let g:autocdls_newline_disp = 0
  let g:autocdls_ls_highlight = 1
  let g:autocdls_lsgrep_ignorecase = 1
  " Commands
  " Mappings

  call neobundle#untap()
endif

" b4b4r07/vim-shellutils {{{2
if s:neobundled('vim-shellutils')
  "call neobundle#config({
  "      \   "lazy" : 1,
  "      \   "autoload" : {
  "      \     "commands" : [
  "      \       "Ls",
  "      \       "File",
  "      \       "Rm",
  "      \       "Mkdir",
  "      \       "Rm",
  "      \       "Touch",
  "      \       "Cat",
  "      \       "Head",
  "      \       "Touch",
  "      \       "Tail",
  "      \       "Cp",
  "      \       "Mv",
  "      \     ],
  "      \   }
  "      \ })

  " Options
  let g:shellutils_disable_commands = ['Ls']
  " Commands
  " Mappings

  call neobundle#untap()
endif

" b4b4r07/vim-pt {{{2
if s:neobundled('vim-pt')
  call neobundle#config({
        \   "lazy" : 1,
        \   "external_commands" : [ "pt" ],
        \   "autoload" : {
        \     "commands" : [
        \       "Pt",
        \       "PtBuffer",
        \     ],
        \   }
        \ })

  call neobundle#untap()
  " Options
  let g:pt_highlight = 1
  " Commands
  " Mappings

  call neobundle#untap()
endif

" mattn/excitetranslate-vim {{{2
if s:neobundled('excitetranslate-vim')
  xnoremap E :ExciteTranslate<CR>
endif

" mattn/webapi-vim {{{2
if s:neobundled('webapi-vim')
  call neobundle#config({
        \   "lazy" : 1,
        \   "function_prefix" : "webapi"
        \ })

  call neobundle#untap()
endif

" mattn/benchvimrc-vim {{{2
if s:neobundled('benchvimrc-vim')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "commands" : [ "BenchVimrc" ],
        \   }
        \ })

  " Options
  " Commands
  " Mappings

  call neobundle#untap()
endif

" mattn/gist-vim {{{2
if s:neobundled('gist-vim')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "commands" : [ "Gist" ],
        \   }
        \ })

  " Options
  let g:github_user = 'b4b4r07'
  let g:github_token = ''
  let g:gist_curl_options = "-k"
  let g:gist_detect_filetype = 1
  " Commands
  " Mappings

  call neobundle#untap()
endif

" mattn/emmet-vim {{{2
if s:neobundled('emmet-vim')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "filetypes" : [
        \       "html",
        \       "xhttml",
        \       "css",
        \       "sass",
        \       "scss",
        \       "styl",
        \       "xml",
        \       "xls",
        \       "markdown",
        \       "htmldjango",
        \     ],
        \   }
        \ })

  " Options
  " Commands
  " Mappings

  call neobundle#untap()
endif

" Shougo/vimproc "{{{2
if s:neobundled('vimproc')
  call neobundle#config({
        \  'build' : {
        \    'windows' : 'make -f make_mingw32.mak',
        \    'cygwin'  : 'make -f make_cygwin.mak',
        \    'mac'     : 'make -f make_mac.mak',
        \    'unix'    : 'make -f make_unix.mak',
        \   },
        \ })

  " Options
  " Commands
  " Mappings

  call neobundle#untap()
endif

" Shougo/vimfiler {{{2
if s:neobundled('vimfiler')
  call neobundle#config({
        \   "lazy" : 1,
        \   "depends" : [],
        \   "autoload" : {
        \     "commands" : [
        \       {
        \         'name' : 'VimFiler',
        \         'complete' : 'customlist,vimfiler#complete',
        \       },
        \       {
        \         'name' : 'VimFilerTab',
        \         'complete' : 'customlist,vimfiler#complete',
        \       },
        \       {
        \         'name' : 'VimFilerBufferDir',
        \         'complete' : 'customlist,vimfiler#complete',
        \       },
        \       {
        \         'name' : 'VimFilerExplorer',
        \         'complete' : 'customlist,vimfiler#complete',
        \       },
        \       {
        \         'name' : 'Edit',
        \         'complete' : 'customlist,vimfiler#complete',
        \       },
        \       {
        \         'name' : 'Write',
        \         'complete' : 'customlist,vimfiler#complete',
        \       },
        \       'Read',
        \       'Source',
        \     ],
        \     'mappings' : '<Plug>(vimfiler_',
        \     'explorer' : 1,
        \   }
        \ })

  " Options
  let g:vimfiler_edit_action = 'tabopen'
  let g:vimfiler_enable_clipboard = 0
  let g:vimfiler_safe_mode_by_default = 0
  let g:vimfiler_as_default_explorer = 1
  let g:vimfiler_detect_drives = s:is_windows ? [
        \ 'C:/', 'D:/', 'E:/', 'F:/', 'G:/', 'H:/', 'I:/',
        \ 'J:/', 'K:/', 'L:/', 'M:/', 'N:/'] :
        \ split(glob('/mnt/*'), '\n') + split(glob('/media/*'), '\n') +
        \ split(glob('/Users/*'), '\n')

  " %p : full path
  " %d : current directory
  " %f : filename
  " %F : filename removed extensions
  " %* : filenames
  " %# : filenames fullpath
  let g:vimfiler_sendto = {
        \ 'unzip' : 'unzip %f',
        \ 'zip' : 'zip -r %F.zip %*',
        \ 'Inkscape' : 'inkspace',
        \ 'GIMP' : 'gimp %*',
        \ 'gedit' : 'gedit',
        \ }

  if s:is_windows
    " Use trashbox.
    let g:unite_kind_file_use_trashbox = 1
  else
    " Like Textmate icons.
    "let g:vimfiler_tree_leaf_icon = ' '
    "let g:vimfiler_tree_opened_icon = '▾'
    "let g:vimfiler_tree_closed_icon = '▸'
    "let g:vimfiler_file_icon = '-'
    "let g:vimfiler_readonly_file_icon = '✗'
    "let g:vimfiler_marked_file_icon = '✓'
  endif
  " let g:vimfiler_readonly_file_icon = '[O]'
  " Commands
  command! V VimFiler -tab -double
  " Mappings
  nnoremap <silent> [Space]v :<C-u>VimFiler -tab -double<CR>

  " Other {{{
  let g:vimfiler_no_default_key_mappings = 1
  augroup vimfiler-mappings
    au!
    au FileType vimfiler nmap <buffer> a <Plug>(vimfiler_choose_action)
    au FileType vimfiler nmap <buffer> b <Plug>(vimfiler_open_file_in_another_vimfiler)
    au FileType vimfiler nmap <buffer> B <Plug>(vimfiler_edit_binary_file)
    au FileType vimfiler nmap <buffer><nowait> c <Plug>(vimfiler_mark_current_line)<Plug>(vimfiler_copy_file)y<CR>
    au FileType vimfiler nmap <buffer> dd <Plug>(vimfiler_mark_current_line)<Plug>(vimfiler_delete_file)y<CR>
    au FileType vimfiler nmap <buffer> ee <Plug>(vimfiler_edit_file)
    au FileType vimfiler nmap <buffer> er <Plug>(vimfiler_edit_binary_file)
    au FileType vimfiler nmap <buffer> E <Plug>(vimfiler_new_file)
    au FileType vimfiler nmap <buffer> ge <Plug>(vimfiler_execute_external_filer)
    au FileType vimfiler nmap <buffer> gr <Plug>(vimfiler_grep)
    au FileType vimfiler nmap <buffer> gf <Plug>(vimfiler_find)
    au FileType vimfiler nmap <buffer> gc <Plug>(vimfiler_cd_vim_current_dir)
    au FileType vimfiler nmap <buffer> gs <Plug>(vimfiler_toggle_safe_mode)
    au FileType vimfiler nmap <buffer> gS <Plug>(vimfiler_toggle_simple_mode)
    au FileType vimfiler nmap <buffer> gg <Plug>(vimfiler_cursor_top)
    au FileType vimfiler nmap <buffer> g<C-g> <Plug>(vimfiler_toggle_maximize_window)
    au FileType vimfiler nmap <buffer> h <Plug>(vimfiler_smart_h)
    au FileType vimfiler nmap <buffer> H <Plug>(vimfiler_popup_shell)
    au FileType vimfiler nmap <buffer> i <Plug>(vimfiler_switch_to_another_vimfiler)
    au FileType vimfiler nmap <buffer> j <Plug>(vimfiler_loop_cursor_down)
    au FileType vimfiler nmap <buffer> k <Plug>(vimfiler_loop_cursor_up)
    au FileType vimfiler nmap <buffer> K <Plug>(vimfiler_make_directory)
    au FileType vimfiler nmap <buffer> l <Plug>(vimfiler_smart_l)
    au FileType vimfiler nmap <buffer> L <Plug>(vimfiler_switch_to_drive)
    au FileType vimfiler nmap <buffer> I <Plug>(vimfiler_cd_input_directory)
    au FileType vimfiler nmap <buffer><nowait> m <Plug>(vimfiler_mark_current_line)<Plug>(vimfiler_move_file)y<CR>
    au FileType vimfiler nmap <buffer> M <Plug>(vimfiler_set_current_mask)
    au FileType vimfiler nmap <buffer> o <Plug>(vimfiler_sync_with_current_vimfiler)
    au FileType vimfiler nmap <buffer> O <Plug>(vimfiler_open_file_in_another_vimfiler)
    "au FileType vimfiler nmap <buffer> O <Plug>(vimfiler_sync_with_another_vimfiler)
    au FileType vimfiler nmap <buffer> p <Plug>(vimfiler_quick_look)
    au FileType vimfiler nmap <buffer> P <Plug>(vimfiler_popd)
    au FileType vimfiler nmap <buffer> q <Plug>(vimfiler_close)
    au FileType vimfiler nmap <buffer> Q <Plug>(vimfiler_exit)
    au FileType vimfiler nmap <buffer> r <Plug>(vimfiler_rename_file)
    au FileType vimfiler nmap <buffer> S <Plug>(vimfiler_select_sort_type)
    au FileType vimfiler nmap <buffer> t <Plug>(vimfiler_expand_tree)
    au FileType vimfiler nmap <buffer> T <Plug>(vimfiler_expand_tree_recursive)
    au FileType vimfiler nmap <buffer> vv <Plug>(vimfiler_toggle_mark_all_lines)
    au FileType vimfiler nmap <buffer> vu <Plug>(vimfiler_clear_mark_all_lines)
    au FileType vimfiler nmap <buffer> vi <Plug>(vimfiler_preview_file)
    au FileType vimfiler nmap <buffer> x <Plug>(vimfiler_execute_system_associated)
    au FileType vimfiler nmap <buffer> yy <Plug>(vimfiler_yank_full_path)
    au FileType vimfiler nmap <buffer> Y <Plug>(vimfiler_pushd)
    au FileType vimfiler nmap <buffer> zc <Plug>(vimfiler_copy_file)
    au FileType vimfiler nmap <buffer> zm <Plug>(vimfiler_move_file)
    au FileType vimfiler nmap <buffer> zd <Plug>(vimfiler_delete_file)
    "au FileType vimfiler nmap <buffer> <C-l> <Plug>(vimfiler_redraw_screen)
    au FileType vimfiler nnoremap <silent><buffer><expr>es   vimfiler#do_action('split')
    au FileType vimfiler nmap <buffer> <RightMouse> <Plug>(vimfiler_execute_external_filer)
    au FileType vimfiler nmap <buffer> <C-CR> <Plug>(vimfiler_execute_external_filer)
    au FileType vimfiler nmap <buffer> <C-g><C-g> <Plug>(vimfiler_print_filename)
    au FileType vimfiler nmap <buffer> <C-v> <Plug>(vimfiler_switch_vim_buffer_mode)
    au FileType vimfiler nmap <buffer> <C-i> <Plug>(vimfiler_switch_to_other_window)
    "au FileType vimfiler nmap <buffer> <CR> <Plug>(vimfiler_execute)
    au FileType vimfiler nmap <buffer> <CR> <Plug>(vimfiler_quick_look)
    au FileType vimfiler nmap <buffer> <S-CR> <Plug>(vimfiler_execute_system_associated)
    au FileType vimfiler nmap <buffer> <2-LeftMouse> <Plug>(vimfiler_execute_system_associated)
    au FileType vimfiler nmap <buffer> <BS> <Plug>(vimfiler_switch_to_parent_directory)
    "au FileType vimfiler nmap <buffer> <C-h> <Plug>(vimfiler_switch_to_history_directory)
    au FileType vimfiler nmap <buffer> <Space> <Plug>(vimfiler_toggle_mark_current_line)
    au FileType vimfiler nmap <buffer> ~ <Plug>(vimfiler_switch_to_home_directory)
    au FileType vimfiler nmap <buffer> \ <Plug>(vimfiler_switch_to_root_directory)
    au FileType vimfiler nmap <buffer> . <Plug>(vimfiler_toggle_visible_dot_files)
    au FileType vimfiler nmap <buffer> ! <Plug>(vimfiler_execute_shell_command)
    au FileType vimfiler nmap <buffer> ? <Plug>(vimfiler_help)
    au FileType vimfiler nmap <buffer> ` <Plug>(vimfiler_toggle_mark_current_line_up)
    au FileType vimfiler vmap <buffer> @ <Plug>(vimfiler_toggle_mark_selected_lines)
    au FileType vimfiler nmap <buffer> @ <Plug>(vimfiler_toggle_mark_current_line)
  augroup END

  let g:vimfiler_quick_look_command =
        \ s:is_windows ? 'maComfort.exe -ql' :
        \ s:is_mac ? 'qlmanage -p' : 'gloobus-preview'
  "autocmd FileType vimfiler call s:vimfiler_my_settings()

  function! s:vimfiler_my_settings()
    call vimfiler#set_execute_file('vim', ['vim', 'notepad'])
    call vimfiler#set_execute_file('txt', 'vim')

    " Overwrite settings.
    nnoremap <silent><buffer> J
          \ <C-u>:Unite -buffer-name=files -default-action=lcd directory_mru<CR>
    " Call sendto.
    " nnoremap <buffer> - <C-u>:Unite sendto<CR>
    " setlocal cursorline


    " Migemo search.
    if !empty(unite#get_filters('matcher_migemo'))
      nnoremap <silent><buffer><expr> /  line('$') > 10000 ?  'g/' :
            \ ":\<C-u>Unite -buffer-name=search -start-insert line_migemo\<CR>"
    endif
    nunmap <buffer><C-l>
  endfunction
  "let g:vimfiler_as_default_explorer = 1
  "let g:vimfiler_safe_mode_by_default = 0
  "" Edit file by tabedit.
  "let g:vimfiler_edit_action = 'edit'
  "" Like Textmate icons.
  "let g:vimfiler_tree_leaf_icon = ' '
  "let g:vimfiler_tree_opened_icon = '▾'
  "let g:vimfiler_tree_closed_icon = '▸'
  "let g:vimfiler_file_icon = '-'
  "let g:vimfiler_marked_file_icon = '*'
  "nmap <F2>  :VimFiler -split -horizontal -project -toggle -quit<CR>
  "autocmd FileType vimfiler nnoremap <buffer><silent>/  :<C-u>Unite file -default-action=vimfiler<CR>
  "autocmd FileType vimfiler nnoremap <silent><buffer> e :call <SID>vimfiler_tree_edit('open')<CR>
  "" Windows.
  "" let g:vimfiler_quick_look_command = 'maComfort.exe -ql'
  "" Linux.
  "" let g:vimfiler_quick_look_command = 'gloobus-preview'
  "" Mac OS X.
  "let g:vimfiler_quick_look_command = 'qlmanage -p'
  "autocmd FileType vimfiler nnoremap <buffer> q <Plug>(vimfiler_quick_look)<CR>
  "autocmd FileType vimfiler nmap <buffer> q <Plug>(vimfiler_quick_look)<CR>
  "}}}

  call neobundle#untap()
endif

" Shougo/unite.vim {{{2
if s:neobundled('unite.vim')
  call neobundle#config({
        \   "lazy" : 1,
        \   "depends" : [ "Shougo/vimproc" ],
        \   "autoload" : {
        \     "commands" : [ "Unite" ],
        \   }
        \ })

  " Options
  let g:unite_winwidth                   = 40
  let g:unite_source_file_mru_limit      = 300
  let g:unite_enable_start_insert        = 0            "off is zero
  let g:unite_enable_split_vertically    = 0
  let g:unite_source_history_yank_enable = 1            "enable history/yank
  let g:unite_source_file_mru_filename_format  = ''
  let g:unite_kind_jump_list_after_jump_scroll = 0
  let g:unite_split_rule = 'botright'
  " Commands
  "nnoremap <silent>[Space]j :Unite file_mru -direction=botright -toggle<CR>
  "nnoremap <silent>[Space]o :Unite outline  -direction=botright -toggle<CR>
  nnoremap <silent>[Space]o :Unite outline -vertical -winwidth=40 -toggle<CR>
  "nnoremap <silent>[Space]o :Unite outline -vertical -no-quit -winwidth=40 -toggle<CR>
  " Grep
  nnoremap <silent> ,g  :<C-u>Unite grep:. -buffer-name=search-buffer<CR>
  " Grep word on cursor
  nnoremap <silent> ,cg :<C-u>Unite grep:. -buffer-name=search-buffer<CR><C-R><C-W>
  " Re-call grep results
  nnoremap <silent> ,r  :<C-u>UniteResume search-buffer<CR>

  if executable('pt')
    let g:unite_source_grep_command = 'pt'
    let g:unite_source_grep_default_opts = '--nogroup --nocolor'
    let g:unite_source_grep_recursive_opt = ''
  elseif executable('ag')
    " Use ag in unite grep source.
    let g:unite_source_grep_command = 'ag'
    let g:unite_source_grep_default_opts =
          \ '--line-numbers --nocolor --nogroup --hidden --ignore ' .
          \  '''.hg'' --ignore ''.svn'' --ignore ''.git'' --ignore ''.bzr'''
    let g:unite_source_grep_recursive_opt = ''
  elseif executable('ack')
  elseif executable('jvgrep')
    " For jvgrep.
    let g:unite_source_grep_command = 'jvgrep'
    let g:unite_source_grep_default_opts = '--exclude ''\.(git|svn|hg|bzr)'''
    let g:unite_source_grep_recursive_opt = '-R'
  endif

  " Mappings

  call neobundle#untap()
endif

" Shougo/neocomplete {{{2
if s:neobundled('neocomplete.vim')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "insert" : 1,
        \   },
        \   'disabled' : !has('lua'),
        \   'vim_version' : '7.3.885'
        \ })

  function! neobundle#tapped.hooks.on_source(bundle) "{{{
    " Use smartcase.
    let g:neocomplete#enable_smart_case = 1
    let g:neocomplete#enable_camel_case = 1
    let g:neocomplete#enable_underbar_completion = 1

    " Use fuzzy completion.
    let g:neocomplete#enable_fuzzy_completion = 1

    " Set minimum syntax keyword length.
    let g:neocomplete#sources#syntax#min_keyword_length = 3
    " Set auto completion length.
    let g:neocomplete#auto_completion_start_length = 2
    " Set manual completion length.
    let g:neocomplete#manual_completion_start_length = 0
    " Set minimum keyword length.
    let g:neocomplete#min_keyword_length = 3

    " Set neosnippet competion length.
    "call neocomplete#custom#source('neosnippet', 'min_pattern_length', 1)

    let g:neocomplete#disable_auto_select_buffer_name_pattern =
    \ '\[Command Line\]'

    if !exists('g:neocomplete#force_omni_input_patterns')
      let g:neocomplete#force_omni_input_patterns = {}
    endif
    let g:jedi#auto_vim_configuration = 0
    let g:neocomplete#sources#omni#input_patterns = {
    \ 'ruby' : '[^. *\t]\.\w*\|\h\w*::',
    \}
    let g:neocomplete#force_omni_input_patterns = {
    \ 'python': '\%([^. \t]\.\|^\s*@\|^\s*from\s.\+import \|^\s*from \|^\s*import \)\w*'
    \}
    " \ 'ruby' : '[^. *\t]\.\|\h\w*::',
    let g:neocomplete#sources#dictionary#dictionaries = {
    \ 'default' : '',
    \ 'vimshell' : $HOME.'/.vimshell_hist',
    \ 'scala' : $HOME.'/.vim/myplugin/vim-scala-dict/dict/scala.dict',
    \ }
  endfunction
  "}}}

  " Options
  let g:neocomplete#enable_at_startup = 1
  let g:neocomplete#enable_ignore_case = 1
  let g:neocomplete#enable_smart_case = 1
  if !exists('g:neocomplete#keyword_patterns')
      let g:neocomplete#keyword_patterns = {}
  endif
  let g:neocomplete#keyword_patterns._ = '\h\w*'
  " Commands
  inoremap <expr><TAB> pumvisible() ? "\<C-n>" : "\<TAB>"
  inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<S-TAB>"
  " Mappings

  " Other {{{
  "inoremap <expr><TAB> pumvisible() ? "\<C-n>" : "\<TAB>"
  "inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<S-TAB>"
  "highlight Pmenu      ctermbg=lightcyan ctermfg=black
  "highlight PmenuSel   ctermbg=blue      ctermfg=black
  "highlight PmenuSbari ctermbg=darkgray
  "highlight PmenuThumb ctermbg=lightgray
  "}}}

  call neobundle#untap()
endif

" Shougo/neosnippet {{{2
if s:neobundled('neosnippet')
  call neobundle#config({
        \   'lazy' : 1,
        \   'autoload' : {
        \     'insert' : 1,
        \     'filetypes' : 'neosnippet',
        \     'unite_sources' : [
        \       'snippet', 'neosnippet/user', 'neosnippet/runtime'
        \     ],
        \   }
        \ })

  function! neobundle#tapped.hooks.on_source(bundle) "{{{
    " For snippet_complete marker.
    if has('conceal')
      set conceallevel=2 concealcursor=i
    endif
    " Enable snipMate compatibility feature.
    let g:neosnippet#enable_snipmate_compatibility = 1
    " Remove snippets marker automatically

    "prioratise snippet
    "call neocomplete#custom#source('neosnippet', 'rank', 400)

    snoremap <Esc> <Esc>:NeoSnippetClearMarkers<CR>
  endfunction
  "}}}

  " Options
  " Enable snipMate compatibility feature.
  let g:neosnippet#enable_snipmate_compatibility = 1
  " Tell Neosnippet about the other snippets
  let g:neosnippet#snippets_directory='~/.vim/bundle/vim-snippets/snippets'
  "" Tell Neosnippet about the other snippets
  "if !exists("g:neosnippet#snippets_directory")
  "  let g:neosnippet#snippets_directory=""
  "endif
  ""let g:neosnippet#snippets_directory='~/.vim/bundle/snipmate-snippets/snippets, ~/.vim/mysnippets'
  "let g:neosnippet#snippets_directory='~/.vim/snippets, ~/.vim/bundle/vim-snippets/snippets'

  " Commands

  " Mappings
  imap <C-k> <Plug>(neosnippet_expand_or_jump)
  smap <C-k> <Plug>(neosnippet_expand_or_jump)
  xmap <C-k> <Plug>(neosnippet_expand_target)
  " SuperTab like snippets behavior.
  "imap <expr><TAB> neosnippet#expandable_or_jumpable() ?
  "      \ "\<Plug>(neosnippet_expand_or_jump)"
  "      \: pumvisible() ? "\<C-n>" : "\<TAB>"
  "smap <expr><TAB> neosnippet#expandable_or_jumpable() ?
  "      \ "\<Plug>(neosnippet_expand_or_jump)"
  "      \: "\<TAB>"

  " For snippet_complete marker.
  if has('conceal')
    set conceallevel=2 concealcursor=i
  endif
endif

" Shougo/vimshell {{{2
if s:neobundled('vimshell')
  call neobundle#config({
        \  'lazy' : 1,
        \  'depends' : [ 'Shougo/vimproc' ],
        \  'autoload' : {
        \    'commands' : [
        \      {
        \        'name' : 'VimShell',
        \        'complete' : 'customlist,vimshell#complete'
        \      },
        \      {
        \        'name' : 'VimShellTab',
        \        'complete' : 'customlist,vimshell#complete'
        \      },
        \      {
        \        'name' : 'VimShellBufferDir',
        \        'complete' : 'customlist,vimshell#complete'
        \      },
        \      {
        \        'name' : 'VimShellCreate',
        \        'complete' : 'customlist,vimshell#complete'
        \      },
        \      'VimShellExecute',
        \      'VimShellInteractive',
        \      'VimShellTerminal',
        \      'VimShellPop'
        \    ],
        \  }
        \ })

  function! neobundle#tapped.hooks.on_source(bundle) "{{{
    " Use current directory as vimshell prompt.
    let g:vimshell_prompt_expr = 'escape(fnamemodify(getcwd(), ":~").">", "\\[]()?! ")." "'
    let g:vimshell_prompt_pattern = '^\%(\f\|\\.\)\+> '
    let g:vimshell_right_prompt = 'vcs#info("(%s)-[%b]%p", "(%s)-[%b|%a]%p")'
  endfunction
  "}}}

  " Options
  " Commands
  " Mappings

  " Other {{{
  augroup my-vimshell
    autocmd!
    autocmd FileType vimshell
          \ imap <expr> <buffer> <C-n> pumvisible() ? "\<C-n>" : "\<Plug>(vimshell_history_neocomplete)"
  augroup END
  "}}}

  call neobundle#untap()
endif

" Shougo/unite-help {{{2
if s:neobundled('unite-help')
  call neobundle#config({
        \   "lazy" : 1,
        \   "depends" : [ 'Shougo/vimproc' ],
        \   "autoload" : {
        \     "unite_sources" : "help"
        \   }
        \ })

  " Options
  " Commands
  " Mappings

  call neobundle#untap()
endif

" Shougo/neomru.vim {{{2
if s:neobundled('neomru.vim')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "unite_sources" : "file_mru"
        \   }
        \ })

  " Options
  " Commands
  " Mappings

  call neobundle#untap()
endif

" Shougo/unite-outline {{{2
if s:neobundled('unite-outline')
  call neobundle#config({
        \   "lazy" : 1,
        \   "depends" : [ 'Shougo/unite.vim' ],
        \   "autoload" : {
        \     "unite_sources" : "outline"
        \   }
        \ })

  " Options
  " Commands
  " Mappings

  call neobundle#untap()
endif

" osyo-manga/vim-anzu {{{2
if s:neobundled('vim-anzu')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "mappings" : [ '<Plug>(anzu-' ],
        \   }
        \ })

  " Options
  " Commands
  " Mappings
  nmap n <Plug>(anzu-n-with-echo)
  nmap N <Plug>(anzu-N-with-echo)
  nmap * <Plug>(anzu-star-with-echo)
  nmap # <Plug>(anzu-sharp-with-echo)
  "nmap n <Plug>(anzu-mode-n)
  "nmap N <Plug>(anzu-mode-N)

  call neobundle#untap()
endif

" thinca/vim-quickrun {{{2
if s:neobundled('vim-quickrun')
  " Options
  let g:quickrun_config = {}
  let g:quickrun_config.markdown = {
        \ 'outputter' : 'null',
        \ 'command'   : 'open',
        \ 'cmdopt'    : '-a',
        \ 'args'      : 'Marked',
        \ 'exec'      : '%c %o %a %s',
        \ }
  " Commands
  " Mappings
endif

" thinca/vim-splash {{{2
if s:neobundled('vim-splash')
  "call neobundle#config({
  "      \   "lazy" : 1,
  "      \   "autoload" : {
  "      \     "commands" : [ 'Splash' ],
  "      \     "functions" : [ 'splash#intro' ],
  "      \   }
  "      \ })

  "let g:loaded_splash = 1
  let s:vim_intro = $HOME . "/.vim/bundle/vim-splash/sample/intro"
  if !isdirectory(s:vim_intro)
    call mkdir(s:vim_intro, 'p')
    execute ":lcd " . s:vim_intro . "/.."
    call system('git clone https://gist.github.com/OrgaChem/7630711 intro')
  endif
  let g:splash#path = expand(s:vim_intro . '/vim_intro.txt')

  " Options
  " Commands
  " Mappings

  call neobundle#untap()
endif

" thinca/vim-portal {{{2
if s:neobundled('vim-portal')
  " Options
  " Commands
  " Mappings
  nmap <Leader>pb <Plug>(portal-gun-blue)
  nmap <Leader>po <Plug>(portal-gun-orange)
  nnoremap <Leader>pr :<C-u>PortalReset<CR>

  call neobundle#untap()
endif

" thinca/vim-poslist {{{2
if s:neobundled('vim-poslist')
  " Options
  " Commands
  " Mappings
  "map <C-o> <Plug>(poslist-prev-pos)
  "map <C-i> <Plug>(poslist-next-pos)

  call neobundle#untap()
endif

" thinca/vim-scouter {{{2
if s:neobundled('vim-scouter')
  call neobundle#config({
        \   'autoload' : {
        \     'commands' : [ 'Scouter' ],
        \   }
        \ })

  " Options
  " Commands
  " Mappings

  call neobundle#untap()
endif

" thinca/vim-qfreplace {{{2
if s:neobundled('vim-qfreplace')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "filetypes" : [
        \       "unite",
        \       "quickfix",
        \     ],
        \   }
        \ })

  " Options
  " Commands
  " Mappings

  call neobundle#untap()
endif

" thinca/vim-ref {{{2
if s:neobundled('vim-ref')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "commands" : [
        \       {
        \         'name' : 'Ref',
        \         'complete' : 'customlist,ref#complete',
        \       },
        \     ],
        \     'unite_sources' : [ 'ref' ],
        \   }
        \ })

  function! neobundle#tapped.hooks.on_source(bundle) "{{{
    let g:ref_jquery_doc_path = $HOME . '/.vim/.bundle/jqapi'
    let g:ref_javascript_doc_path = $HOME . '/.vim/.bundle/jsref/htdocs'
    let g:ref_wikipedia_lang = ['ja', 'en']
    let g:ref_use_cache = 1
    let g:ref_source_webdict_sites = {
    \   'je': {
    \     'url': 'http://eow.alc.co.jp/search?q=%s&ref=sa',
    \   },
    \   'ej': {
    \     'url': 'http://eow.alc.co.jp/search?q=%s&ref=sa',
    \   },
    \   'etm': {
    \     'url': 'http://home.alc.co.jp/db/owa/etm_sch?stg=1&instr=%s',
    \   },
    \   'wiki': {
    \     'url': 'http://ja.wikipedia.org/wiki/%s',
    \   },
    \ }
    let g:ref_alc_encoding = 'utf-8'
  endfunction
  "}}}

  " Options
  " Commands
  " Mappings

  call neobundle#untap()
endif

" tyru/skk.vim {{{2
if s:neobundled('skk.vim')
  set imdisable
  let skk_jisyo = '~/SKK_JISYO.L'
  let skk_large_jisyo = '~/SKK_JISYO.L'
  let skk_auto_save_jisyo = 1
  let skk_keep_state = 0
  let skk_egg_like_newline = 1
  let skk_show_annotation = 1
  let skk_use_face = 1
endif

" tyru/eskk.vim {{{2
if s:neobundled('eskk.vim')
  set imdisable
  let g:eskk#directory = '~/SKK_JISYO.L'
  let g:eskk#dictionary = { 
        \   'path': "~/SKK_JISYO.L",
        \   'sorted': 0,
        \   'encoding': 'utf-8',
        \ }
  let g:eskk#large_dictionary = {
        \   'path': "~/SKK_JISYO.L",
        \   'sorted': 1,
        \   'encoding': 'utf-8',
        \ }
  let g:eskk#enable_completion = 1
endif

" tyru/restart.vim {{{2
if s:neobundled('restart.vim')
  call neobundle#config({
        \   "lazy" : 1,
        \   "gui" : 1,
        \   "autoload" : {
        \     "commands" : [ "Restart" ],
        \   }
        \ })

  " Options
  " Commands
  if has('gui_running')
    let g:restart_sessionoptions
          \ = 'blank,buffers,curdir,folds,help,localoptions,tabpages'
    command!
          \   RestartWithSession
          \   -bar
          \   let g:restart_sessionoptions = 'blank,curdir,folds,help,localoptions,tabpages'
          \   | Restart
  endif

  " Mappings

  call neobundle#untap()
endif

" tyru/open-browser {{{2
if s:neobundled('open-browser.vim')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "commands" : [
        \       "OpenBrowserSmartSearch",
        \       "OpenBrowser",
        \     ],
        \     "mappings" : [ "<Plug>(openbrowser-smart-search)" ],
        \   }
        \ })

  " Options
  " Commands
  " Mappings
  " If it looks like URI, open an URI under cursor.
  " Otherwise, search a word under cursor.
  nmap <Leader>o <Plug>(openbrowser-smart-search)
  " If it looks like URI, open selected URI.
  " Otherwise, search selected word.
  vmap <Leader>o <Plug>(openbrowser-smart-search)

  call neobundle#untap()
endif

" LeafCage/foldCC.vim {{{2
if s:neobundled('foldCC.vim')
  "set foldtext=foldCC#foldtext()
  let g:foldCCtext_head = 'v:folddashes. " "'
  let g:foldCCtext_tail = 'printf(" %s[%4d lines Lv%-2d]%s", v:folddashes, v:foldend-v:foldstart+1, v:foldlevel, v:folddashes)'
  let g:foldCCtext_enable_autofdc_adjuster = 1
endif

" LeafCage/yankround.vim {{{2
if s:neobundled('yankround.vim')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "mappings" : [ "<Plug>(yankround-" ],
        \   }
        \ })

  function! neobundle#tapped.hooks.on_source(bundle)
    " let g:yankround_use_region_hl = 1
  endfunction

  " Options
  let g:yankround_max_history = 100
  " Commands
  " Mappings
  nmap P  <Plug>(yankround-P)
  nmap gP <Plug>(yankround-gP)
  nmap p  <Plug>(yankround-p)
  xmap gp <Plug>(yankround-gp)
  xmap p <Plug>(yankround-p)
  xmap p <Plug>(yankround-p)
  nmap <C-p> <Plug>(yankround-prev)
  nmap <C-n> <Plug>(yankround-next)

  if s:has_plugin('unite.vim')
    nnoremap [Space]p :Unite yankround -direction=botright -toggle<CR>
  endif

  call neobundle#untap()
endif

" cohama/agit.vim {{{
if s:neobundled('agit.vim')
  call neobundle#config({
  \ 'depends': ['tpope/vim-fugitive'],
  \ 'autoload': {
  \   'commands' : ['Agit']
  \   }
  \ })
  call neobundle#untap()
endif

" itchyny/lightline.vim {{{2
if s:neobundled('lightline.vim')
  let g:lightline = {
        \ 'colorscheme': 'solarized',
        \ 'mode_map': {'c': 'NORMAL'},
        \ 'active': {
        \   'left':  [ [ 'mode', 'paste' ], [ 'fugitive' ], [ 'filename' ] ],
        \   'right' : [ [ 'date' ], [ 'filetype', 'fileencoding', 'fileformat', 'lineinfo', 'percent' ], [ 'filepath' ] ],
        \ },
        \ 'component_function': {
        \   'modified': 'MyModified',
        \   'readonly': 'MyReadonly',
        \   'fugitive': 'MyFugitive',
        \   'filepath': 'MyFilepath',
        \   'filename': 'MyFilename',
        \   'fileformat': 'MyFileformat',
        \   'filetype': 'MyFiletype',
        \   'fileencoding': 'MyFileencoding',
        \   'mode': 'MyMode',
        \   'date': 'MyDate'
        \ }
        \ }

  function! MyDate()
    return strftime("%Y/%m/%d %H:%M")
  endfunction

  function! MyModified()
    return &ft =~ 'help\|vimfiler\|gundo' ? '' : &modified ? '+' : &modifiable ? '' : '-'
  endfunction

  function! MyReadonly()
    return &ft !~? 'help\|vimfiler\|gundo' && &readonly ? 'x' : ''
  endfunction

  function! MyFilepath()
    return substitute(getcwd(), $HOME, '~', '')
  endfunction

  function! MyFilename()
    return ('' != MyReadonly() ? MyReadonly() . ' ' : '') .
          \ (&ft == 'vimfiler' ? vimfiler#get_status_string() :
          \  &ft == 'unite' ? unite#get_status_string() :
          \  &ft == 'vimshell' ? vimshell#get_status_string() :
          \ '' != expand('%:p:~') ? expand('%:p:~') : '[No Name]') .
          \ ('' != MyModified() ? ' ' . MyModified() : '')
  endfunction

  function! MyFugitive()
    try
      if &ft !~? 'vimfiler\|gundo' && exists('*fugitive#head')
        return fugitive#head()
      endif
    catch
    endtry
    return ''
  endfunction

  function! MyFileformat()
    return winwidth(0) > 70 ? &fileformat : ''
  endfunction

  function! MyFiletype()
    return winwidth(0) > 70 ? (strlen(&filetype) ? &filetype : 'NONE') : ''
  endfunction

  function! MyFileencoding()
    return winwidth(0) > 70 ? (strlen(&fenc) ? &fenc : &enc) : ''
  endfunction

  function! MyMode()
    return winwidth(0) > 60 ? lightline#mode() : ''
  endfunction

  call neobundle#untap()
endif

" itchyny/calendar.vim {{{2
if s:neobundled('calendar.vim')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "command" : [ "Calendar" ],
        \   },
        \ })


  function! neobundle#tapped.hooks.on_source(bundle) "{{{
    let g:calendar_google_calendar = 1
    let g:calendar_google_task = 1
    let g:calendar_date_endian = 'big'
  endfunction
  "}}}

  call neobundle#untap()
endif
" scrooloose/nerdtree {{{2
if s:neobundled('nerdtree')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "command" : [ "NERDTreeToggle" ],
        \   },
        \ })

  " Options
  let g:NERDTreeQuitOnOpen = 1
  let g:NERDTreeShowHidden = 1
  " Commands
  " Mappings
  nnoremap [Space]n :<C-u>NERDTreeToggle<CR>

  call neobundle#untap()
endif

" Yggdroot/indentLine {{{2
if s:neobundled('indentLine')
  " Options
  let g:indentLine_fileTypeExclude = ['', 'help', 'nerdtree', 'calendar', 'thumbnail', 'tweetvim']
  let g:indentLine_color_term = 111
  let g:indentLine_color_gui = '#708090'
  "let g:indentLine_char = '┆ ' "use ¦, ┆ or │
  " Commands
  " Mappings

  call neobundle#untap()
endif

" nathanaelkane/vim-indent-guides {{{2
if s:neobundled('vim-indent-guides')
  hi IndentGuidesOdd  ctermbg=DarkGreen
  hi IndentGuidesEven ctermbg=Black
  let g:indent_guides_enable_on_vim_startup = 0
  let g:indent_guides_start_level = 1
  let g:indent_guides_auto_colors = 0
  let g:indent_guides_guide_size = 1
endif

" sjl/gundo.vim {{{2
if s:neobundled('gundo.vim')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "command" : [ "GundoToggle" ],
        \   },
        \ })

  " Options
  "nnoremap <Leader>g :<C-u>GundoToggle<CR>
  let g:gundo_auto_preview = 0
  " Commands
  " Mappings

  call neobundle#untap()
endif

" glidenote/memolist.vim {{{2
if s:neobundled('memolist.vim')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "command" : [
        \       "MemoNew",
        \       "MemoGrep",
        \     ],
        \   },
        \ })


  "nnoremap <Leader>g :<C-u>GundoToggle<CR>
  let g:gundo_auto_preview = 0

  call neobundle#untap()
endif

" ujihisa/neco-look {{{2
if s:neobundled('neco-look')
  call neobundle#config({
        \   "lazy" : 1,
        \   "external_commands" : [ "look" ],
        \ })

  " Options
  " Commands
  " Mappings

  call neobundle#untap()
endif

" rking/ag.vim {{{2
if s:neobundled('ag.vim')
  call neobundle#config({
        \   "lazy" : 1,
        \   "external_commands" : [ "ag" ],
        \   "autoload" : {
        \     "commands" : [
        \       "Ag",
        \       "AgBuffer",
        \     ],
        \   }
        \ })

  " Options
  " Commands
  " Mappings

  call neobundle#untap()
endif

" justinmk/vim-dirvish {{{2
if s:neobundled('vim-dirvish')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "commands" : [ "Dirvish" ],
        \     "functions" : [ "dirvish#open()" ],
        \   }
        \ })

  " Options
  let g:dirvish_hijack_netrw = 1
  augroup my_dirvish_events
      au!
      " always show hidden files
      au User DirvishEnter let b:dirvish.showhidden = 1
  augroup END

  " Commands
  " Mappings
  nnoremap [Space]d :<C-u>call <SID>toggle_dirvish()<CR>
  function! s:toggle_dirvish()
    if &filetype == 'dirvish'
      if exists('b:dirvish')
        if winnr('$') > 1
          wincmd c
        else
          bdelete
        endif
      endif
    else
      execute 'Dirvish'
    endif
  endfunction

  call neobundle#untap()
endif

" ctrlpvim/ctrlp.vim {{{2
if s:neobundled('ctrlp.vim')
  "call neobundle#config({
  "\   'autoload' : {
  "\     'commands' : ['CtrlP'],
  "\     'function_prefix' : 'ctrlp',
  "\     'mappings' : '<c-q>'
  "\   }
  "\ })

  " Options
  let g:ctrlp_map = '<c-g>'
  let g:ctrlp_cmd = 'CtrlP'
  let g:ctrlp_user_command = 'find %s -type f'
  "let g:ctrlp_custom_ignore = '\v[\/]\.(git|hg|svn)$'
  let g:ctrlp_custom_ignore = {
    \ 'dir':  '\v[\/]\.(git|hg|svn)$',
    \ 'file': '\v\.(exe|so|dll)$',
    \ 'link': 'some_bad_symbolic_links',
    \ }
  " Commands
  " Mappings

  call neobundle#untap()
endif

" jzaiste/tmux.vim {{{2
if s:neobundled('tmux.vim')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "filetypes" : [ "tmux" ],
        \   }
        \ })

  " Options
  " Commands
  " Mappings

  call neobundle#untap()
endif

" jnwhiteh/vim-golang {{{2
if s:neobundled('vim-golang')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "filetypes" : [ "go" ],
        \   }
        \ })

  " Options
  " Commands
  " Mappings

  call neobundle#untap()
endif

" fatih/vim-go {{{2
if s:neobundled('vim-go')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "filetypes" : [ "go" ],
        \   }
        \ })

  " Options
  " Commands
  " Mappings

  call neobundle#untap()
endif

" cespare/vim-toml {{{2
if s:neobundled('vim-toml')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "filetypes" : [ "toml" ],
        \   }
        \ })

  " Options
  " Commands
  " Mappings

  call neobundle#untap()
endif

" dag/vim-fish {{{2
if s:neobundled('vim-fish')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "filetypes" : [ "fish" ],
        \   }
        \ })

  " Options
  " Commands
  " Mappings

  call neobundle#untap()
endif

" CORDEA/vim-glue {{{2
if s:neobundled('vim-glue')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "filetypes" : [ "glue" ],
        \   }
        \ })

  " Options
  " Commands
  " Mappings

  call neobundle#untap()
endif
" elzr/vim-json {{{2
if s:neobundled('vim-json')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "filetypes" : [ "json" ],
        \   }
        \ })

  " Options
  " Commands
  " Mappings

  call neobundle#untap()
endif

" tpope/vim-markdown {{{2
if s:neobundled('vim-markdown')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "filetypes" : [ "markdown" ],
        \   }
        \ })

  " Options
  " Commands
  " Mappings

  call neobundle#untap()
endif

" tpope/vim-fugutive {{{2
if s:neobundled('vim-fugitive')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "commands" : [
        \       "gstatus",
        \       "gcommit",
        \       "gwrite",
        \       "gdiff",
        \       "gblame",
        \       "git",
        \       "ggprep",
        \     ],
        \   }
        \ })

  " Options
  "nnoremap ;gs :<c-u>gstatus<cr>
  "nnoremap ;gc :<c-u>gcommit -v<cr>
  "nnoremap ;ga :<c-u>gwrite<cr>
  "nnoremap ;gd :<c-u>gdiff<cr>
  "nnoremap ;gb :<c-u>gblame<cr>
  " Commands
  " Mappings

  let s:bundle = neobundle#get('vim-fugitive')
  function! s:bundle.hooks.on_post_source(bundle)
    doautoall fugitive bufnewfile
  endfunction

  call neobundle#untap()
endif

" haya14busa/incsearch.vim {{{2
if s:neobundled('incsearch.vim')
  " let g:incsearch#highlight = {
  "       \   'match' : {
  "       \       'group' : 'IncSearchUnderline'
  "       \   }
  "       \ }
  map / <Plug>(incsearch-forward)
  map ? <Plug>(incsearch-backward)
  map g/ <Plug>(incsearch-stay)
  noremap ;/ /
  noremap ;? ?
  highlight IncSearchCursor ctermfg=0 ctermbg=9 guifg=#000000 guibg=#FF0000

  let g:incsearch#auto_nohlsearch = 1
  " let g:incsearch#consistent_n_direction = 1
  let g:incsearch#do_not_save_error_message_history = 1
  map  n <Plug>(incsearch-nohl)<Plug>(anzu-n-with-echo)
  map  N <Plug>(incsearch-nohl)<Plug>(anzu-N-with-echo)
  map  n <Plug>(incsearch-nohl-n)
  map  N <Plug>(incsearch-nohl-N)
  nmap n <Plug>(incsearch-nohl)<Plug>(anzu-n-with-echo)
  nmap N <Plug>(incsearch-nohl)<Plug>(anzu-N-with-echo)

  noremap <expr> ;<Tab>   incsearch#go({'command': '/', 'pattern': histget('/', -1)})
  noremap <expr> ;<S-Tab> incsearch#go({'command': '?', 'pattern': histget('/', -1)})
  call neobundle#untap()
endif

" vim-jp/vital.vim {{{2
if s:neobundled('vital.vim')
  call neobundle#config({
        \   "lazy" : 1,
        \   "autoload" : {
        \     "commands" : [ "Vitalize" ],
        \   }
        \ })

  " Options
  " Commands
  " Mappings

  call neobundle#untap()
endif

