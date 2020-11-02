let s:_prosettings = {
  \ 'root_dir_markers': ['.git', '.hg', '.bzr', '.svn', 'Makefile'],
  \ 'resolve_symlinks': 0,
  \ 'filename': '.vimrc'
  \ }

let s:ESC = 27 " ASCII number of the ESC key

function! s:getChar() abort
  try
    let l:code = ''
    while type(l:code) != v:t_number
      let l:code = getchar()
    endwhile
    return l:code == s:ESC ? nr2char(s:ESC) : nr2char(l:code)
  catch /Vim:Interrupt/
    return ''
  endtry
endfunction

function! s:getCurrentDir() abort
  let l:fn = expand('%:p', 1)
  if empty(l:fn) | return getcwd() | endif  " opening vim without a file
  if s:prosettings.resolve_symlinks | let l:fn = resolve(l:fn) | endif
  return fnamemodify(l:fn, ':h')
endfunction

function! s:getParentDir(dir) abort
  return fnamemodify(a:dir, ':h')
endfunction

" Returns true if dir is identifier, false otherwise.
"
" dir        - full path to a directory
" identifier - a directory name
function! s:is(dir, identifier) abort
  let l:identifier = substitute(a:identifier, '/$', '', '')
  return fnamemodify(a:dir, ':t') ==# l:identifier
endfunction

" Returns true if dir contains identifier, false otherwise.
"
" dir        - full path to a directory
" identifier - a file name or a directory name; may be a glob
function! s:has(dir, identifier) abort
  return !empty(globpath(a:dir, a:identifier, 1))
endfunction

" Returns true if identifier is an ancestor of dir, false otherwise.
"
" dir        - full path to a directory
" identifier - a directory name
function! s:sub(dir, identifier) abort
  let l:path = s:parent(a:dir)
  while 1
    if fnamemodify(l:path, ':t') ==# a:identifier | return 1 | endif
    let [l:current, l:path] = [l:path, s:getParentDir(l:path)]
    if l:current == l:path | break | endif
  endwhile
  return 0
endfunction

function s:match(dir, pattern) abort
  if a:pattern[0] == '='
    return s:is(a:dir, a:pattern[1:])
  elseif a:pattern[0] == '^'
    return s:sub(a:dir, a:pattern[1:])
  else
    return s:has(a:dir, a:pattern)
  endif
endfunction

function! s:findRootDir() abort
  let l:dir = s:getCurrentDir()

  " breadth-first search
  while 1
    for l:pattern in s:prosettings.root_dir_markers
      if l:pattern[0] == '!'
        let [l:p, l:exclude] = [l:pattern[1:], 1]
      else
        let [l:p, l:exclude] = [l:pattern, 0]
      endif
      if s:match(l:dir, l:p)
        if l:exclude
          break
        else
          return l:dir
        endif
      endif
    endfor

    let [l:current, l:dir] = [l:dir, s:getParentDir(l:dir)]
    if l:current == l:dir | break | endif
  endwhile

  return ''
endfunction

function! s:findSettingsFile() abort
  let l:rootDir = s:findRootDir()
  if l:rootDir ==? '' | return '' | endif
  let l:file = l:rootDir . '/' . s:prosettings.filename
  " if by any chance the user opens Vim in its home folder,
  " and one of the root markers have been found there,
  " we ignore its global .vimrc
  if expand(l:file) == expand("~/.vimrc")
    return ''
  elseif filereadable(l:file)
    return l:file
  endif
  return ''
endfunction

" instead using the `bufdo` command we iterate through all buffers
" and source the settings for each to avoid losing syntax highlighting
" if it's turned on, which will be turned off when `bufdo` is used
function! s:reloadBuffers(file)
  wa " write changed buffers
  noh " turn off highlighting
  messages clear
  let l:active = bufnr('%')
  let l:buffers = map(copy(getbufinfo()), 'v:val.bufnr')
  for i in l:buffers
    silent execute printf('b%i | source %s', i, fnameescape(a:file))
  endfor
  silent execute printf('b%i', l:active)
endfunction

function! s:loadSettingsFile(file, ...) abort
  let l:reload = get(a:, 1, 0) " tells whether the file is reloaded on demand or not
  let l:esFile = fnameescape(a:file)

  try
    silent execute 'source ' . l:esFile
    if l:reload ==? 1
      silent execute 'windo tabdo source ' . l:esFile
      call s:reloadBuffers(a:file) " instead of `bufdo`
    endif
  catch /^Vim\%((\a\+)\)\=:/
    " v:exception contains what is normally in v:errmsg, but with extra
    " exception source info prepended, which we cut away.
    let l:errMsg = substitute(v:exception, '^Vim\%((\a\+)\)\=:', '', '')
    echohl ErrorMsg
    echom printf('Error detected while processing %s: ', l:esFile)
    echom l:errMsg
    echohl None
  endtry
endfunction

function! prosettings#reloadSettings() abort
  let l:file = s:findSettingsFile()
  if l:file ==? '' | return | endif
  call s:loadSettingsFile(l:file, 1)
endfunction

function! prosettings#init() abort
  let s:prosettings = deepcopy(get(g:, 'prosettings', {}))
  for [l:key, l:value] in items(s:_prosettings)
    if type(l:value) == 4
      if !has_key(s:prosettings, l:key)
        let s:prosettings[l:key] = {}
      endif
      call extend(s:prosettings[l:key], l:value, 'keep')
    elseif !has_key(s:prosettings, l:key)
      let s:prosettings[l:key] = l:value
    endif
    unlet l:value
  endfor

  let l:file = s:findSettingsFile()
  if l:file ==? '' | return | endif

  echom printf('%s found, should I load it for you? (y[es] / n[o] or press Esc to cancel)', l:file)
  let l:userInput = ''
  while (index(['y', 'n', nr2char(s:ESC)], l:userInput) == -1)
    let l:userInput = tolower(s:getChar())
  endwhile

  if l:userInput ==? nr2char(s:ESC)
    return
  elseif l:userInput ==? 'y'
    call s:loadSettingsFile(l:file)
  endif
endfunction
