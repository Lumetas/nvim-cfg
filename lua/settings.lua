vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
-- if vim.fn.has('gui_running') == 0 then  -- Если не в GUI, то применяем cmdheight=0
--   vim.opt.cmdheight = 0
-- end
vim.opt.autoindent = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.iminsert = 0
vim.opt.smarttab = true
vim.opt.softtabstop = 4
vim.opt.mouse = 'a'
vim.opt.swapfile = false
vim.opt.clipboard = 'unnamedplus'
vim.opt.encoding = 'UTF-8'
vim.opt.completeopt:remove('preview')
vim.opt.shada = ""
vim.bo.fileformat = "unix"
vim.cmd("let g:user_emmet_leader_key='<C-Z>'")

vim.opt.cursorline = true

vim.g.reset_layout_on_leave = true -- Сбрасывать ли расскладку на английский при выходе из insert mode

-- Добавляем необходимые директории в PATH
local paths_to_add = {
    "/usr/local/bin",
    "/usr/bin", 
    vim.fn.expand("~/.config/composer/vendor/bin"),
    vim.fn.expand("~/.local/bin")
}

-- Проверяем и добавляем только существующие директории
for _, path in ipairs(paths_to_add) do
    if vim.fn.isdirectory(path) == 1 then
        -- Проверяем, нет ли уже этого пути в PATH
        if not string.find(vim.env.PATH, path, 1, true) then
            vim.env.PATH = path .. ":" .. vim.env.PATH
        end
    end
end
