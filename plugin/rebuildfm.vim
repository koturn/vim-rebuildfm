" ============================================================================
" FILE: rebuildfm.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" DESCRIPTION: {{{
" Rebuild.fm client for Vim
" }}}
" ============================================================================
if exists('g:loaded_rebuildfm')
  finish
endif
let g:loaded_rebuildfm = 1
let s:save_cpo = &cpo
set cpo&vim


command! -bar -nargs=1 RebuildfmPlayByNumber call rebuildfm#play_by_number(<f-args>)
command! -bar -nargs=0 RebuildfmLiveStream call rebuildfm#live_stream()
command! -bar -nargs=0 RebuildfmStop call rebuildfm#stop()
command! -bar -nargs=0 RebuildfmTogglePause call rebuildfm#toggle_mute()
command! -bar -nargs=0 RebuildfmToggleMute call rebuildfm#toggle_pause()
command! -bar -nargs=1 RebuildfmSetVolume call rebuildfm#set_volume(<f-args>)
command! -bar -nargs=1 RebuildfmSetSpeed call rebuildfm#set_speed(<f-args>)
command! -bar -nargs=1 RebuildfmSeek call rebuildfm#seek(<f-args>)
command! -bar -nargs=1 RebuildfmRelSeek call rebuildfm#rel_seek(<f-args>)
command! -bar -nargs=0 RebuildfmShowInfo call rebuildfm#show_info()
command! -bar -nargs=0 RebuildfmUpdateChannel call rebuildfm#update_channel()


augroup Rebuildfm
  autocmd!
  autocmd VimLeave * call rebuildfm#stop()
augroup END


let &cpo = s:save_cpo
unlet s:save_cpo
