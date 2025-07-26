vim.opt.laststatus = 2

local icons = {
  git = " ",
  separator_right = "  ",
  separator_left = "  ",
  file = "  ",
  unix = " ",
  dos = " ",
  modified = "", 
  readonly = ""
}
-- ВСЁ ОСТАЛЬНОЕ БЕЗ ИЗМЕНЕНИЙ (ваш оригинальный код ниже)
local function get_git_branch()
  local handle = io.popen("git branch --show-current 2>/dev/null | tr -d '\n'")
  if not handle then return "" end
  local branch = handle:read("*a")
  handle:close()
  return branch ~= "" and icons.git .. branch or ""
end

vim.api.nvim_create_autocmd({"BufEnter", "BufWritePost", "FileChangedShellPost", "TextChanged", "TextChangedI" }, {
  pattern = "*",
  callback = function()
    local filetype = vim.bo.filetype ~= "" and vim.bo.filetype or "no ft"
    local fileformat = vim.bo.fileformat == "unix" and icons.unix or icons.dos

    vim.opt.statusline = table.concat({
      "%#StatusLine#",
      icons.file, "%f",
      vim.bo.modified and " " .. icons.modified or "", 
      vim.bo.readonly and " " .. icons.readonly or "",
      icons.separator_right,
      get_git_branch(),
      "%=",
      filetype, " ", fileformat,
      icons.separator_left,
      "%c",
      "%#StatusLineNC# "
    })
  end
})

vim.cmd([[
  highlight StatusLineGit guifg=#fab387 gui=bold
  highlight StatusLineModified guifg=#f38ba8
  highlight StatusLineReadonly guifg=#a6e3a1
]])
