local RenameableBuffer = require("yazi.renameable_buffer")
local plenary_path = require("plenary.path")

local M = {}

---@param realpath_application string
---@param current_file_dir string
---@param selected_file string
---@return string
function M.relative_path(realpath_application, current_file_dir, selected_file)
  local command = realpath_application
  assert(
    command ~= nil,
    "realpath_application must be set. Please report this as a bug."
  )

  if vim.fn.executable(command) == 0 then
    local msg = string.format(
      "error copying relative_path - the executable `%s` was not found. Try running `:healthcheck yazi` for more information.",
      command
    )

    vim.notify(msg)
    error(msg)
  end

  assert(command ~= nil, "realpath command must be set")

  ---@type Path
  local start_path = plenary_path:new(current_file_dir)
  local start_directory = nil
  if start_path:is_dir() then
    start_directory = start_path
  else
    start_directory = start_path:parent()
  end

  local job = vim.system({
    command,
    "--relative-to",
    start_directory.filename,
    selected_file,
  })
  local result = job:wait(1000)

  if result.code ~= 0 or result.stdout == nil or result.stdout == "" then
    vim.notify("error copying relative_path, exit code " .. result.code)
    error("error running command, exit code " .. result.code)
    print(vim.inspect(result.stderr))
  end

  -- split
  local lines = vim.split(result.stdout, "\n")

  assert(lines, "error copying relative_path, no output")
  assert(#lines >= 1, "error copying relative_path, no output")
  local path = lines[1]

  return path
end

function M.is_yazi_available()
  return vim.fn.executable("yazi") == 1
end

function M.is_ya_available()
  return vim.fn.executable("ya") == 1
end

function M.file_exists(name)
  local f = io.open(name, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

--- get text lines in visual selection
---@return string[]
function M.get_visual_selection_lines()
  local start_row, start_col = unpack(vim.api.nvim_buf_get_mark(0, "<"))
  local end_row, end_col = unpack(vim.api.nvim_buf_get_mark(0, ">"))
  local lines = vim.fn.getline(start_row, end_row) --[[ @as string[] ]]
  if
    #lines > 0
    and start_col
    and end_col
    and end_col < string.len(lines[#lines])
  then
    if start_row == end_row then
      lines[1] = lines[1]:sub(start_col + 1, end_col + 1)
    else
      lines[1] = lines[1]:sub(start_col + 1, -1)
      lines[#lines] = lines[#lines]:sub(1, end_col + 1)
    end
  end
  return lines
end

---@param path string?
function M.selected_file_path(path)
  -- if a file is currently selected in visual mode, use that as the path
  local mode = vim.api.nvim_get_mode().mode
  if mode == "V" or mode == "v" then
    -- needed to make visual selection work
    vim.fn.feedkeys(":", "nx")
    local lines = M.get_visual_selection_lines()
    local line = lines[1]
    -- trim whitespace at the beginning and end of the line
    line = line:gsub("^%s*(.-)%s*$", "%1")
    line = vim.fn.expand(line) or line

    local current_file_dir = vim.fn.expand("%:p:h")
    local absolute_path =
      vim.fn.fnamemodify(current_file_dir .. "/" .. line, ":p")

    if
      vim.fn.filereadable(absolute_path) == 1
      or vim.fn.isdirectory(absolute_path) == 1
    then
      path = absolute_path
    elseif vim.fn.filereadable(line) == 1 or vim.fn.isdirectory(line) == 1 then
      path = line
    end
  end

  -- make sure the path is a full path
  if path == "" or path == nil then
    path = vim.fn.expand("%:p")
  end

  -- if the path is still empty (no file loaded / invalid buffer), try to get
  -- the directory of the current file.
  if path == "" or path == nil then
    path = vim.fn.expand("%:p:h")
  end

  -- if the path is still empty, try to get the current file
  if path == "" or path == nil then
    path = vim.fn.expand("%:p")
  end

  ---@type Path
  return plenary_path:new(path)
end

---@param path string?
function M.selected_file_paths(path)
  local selected_file_path = M.selected_file_path(path)

  local is_quickfix_window_selected = vim.api.nvim_get_option_value(
    "buftype",
    { buf = 0 }
  ) == "quickfix"
  if is_quickfix_window_selected then
    -- get the paths of the files in the quickfix window
    local qflist = vim.fn.getqflist()

    ---@type Path[]
    local filenames = {}
    for _, entry in ipairs(qflist) do
      if entry.bufnr and entry.bufnr > 0 then
        local filename = vim.api.nvim_buf_get_name(entry.bufnr)
        local new_path = plenary_path:new(filename)
        table.insert(filenames, new_path)
      end
    end

    return filenames
  end

  ---@type Path[]
  local paths = { selected_file_path }
  for _, buffer in ipairs(M.get_visible_open_buffers()) do
    -- NOTE: yazi can only display up to 9 paths, and it's an error to give any
    -- more
    if
      #paths < 9
      and not buffer.renameable_buffer:matches_exactly(
        selected_file_path.filename
      )
    then
      table.insert(paths, buffer.renameable_buffer.path)
    end
  end

  return paths
end

---@param file_path string
---@return Path
function M.dir_of(file_path)
  ---@type Path
  local path = plenary_path:new(file_path)
  local parent = path:parent()

  -- for some reason, plenary is documented as returning table|unknown[]. we
  -- want the table version only
  assert(type(parent) == "table", "parent must be a table")

  return parent
end

-- Returns parsed events from yazi
---@param event_lines string[]
function M.parse_events(event_lines)
  ---@type YaziEvent[]
  local events = {}

  for _, line in ipairs(event_lines) do
    local parts = vim.split(line, ",")
    local type = parts[1]
    local yazi_id = parts[3]

    -- selene: allow(if_same_then_else)
    if type == "NvimCycleBuffer" then
      ---@type YaziNvimCycleBufferEvent
      local event = {
        type = "cycle-buffer",
      }
      table.insert(events, event)
    elseif type == "rename" then
      -- example of a rename event:

      -- rename,1712242143209837,1712242143209837,{"tab":0,"from":"/Users/mikavilpas/git/yazi/LICENSE","to":"/Users/mikavilpas/git/yazi/LICENSE2"}
      local data_string = table.concat(parts, ",", 4, #parts)

      ---@type YaziRenameEvent
      local event = {
        type = type,
        yazi_id = yazi_id,
        data = vim.json.decode(data_string),
      }
      table.insert(events, event)
    elseif type == "move" then
      -- example of a move event:
      -- move,1712854829131439,1712854829131439,{"items":[{"from":"/tmp/test/test","to":"/tmp/test"}]}
      local data_string = table.concat(parts, ",", 4, #parts)

      ---@type YaziMoveEvent
      local event = {
        type = type,
        yazi_id = yazi_id,
        data = vim.json.decode(data_string),
      }
      table.insert(events, event)
    elseif type == "bulk" then
      -- example of a bulk event:
      -- bulk,0,1720800121065599,{"changes":{"/tmp/test-directory/test":"/tmp/test-directory/test2"}}
      local data = vim.json.decode(table.concat(parts, ",", 4, #parts))

      ---@type YaziBulkEvent
      local event = {
        type = "bulk",
        changes = data["changes"],
      }
      table.insert(events, event)
    elseif type == "delete" then
      -- example of a delete event:
      -- delete,1712766606832135,1712766606832135,{"urls":["/tmp/test-directory/test_2"]}
      local data_string = table.concat(parts, ",", 4, #parts)

      ---@type YaziDeleteEvent
      local event = {
        type = type,
        yazi_id = yazi_id,
        data = vim.json.decode(data_string),
      }
      table.insert(events, event)
    elseif type == "trash" then
      -- example of a trash event:
      -- trash,1712766606832135,1712766606832135,{"urls":["/tmp/test-directory/test_2"]}

      local data_string = table.concat(parts, ",", 4, #parts)

      ---@type YaziTrashEvent
      local event = {
        type = type,
        yazi_id = yazi_id,
        data = vim.json.decode(data_string),
      }
      table.insert(events, event)
    elseif type == "cd" then
      -- example of a change directory (cd) event:
      -- cd,1716307611001689,1716307611001689,{"tab":0,"url":"/tmp/test-directory"}

      local data_string = table.concat(parts, ",", 4, #parts)

      ---@type YaziChangeDirectoryEvent
      local event = {
        type = type,
        yazi_id = yazi_id,
        url = vim.json.decode(data_string)["url"],
      }
      table.insert(events, event)
    elseif type == "hover" then
      -- example of a hover event:
      -- hover,0,1720375364822700,{"tab":0,"url":"/tmp/test-directory/test"}
      local data_string = table.concat(parts, ",", 4, #parts)
      local json = vim.json.decode(data_string, {
        luanil = {
          array = true,
          object = true,
        },
      })

      -- sometimes ya sends a hover event without a url, not sure why
      ---@type string | nil
      local url = json["url"]
      if url ~= nil then
        ---@type YaziHoverEvent
        local event = {
          yazi_id = yazi_id,
          type = type,
          url = url or "",
        }
        table.insert(events, event)
      end
    elseif type == "hey" then
      -- example of a hey event:
      -- hey,0,69016966727041,{"peers":{"1745849494365272":{"abilities":["hey"]},"69016966727041":{"abilities":["dds-emit","@yank","extract"]},"1745849492676175":{"abilities":["hover","move","hey","bulk","cd","delete","rename","trash","NvimCycleBuffer"]}},"version":"25.4.8 VERGEN_IDEMPOTENT_OUTPUT"}
      ---@type YaziHeyEvent
      local event = {
        yazi_id = yazi_id,
        type = type,
      }
      table.insert(events, event)
    else
      require("yazi.log"):debug(string.format("Unknown event type: %s", type))
      -- Custom user event.
      -- It could look like this (with optional data at the end)
      -- MyMessageNoData,0,1731774290298033,
      local data_string = table.concat(parts, ",", 4, #parts)

      ---@type YaziCustomDDSEvent
      local event = {
        yazi_id = yazi_id,
        type = type,
        raw_data = data_string,
      }
      table.insert(events, event)
    end
  end

  return events
end

---@param event_lines string[]
function M.safe_parse_events(event_lines)
  local success, events = pcall(M.parse_events, event_lines)
  if not success then
    return {}
  end

  return events
end

---@return RenameableBuffer[]
function M.get_open_buffers()
  ---@type RenameableBuffer[]
  local open_buffers = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local path = vim.api.nvim_buf_get_name(bufnr)
    local type = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
    local is_listed =
      vim.api.nvim_get_option_value("buflisted", { buf = bufnr })

    local is_ordinary_file = path ~= vim.NIL
      and path ~= ""
      and type == ""
      and is_listed
    if is_ordinary_file then
      local renameable_buffer = RenameableBuffer.new(bufnr, path)
      open_buffers[#open_buffers + 1] = renameable_buffer
    end
  end

  return open_buffers
end

---@alias YaziVisibleBuffer { renameable_buffer: RenameableBuffer, window_id: integer }

function M.get_visible_open_buffers()
  local open_buffers = M.get_open_buffers()

  ---@type YaziVisibleBuffer[]
  local visible_open_buffers = {}
  for _, buffer in ipairs(open_buffers) do
    local windows = vim.api.nvim_tabpage_list_wins(0)
    for _, window_id in ipairs(windows) do
      if vim.api.nvim_win_get_buf(window_id) == buffer.bufnr then
        ---@type YaziVisibleBuffer
        local data = {
          renameable_buffer = buffer,
          window_id = window_id,
        }
        visible_open_buffers[#visible_open_buffers + 1] = data
      end
    end
  end

  return visible_open_buffers
end

---@param path string
---@return boolean
function M.is_buffer_open(path)
  local open_buffers = M.get_open_buffers()
  for _, buffer in ipairs(open_buffers) do
    if buffer:matches_exactly(path) then
      return true
    end
  end

  return false
end

---@param implementation YaziBufdeleteImpl
---@param bufnr integer
function M.bufdelete(implementation, bufnr)
  if implementation == "snacks-if-available" then
    local ok, bufdelete = pcall(function()
      return require("snacks.bufdelete")
    end)
    if ok then
      return bufdelete.delete({ buf = bufnr, force = true, wipe = true })
    else
      bufdelete = require("yazi.integrations.snacks_bufdelete")
      bufdelete.delete({ buf = bufnr, force = true, wipe = true })
    end
  elseif implementation == "bundled-snacks" then
    local bufdelete = require("yazi.integrations.snacks_bufdelete")
    bufdelete.delete({ buf = bufnr, force = true, wipe = true })
  elseif implementation == "builtin" then
    vim.api.nvim_buf_call(bufnr, function()
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
  else
    -- the user has a custom implementation. Call it.
    if type(implementation) == "function" then
      implementation(bufnr)
    else
      error("Invalid bufdelete implementation: " .. tostring(implementation))
    end
  end
end

---@param config YaziConfig
---@param instruction RenameableBuffer
---@return nil
function M.rename_or_close_buffer(config, instruction)
  -- If the target buffer is already open in neovim, just close the old buffer.
  -- It causes an error to try to rename to a buffer that's already open.
  if M.is_buffer_open(instruction.path.filename) then
    pcall(function()
      M.bufdelete(
        config.integrations.bufdelete_implementation,
        instruction.bufnr
      )
    end)
  end

  pcall(function()
    vim.api.nvim_buf_set_name(instruction.bufnr, instruction.path.filename)
  end)
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(instruction.bufnr) then
      vim.api.nvim_buf_call(instruction.bufnr, function()
        vim.cmd("edit!")
      end)
    end
  end)
end

---@param prev_win integer
---@param window YaziFloatingWindow
---@param config YaziConfig
---@param selected_files string[]
---@param state YaziClosedState
function M.on_yazi_exited(prev_win, window, config, selected_files, state)
  vim.cmd("silent! :checktime")

  window:close()

  do
    -- sanity check: make sure the previous window and buffer are still valid
    if not vim.api.nvim_win_is_valid(prev_win) then
      return
    end
  end

  vim.api.nvim_set_current_win(prev_win)
  if #selected_files <= 0 then
    config.hooks.yazi_closed_successfully(nil, config, state)
    return
  end

  if #selected_files > 1 then
    config.hooks.yazi_opened_multiple_files(selected_files, config, state)
    return
  end

  assert(#selected_files == 1)
  local chosen_file = selected_files[1]
  config.hooks.yazi_closed_successfully(chosen_file, config, state)
  if chosen_file then
    config.open_file_function(chosen_file, config, state)
  end
end

return M
