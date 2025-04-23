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

## lummvc
Позволяет быстро перемещаться по проектам основанным на php mvc фреймворках. Так же использовать утилиты командной строки: `:Mvc migrate` | `ctrl+a migrate`. Необходимо для начала сгенерировать файл конфига проекта `:GenerateLumMVC` После указать там, пути к определённым директориям и к утилите командной строки. По умолчанию это конфиг для laravel

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
Данный плагин позволяет использовать сниппеты. Для того чтобы добавить сниппет необходимо в корневом каталоге конфига создать директорию `lumSnippets`, а в ней уже файл, например `html`. В файле необходимо написать сам сниппет. После чего его можно будет вставить в любом месте используя `LumSN<file>`, В данном случае: `:LumSNhtml`.

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

## file_search
При нажатии `ctrl+f` запросит имя, после ничётким поиском будет искать файлы из корня открытого проекта. в файле `lumignore` вы можете указать какие директории следуюет игнорировать, пример:
```
pack
vendor
node_modules
```

install neovim:
- [linux](https://github.com/lumetas/nvim-cfg/releases/latest/download/nvim)
- [windows](https://github.com/lumetas/nvim-cfg/releases/latest/download/nvim.msi)
