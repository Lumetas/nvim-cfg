-- Переменные и флаги для модулей и плагинов
vim.g.reset_layout_on_leave = true -- Сбрасывать ли расскладку на английский при выходе из insert mode




-- Подключение модулей
require('settings')    -- Основные настройки
require('keymaps')     -- Ключевые отображения
require('plugins')     -- Плагины
require('color') -- Цветовые схемы
require('statusline') -- Полоса
require('lsp') -- LSP Автодополнение и прочее
require('laravel') -- laravel
require('commands') -- Произвольные команды
require('map') -- Русский язык
require('startmenu') -- Стартовое меню
