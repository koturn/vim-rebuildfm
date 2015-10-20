" ============================================================================
" FILE: rebuildfm.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" DESCRIPTION: {{{
" Rebuild.fm client for Vim
" }}}
" ============================================================================
let s:save_cpo = &cpo
set cpo&vim


let g:rebuildfm#play_command = get(g:, 'rebuildfm#play_command', 'mplayer')
let g:rebuildfm#play_option = get(g:, 'rebuildfm#play_option', '-really-quiet -slave')
let g:rebuildfm#cache_dir = get(g:, 'rebuildfm#cache_dir', expand('~/.cache/rebuildfm'))
let g:rebuildfm#verbose = get(g:, 'rebuildfm#verbose', 0)

let s:V = vital#of('rebuildfm')
let s:L = s:V.import('Data.List')
let s:CacheFile = s:V.import('System.Cache').new('file', {'cache_dir': g:rebuildfm#cache_dir})
let s:HTTP = s:V.import('Web.HTTP')
let s:XML = s:V.import('Web.XML')
let s:PM = s:V.import('ProcessManager')

let s:current_channel = {}
let s:REBUILDFM_FEEDS_URL = 'http://feeds.rebuild.fm/rebuildfm'
let s:REBUILDFM_MP3_FILE_FORMAT = 'podcast-ep%s.mp3'
let s:REBUILDFM_LIVE_STREAM_URL = 'http://live.rebuild.fm:8000/listen'
let s:PROCESS_NAME = 'rebuildfm'
lockvar s:REBUILDFM_FEEDS_URL
lockvar s:REBUILDFM_MP3_FILE_FORMAT
lockvar s:REBUILDFM_LIVE_STREAM_URL
lockvar s:PROCESS_NAME


function! rebuildfm#play(channel) abort
  let s:current_channel = a:channel
  call s:play(a:channel.enclosure)
endfunction

function! rebuildfm#play_by_number(str) abort
  let channels = rebuildfm#get_channel_list()
  let filename = printf(s:REBUILDFM_MP3_FILE_FORMAT, a:str)
  let channel = s:search_mp3_url(channels, filename)
  if empty(channel)
    let filename = printf(s:REBUILDFM_MP3_FILE_FORMAT, a:str . '-r2')
    let channel = s:search_mp3_url(channels, filename)
  endif
  if empty(channel)
    let filename = printf(s:REBUILDFM_MP3_FILE_FORMAT, a:str . '-r2')
    let channel = s:search_mp3_url(channels, filename)
  endif

  if empty(channel)
    echoerr 'Cannot find mp3 file by the specified number string:' a:str
  else
    let s:current_channel = channel
    call s:play(channel.enclosure)
    if g:rebuildfm#verbose
      echo 'Now playing:' channel.enclosure
    endif
  endif
endfunction

function! rebuildfm#show_info() abort
  if empty(s:current_channel) || !s:is_playing() | return | endif
  echo '[TITLE] ' s:current_channel.title
  echo '[PUBLISHED DATE] ' s:current_channel.pubDate
  echo '[DURATION] ' s:current_channel.duration
  echo '[SUMMARY]'
  echo '  ' s:current_channel.summary
  echo '[NOTES]'
  for item in s:current_channel.note
    echo '  -' item.text
  endfor
endfunction

function! rebuildfm#toggle_pause() abort
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'pause')
  endif
endfunction

function! rebuildfm#toggle_mute() abort
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'mute')
  endif
endfunction

function! rebuildfm#set_volume(volume) abort
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'volume ' . a:volume . ' 1')
  endif
endfunction

function! rebuildfm#set_speed(speed) abort
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'speed_set ' . a:speed)
  endif
endfunction

function! rebuildfm#seek(pos) abort
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'seek ' . a:pos . ' 1')
  endif
endfunction

function! rebuildfm#rel_seek(pos) abort
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'seek ' . a:pos)
  endif
endfunction

function! rebuildfm#stop() abort
  if s:is_playing()
    call s:PM.kill(s:PROCESS_NAME)
  endif
endfunction

function! rebuildfm#live_stream() abort
  call s:play(s:REBUILDFM_LIVE_STREAM_URL)
endfunction

function! rebuildfm#get_channel_list() abort
  let infos = s:CacheFile.get('channel')
  return empty(infos) ? rebuildfm#update_channel() : infos
endfunction

function! rebuildfm#update_channel() abort
  let start_time = reltime()
  let time = start_time
  let response = s:HTTP.get(s:REBUILDFM_FEEDS_URL)
  if response.status != 200
    echoerr 'Connection error:' '[' . response.status . ']' response.statusText
    return
  endif
  if g:rebuildfm#verbose
    echomsg '[HTTP request]:' reltimestr(reltime(time)) 's'
  endif

  let time = reltime()
  let dom = s:XML.parse(response.content)
  if g:rebuildfm#verbose
    echomsg '[parse XML]:   ' reltimestr(reltime(time)) 's'
  endif

  let time = reltime()
  let infos = s:parse_dom(dom)
  if g:rebuildfm#verbose
    echomsg '[parse DOM]:   ' reltimestr(reltime(time)) 's'
    echomsg '[total]:       ' reltimestr(reltime(start_time)) 's'
  endif

  call s:CacheFile.set('channel', infos)
  return infos
endfunction


function! s:parse_dom(dom) abort
  return map(a:dom.childNode('channel').childNodes('item'), 's:make_info(v:val)')
endfunction

function! s:make_info(item) abort
  let info = {}
  for c in filter(a:item.child, 'type(v:val) == 4')
    if c.name ==# 'title'
      let info.title = c.value()
    elseif c.name ==# 'description'
      let info.note = s:parse_description('<html>' . c.value() . '</html>')
    elseif c.name ==# 'pubDate'
      let info.pubDate = c.value()
    elseif c.name ==# 'itunes:subtitle'
      let info.summary = substitute(c.value(), '\n', ' ', 'g')
    elseif c.name ==# 'itunes:duration'
      let info.duration = c.value()
    elseif c.name ==# 'enclosure'
      let info.enclosure = c.attr.url
    endif
  endfor
  return info
endfunction

function! s:parse_description(xml) abort
  let lis = s:L.flatten(map(s:XML.parse(a:xml).childNodes('ul'), 'v:val.childNodes("li")'), 1)
  return map(map(filter(lis, '!empty(v:val.child) && type(v:val.child[0]) == 4'), 'v:val.child[0]'), '{
        \ "href": v:val.attr.href,
        \ "text": v:val.value()
        \}')
endfunction

function! s:search_mp3_url(channels, filename) abort
  let pattern = a:filename . '$'
  let channels = filter(a:channels, 'v:val.enclosure =~# pattern')
  return len(channels) == 0 ? {} : channels[0]
endfunction

function! s:play(url) abort
  if !executable(g:rebuildfm#play_command)
    echoerr 'Error: Please install mplayer'
    return
  endif
  if !s:PM.is_available()
    echoerr 'Error: vimproc is unavailable'
    return
  endif
  call rebuildfm#stop()
  call s:PM.touch(s:PROCESS_NAME, g:rebuildfm#play_command . ' ' . g:rebuildfm#play_option . ' ' . a:url)
endfunction

function! s:is_playing() abort
  let status = 'dead'
  try
    let status = s:PM.status(s:PROCESS_NAME)
  catch
  endtry
  return status ==# 'inactive' || status ==# 'active'
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
