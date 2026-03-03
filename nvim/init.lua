-- ~/.config/nvim/init.lua

-- ── Options ─────────────────────────────────────────────────────────────────
vim.opt.number         = true          -- show line numbers
vim.opt.relativenumber = true          -- relative line numbers
vim.opt.expandtab      = true          -- spaces instead of tabs
vim.opt.tabstop        = 4
vim.opt.shiftwidth     = 4
vim.opt.smartindent    = true
vim.opt.wrap           = false
vim.opt.termguicolors  = true
vim.opt.ignorecase     = true
vim.opt.smartcase      = true
vim.opt.splitbelow     = true
vim.opt.splitright     = true
vim.opt.clipboard      = "unnamedplus" -- use system clipboard
vim.opt.scrolloff      = 8

-- ── Key mappings ────────────────────────────────────────────────────────────
vim.g.mapleader = " "

local map = vim.keymap.set
map("n", "<leader>w", "<cmd>w<cr>",  { desc = "Save" })
map("n", "<leader>q", "<cmd>q<cr>",  { desc = "Quit" })
map("n", "<leader>e", "<cmd>Ex<cr>", { desc = "File explorer" })

-- Move between windows with Ctrl+hjkl
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")
