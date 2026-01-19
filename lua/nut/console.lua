local M = {}

function M:new(nut)
  local console = setmetatable({}, { __index = self })
  console.nut = nut
  console.buffer = nil
  console.win_id = nil
  console.buffer_name = "NUT Console"
  return console
end

function M:log(...)
  local args = {...}
  local messages = {}
  
  for _, arg in ipairs(args) do
    if type(arg) == "table" then
      table.insert(messages, vim.inspect(arg))
    else
      table.insert(messages, tostring(arg))
    end
  end
  
  local message = table.concat(messages, " ")
  
  -- Сохраняем в историю
  if self.nut and self.nut._consoleHistory then
    -- Разбиваем многострочные сообщения на отдельные строки
    for line in message:gmatch("[^\r\n]+") do
      table.insert(self.nut._consoleHistory, line)
    end
  end
  
  -- Если консоль открыта, обновляем её
  if self.buffer and vim.api.nvim_buf_is_valid(self.buffer) then
    local lines = vim.api.nvim_buf_get_lines(self.buffer, 0, -1, false)
    -- Разбиваем многострочные сообщения на отдельные строки
    for line in message:gmatch("[^\r\n]+") do
      table.insert(lines, line)
    end
    vim.api.nvim_buf_set_lines(self.buffer, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(self.buffer, 'modified', false)
    
    -- Автопрокрутка
    if self.win_id and vim.api.nvim_win_is_valid(self.win_id) then
      local line_count = vim.api.nvim_buf_line_count(self.buffer)
      vim.api.nvim_win_set_cursor(self.win_id, {line_count, 0})
    end
  end
  
  -- Также выводим в echo area (только первую строку для удобства)
  local first_line = message:match("([^\r\n]*)") or message
  vim.api.nvim_echo({{first_line, "Normal"}}, false, {})
end

function M:get_or_create_buffer()
  -- Если у нас уже есть валидный буфер, используем его
  if self.buffer and vim.api.nvim_buf_is_valid(self.buffer) then
    return self.buffer
  end
  
  -- Ищем существующий буфер по имени
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name == self.buffer_name then
        self.buffer = buf
        return self.buffer
      end
    end
  end
  
  -- Создаем новый буфер
  self.buffer = vim.api.nvim_create_buf(false, true)
  
  -- Устанавливаем имя
  vim.api.nvim_buf_set_name(self.buffer, self.buffer_name)
  
  vim.api.nvim_buf_set_option(self.buffer, 'filetype', 'nutconsole')
  vim.api.nvim_buf_set_option(self.buffer, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(self.buffer, 'readonly', false)
  
  -- Заполняем историей если есть
  if self.nut and self.nut._consoleHistory then
    vim.api.nvim_buf_set_lines(self.buffer, 0, -1, false, self.nut._consoleHistory)
  end
  
  -- Настраиваем маппинги
  vim.api.nvim_buf_set_keymap(self.buffer, 'n', 'q', '<cmd>close<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(self.buffer, 'n', '<ESC>', '<cmd>close<CR>', { noremap = true, silent = true })
  
  return self.buffer
end

function M:open()
  -- Если окно уже открыто, фокусируемся
  if self.win_id and vim.api.nvim_win_is_valid(self.win_id) then
    vim.api.nvim_set_current_win(self.win_id)
    return
  end

  -- Получаем или создаем буфер
  local buf = self:get_or_create_buffer()
  
  -- Создаем окно
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.6)
  
  self.win_id = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = self.buffer_name,
    title_pos = "center"
  })

  -- Автопрокрутка к концу
  local line_count = vim.api.nvim_buf_line_count(buf)
  if line_count > 0 then
    vim.api.nvim_win_set_cursor(self.win_id, {line_count, 0})
  end
  
  -- Настраиваем автозакрытие
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(self.win_id),
    callback = function()
      self.win_id = nil
    end
  })
end

function M:refresh()
  local buf = self:get_or_create_buffer()
  if self.nut and self.nut._consoleHistory then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, self.nut._consoleHistory)
    vim.api.nvim_buf_set_option(buf, 'modified', false)
    
    if self.win_id and vim.api.nvim_win_is_valid(self.win_id) then
      local line_count = vim.api.nvim_buf_line_count(buf)
      vim.api.nvim_win_set_cursor(self.win_id, {line_count, 0})
    end
  end
end

function M:close()
  if self.win_id and vim.api.nvim_win_is_valid(self.win_id) then
    vim.api.nvim_win_close(self.win_id, true)
    self.win_id = nil
  end
end

-- Полная очистка консоли
function M:clear_all()
  if self.nut then
    self.nut._consoleHistory = {}
  end
  self:refresh()
end

return M
