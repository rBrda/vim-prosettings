# vim-prosettings

A plugin to discover and load project specific Vim settings.

Note: I personally use Neovim and developed the plugin in that, so I haven't tested in Vim.

## Usage

The plugin doesn't require configuration and works automatically.

When you launch your Vim editor in your project's folder you will be prompted to choose to load or not to load the `.vimrc` file (or whatever you specify for the plugin to use) in your project's root directory, if there was any found.

## Installation

With [vim-plug](https://github.com/junegunn/vim-plug):
```
Plug 'rBrda/vim-prosettings'
```

## Configuration

You can configure the plugin by setting the following global variable in your Vim configuration file (here you see all the properties included that can be modified):

```vim
let g:prosettings = {
    \ 'root_dir_markers': ['.git', '.hg', '.bzr', '.svn', 'Makefile'],
    \ 'resolve_symlinks': 0,
    \ 'filename': '.vimrc'
    \ }
```

### `g:prosettings.root_dir_markes`

*Note: this section is take from the original [vim-rooter](https://github.com/airblade/vim-rooter) readme, I just adjusted it where it was needed.*

Default value: `['.git', '.hg', '.bzr', '.svn', 'Makefile']`

This is a list of directories or files that can help to identify the root directory. They are checked breadth-first as the plugin walks up the directory tree and the first match is used.

To specify the root is a certain directory, prefix it with  `=`.

```vim
let g:prosettings.root_dir_markes = ['=src']
```

To specify the root has a certain directory or file (which may be a glob), just give the name:

```vim
let g:prosettings.root_dir_markes = ['.git', 'Makefile', '*.sln', 'build/env.sh']
```

To specify the root has a certain directory as an ancestor (useful for excluding directories), prefix it with  `^`:

```vim
let g:prosettings.root_dir_markes = ['^fixtures']
```

To exclude a pattern, prefix it with  `!`.

```vim
let g:prosettings.root_dir_markes = ['!=extras', '!^fixtures', '!build/env.sh']
```
List your exclusions before the patterns you do want.

### `g:prosettings.resolve_symlinks`

Default value: `0`

If turned on (`1`), the plugin will resolve the symlink for the current path.

### `g:prosettings.filename`

Default value: `.vimrc`

Specifies the filename that contains your project specific Vim settings.

## Commands

The plugin has the `PSReloadSettings` command for reloading the project specific Vim settings on demand.

## Why was this n+1 plugin created?

I recently started to use Vim (Neovim) for my work and I immediately ran into a problem. There were several projects that use different settings like for instance tabs instead of spaces, debugger settings (vdebug), filetype specific configuration. So I created separate `.vimrc` files for each and stored these settings in the root directory of the projects. I'm still not sure if this was the right decision, but it seems to work for me.

However, I found the manual sourcing of these files cumbersome (sometimes I even forget to do it) and decided to semi-automatize the process. So I looked first for already existing plugins that could help me to solve the this issue, but I didn't find any that would fit my needs... So I decided to put together one, that does what I want and nothing more.

Most parts of the plugin are based on functionality taken over from the vim-rooter plugin, which you can find here: https://github.com/airblade/vim-rooter

I was originally planning to use the the FindRootDirectory() method that vim-rooter offers to find the root directory, but vim-rooter is by default enabled and one has to manually turn it off by setting `g:rooter_manual_only` to `0` to prevent it from changing the working directory (if you don't want that, or vim-rooter installed).

However, I want to thank the original author for its work! I personally use vim-rooter for my daily work.

Important to mention that this is my first Vim plugin, so please be forgiving if you see something that you don't like. Suggestions, ideas are welcome!
