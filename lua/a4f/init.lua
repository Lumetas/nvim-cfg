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
local function cmd_list()
  local list = {}
  if not M.is_disabled("shell") then list[#list+1] = "shell - run shell command (data-style)" end
  if not M.is_disabled("read")  then list[#list+1] = "read|path - read file (uses buffer if open)" end
  if not M.is_disabled("write") then list[#list+1] = "write|path - write file (uses buffer if open)" end
  if not M.is_disabled("edit")  then list[#list+1] = "edit|path - edit file (diff lines in data)" end
  list[#list+1] = "open|path - open file in current window"
  list[#list+1] = "split|path - horizontal split"
  list[#list+1] = "vsplit|path - vertical split"
  list[#list+1] = "tab|path - new tab"
  list[#list+1] = "close - close current window"
  list[#list+1] = "save - save current buffer"
  list[#list+1] = "buffers - list open buffers"
  list[#list+1] = "buf_content - current buffer content"
  list[#list+1] = "goto|line:col - move cursor"
  list[#list+1] = "select|start,end - visual line selection"
  list[#list+1] = "cursor - current cursor/file info"
  list[#list+1] = "pwd - print working directory"
  list[#list+1] = "grep|pattern - ripgrep in cwd (or data)"
  list[#list+1] = "find|pattern - find files by name (or data)"
  list[#list+1] = "diagnostics - LSP diagnostics for current buffer"
  list[#list+1] = "windows - list windows"
  list[#list+1] = "lsp_format - format current buffer via LSP (sync)"
  list[#list+1] = "lsp_rename|new_name - rename symbol under cursor via LSP"
  list[#list+1] = "lsp_code_action|filter - apply code action (e.g. organize imports)"
  list[#list+1] = "lsp_hover - hover info for symbol under cursor"
  list[#list+1] = "lsp_definition - go to definition, returns location"
  list[#list+1] = "lsp_references - find references of symbol under cursor"
  list[#list+1] = "args - list arglist"
  list[#list+1] = "args_add|paths - add file(s) to arglist (space/comma separated)"
  list[#list+1] = "args_set|paths - replace arglist with given file(s)"
  list[#list+1] = "args_next / args_prev - move through arglist"
  list[#list+1] = "args_open|index - open arglist entry by index"
  list[#list+1] = "workspace_diagnostics - diagnostics across all loaded buffers"
  list[#list+1] = "file_diagnostics|path - diagnostics for a specific file"
  list[#list+1] = "lsp_actions_at|path:line:col - list code actions at position"
  list[#list+1] = "lsp_fix_at|path:line:col - apply first code action at position"
  list[#list+1] = "lsp_fix_all|path - apply all fixable code actions in a file"
  list[#list+1] = "chat_read - read the a4f://chat buffer"
  list[#list+1] = "chat_write - replace the chat buffer (data)"
  list[#list+1] = "chat_append - append text to the chat buffer (data)"
  list[#list+1] = "ex|:cmd - run a Neovim ex-command (e.g. :e file, :bd, :set ...)"
  list[#list+1] = "normal|keys - feed normal-mode keys (e.g. ggVG, dd)"
  list[#list+1] = "feed|mode:keys - feed keys in mode n/v/i/t (e.g. n:gg)"
  list[#list+1] = "selection - current/last visual selection text + range"
  return table.concat(list, "\n")
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

ENVIRONMENT:
- cwd: %s
- user: %s
- host: %s
- editor: Neovim %s
%s
=== HARD RULES ===
- ONE command per response. NEVER more than one.
- 1-2 sentences of text, then ONE command block, then STOP.
- Never write text after closing tag.
- NEVER guess file content. Always read first.
- NEVER send an empty command. `shell` needs a non-empty command string.
- If a tool returns "[error] ...", do NOT repeat the same broken call — fix the args.

=== PATH RULES (VERY IMPORTANT) ===
- read, write, edit, open, split, vsplit, tab REQUIRE a |param (a path).
- NEVER emit <a4f-UID:edit|></a4f-UID:edit|> or <a4f-UID:write|> without a path.
- If you don't know the file path, FIRST call `cursor` (returns "file=...") or `buffers`.
- NEVER write to a4f://chat. That buffer is the chat itself; you cannot edit it.

=== EDIT SEMANTICS ===
- `edit` diff: (-) lines must EXIST VERBATIM in the file (one contiguous block).
  (+) lines replace them. If the (-) block is not found, the edit fails.
- To create a new file or replace a whole file: use `write` with full content.
- To append lines to an existing file: use `edit` with only (+) lines.

=== TOOL PRIORITY (highest first) ===
1. buf_content / read     -> inspect content
2. edit / write           -> modify content
3. open / split / vsplit / tab / goto / select / cursor / buffers / windows / pwd
4. lsp_format / lsp_rename / lsp_code_action / lsp_hover / lsp_definition / lsp_references / diagnostics
5. shell                  -> ONLY if no nvim equivalent (git, build, test)
   ls -> buffers/find ; cat -> read ; sed/awk edits -> edit ; formatters -> lsp_format

=== ARGUMENT STYLE ===
- data-style  (arg between tags): shell, grep, find, write, edit
- param-style (arg after `|`):   read, open, split, vsplit, tab, goto, select,
                                 lsp_rename, lsp_code_action

=== COMMAND FORMAT ===
<a4f-XXXXXXXX:COMMAND|PARAM>DATA</a4f-XXXXXXXX:COMMAND|PARAM>
XXXXXXXX = 8 random alnum chars.
Close tag = copy of the open tag with `<` replaced by `</`.
For data-style commands (shell, grep, find, write, edit), close tag has NO extra `|`.
For param-style commands, close tag repeats the |param.

=== EXAMPLES ===
Pwd:
<a4f-a1b2c3d4:pwd></a4f-a1b2c3d4:pwd>

Read file:
<a4f-q1w2e3r4:read|src/main.php></a4f-q1w2e3r4:read|src/main.php>

Create/replace file:
<a4f-b7c8d9e0:write|src/main.php>
<?php
// full content here
</a4f-b7c8d9e0:write|src/main.php>

Edit file (change one block):
<a4f-m3n4o5p6:edit|src/main.php>
-<?php
+<?php
+
+function bubbleSort(array $arr): array { /* ... */ }
</a4f-m3n4o5p6:edit|src/main.php>

Format via LSP (after edit):
<a4f-z9y8x7w6:lsp_format></a4f-z9y8x7w6:lsp_format>

=== REFACTOR WORKFLOW ===
1. cursor or buffers -> learn the current file path.
2. read|path         -> see the code.
3. write|path (whole file) OR edit|path (single -/+ block).
4. lsp_format        -> format via LSP. NEVER use stylua/gofmt/prettier via shell.
5. diagnostics       -> confirm nothing is broken.
6. Plain text answer, NO tags.

=== NEVER ===
- multiple commands
- markdown fences
- text after closing tag
- empty shell command
- edit/write without a path
- writing to a4f://chat
- repeating a call that returned [error]
]]):format(cwd, user, host, vim.version().major .. "." .. vim.version().minor, agents, cmd_list())
end

local function short_prompt()
  return table.concat({
    "REMINDER:",
    "- ONE command per response, 1-2 sentences, then ONE <a4f-XXXX:cmd|param>...</a4f-XXXX:cmd|param>, then STOP.",
    "- read/write/edit/open/split/tab REQUIRE a non-empty |path.",
    "- Never write to a4f://chat.",
    "- If a tool returned [error], do NOT repeat it — change the args.",
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
            step(
              "[System] Your previous message contained a malformed <a4f-...> tag:\n" ..
              snippet .. "\n" ..
              "Exact format: <a4f-XXXXXXXX:cmd|param>DATA</a4f-XXXXXXXX:cmd|param>. " ..
              "Close tag must mirror the open tag. For `edit`/`write`, the |path MUST be non-empty. " ..
              "Send ONE command, nothing after it.",
              true
            )
            return
          end
          finish(nil)
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

  -- Make sure the chat output is visible WITHOUT stealing focus.
  M.show_chat_passive()

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
