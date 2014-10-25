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

let s:rebuildfm_var = {
      \ 'init':   'ctrlp#rebuildfm#init()',
      \ 'accept': 'ctrlp#rebuildfm#accept',
      \ 'lname':  'rebuildfm',
      \ 'sname':  'rebuildfm',
      \ 'type':   'line',
      \ 'sort':   0
      \}
if exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
  let g:ctrlp_ext_vars = add(g:ctrlp_ext_vars, s:rebuildfm_var)
else
  let g:ctrlp_ext_vars = [s:rebuildfm_var]
endif


function! ctrlp#rebuildfm#init()
  let s:channel_list = rebuildfm#get_channel_list()
  return map(copy(s:channel_list), 'v:val.title')
endfunction

function! ctrlp#rebuildfm#accept(mode, str)
  call ctrlp#exit()
  for l:channel in s:channel_list
    if l:channel.title ==# a:str
      call rebuildfm#play(l:channel)
      call rebuildfm#show_info()
      return
    endif
  endfor
endfunction

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
function! ctrlp#rebuildfm#id()
  return s:id
endfunction
