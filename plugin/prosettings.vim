if exists('g:loaded_prosettings') || &cp
  finish
endif
let g:loaded_prosettings = 1

command! -bar -bang -nargs=0 PSReloadSettings
      \ execute prosettings#reloadSettings()

augroup prosettings-init
  autocmd!
  autocmd VimEnter * ++once call prosettings#init()
augroup END
