-- Настройка UFO с учетом org-файлов
local function setup_ufo()
  require('ufo').setup({
    provider_selector = function(bufnr, filetype, buftype)
      if filetype == 'org' or filetype == 'startup' then
        return '' -- отключаем UFO для org-файлов
      end
      return {'treesitter', 'indent'} -- включаем для остальных
    end
  })
end

-- Автокоманда для включения UFO только для нужных типов файлов
vim.api.nvim_create_autocmd({'FileType'}, {
  pattern = {'php', 'markdown'},
  callback = function()
    vim.o.foldcolumn = '1'
    vim.o.foldlevel = 99
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true
    setup_ufo()
    
    -- Клавиши для управления сворачиванием
    vim.keymap.set('n', '<leader>zo', require('ufo').openAllFolds, { buffer = true })
    vim.keymap.set('n', '<leader>zc', require('ufo').closeAllFolds, { buffer = true })
  end
})

-- Для org-файлов используем другую настройку
vim.api.nvim_create_autocmd({'FileType'}, {
  pattern = {'org', 'startup'},
  callback = function()
    vim.o.foldcolumn = '1'
    vim.o.foldlevel = 99
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true
    -- Здесь могут быть специфичные настройки для orgmode
  end
})
