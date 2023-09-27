local M = {}

function M:new(nut)
  local core = setmetatable({}, { __index = self })
  core.nut = nut
  core.windows = {}
  return core
end

function M:emit(eventName, data)
  local handlers = self.nut._events[eventName] or {}
  for _, handler in ipairs(handlers) do
    handler({
      name = eventName,
      type = type(data),
      data = data
    })
  end
end

function M:on(eventName, handler)
  if not self.nut._events[eventName] then
    self.nut._events[eventName] = {}
  end
  table.insert(self.nut._events[eventName], handler)
end

return M
