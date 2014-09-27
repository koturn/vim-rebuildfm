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
let g:rebuildfm#cache_dir = get(g:, 'rebuildfm#cache_dir', expand("~/.cache/rebuildfm"))
let g:rebuildfm#verbose = get(g:, 'rebuildfm#verbose', 0)

let s:V = vital#of('rebuildfm')
let s:PM = s:V.import('ProcessManager')
let s:CACHE = s:V.import('System.Cache')
let s:JSON = s:V.import('Web.JSON')
let s:HTTP = s:V.import('Web.HTTP')
let s:XML = s:V.import('Web.XML')

let s:current_channel = {}
let s:REBUILDFM_FEEDS_URL = 'http://feeds.rebuild.fm/rebuildfm'
let s:REBUILDFM_MP3_URL = 'http://cache.rebuild.fm/'
let s:REBUILDFM_MP3_FILE_FORMAT = 'podcast-ep%s.mp3'
let s:REBUILDFM_LIVE_STREAM_URL = 'http://live.rebuild.fm:8000/listen'
let s:CACHE_FILENAME = 'channel.json'
let s:PROCESS_NAME = 'rebuildfm'
lockvar s:REBUILDFM_FEEDS_URL
lockvar s:REBUILDFM_MP3_URL
lockvar s:REBUILDFM_MP3_FILE_FORMAT
lockvar s:REBUILDFM_LIVE_STREAM_URL
lockvar s:CACHE_FILENAME
lockvar s:PROCESS_NAME


function! rebuildfm#play(channel)
  let s:current_channel = a:channel
  call s:play(a:channel.enclosure)
endfunction

function! rebuildfm#play_by_number(str)
  let l:channels = rebuildfm#get_channel_list()
  let l:filename = printf(s:REBUILDFM_MP3_FILE_FORMAT, a:str)
  let l:channel = s:search_mp3_url(l:channels, l:filename)
  if empty(l:channel)
    let l:filename = printf(s:REBUILDFM_MP3_FILE_FORMAT, a:str . '-r2')
    let l:channel = s:search_mp3_url(l:channels, l:filename)
  endif
  if empty(l:channel)
    let l:filename = printf(s:REBUILDFM_MP3_FILE_FORMAT, a:str . '-r2')
    let l:channel = s:search_mp3_url(l:channels, l:filename)
  endif

  if empty(l:channel)
    echoerr 'Cannot find by number'
  else
    let s:current_channel = l:channel
    call s:play(l:channel.enclosure)
    if g:rebuildfm#verbose
      echo 'Now playing:' l:channel.enclosure
    endif
  endif
endfunction

function! rebuildfm#show_info()
  if empty(s:current_channel) || !s:is_playing() | return | endif
  echo '[TITLE] ' s:current_channel.title
  echo '[PUBLISHED DATE] ' s:current_channel.pubDate
  echo '[DURATION] ' s:current_channel.duration
  echo '[SUMMARY]'
  echo '  ' s:current_channel.summary
  echo '[NOTES]'
  for l:item in s:current_channel.note
    echo '  -' l:item.text
  endfor
endfunction

function! rebuildfm#toggle_pause()
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'pause')
  endif
endfunction

function! rebuildfm#toggle_mute()
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'mute')
  endif
endfunction

function! rebuildfm#set_volume(volume)
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'volume ' . a:volume . ' 1')
  endif
endfunction

function! rebuildfm#set_speed(speed)
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'speed_set ' . a:speed)
  endif
endfunction

function! rebuildfm#seek(pos)
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'seek ' . a:pos . ' 1')
  endif
endfunction

function! rebuildfm#rel_seek(pos)
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'seek ' . a:pos)
  endif
endfunction

function! rebuildfm#stop()
  if s:is_playing()
    call s:PM.kill(s:PROCESS_NAME)
  endif
endfunction

function! rebuildfm#live_stream()
  call s:play(s:REBUILDFM_LIVE_STREAM_URL)
endfunction

function! rebuildfm#get_channel_list()
  if s:CACHE.filereadable(g:rebuildfm#cache_dir, s:CACHE_FILENAME)
    return s:JSON.decode(s:CACHE.readfile(g:rebuildfm#cache_dir, s:CACHE_FILENAME)[0]).rebuildfm
  else
    return rebuildfm#update_channel()
  endif
endfunction

function! rebuildfm#update_channel()
  let l:start_time = reltime()
  let l:response = s:HTTP.get(s:REBUILDFM_FEEDS_URL)
  if l:response.status != 200
    echoerr 'Connection error:' '[' . l:response.status . ']' l:response.statusText
    return
  endif
  if l:rebuildfm#verbose
    echomsg '[HTTP request]:' reltimestr(reltime(l:start_time)) 'ms'
  endif

  let l:start_time = reltime()
  let l:dom = s:XML.parse(l:response.content)
  if l:rebuildfm#verbose
    echomsg '[parse XML]:' reltimestr(reltime(l:start_time)) 'ms'
  endif

  let l:start_time = reltime()
  let l:infos = s:parse_dom(l:dom)
  if l:rebuildfm#verbose
    echomsg '[parse DOM]:' reltimestr(reltime(l:start_time)) 'ms'
  endif

  let l:write_list = [s:JSON.encode({'rebuildfm': l:infos})]
  call s:CACHE.writefile(l:rebuildfm#cache_dir, s:CACHE_FILENAME, l:write_list)
  return l:infos
endfunction


function! s:parse_dom(dom)
  let l:infos = []
  for l:c1 in a:dom.child
    if type(l:c1) == 4 && l:c1.name ==# 'channel'
      for l:c2 in l:c1.child
        if type(l:c2) == 4 && l:c2.name ==# 'item'
          let l:info = {}
          for l:c3 in l:c2.child
            if type(l:c3) == 4
              if l:c3.name ==# 'title'
                let l:info.title = l:c3.child[0]
              elseif l:c3.name ==# 'description'
                let l:info.note = s:parse_description('<html>' . l:c3.child[0] . '</html>')
              elseif l:c3.name ==# 'pubDate'
                let l:info.pubDate = l:c3.child[0]
              elseif l:c3.name ==# 'itunes:summary'
                let l:info.summary = l:c3.child[0]
              elseif l:c3.name ==# 'itunes:duration'
                let l:info.duration = l:c3.child[0]
              elseif l:c3.name ==# 'enclosure'
                let l:info.enclosure = l:c3.attr.url
              endif
            endif
            unlet l:c3
          endfor
          call add(l:infos, l:info)
        endif
        unlet l:c2
      endfor
    endif
    unlet l:c1
  endfor
  return l:infos
endfunction

function! s:parse_description(xml)
  let l:dom = s:XML.parse(a:xml)
  let l:note = []
  for l:c1 in l:dom.child
    if type(l:c1) == 4 && l:c1.name ==# 'ul'
      for l:c2 in l:c1.child
        if type(l:c2) == 4 && l:c2.name ==# 'li'
          call add(l:note, {
                \ 'href': l:c2.child[0].attr.href,
                \ 'text': l:c2.child[0].child[0]
                \})
        endif
        unlet l:c2
      endfor
    endif
    unlet l:c1
  endfor
  return l:note
endfunction

function! s:search_mp3_url(channels, filename)
  for l:channel in a:channels
    if l:channel.enclosure =~# a:filename . '$'
      return l:channel
    endif
  endfor
  return {}
endfunction

function! s:play(url)
  if executable(g:rebuildfm#play_command)
    if s:PM.is_available()
      call rebuildfm#stop()
      call s:PM.touch(s:PROCESS_NAME, g:rebuildfm#play_command . ' ' . g:rebuildfm#play_option . ' ' . a:url)
    else
      echoerr 'Error: vimproc is unavailable'
    endif
  else
    echoerr 'Error: Please install mplayer'
  endif
endfunction

function! s:is_playing()
  let l:status = 'dead'
  try
    let l:status = s:PM.status(s:PROCESS_NAME)
  catch
  endtry
  return l:status ==# 'inactive' || l:status ==# 'active'
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
