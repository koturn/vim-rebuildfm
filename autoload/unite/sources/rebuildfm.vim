" ============================================================================
" FILE: rebuildfm.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" DESCRIPTION: {{{
" Unite source of vim-rebuildfm
" unite.vim: https://github.com/Shougo/unite.vim
" }}}
" ============================================================================
let s:save_cpo = &cpo
set cpo&vim


let s:source = {
      \ 'name': 'rebuildfm',
      \ 'description': 'candidates from Rebuild.fm numbers',
      \ 'action_table': {
      \   'play': {
      \     'description': 'Play this mp3',
      \   }
      \ },
      \ 'default_action': 'play',
      \}

function! unite#sources#rebuildfm#define() abort
  return s:source
endfunction


function! s:source.action_table.play.func(candidate) abort
  call rebuildfm#play(a:candidate.action__channel)
endfunction

function! s:source.gather_candidates(args, context) abort
  let channels = rebuildfm#get_channel_list()
  return map(channels, '{
        \ "word": v:val.title,
        \ "action__channel": v:val,
        \}')
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
