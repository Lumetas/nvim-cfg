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
nnoremap <C-b> :NERDTreeFocus<CR>:NERDTreeRefreshRoot<CR>

inoremap <A-f> <ESC>
nnoremap <TAB> gt

vnoremap <A-C-l> $
vnoremap <A-C-H> 0
vnoremap <C-h> b
vnoremap <C-l> w
nnoremap <A-C-l> $
nnoremap <A-C-H> 0
nnoremap <C-h> b
nnoremap <C-l> w
nnoremap <ESC> :nohl<CR>
tnoremap <A-f> <C-\><C-n>
nnoremap q: <Nop>
nnoremap J <C-d>
nnoremap K <C-u>  

vnoremap d "_d
nnoremap d "_d
   
"PlugInstall
"Используется vim-plug https://github.com/junegunn/vim-plug
call plug#begin()
Plug 'https://github.com/tpope/vim-commentary'
Plug 'https://github.com/ap/vim-css-color'
Plug 'https://github.com/vim-airline/vim-airline'
Plug 'https://github.com/preservim/nerdtree'

Plug 'https://github.com/rafi/awesome-vim-colorschemes'
set encoding=UTF-8
:set completeopt-=preview 
call plug#end()


command! -nargs=1 Artisan echo system('php artisan ' . <q-args>)
function! RunArtisan()
    let command = input('artisan: ')
    echo system('php artisan ' . command)
endfunction
nnoremap <C-a> :call RunArtisan()<CR>



" source ~/.config/nvim/themes/monokai.vim
source ~/.config/nvim/themes/iceberg.vim
" colorscheme elflord
" Пример скрипта на Vimscript

" Установите переменную с путем к директории форматирования
let g:formater_dir = '/home/lum/formatters'
let g:checker_dir = '/home/lum/checkers'
source ~/.config/nvim/lum_formater.vim
source ~/.config/nvim/gpt.vim
