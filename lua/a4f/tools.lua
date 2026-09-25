local M = {}

-- ============================================================
-- Helpers
-- ============================================================
local function is_special_buf_name(name)
  return name == "" or name:find("^a4f://", 1, true) ~= nil
      or name:find("^term://", 1, true) ~= nil
      or name:find("^oil://", 1, true) ~= nil
end

local function working_buf(plugin)
  local cur = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(cur)
  if name:find("^a4f://", 1, true) then
    if plugin and plugin.state and plugin.state.context_buf
       and vim.api.nvim_buf_is_valid(plugin.state.context_buf) then
      return plugin.state.context_buf
    end
  end
  return cur
end

local function working_win(plugin)
  if plugin and plugin.state and plugin.state.context_win
     and vim.api.nvim_win_is_valid(plugin.state.context_win) then
    return plugin.state.context_win
  end
  return vim.api.nvim_get_current_win()
end

-- Resolve a path param, or fall back to the working buffer's file name.
local function resolve_path(plugin, param)
  if param and param ~= "" then
    return vim.fn.fnamemodify(vim.fn.expand(param), ":p")
  end
  local b = working_buf(plugin)
  local name = vim.api.nvim_buf_get_name(b)
  if is_special_buf_name(name) then return nil end
  return vim.fn.fnamemodify(name, ":p")
end

local function find_buf(path)
  path = vim.fn.fnamemodify(vim.fn.expand(path), ":p")
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) then
      local name = vim.api.nvim_buf_get_name(b)
      if name ~= "" and vim.fn.fnamemodify(name, ":p") == path then
        return b
      end
    end
  end
  return nil
end

local function read_file(path)
  path = vim.fn.expand(path)
  local buf = find_buf(path)
  if buf then
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    return "[buffer] " .. path .. "\n---\n" .. table.concat(lines, "\n")
  end
  if vim.fn.filereadable(path) == 0 then
    return "[error] file not found: " .. path
  end
  return "[file] " .. path .. "\n---\n" .. table.concat(vim.fn.readfile(path), "\n")
end

local function write_file(path, content)
  path = vim.fn.expand(path)
  if path == "" then return "[error] write: empty path" end
  if path:find("^a4f://", 1, true) then
    return "[error] write: cannot write to a4f internal buffer (" .. path .. ")"
  end

  local buf = find_buf(path)
  local lines = vim.split(content, "\n", { plain = true })
  if buf then
    if not vim.bo[buf].modifiable then
      return "[error] write: buffer is not modifiable: " .. path
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    return "Buffer updated: " .. path
  end
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  vim.fn.writefile(lines, path)
  return "Written: " .. path
end

local function edit_file(path, diff)
  path = vim.fn.expand(path)
  if path == "" then return "[error] edit: empty path" end

  local buf = find_buf(path)
  local lines
  if buf then
    lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  elseif vim.fn.filereadable(path) == 1 then
    lines = vim.fn.readfile(path)
  else
    return "[error] file not found: " .. path
  end

  local old, new = {}, {}
  for line in diff:gmatch("[^\n]+") do
    if line:sub(1, 1) == "-" then
      table.insert(old, line:sub(2))
    elseif line:sub(1, 1) == "+" then
      table.insert(new, line:sub(2))
    end
  end

  if #old == 0 and #new == 0 then
    return "[error] edit: no +/- lines in diff"
  end

  local result = {}
  local i = 1
  local replaced = false
  while i <= #lines do
    if not replaced and lines[i] == old[1] then
      local match = true
      for k = 1, #old do
        if lines[i + k - 1] ~= old[k] then match = false; break end
      end
      if match then
        for _, l in ipairs(new) do table.insert(result, l) end
        i = i + #old
        replaced = true
        goto continue
      end
    end
    table.insert(result, lines[i])
    i = i + 1
    ::continue::
  end

  if not replaced then
    if #old > 0 then
      return "[error] edit: old block not found"
    end
    for _, l in ipairs(new) do table.insert(result, l) end
  end

  return write_file(path, table.concat(result, "\n"))
end

local function open_in(mode, path)
  path = vim.fn.expand(path)
  if path == "" then return "[error] open: empty path" end
  local cmd = ({ edit = "edit", split = "split", vsplit = "vsplit", tab = "tabedit" })[mode] or "edit"
  vim.cmd(cmd .. " " .. vim.fn.fnameescape(path))
  return "Opened " .. mode .. ": " .. path
end

-- Run a function with context window active (used by LSP tools).
local function with_context_win(plugin, fn)
  local cur_win = vim.api.nvim_get_current_win()
  local ctx_win = working_win(plugin)
  if cur_win == ctx_win or not vim.api.nvim_win_is_valid(ctx_win) then
    return fn()
  end
  vim.api.nvim_set_current_win(ctx_win)
  local ok, res = pcall(fn)
  if vim.api.nvim_win_is_valid(cur_win) then
    vim.api.nvim_set_current_win(cur_win)
  end
  if not ok then error(res) end
  return res
end

-- Synchronously wait for an LSP callback with a timeout.
local function with_lsp(bufnr, timeout_ms, invoke)
  if not vim.lsp then return "[error] lsp: not available" end
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if #clients == 0 then return "[error] lsp: no client attached to this buffer" end

  local done_flag, out = false, nil
  local function finish(s) if done_flag then return end; done_flag = true; out = s or "" end

  local ok, err = pcall(invoke, finish)
  if not ok then return "[error] lsp: " .. tostring(err) end
  if not done_flag then vim.wait(timeout_ms or 2000, function() return done_flag end, 20) end
  if not done_flag then return "[error] lsp: timeout" end
  return out
end

-- ============================================================
-- LSP commands
-- ============================================================
local function lsp_format()
  local bufnr = vim.api.nvim_get_current_buf()
  if #vim.lsp.get_clients({ bufnr = bufnr }) == 0 then
    return "[error] lsp: no client attached to this buffer"
  end
  local ok, err = pcall(function()
    vim.lsp.buf.format({ bufnr = bufnr, async = false, timeout_ms = 3000 })
  end)
  if not ok then return "[error] lsp_format: " .. tostring(err) end

  local name = vim.api.nvim_buf_get_name(bufnr)
  if name ~= "" and vim.bo[bufnr].modified then
    vim.api.nvim_buf_call(bufnr, function() vim.cmd("silent write") end)
  end
  return "Formatted buffer via LSP" .. (name ~= "" and (" and saved " .. name) or "")
end

local function lsp_rename(new_name)
  if not new_name or new_name == "" then
    return "[error] lsp_rename: empty new_name"
  end
  local bufnr = vim.api.nvim_get_current_buf()
  if #vim.lsp.get_clients({ bufnr = bufnr }) == 0 then
    return "[error] lsp: no client attached to this buffer"
  end

  local pos = vim.api.nvim_win_get_cursor(0)
  local params = vim.lsp.util.make_position_params(0, nil)

  return with_lsp(bufnr, 3000, function(done)
    vim.lsp.buf_request(bufnr, "textDocument/rename", params, function(err, result, ctx)
      if err then done("[error] lsp_rename: " .. tostring(err.message or err)); return end
      if not result then done("[error] lsp_rename: no rename result"); return end
      local client = vim.lsp.get_client_by_id(ctx.client_id)
      local enc = (client and client.offset_encoding) or "utf-16"
      vim.lsp.util.apply_workspace_edit(result, enc)
      vim.cmd("silent write")
      done(string.format("Renamed symbol at %d:%d -> %q", pos[1], pos[2] + 1, new_name))
    end)
  end)
end

local function lsp_code_action(filter)
  local bufnr = vim.api.nvim_get_current_buf()
  if #vim.lsp.get_clients({ bufnr = bufnr }) == 0 then
    return "[error] lsp: no client attached to this buffer"
  end

  local params = vim.lsp.util.make_range_params(0, nil)
  params.context = { diagnostics = vim.diagnostic.get(bufnr) }

  return with_lsp(bufnr, 3000, function(done)
    vim.lsp.buf_request(bufnr, "textDocument/codeAction", params, function(err, result, ctx)
      if err then done("[error] lsp_code_action: " .. tostring(err.message or err)); return end
      if not result or #result == 0 then done("[error] lsp_code_action: no actions available"); return end

      local pick = result[1]
      if filter and filter ~= "" then
        local lf = filter:lower()
        for _, a in ipairs(result) do
          if (a.title or ""):lower():find(lf, 1, true) then pick = a; break end
        end
      end

      local function apply(action)
        if action.edit then
          local client = vim.lsp.get_client_by_id(ctx.client_id)
          local enc = (client and client.offset_encoding) or "utf-16"
          vim.lsp.util.apply_workspace_edit(action.edit, enc)
          vim.cmd("silent write")
          done("Applied code action: " .. (action.title or "?"))
        elseif action.command then
          local client = vim.lsp.get_client_by_id(ctx.client_id)
          if client then
            client.request_sync("workspace/executeCommand", action.command, 3000, bufnr)
          end
          done("Executed command: " .. (action.title or "?"))
        else
          done("[error] lsp_code_action: action has no edit/command")
        end
      end

      if pick.edit or pick.command then
        apply(pick)
      else
        local client = vim.lsp.get_client_by_id(ctx.client_id)
        if not client then done("[error] lsp_code_action: no client"); return end
        local resolved = client.request_sync("codeAction/resolve", pick, 2000, bufnr)
        if resolved and resolved.result then apply(resolved.result)
        else done("[error] lsp_code_action: could not resolve") end
      end
    end)
  end)
end

local function lsp_hover()
  local bufnr = vim.api.nvim_get_current_buf()
  if #vim.lsp.get_clients({ bufnr = bufnr }) == 0 then
    return "[error] lsp: no client attached to this buffer"
  end
  local params = vim.lsp.util.make_position_params(0, nil)
  return with_lsp(bufnr, 2000, function(done)
    vim.lsp.buf_request(bufnr, "textDocument/hover", params, function(err, result)
      if err then done("[error] lsp_hover: " .. tostring(err.message or err)); return end
      if not result or not result.contents then done("(no hover info)"); return end
      local c = result.contents
      local text
      if type(c) == "string" then text = c
      elseif c.value then text = c.value
      elseif type(c) == "table" then
        local parts = {}
        for _, x in ipairs(c) do parts[#parts+1] = type(x) == "string" and x or (x.value or "") end
        text = table.concat(parts, "\n")
      else text = vim.inspect(c) end
      done(text)
    end)
  end)
end

local function lsp_definition()
  local bufnr = vim.api.nvim_get_current_buf()
  if #vim.lsp.get_clients({ bufnr = bufnr }) == 0 then
    return "[error] lsp: no client attached to this buffer"
  end
  local params = vim.lsp.util.make_position_params(0, nil)
  return with_lsp(bufnr, 2000, function(done)
    vim.lsp.buf_request(bufnr, "textDocument/definition", params, function(err, result)
      if err then done("[error] lsp_definition: " .. tostring(err.message or err)); return end
      if not result or #result == 0 then done("(no definition)"); return end
      local loc = result[1]
      local uri = loc.uri or loc.targetUri
      local rng = loc.range or loc.targetRange
      local path = vim.uri_to_fname(uri)
      local line = (rng and rng.start and rng.start.line or 0) + 1
      local col = (rng and rng.start and rng.start.character or 0) + 1
      vim.cmd("edit " .. vim.fn.fnameescape(path))
      vim.api.nvim_win_set_cursor(0, { line, col - 1 })
      done(string.format("%s:%d:%d", path, line, col))
    end)
  end)
end

local function lsp_references()
  local bufnr = vim.api.nvim_get_current_buf()
  if #vim.lsp.get_clients({ bufnr = bufnr }) == 0 then
    return "[error] lsp: no client attached to this buffer"
  end
  local params = vim.lsp.util.make_position_params(0, nil)
  params.context = { includeDeclaration = true }
  return with_lsp(bufnr, 3000, function(done)
    vim.lsp.buf_request(bufnr, "textDocument/references", params, function(err, result)
      if err then done("[error] lsp_references: " .. tostring(err.message or err)); return end
      if not result or #result == 0 then done("(no references)"); return end
      local out = {}
      for _, loc in ipairs(result) do
        local path = vim.uri_to_fname(loc.uri)
        local line = (loc.range and loc.range.start.line or 0) + 1
        local col = (loc.range and loc.range.start.character or 0) + 1
        out[#out+1] = string.format("%s:%d:%d", path, line, col)
      end
      done(table.concat(out, "\n"))
    end)
  end)
end

-- ============================================================
-- Dispatcher
-- ============================================================
function M.execute(cmd, param, data, plugin)
  param = param or ""
  data = data or ""

  if cmd == "shell" then
    local c = (param ~= "" and param) or data
    if c == "" then return "[error] shell: empty command" end
    return vim.fn.system(c .. " 2>&1")

  elseif cmd == "pwd" then
    return vim.fn.getcwd()

  elseif cmd == "read" then
    local path = resolve_path(plugin, param)
    if not path then return "[error] read: no path given and no active file buffer" end
    return read_file(path)

  elseif cmd == "write" then
    local path = resolve_path(plugin, param)
    if not path then return "[error] write: no path given and no active file buffer" end
    if data == "" then return "[error] write: empty content" end
    return write_file(path, data)

  elseif cmd == "edit" then
    local path = resolve_path(plugin, param)
    if not path then return "[error] edit: no path given and no active file buffer" end
    if data == "" then return "[error] edit: empty diff" end
    return edit_file(path, data)

  elseif cmd == "open" then
    if param == "" then return "[error] open: empty path" end
    return open_in("edit", param)
  elseif cmd == "split" then
    if param == "" then return "[error] split: empty path" end
    return open_in("split", param)
  elseif cmd == "vsplit" then
    if param == "" then return "[error] vsplit: empty path" end
    return open_in("vsplit", param)
  elseif cmd == "tab" then
    if param == "" then return "[error] tab: empty path" end
    return open_in("tab", param)

  elseif cmd == "close" then
    vim.cmd("close"); return "Closed window"

  elseif cmd == "save" then
    vim.cmd("silent write"); return "Saved " .. vim.fn.expand("%")

  elseif cmd == "buffers" then
    local out = {}
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(b) then
        local name = vim.api.nvim_buf_get_name(b)
        out[#out+1] = string.format("[%d]%s %s", b,
          vim.api.nvim_get_current_buf() == b and "*" or " ",
          name == "" and "(no name)" or name)
      end
    end
    return table.concat(out, "\n")

  elseif cmd == "buf_content" then
    local b = working_buf(plugin)
    local name = vim.api.nvim_buf_get_name(b)
    local lines = vim.api.nvim_buf_get_lines(b, 0, -1, false)
    local header = is_special_buf_name(name) and "[buffer unnamed]" or ("[buffer] " .. name)
    return header .. "\n---\n" .. table.concat(lines, "\n")

  elseif cmd == "goto" then
    -- Accept optional "path:line[:col]", "line:col", or "line".
    local l, c
    local p_l, p_c = param:match(":(%d+):(%d+)$")
    if p_l then
      l, c = p_l, p_c
    else
      local p_l2 = param:match(":(%d+)$")
      if p_l2 then l, c = p_l2, "1"
      else
        l, c = param:match("^(%d+):(%d+)$")
        if not l then l = param:match("^(%d+)$"); c = "1" end
      end
    end
    if l then
      local w = working_win(plugin)
      vim.api.nvim_win_set_cursor(w, { tonumber(l), tonumber(c) - 1 })
      return "Cursor -> " .. l .. ":" .. c
    end
    return "[error] goto: bad param (expected [path:]line[:col])"

  elseif cmd == "select" then
    local a, b = param:match("^(%d+),(%d+)$")
    if not a then return "[error] select: bad param (expected start,end)" end
    vim.cmd(string.format("normal! %dGV%dG", tonumber(a), tonumber(b)))
    return "Selected lines " .. a .. "-" .. b

  elseif cmd == "cursor" then
    local w = working_win(plugin)
    local pos = vim.api.nvim_win_get_cursor(w)
    local buf = vim.api.nvim_win_get_buf(w)
    local file = vim.api.nvim_buf_get_name(buf)
    return string.format("file=%s line=%d col=%d", file, pos[1], pos[2] + 1)

  elseif cmd == "windows" then
    local out = {}
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      local b = vim.api.nvim_win_get_buf(w)
      out[#out+1] = string.format("win %d buf %d %s", w, b, vim.api.nvim_buf_get_name(b))
    end
    return table.concat(out, "\n")

  elseif cmd == "grep" then
    local pattern = (param ~= "" and param) or data
    if pattern == "" then return "[error] grep: empty pattern" end
    return vim.fn.system(string.format(
      "rg -n --no-heading --color=never %q . 2>&1 | head -200", pattern))

  elseif cmd == "find" then
    local pattern = (param ~= "" and param) or data
    if pattern == "" then return "[error] find: empty pattern" end
    return vim.fn.system(string.format(
      "find . -name %q " ..
      "-not -path '*/.*' " ..
      "-not -path '*/vendor/*' " ..
      "-not -path '*/node_modules/*' " ..
      "2>&1 | head -200",
      "*" .. pattern .. "*"))

  elseif cmd == "diagnostics" then
    local w = working_win(plugin)
    local buf = vim.api.nvim_win_get_buf(w)
    local diags = vim.diagnostic.get(buf)
    if #diags == 0 then return "No diagnostics" end
    local out = {}
    for _, d in ipairs(diags) do
      out[#out+1] = string.format("%d:%d [%s] %s",
        d.lnum + 1, d.col + 1, d.severity, d.message)
    end
    return table.concat(out, "\n")

  elseif cmd == "lsp_format" then
    return with_context_win(plugin, lsp_format)
  elseif cmd == "lsp_rename" then
    return with_context_win(plugin, function() return lsp_rename(param) end)
  elseif cmd == "lsp_code_action" then
    return with_context_win(plugin, function() return lsp_code_action(param) end)
  elseif cmd == "lsp_hover" then
    return with_context_win(plugin, lsp_hover)
  elseif cmd == "lsp_definition" then
    return with_context_win(plugin, lsp_definition)
  elseif cmd == "lsp_references" then
    return with_context_win(plugin, lsp_references)
  end

  -- extended tools (arglist + advanced LSP)
  local extra = require("a4f.extra")
  if cmd == "args" then
    return extra.args_list()
  elseif cmd == "args_add" then
    return extra.args_add(param)
  elseif cmd == "args_set" then
    return extra.args_set(param)
  elseif cmd == "args_next" then
    return extra.args_next()
  elseif cmd == "args_prev" then
    return extra.args_prev()
  elseif cmd == "args_open" then
    return extra.args_open(param)
  elseif cmd == "workspace_diagnostics" then
    return extra.workspace_diagnostics()
  elseif cmd == "file_diagnostics" then
    return extra.file_diagnostics(plugin, param)
  elseif cmd == "lsp_actions_at" then
    return extra.lsp_actions_at(param)
  elseif cmd == "lsp_fix_at" then
    return extra.lsp_fix_at(param)
  elseif cmd == "lsp_fix_all" then
    return extra.lsp_fix_all(param)
  elseif cmd == "chat_read" then
    return extra.chat_read(plugin)
  elseif cmd == "chat_write" then
    return extra.chat_write(plugin, data)
  elseif cmd == "chat_append" then
    return extra.chat_append(plugin, data)
  elseif cmd == "ex" then
    return extra.ex(param ~= "" and param or data)
  elseif cmd == "normal" then
    return extra.normal(param ~= "" and param or data)
  elseif cmd == "feed" then
    return extra.feed(param ~= "" and param or data)
  elseif cmd == "selection" then
    return extra.selection()
  end

  return "[error] unknown command: " .. cmd
end

return M
