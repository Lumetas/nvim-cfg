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

# Plugins
Вместе с этим конфигом имеется несколько самописных плагинов, они не настолько крупны и обширны чтобы выделять им свой репозиторий. Так что кратко расскажу о них здесь.

## startmenu
Работает с директорией lumProjects в корне пользователя. В ней должны распологаться директории с проектами. При открытии вима без указания пути будет возможность выбрать проект и соответственно перейти в него открыв попутно файл README.md . `:CreateProject` создаёт проект и файл README.md в нём. 

## lumlaravel
Позволяет использовать `artisan` Прямо из вима. Командой `:Artisan` или сочетанием клавиш ctrl+a. Так же позволяет быстро перемещаться к моделям, контроллерам и т.д. Для работы плагина в корне проекта должен находиться файл `lumlaravel` сгенерировать его можно командой `:GenerateLumLaravel`.

Навигация происходит по нажатию ctrl+m <type>. Сопоставление типов:
| key | type |
| --- | ---- |
| m | models |
| r | routers |
| c | controllers |
| v | views |
| s | seaders |
| g | migrations |

## lumSnippets
Данный плагин позволяет использовать сниппеты. Для того чтобы добавить сниппет необходимо в корневом каталоге пользователя создать директорию `lumSnippets`, а в ней уже файл, например `html`. В файле необходимо написать сам сниппет. После чего его можно будет вставить в любом месте используя `LumSN<file>`, В данном случае: `:LumSNhtml`.

### placeholders
Для добавления плейсхолдера(параметра), необходимо использовать следующую структуру `%{name}%`. Тогда при вставлении сниппета вас спросят что вставить на место этого поля.

### Условия
Используя синтаксис:
```
%{include script}?%<script src="main.js"></script>%?{include script}%
```
Вы можете добавить условие. В таком случае при вставке у вас спросят добавлять ли даный фрагмент в итоговый сниппет. Вопросы обо всех сниппетах маркированы(маркером является строка в фигурных скобках). 

### Мои сниппеты:
```
https://github.com/Lumetas/lumSnippets.git
```

install neovim:
- [linux](https://github.com/lumetas/nvim-cfg/releases/latest/download/nvim)
- [windows](https://github.com/lumetas/nvim-cfg/releases/latest/download/nvim.msi)
