local job = require('plenary.job')
local conf = require('cmp_ai.config')
Service = {}

function Service:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Service:complete(
  lines_before, ---@diagnostic disable-line
  lines_after, ---@diagnostic disable-line
  _
) ---@diagnostic disable-line
  error('Not Implemented!')
end

function Service:json_decode(data)
  local status, result = pcall(vim.fn.json_decode, data)
  if status then
    return result
  else
    return nil, result
  end
end
function Service:Get(url, headers, data, cb)
  -- Создаем базовые заголовки
  local curl_headers = {
    "Content-Type: application/json"
  }
  
  -- Добавляем пользовательские заголовки, если они есть
  if headers then
    for _, h in ipairs(headers) do
      -- Убираем лишние кавычки, если они есть
      local clean_header = h:gsub("^'", ""):gsub("'$", "")
      table.insert(curl_headers, clean_header)
    end
  end

  local tmpfname = os.tmpname()
  local f = io.open(tmpfname, 'w+')
  if f == nil then
    vim.notify('Cannot open temporary message file: ' .. tmpfname, vim.log.levels.ERROR)
    return
  end
  f:write(vim.fn.json_encode(data))
  f:close()

  -- Собираем аргументы для curl
  local args = {
    url,
    '-d', '@' .. tmpfname,
    '-H', 'Content-Type: application/json'  -- Явно передаем Content-Type
  }

  -- Добавляем остальные заголовки
  for _, h in ipairs(curl_headers) do
    if h ~= "Content-Type: application/json" then  -- Уже добавили
      table.insert(args, '-H')
      table.insert(args, h)
    end
  end

  -- Добавляем таймаут, если задан
  local timeout_seconds = conf:get('max_timeout_seconds')
  if tonumber(timeout_seconds) ~= nil then
    table.insert(args, '--max-time')
    table.insert(args, tostring(timeout_seconds))
  elseif timeout_seconds ~= nil then
    vim.notify('cmp-ai: your max_timeout_seconds config is not a number', vim.log.levels.WARN)
  end

  job
    :new({
      command = 'curl',
      args = args,
      on_exit = vim.schedule_wrap(function(response, exit_code)
        os.remove(tmpfname)
        if exit_code ~= 0 then
          if conf:get('log_errors') then
            vim.notify('Curl error (code '..exit_code..'): '..table.concat(response:result(), '\n'), vim.log.levels.ERROR)
          end
          cb({ { error = 'ERROR: API Error' } })
          return
        end

        local result = table.concat(response:result(), '\n')
        local json = self:json_decode(result)
        if type(self.params.raw_response_cb) == 'function' then
          self.params.raw_response_cb(json)
        end
        if json == nil then
          cb({ { error = 'No Response.' } })
        else
          cb(json)
        end
      end),
    })
    :start()
end

return Service
