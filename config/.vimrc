set nu rnu

set nocompatible
filetype on
filetype plugin on
filetype indent on
syntax on

" Soft wrap text
set formatoptions+=l
set formatoptions-=t
set textwidth=0
set wrapmargin=0
set wrap
set linebreak
" set columns=80

set expandtab
set shiftwidth=2
set tabstop=2
set softtabstop=2

set history=1000
" Allow hidden buffers
set hidden
" Rendering
set ttyfast
" Status bar
set laststatus=2
" Last line
set showmode
set showcmd

set wildmenu
set wildmode=list:longest
set wildignore=*.docx,*.jpg,*.png,*.gif,*.webp,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx

" Cursor motion
set scrolloff=4
set backspace=indent,eol,start
set matchpairs+=<:> " use % to jump between pairs
runtime! macros/matchit.vim


let mapleader=" "
nnoremap <SPACE> <Nop>

" Searching
nnoremap / /\v
vnoremap / /\v
set hlsearch
set incsearch
set ignorecase
set smartcase
set showmatch
map <leader><space> :let @/=''<cr> " clear search
" Remap help key.
inoremap <F1> <ESC>:set invfullscreen<CR>a
nnoremap <F1> :set invfullscreen<CR>
vnoremap <F1> :set invfullscreen<CR>
" Textmate holdouts
" Formatting
map <leader>q gqip
" Visualize tabs and newlines
set listchars=tab:▸\ ,eol:¬
" Uncomment this to enable by default:
" set list " To enable by default
" Or use your leader key + l to toggle on/off
map <leader>l :set list!<CR> " Toggle tabs and EOL
set showmatch

set hlsearch

set t_Co=256
