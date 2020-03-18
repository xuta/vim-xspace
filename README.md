# XSpace

`XSpace` enhanced vim's native `mksession` to provide a solution for sessions management and great integration with `git` projects.

# Features

### Sessions management

When `XSpace is on`, it records all changes with your windows position, tabs, buffers, changes (on files), etc.. to help you continue with what you left from last time, even you can undo your changes.

### Git integration

If you start a vim session under a `git` project, `XSpace` will automatically set it `on` with `s:xspace_session_dir` is **root of the git project directory**

```vim
let s:xspace_session_dir = system("git rev-parse --show-toplevel 2>/dev/null | tr '\\n' '/'")
```

# How to work with XSpace

Very easy, the plugin provides you three commands


### XSpaceInfo

```
:XSpaceInfo
```
It will shows state of `XSpace` is on/off and path to session file and undo dir.


### XSpaceOn

```
:XSpaceOn
```

To start `XSpace` if it wasn't started yet or just show a message that `XSpace is on already!!!`


### XSpaceOff

```
:XSpaceOff
```

To stop `XSpace` if it's on or just show a message that `XSpace is off already!!!`


# Configuration

By default, the plugin sets use `Session.vim` as session name and `.undodir` as undo directory.

You can change if you like to do so

```vim
let g:xspace_session_name = 'A_NEW_NAME.vim'
let g:xspace_undodir = 'A_NEW_DIR'
```


# Installation
The plugin requires Vim >= 8.0 or Neovim >= 0.4

### Vim Plug

```vim
Plug 'xuta/vim-xspace'
```

### Using Vundle

```vim
Plugin 'xuta/vim-xspace'
```

### Using Pathogen

```bash
cd /.vim/bundle
git clone https://github.com/xuta/vim-xspace
```


# License
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
