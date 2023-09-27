local M = {}

function M:new(nut)
  local app = setmetatable({}, { __index = self })
  app.nut = nut
  return app
end

function M:create(appName)
  local customApp = {
    name = appName,
    type = "float",
    position = "center:center",
    events = {},
    buffer = nil,
    win_id = nil,
    job_id = nil
  }
  
  local methods = {
	nut = self.nut,
    show = function(self)
      self:_launchApp()
	  self.nut.utils:setMode("insert")
    end,
    
    hide = function(self)
      if self.win_id and vim.api.nvim_win_is_valid(self.win_id) then
        vim.api.nvim_win_hide(self.win_id)
      end
    end,
    
    close = function(self)
      if self.job_id then
        vim.fn.jobstop(self.job_id)
      end
      self:hide()
      if self.buffer and vim.api.nvim_buf_is_valid(self.buffer) then
        vim.api.nvim_buf_delete(self.buffer, { force = true })
      end
      self:emit("onClose")
    end,
    
    emit = function(self, eventName)
      if self.events[eventName] then
        for _, handler in ipairs(self.events[eventName]) do
          handler({ name = eventName, type = "app", data = self })
        end
      end
    end,
    
    _launchApp = function(self)
      -- Создаем терминальный буфер
      self.buffer = vim.api.nvim_create_buf(false, true)
      
      local config = self:_getWindowConfig()
      self.win_id = vim.api.nvim_open_win(self.buffer, true, config)
      
      -- Запускаем приложение в терминале
      vim.cmd('terminal ' .. self.name)
      
      -- Получаем job ID
      local job_id = vim.b.terminal_job_id
      if job_id then
        self.job_id = job_id
      end
      
      self:emit("onOpen")
      
      -- Следим за завершением процесса
      vim.api.nvim_create_autocmd("TermClose", {
        buffer = self.buffer,
        callback = function()
          self:close()
        end
      })
    end,
    
    _getWindowConfig = function(self)
      local width = vim.o.columns
      local height = vim.o.lines
      
      local config = {
        style = "minimal"
      }
      
      if self.type == "float" then
        config.width = math.floor(width * 0.8)
        config.height = math.floor(height * 0.8)
        config.col = math.floor((width - config.width) / 2)
        config.row = math.floor((height - config.height) / 2)
        config.relative = "editor"
        config.border = "rounded"
      elseif self.type == "split" then
        config.width = math.floor(width * 0.5)
        config.height = height - 3
        if self.position == "left" then
          config.col = 0
          config.row = 0
        elseif self.position == "right" then
          config.col = width - config.width
          config.row = 0
        end
        config.relative = "editor"
        config.style = nil
      end
      
      return config
    end
  }
  
  setmetatable(customApp, { __index = methods })
  
  -- Event setters
  for _, event in ipairs({ "onOpen", "onClose" }) do
    customApp[event] = function(self, handler)
      self.events[event] = { handler }
      return self
    end
  end
  
  return customApp
end

return M
