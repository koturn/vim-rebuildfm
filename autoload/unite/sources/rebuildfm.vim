" ============================================================================
" FILE: rebuildfm.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" DESCRIPTION: {{{
" Unite source of rebuildfm.vim
" }}}
" ============================================================================
let s:save_cpo = &cpo
set cpo&vim


let s:source = {
      \ 'name': 'rebuildfm',
      \ 'description': 'candidates from Mozaic.fm numbers',
      \ 'hooks': {},
      \ 'action_table': {
      \   'play': {
      \     'description': 'Play this mp3',
      \   }
      \ },
      \ 'default_action': 'play',
      \}

function! unite#sources#rebuildfm#define()
  return s:source
endfunction


function! s:source.action_table.play.func(candidate)
  call rebuildfm#play(a:candidate.action__channel)
endfunction

function! s:source.async_gather_candidates(args, context)
  let l:channels = rebuildfm#get_channel_list()
  let a:context.source.unite__cached_candidates = []
  return map(l:channels, '{
        \ "word": v:val.title,
        \ "action__channel": v:val,
        \}')
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
