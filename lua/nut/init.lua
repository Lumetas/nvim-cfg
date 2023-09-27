local M = {}

-- Леничная загрузка модулей через метатаблицу
local lazy_modules = {
  "utils", "json", "console", "http", "app", "document", "components"
}

function M.new(pluginName)
  local nut = {
    _pluginName = pluginName or "unknown",
    _events = {},
    _consoleHistory = {},
    _modules = {} -- Кэш для загруженных модулей
  }
  
  setmetatable(nut, { 
    __index = function(self, key)
      -- Ленивая загрузка модулей
      for _, module_name in ipairs(lazy_modules) do
        if key == module_name then
          if not rawget(self._modules, module_name) then
            local ok, module = pcall(require, "nut." .. module_name)
            if ok then
              self._modules[module_name] = module:new(self)
            else
              error("Failed to load nut module: " .. module_name)
            end
          end
          return self._modules[module_name]
        end
      end
      return rawget(M, key)
    end
  })

  -- Инициализация команд (только нужные)
  nut:_setup_commands()

  return nut
end

function M:_setup_commands()
  local commands = {
    NUTconsoleOpen = function() 
      self.console:open() 
    end,
    NUTconsoleRefresh = function() 
      self.console:refresh() 
    end,
    NUTconsoleClear = function() 
      self.console:clear_all() 
    end
  }

  for cmd, handler in pairs(commands) do
    vim.api.nvim_create_user_command(cmd, handler, {})
  end
end

-- Красивая загрузка компонентов
function M:load(...)
  local components = {}
  for i, component in ipairs({...}) do
    components[i] = self[component] -- Триггерит ленивую загрузку
  end
  return unpack(components)
end

function M:initCLI()
  if #vim.api.nvim_list_uis() == 0 then
    print("NUT CLI mode initialized")
  end
end

return M
