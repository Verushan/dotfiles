-- Basic Settings
vim.opt.number = true -- Show line numbers
vim.opt.signcolumn = "yes"
vim.opt.relativenumber = true -- Relative line numbers help with jumping
vim.opt.mouse = "a" -- Enable mouse support
vim.opt.termguicolors = true
vim.opt.ignorecase = true -- Case insensitive searching
vim.opt.smartcase = true -- ... unless uppercase is used
vim.opt.expandtab = true
vim.opt.tabstop = 4 -- Number of spaces that a <Tab> in the file counts for
vim.opt.shiftwidth = 4 -- Number of spaces to use for each step of indentation
vim.opt.softtabstop = 4 -- Number of spaces a <Tab> counts for when typing in Insert mode

-- The Transparency Fix
local groups = { "Normal", "NormalNC", "SignColumn", "EndOfBuffer", "MsgArea" }

for _, group in ipairs(groups) do
	vim.api.nvim_set_hl(0, group, { bg = "none", ctermbg = "none" })
end
