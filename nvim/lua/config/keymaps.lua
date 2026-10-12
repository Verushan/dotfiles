local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

vim.g.mapleader = " "

keymap("i", "jk", "<Esc>", opts)

keymap("n", "<leader>e", ":Ex<CR>", opts)
keymap("n", "<leader>w", ":w<CR>", opts) -- Write to current buffer
keymap("n", "<leader>q", ":q<CR>", opts) -- Close current buffer
keymap("n", "<C-w>", ":xa<CR>", opts) -- Save and close all buffers
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)
