-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2

vim.opt.relativenumber = true
vim.opt.number = true

vim.opt.colorcolumn = "80"
vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.wrap = true

-- conform owns TypeScript formatting; the ESLint LSP must not register a second formatter
vim.g.lazyvim_eslint_auto_format = false

-- Prettier is the fallback when no oxfmt/biome marker exists
vim.g.lazyvim_prettier_needs_config = false
