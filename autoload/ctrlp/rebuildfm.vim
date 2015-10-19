" ============================================================================
" FILE: rebuildfm.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" DESCRIPTION: {{{
" CtrlP extension of vim-rebuildfm.
" CtrlP: https://github.com/ctrlpvim/ctrlp.vim
" }}}
" ============================================================================
if exists('g:loaded_ctrlp_rebuildfm') && g:loaded_ctrlp_rebuildfm
  finish
endif
let g:loaded_ctrlp_rebuildfm = 1
let s:ctrlp_builtins = ctrlp#getvar('g:ctrlp_builtins')

let s:rebuildfm_var = {
      \ 'init': 'ctrlp#rebuildfm#init()',
      \ 'accept': 'ctrlp#rebuildfm#accept',
      \ 'lname': 'rebuildfm',
      \ 'sname': 'rebuildfm',
      \ 'type': 'line',
      \ 'sort': 0,
      \ 'nolim': 1
      \}
if exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
  call add(g:ctrlp_ext_vars, s:rebuildfm_var)
else
  let g:ctrlp_ext_vars = [s:rebuildfm_var]
endif

let s:id = s:ctrlp_builtins + len(g:ctrlp_ext_vars)
unlet s:ctrlp_builtins
function! ctrlp#rebuildfm#id() abort
  return s:id
endfunction

function! ctrlp#rebuildfm#init() abort
  let s:channel_list = rebuildfm#get_channel_list()
  return map(copy(s:channel_list), 'v:val.title')
endfunction

function! ctrlp#rebuildfm#accept(mode, str) abort
  call ctrlp#exit()
  for channel in s:channel_list
    if channel.title ==# a:str
      call rebuildfm#play(channel)
      call rebuildfm#show_info()
      return
    endif
  endfor
endfunction
