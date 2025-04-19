-- Команда для форматирования кода
vim.api.nvim_create_user_command('Format', function()
    -- Устанавливаем метку 'b' на текущей строке
    vim.cmd('normal mbgg=G`b')
end, {})

-- Автоматическое обновление древа NERDTree при смене директории
vim.api.nvim_create_augroup('NERDTreeAutoUpdate', { clear = true })
vim.api.nvim_create_autocmd('DirChanged', {
  group = 'NERDTreeAutoUpdate',
  pattern = '*',
  callback = function()
    vim.cmd('NERDTreeCWD')
  end,
})


vim.api.nvim_create_user_command(
  'ClearWIN',
  function()
    vim.cmd([[%s/\r//g]])  -- выполняем замену
    print("Удалены все ^M (CR) из файла")
  end,
  { desc = "Remove all Windows CR (^M) characters" }
)
