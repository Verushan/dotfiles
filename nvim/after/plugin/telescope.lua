local keymap = vim.keymap.set
local builtin = require('telescope.builtin')

keymap('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
keymap('n', '<leader>fg', builtin.git_files, { desc = 'Telescope find in git files' })
keymap('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
keymap('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
keymap('n', '<leader>lg', function() 
	builtin.grep_string( {search = vim.fn.input("Grep > ") }); 
end)
