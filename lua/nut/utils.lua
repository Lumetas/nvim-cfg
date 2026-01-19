local M = {}

function M:new(nut)
  local utils = setmetatable({}, { __index = self })
  utils.nut = nut
  return utils
end

function M:getSelection()
  local selection = {
    text = "",
    start_pos = {},
    end_pos = {}
  }
  
  local mode = vim.fn.mode()
  
  if mode == "v" or mode == "V" or mode == "" then
    -- Visual mode - get selected text
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    
    selection.start_pos = { line = start_pos[2], col = start_pos[3] }
    selection.end_pos = { line = end_pos[2], col = end_pos[3] }
    
    -- Сохраняем текущее выделение в регистр a
    vim.cmd('normal! "ay')
    selection.text = vim.fn.getreg('a')
    vim.fn.setreg('a', '') -- Очищаем регистр a
  else
    -- Normal mode - get current line
    local current_line = vim.api.nvim_get_current_line()
    selection.text = current_line
    selection.start_pos = { line = vim.fn.line("."), col = 1 }
    selection.end_pos = { line = vim.fn.line("."), col = #current_line }
  end
  
  local methods = {
    delete = function(self)
      if vim.fn.mode() == "n" then
        vim.api.nvim_set_current_line("")
      else
        vim.cmd('normal! d')
      end
    end,
    
    getPosition = function(self)
      return {
        [1] = self.start_pos,
        [2] = self.end_pos
      }
    end,
    
    setPosition = function(self, positions)
      if positions[1] and positions[2] then
        vim.fn.cursor(positions[1].line, positions[1].col)
        vim.fn.setpos("'<", {0, positions[1].line, positions[1].col, 0})
        vim.fn.setpos("'>", {0, positions[2].line, positions[2].col, 0})
        vim.cmd('normal! gv')
      end
    end,
    
    save = function(self)
      -- Применяем изменения
      vim.cmd('normal! u')
    end
  }
  
  return setmetatable(selection, { __index = methods })
end

function M:getCursor()
  local cursor = {
    line = vim.fn.line("."),
    col = vim.fn.col(".")
  }
  
  local methods = {
    save = function(self)
      vim.fn.cursor(self.line, self.col)
    end
  }
  
  return setmetatable(cursor, { __index = methods })
end

function M:setMode(mode)
  if mode == "insert" then
    vim.cmd('startinsert')
  elseif mode == "normal" then
    vim.cmd('stopinsert')
    vim.cmd('normal! ')
  elseif mode == "visual" then
    vim.cmd('normal! v')
  end
end

return M
