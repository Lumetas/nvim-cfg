require('packer').startup(function(use)
	-- Плагин packer.nvim (обязательно)
	use 'wbthomason/packer.nvim'

	-- Ваши плагины
	use 'tpope/vim-commentary'
	use 'ap/vim-css-color'
	-- use 'vim-airline/vim-airline'
	use 'preservim/nerdtree'
	use 'neovim/nvim-lspconfig'

	-- use 'rafi/awesome-vim-colorschemes'
end)
