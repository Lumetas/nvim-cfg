-- Проверяем путь к бинарнику (должен быть задан в vim.g.markdown_bin)
local bin_path = vim.g.markdown_bin
if not bin_path then
    print("Error: vim.g.markdown_bin not set")
    return
end

local pid = nil
local function run_and_kill_on_exit(command)
  local handle = vim.loop.spawn("php", {
    args = {command},
    stdio = {nil, nil, nil},
  }, function(_, _)
    if handle then handle:close() end
  end)
  pid = handle.pid

  -- Убиваем процесс при выходе из Neovim
  vim.api.nvim_create_autocmd("VimLeave", {
    callback = function()
      if pid then
        vim.loop.kill(pid, 9)  -- SIGKILL
      end
    end,
  })
end
run_and_kill_on_exit(bin_path)
-- Команда :MD для открытия в браузере
vim.api.nvim_create_user_command("MD", function()
    local filepath = vim.fn.expand("%:p")  -- абсолютный путь к файлу
    if filepath == "" then
        print("No file opened")
        return
    end

    local url = "http://localhost:8365?file=" .. vim.fn.escape(filepath, " \\#%?")  -- экранируем спецсимволы

    -- Открываем URL в браузере (кросс-платформенно)
    local cmd
    if vim.fn.has('win32') == 1 then
        cmd = "start " .. url
    elseif vim.fn.has('macunix') == 1 then
        cmd = "open " .. url
    else
        cmd = "xdg-open " .. url
    end

    os.execute(cmd)  -- выполняем команду
end, {})
