" Vim plugin
" License:        Apache 2.0
" Origin Author:  Thaer Khawaja
" Origin URL:     https://github.com/thaerkh/vim-workspace
" Mantainer:      Xuta Le
" URL:            https://github.com/xuta/vim-xspace

let g:xspace_session_name = get(g:, 'xspace_session_name', 'Session.vim')
let g:xspace_undodir = get(g:, 'xspace_undodir', '.undodir')
let g:xspace_autosave_ignore = get(s:, 'xspace_autosave_ignore', ['gitcommit', 'gitrebase', 'nerdtree'])

let s:xspace_session_dir = system("git rev-parse --show-toplevel 2>/dev/null | tr '\\n' '/'")
let s:is_git_project = empty(s:xspace_session_dir) ? 0 : 1
let s:xspace_session_path = s:xspace_session_dir . g:xspace_session_name
let s:xspace_undodir_path = s:xspace_session_dir . g:xspace_undodir

let s:xspace_autosave_au_updatetime = get(s:, 'xspace_autosave_au_updatetime', 3)

function! s:WorkspaceExists()
  return filereadable(s:xspace_session_path)
endfunction

function! s:MakeWorkspace(workspace_save_session)
  if a:workspace_save_session == 1 || get(s:, 'workspace_save_session', 0) == 1
    let s:workspace_save_session = 1
    execute printf('mksession! %s', s:xspace_session_path)
  endif
endfunction

function! s:FindOrNew(filename)
  let l:fnr = bufnr(a:filename)
  for tabnr in range(1, tabpagenr("$"))
    for bufnr in tabpagebuflist(tabnr)
      if (bufnr == l:fnr)
        execute 'tabn ' . tabnr
        call win_gotoid(win_findbuf(l:fnr)[0])
        return
      endif
    endfor
  endfor
  execute 'buffer ' . l:fnr
endfunction

function! s:ConfigureWorkspace()
  call s:SetUndoDir()
  call s:SetAutosave(1)
endfunction

function! s:RemoveWorkspace()
  let s:workspace_save_session  = 0
  execute printf('call delete("%s")', s:xspace_session_path)
endfunction

function! s:XSpaceInfo()
  if s:WorkspaceExists()
    echo 'XSpace is on!'
    echo 'session file is ' . s:xspace_session_path
    echo 'undodir is ' . s:xspace_undodir_path
  else
    echo 'XSpace is off'
  endif
endfunction

function! s:XSpaceOn()
  if s:WorkspaceExists()
    echo 'XSpace is on already!!!'
  else
    call s:MakeWorkspace(1)
    call s:ConfigureWorkspace()
    echo 'XSpace is on!!!'
  endif
endfunction

function! s:XSpaceOff()
  if s:WorkspaceExists()
    call s:RemoveWorkspace()
    execute printf('silent !rm -rf %s', s:xspace_undodir_path)
    call feedkeys("") | silent! redraw!  " Recover view from external comand
    echo 'XSpace is off'
  else
    echo 'XSpace is off already!!!'
  endif
endfunction

function! s:LoadWorkspace()
  if index(g:xspace_autosave_ignore, &filetype) != -1 || get(s:, 'read_from_stdin', 0)
    return
  endif

  if s:WorkspaceExists()
    let s:workspace_save_session = 1
    let l:filename = expand(@%)
    execute 'source ' . s:xspace_session_path
    call s:ConfigureWorkspace()
    call s:FindOrNew(l:filename)
  else
    if s:is_git_project
      call s:XSpaceOn()
    else
      let s:workspace_save_session = 0
    endif
  endif
  set sessionoptions-=options
endfunction

function! s:Autosave(timed)
  if index(g:xspace_autosave_ignore, &filetype) != -1 || &readonly || mode() == 'c' || pumvisible()
    return
  endif

  let current_time = localtime()
  let s:last_update = get(s:, 'last_update', 0)
  let s:time_delta = current_time - s:last_update

  if a:timed == 0 || s:time_delta >= 1
    let s:last_update = current_time
    checktime  " checktime with autoread will sync files on a last-writer-wins basis.
    silent! doautocmd BufWritePre %  " needed for soft checks
    silent! update  " only updates if there are changes to the file.
    if a:timed == 0 || s:time_delta >= s:xspace_autosave_au_updatetime
      silent! doautocmd BufWritePost %  " Periodically trigger BufWritePost.
    endif
  endif
endfunction

function! s:SetAutosave(enable)
  if a:enable == 1
    let s:autoread = &autoread
    let s:autowriteall = &autowriteall
    let s:swapfile  = &swapfile
    let s:updatetime = &updatetime
    set autoread
    set autowriteall
    set noswapfile
    " don't clobber lower settings by user
    if s:updatetime >= 1000
      set updatetime=1000 " limited to 1s as default to match localtime() trigger limitations,
    endif
    if !has('nvim')
      let s:swapsync = &swapsync
      set swapsync=""
    endif
    augroup XSpace
      au! BufLeave,FocusLost,FocusGained,InsertLeave * call s:Autosave(0)
      au! CursorHold * call s:Autosave(1)
      au! BufEnter * call s:MakeWorkspace(0)
    augroup END
    let s:autosave_on = 1
  else
    let &autoread = s:autoread
    let &autowriteall = s:autowriteall
    let &updatetime = s:updatetime
    let &swapfile = s:swapfile
    if !has('nvim')
      let &swapsync = s:swapsync
    endif
    au! XSpace * *
    let s:autosave_on = 0
  endif
endfunction

function! s:SetUndoDir()
  if !isdirectory(s:xspace_undodir_path)
    call mkdir(s:xspace_undodir_path)
  endif
  execute 'set undodir=' . resolve(s:xspace_undodir_path)
  set undofile
endfunction

function! s:PostLoadCleanup()
  if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endfunction

augroup Workspace
  au! VimEnter * nested call s:LoadWorkspace()
  au! StdinReadPost * let s:read_from_stdin = 1
  au! VimLeave * call s:MakeWorkspace(0)
  au! InsertLeave * if getcmdwintype() == '' && pumvisible() == 0 | pclose | endif
  au! SessionLoadPost * call s:PostLoadCleanup()
augroup END

command! XSpaceOn call s:XSpaceOn()
command! XSpaceOff call s:XSpaceOff()
command! XSpaceInfo call s:XSpaceInfo()

set sessionoptions-=blank

" vim: ts=2 sw=2 et
