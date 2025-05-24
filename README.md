<!-- # vim-plug -->
<!-- linux/mac -->
<!-- ~~~ -->
<!-- sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \ -->
<!--        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim' -->
<!-- ~~~ -->
<!-- windows(powershell) -->
<!-- ~~~ -->
<!-- iwr -useb https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim |` -->
<!--     ni "$(@($env:XDG_DATA_HOME, $env:LOCALAPPDATA)[$null -eq $env:XDG_DATA_HOME])/nvim-data/site/autoload/plug.vim" -Force -->
<!-- ~~~ -->
<!-- in nvim: -->
<!-- ~~~ -->
<!-- PlugInstall -->
<!-- ~~~ -->


<!-- # packer -->
<!-- linux/mac -->
<!-- ~~~ -->
<!-- git clone --depth 1 https://github.com/wbthomason/packer.nvim\ -->
<!--  ~/.local/share/nvim/site/pack/packer/start/packer.nvim -->
<!-- ~~~ -->
<!-- windows(powershell) -->
<!-- ~~~ -->
<!-- git clone https://github.com/wbthomason/packer.nvim "$env:LOCALAPPDATA\nvim-data\site\pack\packer\start\packer.nvim" -->
<!-- ~~~ -->
<!-- in nvim: -->
<!-- ~~~ -->
<!-- PackerSync -->
<!-- ~~~ -->

## Менеджер плагинов
Мне намного удобнее утсанавливать плагины руками + плюс их не так много, так что все плагины устанавливаются прямо в директорию конфига. Список используемых здесь плагинов:
- [nerdtree](https://github.com/preservim/nerdtree)
- [emmet-vim](https://github.com/mattn/emmet-vim)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- [plenaty.nvim](https://github.com/nvim-lua/plenary.nvim)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [vim-commentary](https://github.com/tpope/vim-commentary)
