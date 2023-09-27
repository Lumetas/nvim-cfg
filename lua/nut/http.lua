local M = {}

-- Инициализируем sync и async таблицы
M.sync = {}
M.async = {}

function M:new(nut)
  local http = setmetatable({}, { __index = self })
  http.nut = nut
  return http
end

function M.sync:get(url, options)
  options = options or {}
  local stdout = {}
  local stderr = {}
  
  local job_id = vim.fn.jobstart({"curl", "-s", "-H", options.headers or "", url}, {
    on_stdout = function(_, data)
      stdout = data
    end,
    on_stderr = function(_, data)
      stderr = data
    end,
    stdout_buffered = true,
    stderr_buffered = true,
  })
  
  local result = vim.fn.jobwait({job_id})[1]
  if result == 0 then
    return { success = true, data = table.concat(stdout, "\n") }
  else
    return { success = false, error = table.concat(stderr, "\n") or "HTTP request failed" }
  end
end

function M.sync:post(url, options)
  options = options or {}
  local headers = {}
  local stdout = {}
  local stderr = {}
  
  if options.headers then
    for k, v in pairs(options.headers) do
      table.insert(headers, "-H")
      table.insert(headers, k .. ": " .. v)
    end
  end
  
  local args = {"curl", "-s", "-X", "POST"}
  for _, header in ipairs(headers) do
    table.insert(args, header)
  end
  
  if options.body then
    table.insert(args, "-d")
    table.insert(args, options.body)
  end
  
  table.insert(args, url)
  
  local job_id = vim.fn.jobstart(args, {
    on_stdout = function(_, data)
      stdout = data
    end,
    on_stderr = function(_, data)
      stderr = data
    end,
    stdout_buffered = true,
    stderr_buffered = true,
  })
  
  local result = vim.fn.jobwait({job_id})[1]
  if result == 0 then
    return { success = true, data = table.concat(stdout, "\n") }
  else
    return { success = false, error = table.concat(stderr, "\n") or "HTTP request failed" }
  end
end

function M.async:get(url, callback, options)
  options = options or {}
  
  local function on_exit(job_id, exit_code, _)
    if exit_code == 0 then
      callback({ success = true })
    else
      callback({ success = false, error = "HTTP request failed" })
    end
  end
  
  vim.fn.jobstart({"curl", "-s", url}, {
    on_stdout = function(_, data)
      callback({ success = true, data = table.concat(data, "\n") })
    end,
    on_stderr = function(_, data)
      callback({ success = false, error = table.concat(data, "\n") })
    end,
    on_exit = on_exit,
    stdout_buffered = true,
    stderr_buffered = true,
  })
end

function M.async:post(url, options, callback)
  local headers = {}
  
  if options.headers then
    for k, v in pairs(options.headers) do
      table.insert(headers, "-H")
      table.insert(headers, k .. ": " .. v)
    end
  end
  
  local args = {"curl", "-s", "-X", "POST"}
  for _, header in ipairs(headers) do
    table.insert(args, header)
  end
  
  if options.body then
    table.insert(args, "-d")
    table.insert(args, options.body)
  end
  
  table.insert(args, url)
  
  local function on_exit(job_id, exit_code, _)
    if exit_code == 0 then
      callback({ success = true })
    else
      callback({ success = false, error = "HTTP request failed" })
    end
  end
  
  vim.fn.jobstart(args, {
    on_stdout = function(_, data)
      callback({ success = true, data = table.concat(data, "\n") })
    end,
    on_stderr = function(_, data)
      callback({ success = false, error = table.concat(data, "\n") })
    end,
    on_exit = on_exit,
    stdout_buffered = true,
    stderr_buffered = true,
  })
end

return M
