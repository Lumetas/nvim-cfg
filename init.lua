-- Переменные и флаги для модулей и плагинов
vim.g.reset_layout_on_leave = true -- Сбрасывать ли расскладку на английский при выходе из insert mode

-- vim_theme = { "cyberpunk", "vim" }
vim_theme = { "neofusion", "nvim" }

vim_dir = vim.fn.stdpath('config')



-- Подключение модулей
require('settings')    -- Основные настройки

require('color') -- Цветовые схемы
require('statusline') -- Полоса
require('lsp') -- LSP Автодополнение и прочее
require('lummvc') -- mvc
require('commands') -- Произвольные команды
require('map') -- Русский язык
-- require('startmenu') -- Стартовое меню
require('lumSnippets') -- Сниппеты
require('file_search') -- Поиск файлов

require('keymaps')     -- Ключевые отображения
