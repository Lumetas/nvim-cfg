require("nvim-tree").setup({
  git = {
    enable = true,
    timeout = 400,
  },
  filesystem_watchers = {
    enable = false,  -- ускоряет работу, но требует ручного обновления (клавиша `R`)
  },
  renderer = {
    group_empty = true,  -- схлопывать пустые папки
    indent_markers = {
      enable = true,
    },
  },
  actions = {
    change_dir = {
      global = false,  -- не менять корневую папку без указания
    },
    open_file = {
      quit_on_open = false,
    },
  },
})
