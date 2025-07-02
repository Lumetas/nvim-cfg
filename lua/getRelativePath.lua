local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local path = require("plenary.path")

local M = {}

-- Улучшенная версия функции для относительных путей
local function get_relative_path(target, base)
  target = path:new(target):absolute()
  base = path:new(base):absolute()

  -- Нормализация путей для Windows/Unix
  target = target:gsub("\\", "/")
  base = base:gsub("\\", "/")

  local target_parts = vim.split(target, "/", { plain = true })
  local base_parts = vim.split(base, "/", { plain = true })

  local i = 1
  while i <= #base_parts and i <= #target_parts and base_parts[i] == target_parts[i] do
    i = i + 1
  end

  local rel_path = {}
  for _ = i, #base_parts do
    table.insert(rel_path, "..")
  end
  for j = i, #target_parts do
    table.insert(rel_path, target_parts[j])
  end

  return table.concat(rel_path, "/")
end

function M.insert_relative_path(prompt_bufnr)
  local entry = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  
  if not entry then return end
  
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir = current_file ~= "" and path:new(current_file):parent().filename or vim.fn.getcwd()
  local selected_path = entry.path
  local rel_path = get_relative_path(selected_path, current_dir)

  vim.schedule(function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    -- Вставляем текст
    vim.api.nvim_buf_set_text(0, row-1, col, row-1, col, {rel_path})
    -- Устанавливаем курсор ПОСЛЕ последнего символа
    vim.api.nvim_win_set_cursor(0, {row, col + #rel_path})
    -- Возвращаем в insert mode и перемещаем курсор в конец
    vim.cmd("startinsert!")
    -- Дополнительное перемещение на случай, если startinsert сбросил позицию
    vim.api.nvim_win_set_cursor(0, {row, col + #rel_path})
  end)
end

return M
