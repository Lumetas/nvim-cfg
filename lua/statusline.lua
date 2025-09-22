
-- Устанавливаем глобальную строку состояния (для Neovim 0.7+)
vim.opt.laststatus = 3  -- Важно! Без этого будет работать некорректно.

local icons = {
  git = " ",
  separator_right = "  ",
  separator_left = "  ",
  file = "  ",
  unix = " ",
  dos = " ",
  modified = "", 
  readonly = ""
}

local function get_git_branch()
  local handle = io.popen("git branch --show-current 2>/dev/null | tr -d '\n'")
  if not handle then return "" end
  local branch = handle:read("*a")
  handle:close()
  return branch ~= "" and icons.git .. branch or ""
end

-- Функция для обновления статусной строки
local function update_statusline()
  local filetype = vim.bo.filetype ~= "" and vim.bo.filetype or "no ft"
  local fileformat = vim.bo.fileformat == "unix" and icons.unix or icons.dos

  -- Используем `vim.o.statusline` вместо `vim.opt.statusline` для глобального применения
  vim.o.statusline = table.concat({
    "%#StatusLine#",
    icons.file, "%f",
    vim.bo.modified and " " .. icons.modified or "", 
    vim.bo.readonly and " " .. icons.readonly or "",
    icons.separator_right,
    get_git_branch(),
    "%=",  -- Выравнивание вправо
    filetype, " ", fileformat,
    icons.separator_left,
    "%c",  -- Номер колонки
    "%#StatusLineNC# "
  })
end

-- Обновляем статусную строку при событиях
vim.api.nvim_create_autocmd({
  "BufEnter", "BufWritePost", "FileChangedShellPost", 
  "TextChanged", "TextChangedI", "VimResized"  -- Добавляем VimResized для обработки изменений размера окна
}, {
  pattern = "*",
  callback = update_statusline
})

-- Инициализация при старте
update_statusline()

-- Стили (можно оставить как есть)
vim.cmd([[
  highlight StatusLineGit guifg=#fab387 gui=bold
  highlight StatusLineModified guifg=#f38ba8
  highlight StatusLineReadonly guifg=#a6e3a1
]])
