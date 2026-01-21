local function bootstrap_lnpm()
	local lnpm_path = vim.fn.stdpath('config') .. '/pack/plugin/start/lnpm.nvim'

	if vim.fn.isdirectory(lnpm_path) == 0 then
		vim.notify('Installing LNPM...', vim.log.levels.INFO)
		vim.fn.mkdir(vim.fn.stdpath('config') .. '/pack/plugin/start', 'p')

		-- Используем vim.system для тихой установки
		local result = vim.system({
			'git',
			'clone',
			'--depth', '1',
			'--quiet',
			'https://github.com/lumetas/lnpm.nvim.git',
			lnpm_path
		}):wait()

		if result.code == 0 then
			return true
		else
			vim.notify('✗ Failed to install LNPM', vim.log.levels.ERROR)
			return false
		end
	end

	return false
end

if bootstrap_lnpm() then
	vim.cmd('silent! packadd lnpm.nvim')
end
