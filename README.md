vim-rebuildfm
=============

[Rebuild.fm](http://rebuild.fm/) client for Vim.
Let's enjoy Rebuild.fm with Vim!


## Usage

First, get urls of mp3 and save cache by execute following command.
It takes some time until the command is done.

```vim
:RebuildfmUpdateChannel
```

Second, specify the number you want to listen.

```vim
:RebuildfmPlayByNumber 20
```

If you available [unite.vim](https://github.com/Shougo/unite.vim), you may use
the unite source of this Rebuild.fm client.

```vim
:Unite rebuild
```


## Dependent plugin

- [vimproc.vim](https://github.com/Shougo/vimproc.vim)


## Requirement

- mplayer
- HTTP Client (one of the following)
  - python
  - curl
  - wget


## LICENSE

This software is released under the MIT License, see LICENSE.
