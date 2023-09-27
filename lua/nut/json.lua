local M = {}

function M:new(nut)
  local json = setmetatable({}, { __index = self })
  json.nut = nut
  return json
end

function M:encode(data)
  return vim.fn.json_encode(data)
end

function M:decode(json_str)
  return vim.fn.json_decode(json_str)
end

return M
