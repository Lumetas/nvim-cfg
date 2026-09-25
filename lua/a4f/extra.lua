-- Extra tools for a4f: arglist + extended LSP (diagnostics, code actions, fixes).
-- Loaded by a4f/tools.lua and dispatched through the same execute().
local M = {}

-- ============================================================
-- shared helpers (duplicated to stay self-contained)
-- ============================================================
local function is_special_buf_name(name)
  return name == "" or name:find("^a4f://", 1, true) ~= nil
      or name:find("^term://", 1, true) ~= nil
      or name:find("^oil://", 1, true) ~= nil
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

local function ensure_lsp_buf(path)
  local buf = find_buf(path)
  if not buf then
    buf = vim.fn.bufadd(path); vim.fn.bufload(buf); vim.bo[buf].buflisted = true
  end
  if #vim.lsp.get_clients({ bufnr = buf }) == 0 then
    vim.wait(1500, function() return #vim.lsp.get_clients({ bufnr = buf }) > 0 end, 50)
  end
  return buf
end

local function diag_format(buf)
  local out = {}
  for _, d in ipairs(vim.diagnostic.get(buf)) do
    out[#out+1] = string.format("%d:%d [%s] %s",
      d.lnum + 1, d.col + 1,
      vim.diagnostic.severity[d.severity] or d.severity,
      (d.message or ""):gsub("\n", " "))
  end
  return out
end

-- ============================================================
-- arglist
-- ============================================================
function M.args_list()
  local out = {}
  local cur = vim.fn.argidx()
  for i, a in ipairs(vim.fn.argv()) do
    local mark = (i - 1 == cur) and "*" or " "
    out[#out+1] = string.format("[%d]%s %s", i - 1, mark, a)
  end
  if #out == 0 then return "(arglist empty)" end
  return table.concat(out, "\n")
end

function M.args_add(param)
  if not param or param == "" then return "[error] args_add: empty path" end
  local added, skipped = 0, 0
  for p in param:gmatch("[^%s,]+") do
    local full = vim.fn.fnamemodify(vim.fn.expand(p), ":p")
    if vim.fn.filereadable(full) == 1 or vim.fn.isdirectory(full) == 1 then
      vim.cmd("argadd " .. vim.fn.fnameescape(full))
      added = added + 1
    else
      skipped = skipped + 1
    end
  end
  return string.format("argadd: added %d, skipped %d (not found)", added, skipped)
end

function M.args_set(param)
  if not param or param == "" then return "[error] args_set: empty path(s)" end
  vim.cmd("argdelete *")
  return M.args_add(param)
end

function M.args_next()
  vim.cmd("next"); return "next -> " .. vim.fn.expand("%")
end

function M.args_prev()
  vim.cmd("prev"); return "prev -> " .. vim.fn.expand("%")
end

function M.args_open(param)
  local n = tonumber(param)
  if not n then return "[error] args_open: expected index" end
  vim.cmd("argument " .. n)
  return "argument " .. n .. " -> " .. vim.fn.expand("%")
end

-- ============================================================
-- diagnostics
-- ============================================================
function M.workspace_diagnostics()
  local out, total = {}, 0
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) then
      local name = vim.api.nvim_buf_get_name(b)
      if not is_special_buf_name(name) then
        local lines = diag_format(b)
        if #lines > 0 then
          total = total + #lines
          out[#out+1] = "## " .. name
          for _, l in ipairs(lines) do out[#out+1] = l end
        end
      end
    end
  end
  if total == 0 then return "No diagnostics in loaded buffers" end
  return table.concat(out, "\n")
end

function M.file_diagnostics(plugin, param)
  local path = vim.fn.fnamemodify(vim.fn.expand(param), ":p")
  if param == "" then
    local b = vim.api.nvim_get_current_buf()
    path = vim.api.nvim_buf_get_name(b)
  end
  if path == "" or vim.fn.filereadable(path) == 0 then
    return "[error] file_diagnostics: not found: " .. path
  end
  local buf = ensure_lsp_buf(path)
  vim.wait(800, function() return #vim.diagnostic.get(buf) > 0 end, 50)
  local lines = diag_format(buf)
  if #lines == 0 then return "No diagnostics: " .. path end
  return "## " .. path .. "\n" .. table.concat(lines, "\n")
end

-- ============================================================
-- LSP code actions / fixes
-- ============================================================
function M.lsp_actions_at(param)
  local file, line_s, col_s = param:match("^(.-):(%d+):(%d+)$")
  if not file then return "[error] lsp_actions_at: expected path:line:col" end
  local line = tonumber(line_s) - 1
  local col  = tonumber(col_s) - 1
  local path = vim.fn.fnamemodify(vim.fn.expand(file), ":p")
  local buf = ensure_lsp_buf(path)
  if #vim.lsp.get_clients({ bufnr = buf }) == 0 then
    return "[error] lsp_actions_at: no LSP client for " .. path
  end
  local diags = vim.diagnostic.get(buf, { lnum = line })
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(buf),
    range = { start = { line = line, character = col },
              ["end"] = { line = line, character = col } },
    context = { diagnostics = diags },
  }
  local done_flag, out = false, nil
  vim.lsp.buf_request(buf, "textDocument/codeAction", params, function(err, result)
    if err then out = "[error] lsp_actions_at: " .. tostring(err.message or err)
    elseif not result or #result == 0 then out = "(no code actions)"
    else
      local lines = {}
      for i, a in ipairs(result) do
        lines[#lines+1] = string.format("%d. %s%s", i, a.title or "?",
          a.kind and (" [" .. a.kind .. "]") or "")
      end
      out = table.concat(lines, "\n")
    end
    done_flag = true
  end)
  if not done_flag then vim.wait(2500, function() return done_flag end, 20) end
  return out or "[error] lsp_actions_at: timeout"
end

function M.lsp_fix_at(param)
  local file, line_s, col_s = param:match("^(.-):(%d+):(%d+)$")
  if not file then return "[error] lsp_fix_at: expected path:line:col" end
  local line = tonumber(line_s) - 1
  local col  = tonumber(col_s) - 1
  local path = vim.fn.fnamemodify(vim.fn.expand(file), ":p")
  local buf = ensure_lsp_buf(path)
  if #vim.lsp.get_clients({ bufnr = buf }) == 0 then
    return "[error] lsp_fix_at: no LSP client for " .. path
  end
  local diags = vim.diagnostic.get(buf, { lnum = line })
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(buf),
    range = { start = { line = line, character = col },
              ["end"] = { line = line, character = col } },
    context = { diagnostics = diags },
  }
  local done_flag, out = false, nil
  local function finish(s) if done_flag then return end; done_flag = true; out = s end
  vim.lsp.buf_request(buf, "textDocument/codeAction", params, function(err, result, ctx)
    if err then finish("[error] lsp_fix_at: " .. tostring(err.message or err)); return end
    if not result or #result == 0 then
      finish(string.format("No code actions at %s:%d:%d", path, line + 1, col + 1)); return
    end
    local pick = result[1]
    local function apply(action)
      local client = vim.lsp.get_client_by_id(ctx.client_id)
      local enc = (client and client.offset_encoding) or "utf-16"
      if action.edit then
        vim.lsp.util.apply_workspace_edit(action.edit, enc)
        vim.api.nvim_buf_call(buf, function() vim.cmd("silent write") end)
        finish("Fixed: " .. (action.title or "?"))
      elseif action.command then
        if client then client.request_sync("workspace/executeCommand", action.command, 3000, buf) end
        vim.api.nvim_buf_call(buf, function() vim.cmd("silent write") end)
        finish("Executed: " .. (action.title or "?"))
      else
        finish("[error] lsp_fix_at: action has no edit/command")
      end
    end
    if pick.edit or pick.command then
      apply(pick)
    else
      local client = vim.lsp.get_client_by_id(ctx.client_id)
      local resolved = client and client.request_sync("codeAction/resolve", pick, 2000, buf)
      if resolved and resolved.result then apply(resolved.result)
      else finish("[error] lsp_fix_at: could not resolve action") end
    end
  end)
  if not done_flag then vim.wait(3000, function() return done_flag end, 20) end
  return out or "[error] lsp_fix_at: timeout"
end

function M.lsp_fix_all(param)
  local path = vim.fn.fnamemodify(vim.fn.expand(param), ":p")
  if vim.fn.filereadable(path) == 0 then
    return "[error] lsp_fix_all: not found: " .. path
  end
  local buf = ensure_lsp_buf(path)
  if #vim.lsp.get_clients({ bufnr = buf }) == 0 then
    return "[error] lsp_fix_all: no LSP client for " .. path
  end
  local applied = 0
  for _ = 1, 50 do
    local diags = vim.diagnostic.get(buf)
    if #diags == 0 then break end
    table.sort(diags, function(a, b)
      if a.lnum == b.lnum then return a.col < b.col end
      return a.lnum < b.lnum
    end)
    local d = diags[1]
    local res = M.lsp_fix_at(string.format("%s:%d:%d", path, d.lnum + 1, d.col + 1))
    if res and (res:find("^Fixed") or res:find("^Executed")) then
      applied = applied + 1
    else
      break
    end
    vim.wait(300, function() return false end, 50)
  end
  return string.format("lsp_fix_all %s: applied=%d, remaining=%d",
    path, applied, #vim.diagnostic.get(buf))
end

-- ============================================================
-- Chat buffer access (a4f://chat) - read + write
-- ============================================================
function M.chat_read(plugin)
  local buf = plugin and plugin.state and plugin.state.chat_buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return "[error] chat_read: chat buffer not open"
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return "[chat]\n---\n" .. table.concat(lines, "\n")
end

function M.chat_write(plugin, data)
  if plugin and plugin.set_chat then
    return plugin.set_chat(data)
  end
  return "[error] chat_write: plugin.set_chat not available"
end

function M.chat_append(plugin, data)
  if plugin and plugin.append_chat then
    plugin.append_chat(data)
    return "chat appended"
  end
  return "[error] chat_append: plugin.append_chat not available"
end

-- ============================================================
-- Raw Neovim control: ex-commands, normal-mode keys, visual selection
-- ============================================================
function M.ex(param)
  if not param or param == "" then return "[error] ex: empty command" end
  local ok, err = pcall(vim.cmd, param)
  if not ok then return "[error] ex: " .. tostring(err) end
  return "Ran: " .. param
end

function M.normal(param)
  if not param or param == "" then return "[error] normal: empty keys" end
  local keys = vim.api.nvim_replace_termcodes(param, true, false, true)
  local ok, err = pcall(vim.api.nvim_feedkeys, keys, "m", false)
  if not ok then return "[error] normal: " .. tostring(err) end
  return "Fed normal keys: " .. param
end

-- Run a key sequence in a given mode: mode in {n,v,x,i,t}
function M.feed(param)
  local mode, keys = param:match("^(%a):(.*)$")
  if not mode then return "[error] feed: expected mode:keys (e.g. n:gg)" end
  local seq = vim.api.nvim_replace_termcodes(keys, true, false, true)
  local ok, err = pcall(function()
    if mode == "n" then
      vim.api.nvim_feedkeys(seq, "m", false)
    elseif mode == "i" then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true) .. seq, "m", false)
    else
      vim.api.nvim_feedkeys(seq, "m", false)
    end
  end)
  if not ok then return "[error] feed: " .. tostring(err) end
  return "Fed " .. mode .. " keys: " .. keys
end

-- Inspect current visual selection (call right after selecting, or use marks).
function M.selection()
  local s = vim.fn.getpos("'<")
  local e = vim.fn.getpos("'>")
  if s[2] == 0 or e[2] == 0 then return "(no visual selection marks)" end
  local buf = vim.api.nvim_get_current_buf()
  local l1, c1, l2, c2 = s[2], s[3], e[2], e[3]
  if l1 > l2 or (l1 == l2 and c1 > c2) then l1, c1, l2, c2 = l2, c2, l1, c1 end
  local lines = vim.api.nvim_buf_get_lines(buf, l1 - 1, l2, false)
  local name = vim.api.nvim_buf_get_name(buf)
  return string.format("%s:%d:%d-%d:%d\n%s",
    name, l1, c1, l2, c2, table.concat(lines, "\n"))
end

return M
