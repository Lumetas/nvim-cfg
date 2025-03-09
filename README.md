# vim-plug
linux/mac
~~~
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
~~~
windows(powershell)
~~~
iwr -useb https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim |`
    ni "$(@($env:XDG_DATA_HOME, $env:LOCALAPPDATA)[$null -eq $env:XDG_DATA_HOME])/nvim-data/site/autoload/plug.vim" -Force
~~~
in nvim:
~~~
PlugInstall
~~~


# packer
linux/mac
~~~
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim
~~~
windows(powershell)
~~~
git clone https://github.com/wbthomason/packer.nvim "$env:LOCALAPPDATA\nvim-data\site\pack\packer\start\packer.nvim"
~~~
in nvim:
~~~
PackerSync
~~~
install neovim:
- [linux](https://github.com/lumetas/nvim-cfg/releases/latest/downlaod/nvim)
- [windows](https://github.com/lumetas/nvim-cfg/releases/latest/downlaod/nvim.msi)
