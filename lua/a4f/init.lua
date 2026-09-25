local M = {}

local tools = require("a4f.tools")

M.config = {
  api_url = "http://localhost:1337",
  api_key = "",
  thinking = false,
  searching = false,
  max_iterations = 50,
  http_timeout = 300,        -- seconds, curl --max-time
  busy_watchdog_ms = 15 * 60 * 1000,
  disable_features = {},
  debug = false,
  chat = { split = "right", size = 70 },
}

M.state = {
  chat_id = nil,
  is_first_message = true,
  busy = false,
  busy_since = nil,
  read_files = {},
  chat_buf = nil,
  chat_win = nil,
  context_buf = nil,      -- "real" buffer the user cares about
  context_win = nil,
  history = {},
}

-- ============================================================
-- Config
-- ============================================================
local function deep_merge(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" and type(dst[k]) == "table" then
      deep_merge(dst[k], v)
    else
      dst[k] = v
    end
  end
end

local function load_config_file()
  local path = vim.fn.expand("~/.config/a4f/config.json")
  if vim.fn.filereadable(path) ~= 1 then return end
  local content = table.concat(vim.fn.readfile(path), "\n")
  local ok, decoded = pcall(vim.fn.json_decode, content)
  if not ok or type(decoded) ~= "table" then return end
  if decoded.disableFeatures and not decoded.disable_features then
    decoded.disable_features = decoded.disableFeatures
  end
  deep_merge(M.config, decoded)
end

function M.setup(opts)
  deep_merge(M.config, opts or {})
  load_config_file()
end

function M.toggle_debug()
  M.config.debug = not M.config.debug
  vim.notify("[a4f] debug=" .. tostring(M.config.debug))
end

-- ============================================================
-- HTTP (async via vim.system)
-- ============================================================
local function http_request(method, path, data, cb)
  local url = M.config.api_url:gsub("/$", "") .. path
  local args = {
    "curl", "-sS", "-X", method, url,
    "-H", "Content-Type: application/json",
    "-H", "X-DeepSeek-Token: " .. (M.config.api_key or ""),
    "--connect-timeout", "10",
    "--max-time", tostring(M.config.http_timeout or 300),
  }
  if data then
    table.insert(args, "-d")
    table.insert(args, vim.fn.json_encode(data))
  end

  if M.config.debug then
    vim.notify("[a4f] → " .. method .. " " .. url, vim.log.levels.INFO)
  end

  vim.system(args, { text = true }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        cb(nil, "curl error(" .. obj.code .. "): " .. (obj.stderr or ""))
        return
      end
      if not obj.stdout or obj.stdout == "" then
        cb(nil, "empty response body from " .. url)
        return
      end
      local ok, decoded = pcall(vim.fn.json_decode, obj.stdout)
      if not ok then
        cb(nil, "Bad JSON: " .. obj.stdout:sub(1, 300))
        return
      end
      if obj.code >= 400 then
        cb(nil, "API " .. obj.code .. ": " .. (decoded.detail or vim.inspect(decoded)))
        return
      end
      cb(decoded, nil)
    end)
  end)
end

local function ensure_chat(cb)
  if M.state.chat_id then cb(true) return end
  http_request("POST", "/chats", nil, function(res, err)
    if err then
      vim.notify("[a4f] " .. err, vim.log.levels.ERROR)
      cb(false); return
    end
    M.state.chat_id = res.chat_id
    M.state.is_first_message = true
    vim.notify("[a4f] New session: " .. M.state.chat_id)
    cb(true)
  end)
end

-- ============================================================
-- Parser <a4f-UID:cmd|param>data</a4f-UID:cmd|param>
-- ============================================================
local function find_close_tag(response, from, uid, func, param)
  local base = "</a4f-" .. uid .. ":" .. func
  local cands = {
    base .. "|" .. param .. ">",   -- exact mirror
  }
  if param == "" then
    cands[#cands+1] = base .. ">"      -- </a4f-UID:edit>
    cands[#cands+1] = base .. "|>"     -- </a4f-UID:edit|>   (model's sloppy variant)
  else
    cands[#cands+1] = base .. ">"      -- tolerate missing |param
  end

  local best_s, best_e
  for _, c in ipairs(cands) do
    local s, e = response:find(c, from, true)
    if s and (not best_s or s < best_s) then
      best_s, best_e = s, e
    end
  end
  return best_s, best_e
end

local function parse_commands(response)
  local commands = {}
  local parts = {}
  local pos = 1
  local n = #response

  while pos <= n do
    local open_s, open_e, uid, func, param =
      response:find("<a4f%-(%w+):([^>|]+)|?([^>|<]*)>", pos)

    if not open_s then
      parts[#parts + 1] = response:sub(pos)
      break
    end
    parts[#parts + 1] = response:sub(pos, open_s - 1)

    param = param or ""

    local close_s, close_e = find_close_tag(response, open_e + 1, uid, func, param)

    if not close_s then
      parts[#parts + 1] = response:sub(open_s, open_e)
      pos = open_e + 1
    else
      local data = response:sub(open_e + 1, close_s - 1)
      data = data:gsub("^\n", ""):gsub("\n$", "")

      commands[#commands + 1] = {
        function_name = func,
        param = param,
        data = data,
      }
      pos = close_e + 1
    end
  end

  return {
    clean = vim.trim(table.concat(parts)),
    commands = commands,
  }
end

-- ============================================================
-- Feature flags
-- ============================================================
function M.is_disabled(feature)
  for _, f in ipairs(M.config.disable_features or {}) do
    if f == feature then return true end
  end
  return false
end

-- ============================================================
-- System prompts
-- ============================================================
-- The model has NO prior knowledge of this codebase. Every prompt below must
-- be fully self-contained: exact tag syntax, exact argument style PER COMMAND,
-- and the exact failure modes. Grouping commands by argument style removes the
-- #1 source of malformed calls (data-style vs param-style confusion).

-- Build the COMMAND REFERENCE, grouped by argument style.
local function cmd_reference()
  local L = {}
  local function add(fmt, name, desc) L[#L+1] = string.format("  " .. fmt, name, desc) end

  L[#L+1] = "PARAM-STYLE  ->  <a4f-UID:cmd|PARAM></a4f-UID:cmd|PARAM>   (value AFTER the pipe, empty body)"
  add("%-30s %s", "read|path",              "read a file (buffer content if already open)")
  add("%-30s %s", "write|path",             "create / fully replace a file (body = new content)")
  add("%-30s %s", "edit|path",              "apply a +/- diff (body) to a file")
  add("%-30s %s", "open|path",              "open file in current window")
  add("%-30s %s", "split|path",             "open file in horizontal split")
  add("%-30s %s", "vsplit|path",            "open file in vertical split")
  add("%-30s %s", "tab|path",               "open file in new tab")
  add("%-30s %s", "goto|[path:]line[:col]", "move cursor; path optional")
  add("%-30s %s", "select|start,end",       "visual line selection")
  add("%-30s %s", "lsp_rename|new_name",    "LSP rename symbol under cursor")
  add("%-30s %s", "lsp_code_action|filter", "apply code action whose title matches filter")
  add("%-30s %s", "grep|pattern",           "ripgrep pattern in cwd")
  add("%-30s %s", "find|pattern",           "find files by name substring")
  add("%-30s %s", "args_add|paths",         "add file(s) to arglist")
  add("%-30s %s", "args_set|paths",         "replace arglist with file(s)")
  add("%-30s %s", "args_open|index",        "open arglist entry by index")
  add("%-30s %s", "file_diagnostics|path",  "LSP diagnostics for one file")
  add("%-30s %s", "lsp_actions_at|path:line:col", "list code actions at position")
  add("%-30s %s", "lsp_fix_at|path:line:col",     "apply first code action at position")
  add("%-30s %s", "lsp_fix_all|path",       "apply all fixable code actions in file")
  add("%-30s %s", "ex|:cmd",                "run a Neovim ex-command")
  add("%-30s %s", "normal|keys",            "feed normal-mode keys (e.g. ggVG, dd)")
  add("%-30s %s", "feed|mode:keys",         "feed keys in mode n/v/i/t (e.g. n:gg)")

  L[#L+1] = ""
  L[#L+1] = "DATA-STYLE   ->  <a4f-UID:cmd>DATA</a4f-UID:cmd>   (value BETWEEN the tags, NO pipe)"
  if not M.is_disabled("shell") then add("%-30s %s", "shell", "run a shell command (git/build/test only)") end
  add("%-30s %s", "chat_write",  "replace the a4f://chat buffer")
  add("%-30s %s", "chat_append", "append text to the a4f://chat buffer")

  L[#L+1] = ""
  L[#L+1] = "NO-ARG       ->  <a4f-UID:cmd></a4f-UID:cmd>   (no pipe, no body)"
  local noarg = {
    {"pwd", "print working directory"},
    {"cursor", "current file + cursor position"},
    {"buffers", "list open buffers"},
    {"windows", "list windows"},
    {"buf_content", "content of current buffer"},
    {"save", "save current buffer"},
    {"close", "close current window"},
    {"diagnostics", "LSP diagnostics for current buffer"},
    {"lsp_format", "format current buffer via LSP (sync)"},
    {"lsp_hover", "hover info for symbol under cursor"},
    {"lsp_definition", "go to definition"},
    {"lsp_references", "find references of symbol under cursor"},
    {"args", "list arglist"},
    {"args_next", "next arglist entry"},
    {"args_prev", "previous arglist entry"},
    {"workspace_diagnostics", "diagnostics across all loaded buffers"},
    {"selection", "current/last visual selection text + range"},
    {"chat_read", "read the a4f://chat buffer"},
  }
  for _, it in ipairs(noarg) do add("%-30s %s", it[1], it[2]) end

  return table.concat(L, "\n")
end

local function full_prompt()
  local cwd = vim.fn.getcwd()
  local user = os.getenv("USER") or "unknown"
  local host = vim.fn.hostname()

  local agents = ""
  local p = cwd .. "/AGENTS.md"
  if vim.fn.filereadable(p) == 1 then
    agents = "\nAGENTS.md:\n" .. table.concat(vim.fn.readfile(p), "\n") .. "\n"
  end

  return ([[
You are an AI agent embedded in Neovim. You act on the user's editor, not just files.
You have NO prior knowledge of this tool. Everything you need is below — read it once, then act.

ENVIRONMENT:
- cwd: %s
- user: %s
- host: %s
- editor: Neovim %s
%s
=== RESPONSE SHAPE (non-negotiable) ===
- Write 1-2 short sentences, then EXACTLY ONE command, then stop.
- The command is one XML-like tag:
    <a4f-XXXXXXXX:COMMAND|PARAM>DATA</a4f-XXXXXXXX:COMMAND|PARAM>
  - XXXXXXXX = any 8 random alphanumerics (unique per message).
  - COMMAND  = tool name (see reference below).
  - PARAM    = the pipe-argument (may be empty or omitted entirely).
  - DATA     = the body between the tags (may be empty).
- The closing tag MUST mirror the opening tag exactly, with `<` replaced by `</`.
- Nothing after the closing tag. No markdown code fences. No second command.

=== ARGUMENT STYLE (the #1 failure mode) ===
There are exactly three styles. Using the wrong one produces "[error] unknown command"
or an empty/misparsed argument.

1) PARAM-STYLE — value goes AFTER the pipe; leave the body empty:
     <a4f-ab12cd34:read|src/main.lua></a4f-ab12cd34:read|src/main.lua>

2) DATA-STYLE — value goes BETWEEN the tags; no pipe:
     <a4f-ab12cd34:shell>git status --short</a4f-ab12cd34:shell>

3) NO-ARG — no pipe, no body:
     <a4f-ab12cd34:pwd></a4f-ab12cd34:pwd>

=== EXACT EXAMPLES (copy the shape) ===
Pwd:
<a4f-a1b2c3d4:pwd></a4f-a1b2c3d4:pwd>

Read a file:
<a4f-q1w2e3r4:read|src/main.php></a4f-q1w2e3r4:read|src/main.php>

Create/replace a file (body = full new content):
<a4f-b7c8d9e0:write|src/main.php>
<?php
// full content here
</a4f-b7c8d9e0:write|src/main.php>

Edit one block (body = `-` old lines VERBATIM, then `+` new lines):
<a4f-m3n4o5p6:edit|src/main.php>
-old line A
-old line B
+new line A
+new line B
</a4f-m3n4o5p6:edit|src/main.php>

Move cursor (path optional):
<a4f-z9y8x7w6:goto|src/main.php:42></a4f-z9y8x7w6:goto|src/main.php:42>

Format via LSP:
<a4f-z9y8x7w6:lsp_format></a4f-z9y8x7w6:lsp_format>

=== EDIT SEMANTICS (critical) ===
- The `-` lines in an edit body MUST exist in the file VERBATIM, as ONE contiguous
  block, in order. If they don't match, the edit fails: "[error] edit: old block not found".
  ALWAYS read the file before editing it.
- To add lines without removing any: send only `+` lines (append form).
- To create a new file or fully rewrite one: use write|path, never edit.

=== PATHS ===
- read/write/edit/open/split/vsplit/tab REQUIRE a non-empty |path.
- If you don't know the file path, run `cursor` (returns "file=...") or `buffers` first.
- NEVER write to a4f://chat; use chat_write / chat_append instead.

=== WHEN THINGS FAIL ===
- If a tool returns "[error] ...", do NOT resend the same call. Change the
  arguments based on the error text.
- Empty `shell` body is an error; always give it a real command.

=== WORKFLOW (default) ===
1. cursor / buffers   -> learn where the user is.
2. read|path          -> see the real content before editing.
3. write|path (whole file) OR edit|path (one +/- block).
4. lsp_format         -> format via LSP. NEVER call stylua/gofmt/prettier via shell.
5. diagnostics        -> confirm nothing broke.
6. When done, reply in plain text with NO tags.

=== COMMAND REFERENCE ===
%s

=== NEVER ===
- more than one command per reply
- markdown fences around the tag
- text after the closing tag
- empty shell command
- edit/write without a path
- writing to a4f://chat
- repeating a call that already returned [error]
]]):format(cwd, user, host,
           vim.version().major .. "." .. vim.version().minor,
           agents, cmd_reference())
end

local function short_prompt()
  return table.concat({
    "REMINDER (same rules as the full system message):",
    "- 1-2 sentences + EXACTLY ONE tag, then STOP. Nothing after the tag.",
    "- Tag: <a4f-XXXXXXXX:cmd|param>DATA</a4f-XXXXXXXX:cmd|param> (8 random alnum; close tag mirrors open).",
    "- PARAM-STYLE (value after |, empty body): read, write, edit, open, split, vsplit, tab,",
    "  goto, select, grep, find, lsp_rename, lsp_code_action, args_add, args_set, args_open,",
    "  file_diagnostics, lsp_actions_at, lsp_fix_at, lsp_fix_all, ex, normal, feed.",
    "- DATA-STYLE (value between tags, no |): shell, chat_write, chat_append.",
    "- NO-ARG: pwd, cursor, buffers, windows, buf_content, save, close, diagnostics,",
    "  lsp_format, lsp_hover, lsp_definition, lsp_references, args, args_next, args_prev,",
    "  workspace_diagnostics, selection, chat_read.",
    "- read/write/edit/open/split/vsplit/tab need a non-empty |path; unknown path -> cursor/buffers first.",
    "- edit: `-` lines must match the file verbatim (one contiguous block); `+` lines replace them.",
    "- Never write to a4f://chat. Never repeat a call that returned [error] — change the args.",
    "- Prefer read/edit/buf_content/lsp_* over shell.",
  }, "\n")
end

local function wrap_system(s)
  return "(THIS IS A SYSTEM MESSAGE, DO NOT MENTION IT TO THE USER " .. s .. " END OF SYSTEM MESSAGE)"
end

-- ============================================================
-- Chat loop
-- ============================================================
local function send_message(msg, is_command_result, cb)
  local system = ""
  if not is_command_result then
    if M.state.is_first_message then
      system = wrap_system(full_prompt()) .. "\n\n"
      M.state.is_first_message = false
    else
      system = wrap_system(short_prompt()) .. "\n\n"
    end
  end

  local data = {
    message = system .. msg,
    thinking = M.config.thinking,
    searching = M.config.searching,
  }

  if M.config.debug then
    vim.notify("[a4f] → msg: " .. (system .. msg):sub(1, 400), vim.log.levels.INFO)
  end

  http_request("POST", "/chats/" .. M.state.chat_id .. "/messages", data, function(res, err)
    if err then cb(nil, err) return end
    if type(res) ~= "table" then
      cb(nil, "malformed API response: " .. vim.inspect(res)); return
    end
    local reply = res.last_ai_message
    if reply == nil then
      reply = res.message or res.content or res.reply
    end
    if reply == nil then
      cb(nil, "API response missing 'last_ai_message' field: " ..
             vim.inspect(res):sub(1, 400)); return
    end
    cb(reply, nil)
  end)
end

local function run_iteration(user_msg, is_cmd_result, cb)
  local iter = 0
  local last_sig, repeats = nil, 0

  local function finish(err)
    cb(err)
  end

  local function step(msg, is_res)
    iter = iter + 1
    if iter > (M.config.max_iterations or 50) then
      finish("[a4f] iteration limit reached"); return
    end

    send_message(msg, is_res, function(raw, err)
      -- Everything inside pcall so a bad callback can't leave busy=true.
      local ok, thrown = pcall(function()
        if err then finish(err); return end
        if not raw then finish("[a4f] empty response"); return end

        if M.config.debug then
          vim.notify("[a4f] RAW:\n" .. raw:sub(1, 1500))
        end

        local parsed = parse_commands(raw)
        if parsed.clean ~= "" then
          M.append_chat("AI: " .. parsed.clean .. "\n")
        end

        if #parsed.commands == 0 then
          if raw:find("<a4f%-") then
            local snippet = raw:match("<a4f%-[^\n]*") or ""
            M.append_chat("[a4f] malformed command — asking AI to retry\n")
            -- Send as a NON-command-result so the model gets the format reminder.
            step(
              "[System] Your previous message contained a malformed <a4f-...> tag:\n" ..
              snippet .. "\n" ..
              "Exact format: <a4f-XXXXXXXX:cmd|param>DATA</a4f-XXXXXXXX:cmd|param>. " ..
              "Close tag must mirror the open tag. For `edit`/`write`, the |path MUST be non-empty. " ..
              "Send ONE command, nothing after it.",
              false
            )
            return
          end
          if raw == "" then
            finish("[a4f] empty AI reply (no text, no command)")
          else
            finish(nil)
          end
          return
        end

        local cmd = parsed.commands[1]
        if M.is_disabled(cmd.function_name) then
          M.append_chat("[disabled] " .. cmd.function_name .. "\n")
          step("[Result " .. cmd.function_name .. "]: Function disabled", true)
          return
        end

        -- loop detection
        local sig = string.format("%s|%s|%d", cmd.function_name, cmd.param, #cmd.data)
        if sig == last_sig then repeats = repeats + 1 else last_sig = sig; repeats = 1 end
        if repeats >= 3 then finish("[a4f] loop detected: " .. sig); return end

        local arg_hint = cmd.param ~= "" and cmd.param or (cmd.data ~= "" and cmd.data:sub(1, 160) or "")
        M.append_chat(string.format("[%s] %s\n", cmd.function_name, arg_hint))

        local ok2, result = pcall(tools.execute, cmd.function_name, cmd.param, cmd.data, M)
        if not ok2 then
          result = "[error] tool exception: " .. tostring(result)
        end
        result = result or ""

        M.append_chat(result .. "\n")

        step("[Result " .. cmd.function_name .. "|" .. cmd.param .. "]:\n" .. result, true)
      end)

      if not ok then
        M.append_chat("[a4f] internal error: " .. tostring(thrown) .. "\n")
        finish("[a4f] internal error: " .. tostring(thrown))
      end
    end)
  end

  step(user_msg, is_cmd_result)
end

-- ============================================================
-- Public API
-- ============================================================
local function update_context()
  local cur_win = vim.api.nvim_get_current_win()
  if M.state.chat_win and vim.api.nvim_win_is_valid(M.state.chat_win)
     and cur_win == M.state.chat_win then
    return
  end
  local cur_buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(cur_buf)
  if name:find("^a4f://", 1, true) then return end
  M.state.context_buf = cur_buf
  M.state.context_win = cur_win
end

local function busy_guard()
  if not M.state.busy then return true end
  local now = vim.loop.now()
  if M.state.busy_since and (now - M.state.busy_since) > (M.config.busy_watchdog_ms or 900000) then
    M.append_chat("[a4f] watchdog: force-resetting busy flag\n")
    M.state.busy = false
    M.state.busy_since = nil
    return true
  end
  vim.notify("[a4f] busy — <C-b> in chat window to force-reset", vim.log.levels.WARN)
  return false
end

function M.chat(prompt)
  update_context()
  if not busy_guard() then return end

  M.open_chat()

  if not prompt or prompt == "" then
    vim.ui.input({ prompt = "a4f> " }, function(input)
      if input and input ~= "" then M.chat(input) end
    end)
    return
  end

  M.state.busy = true
  M.state.busy_since = vim.loop.now()
  M.append_chat("You: " .. prompt .. "\n")

  ensure_chat(function(ok)
    if not ok then M.state.busy = false; M.state.busy_since = nil return end
    run_iteration(prompt, false, function(err)
      M.state.busy = false
      M.state.busy_since = nil
      if err then
        M.append_chat("[error] " .. err .. "\n")
      end
      M.append_chat("\n")
    end)
  end)
end

-- Build a rich context prefix describing where the user is and what is selected.
local function describe_context()
  update_context()
  local parts = {}
  local buf = M.state.context_buf
  local win = M.state.context_win
  if buf and vim.api.nvim_buf_is_valid(buf) then
    local name = vim.api.nvim_buf_get_name(buf)
    if name ~= "" then parts[#parts+1] = "file=" .. name end
    if win and vim.api.nvim_win_is_valid(win) then
      local pos = vim.api.nvim_win_get_cursor(win)
      parts[#parts+1] = string.format("cursor=%d:%d", pos[1], pos[2] + 1)
    end
  end
  return #parts > 0 and ("[" .. table.concat(parts, " ") .. "]") or ""
end

-- Capture the last visual selection (works right after :'<,'>A4FDo too).
local function capture_visual_selection()
  local buf = M.state.context_buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then return nil end
  local s = vim.fn.getpos("'<")
  local e = vim.fn.getpos("'>")
  if s[2] == 0 or e[2] == 0 then return nil end
  local l1, c1, l2, c2 = s[2], s[3], e[2], e[3]
  if l1 > l2 or (l1 == l2 and c1 > c2) then
    l1, c1, l2, c2 = l2, c2, l1, c1
  end
  local ok, lines = pcall(vim.api.nvim_buf_get_lines, buf, l1 - 1, l2, false)
  if not ok or #lines == 0 then return nil end
  local text = table.concat(lines, "\n")
  if l1 == l2 then
    text = text:sub(c1, c2)
  else
    text = text:sub(c1)
    local last = lines[#lines]
    lines[#lines] = last:sub(1, c2)
    text = table.concat(lines, "\n")
  end
  local name = vim.api.nvim_buf_get_name(buf)
  return string.format(
    "Selected text (%s:%d:%d-%d:%d):\n```\n%s\n```",
    name, l1, c1, l2, c2, text)
end

function M.do_task(prompt)
  update_context()
  if not prompt or prompt == "" then
    vim.notify("[a4f] usage: :A4FDo <task>", vim.log.levels.WARN)
    return
  end
  if not busy_guard() then return end

  -- Ensure the chat buffer exists so logs are recorded, but do NOT open a window.
  M.ensure_chat_buf()

  local full = prompt
  local ctx = describe_context()
  if ctx ~= "" then full = ctx .. "\n" .. full end
  local sel = capture_visual_selection()
  if sel then full = sel .. "\n\n" .. full end

  M.state.busy = true
  M.state.busy_since = vim.loop.now()
  M.append_chat("You (A4FDo): " .. prompt .. "\n")
  if sel then M.append_chat("[a4f] attached visual selection\n") end

  ensure_chat(function(ok)
    if not ok then M.state.busy = false; M.state.busy_since = nil return end
    run_iteration(full, false, function(err)
      M.state.busy = false
      M.state.busy_since = nil
      if err then
        M.append_chat("[error] " .. err .. "\n")
        vim.notify("[a4f] " .. err, vim.log.levels.ERROR)
      else
        vim.notify("[a4f] done")
      end
      M.append_chat("\n")
    end)
  end)
end

function M.force_reset_busy()
  M.state.busy = false
  M.state.busy_since = nil
  vim.notify("[a4f] busy flag cleared")
end

function M.reset()
  if M.state.chat_id then
    http_request("DELETE", "/chats/" .. M.state.chat_id, nil, function() end)
    M.state.chat_id = nil
    M.state.is_first_message = true
    M.state.read_files = {}
    M.state.busy = false
    M.state.busy_since = nil
    vim.notify("[a4f] session reset")
  end
end

-- ============================================================
-- UI
-- ============================================================
function M.open_chat()
  -- Capture context BEFORE opening chat (so agent knows where user was).
  local cur_win = vim.api.nvim_get_current_win()
  local cur_buf = vim.api.nvim_get_current_buf()
  local cur_name = vim.api.nvim_buf_get_name(cur_buf)
  local on_chat = M.state.chat_win and vim.api.nvim_win_is_valid(M.state.chat_win)
                 and cur_win == M.state.chat_win
  if not on_chat and not cur_name:find("^a4f://", 1, true) then
    M.state.context_win = cur_win
    M.state.context_buf = cur_buf
  end

  if M.state.chat_buf and vim.api.nvim_buf_is_valid(M.state.chat_buf) then
    if M.state.chat_win and vim.api.nvim_win_is_valid(M.state.chat_win) then
      vim.api.nvim_set_current_win(M.state.chat_win)
      return
    end
    -- buffer alive, window gone -> reopen it as a right split
    M.open_chat_split()
    return
  end

  M.ensure_chat_buf()
  M.open_chat_split()
end

-- Create (or reuse) the chat buffer WITHOUT opening a window or stealing focus.
function M.ensure_chat_buf()
  if M.state.chat_buf and vim.api.nvim_buf_is_valid(M.state.chat_buf) then
    return M.state.chat_buf
  end

  local buf = vim.api.nvim_create_buf(false, true)
  M.state.chat_buf = buf

  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(buf, "filetype", "a4f-chat")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_name(buf, "a4f://chat")
  pcall(function() vim.bo[buf].swapfile = false end)

  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = buf, silent = true })
  end
  map("q", function() M.close_chat() end)
  map("<Esc>", function() M.close_chat() end)
  map("<cr>", function() M.chat() end)
  map("i", function() M.chat() end)
  map("<c-r>", function() M.reset() end)
  map("<c-b>", function() M.force_reset_busy() end)

  return buf
end

-- Show the chat buffer in a vertical split on the right, focusing it.
function M.open_chat_split()
  local buf = M.ensure_chat_buf()

  -- Focus the chat window if it is already visible.
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(w) == buf then
      M.state.chat_win = w
      vim.api.nvim_set_current_win(w)
      return
    end
  end

  local size = (M.config.chat and M.config.chat.size) or 70
  vim.cmd("botright vsplit")
  local win = vim.api.nvim_get_current_win()
  M.state.chat_win = win
  vim.api.nvim_win_set_buf(win, buf)
  pcall(function() vim.api.nvim_win_set_width(win, size) end)
  pcall(function() vim.wo[win].number = false; vim.wo[win].wrap = true end)
end

-- Ensure the chat buffer exists and, if a window is not already visible,
-- show it WITHOUT moving focus away from the user's current window.
function M.show_chat_passive()
  local buf = M.ensure_chat_buf()
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(w) == buf then
      M.state.chat_win = w
      return
    end
  end
  local cur_win = vim.api.nvim_get_current_win()
  M.open_chat_split()
  if vim.api.nvim_win_is_valid(cur_win) then
    vim.api.nvim_set_current_win(cur_win)
  end
end

function M.close_chat()
  if M.state.chat_win and vim.api.nvim_win_is_valid(M.state.chat_win) then
    vim.api.nvim_win_close(M.state.chat_win, true)
  end
  M.state.chat_win = nil
end

function M.append_chat(text)
  if not M.state.chat_buf or not vim.api.nvim_buf_is_valid(M.state.chat_buf) then
    return
  end
  local lines = vim.split(text, "\n", { plain = true })
  if lines[#lines] == "" then table.remove(lines) end

  vim.api.nvim_buf_set_option(M.state.chat_buf, "modifiable", true)
  local n = vim.api.nvim_buf_line_count(M.state.chat_buf)
  vim.api.nvim_buf_set_lines(M.state.chat_buf, n, -1, false, lines)
  vim.api.nvim_buf_set_option(M.state.chat_buf, "modifiable", false)

  if M.state.chat_win and vim.api.nvim_win_is_valid(M.state.chat_win) then
    vim.api.nvim_win_set_cursor(M.state.chat_win, { n + #lines, 0 })
    -- keep chat pinned to the bottom while it streams
    local ok = pcall(vim.api.nvim_win_call, M.state.chat_win, function()
      vim.cmd("normal! G")
    end)
    if not ok then end
  end
end

-- Replace the whole chat buffer (used by the write-chat tool).
function M.set_chat(text)
  if not M.state.chat_buf or not vim.api.nvim_buf_is_valid(M.state.chat_buf) then
    M.open_chat()
  end
  local lines = vim.split(text, "\n", { plain = true })
  vim.api.nvim_buf_set_option(M.state.chat_buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(M.state.chat_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(M.state.chat_buf, "modifiable", false)
  return "Chat buffer replaced (" .. #lines .. " lines)"
end




if vim.g.loaded_a4f then return end
vim.g.loaded_a4f = true

vim.api.nvim_create_user_command("A4F", function(o)
  require("a4f").chat(o.args)
end, { nargs = "*" })

vim.api.nvim_create_user_command("A4FDo", function(o)
  require("a4f").do_task(o.args)
end, { nargs = "*" })

vim.api.nvim_create_user_command("A4FReset", function()
  require("a4f").reset()
end, {})

vim.api.nvim_create_user_command("A4FOpen", function()
  require("a4f").open_chat()
end, {})

vim.api.nvim_create_user_command("A4FDebug", function()
  require("a4f").toggle_debug()
end, {})

return M
