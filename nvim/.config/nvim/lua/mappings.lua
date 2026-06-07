require "nvchad.mappings"

local map = vim.keymap.set
local del = vim.keymap.del

-- NvChad sets C-h/j/k/l to <C-w>h/j/k/l; remove so vim-tmux-navigator handles them
del("n", "<C-h>")
del("n", "<C-j>")
del("n", "<C-k>")
del("n", "<C-l>")

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("n", "<leader>cc", "<cmd>ClaudeCode<cr>", { desc = "Claude Code" })
-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
