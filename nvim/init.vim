:set number 
:set relativenumber
:set autoindent
:set tabstop=4
:set shiftwidth=4
:set iminsert=0
:set smarttab
:set softtabstop=4
:set mouse=a
:set noswapfile


:set clipboard=unnamedplus


inoremap <C-BS> <C-w>

nnoremap <C-n> :NERDTreeToggle<CR>
nnoremap <C-b> :NERDTreeFocus<CR>

inoremap <A-f> <ESC>
nnoremap <TAB> gt

nnoremap <A-C-l> $
nnoremap <A-C-H> 0
nnoremap <C-h> b
nnoremap <C-l> w
nnoremap <ESC> :nohl<CR>

"Используется vim-plug https://github.com/junegunn/vim-plug
"PlugInstall
call plug#begin()
Plug 'https://github.com/tpope/vim-commentary'
Plug 'https://github.com/ap/vim-css-color'
Plug 'https://github.com/vim-airline/vim-airline'
Plug 'https://github.com/preservim/nerdtree'

Plug 'https://github.com/rafi/awesome-vim-colorschemes'
set encoding=UTF-8
:set completeopt-=preview 
call plug#end()


"source ~/.config/nvim/themes/monokai.vim
source ~/.config/nvim/themes/iceberg.vim
"colorscheme elflord
