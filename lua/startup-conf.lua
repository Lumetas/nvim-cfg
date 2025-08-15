require('startup').setup({
  -- Секция 1: Заголовок и приветствие
  section_1 = {
    type = "text",
    align = "center",
    fold_section = false,
    title = "Welcome",
    margin = 0,
    content = {
	"██╗     ██╗   ██╗███╗   ███╗███████╗████████╗ █████╗ ███████╗",
	"██║     ██║   ██║████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██╔════╝",
	"██║     ██║   ██║██╔████╔██║█████╗     ██║   ███████║███████╗",
	"██║     ██║   ██║██║╚██╔╝██║██╔══╝     ██║   ██╔══██║╚════██║",
	"███████╗╚██████╔╝██║ ╚═╝ ██║███████╗   ██║   ██║  ██║███████║",
	"╚══════╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝",
      "",
    },
    highlight = "Title",
    default_color = "#56B6C2",
  },

  section_2 = {
    type = "mapping",
    align = "center",
    fold_section = false,
    title = "Commands",
    margin = 5,
    content = {
      {"  Lum Projects", "LumProjectsTelescope", "fg"},
      {"  File Browser", "Yazi", "fb"},
      {"  Keymaps", "Telescope keymaps", "fk"},
    },
    highlight = "String",
    default_color = "#E5C07B",
  },

  -- Настройки
  options = {
    mapping_keys = true,
    cursor_column = 0.5,
    after = function()
      -- Автоматически закрывать ненужные буферы при открытии файла
      vim.cmd [[ autocmd User StartupLoaded ++once lua require('startup').delete_buffer() ]]
    end,
    empty_lines_between_mappings = true,
    disable_statuslines = true,
    paddings = { 2, 2, 2 }, -- Отступы перед каждой секцией
  },

  -- Клавиши для взаимодействия
  mappings = {
    execute_command = "<CR>",
    open_file = "o",
    open_file_split = "<c-o>",
    open_section = "<TAB>",
    open_help = "?",
  },

  -- Цвета
  colors = {
    background = "#1f2227",
    folded_section = "#56b6c2",
  },

  -- Порядок секций
  parts = { "section_1", "section_2" },
})
