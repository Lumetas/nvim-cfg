# Описание
Моя конфигурация, работает с nvim версии 0.11.0 ввиду lsp config

## Менеджер плагинов
[lnpm.nvim](https://github.com/Lumetas/lnpm.nvim)


## Установка
Склонировать данный репозиторий в директорию конфига.
linux/mac:
```
~/.config/nvim
```
windows:
```
~\AppData\Local\nvim
```
Установить lsp:
```
npm install -g intelephense
```

Так же необходимо установить утилиту fd примеры для систем:
```
winget install sharkdp.fd
brew install fd
pacman -S fd
apk add fd
dnf install fd-find
apt istall fd

dnf copr enable tkbcopr/fd
dnf install fd
```

Для использования xdebug Необходимо поставить vscode-php-debug Ввести в виме:
```
:LumInstallXdebug
```
# Галерея
![image1](images/1.png)
![image2](images/2.png)
![image3](images/3.png)
![image4](images/4.png)
![image5](images/5.png)
