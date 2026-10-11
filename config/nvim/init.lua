-- LazyVim writes lazyvim.json next to init.lua by default, which is a
-- read-only store symlink under home-manager, so :LazyExtras would fail to
-- save. stdpath("data") stays writable.
vim.g.lazyvim_json = vim.fn.stdpath("data") .. "/lazyvim.json"

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
