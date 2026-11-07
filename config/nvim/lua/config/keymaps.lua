-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set

local function del(mode, lhs)
  pcall(vim.keymap.del, mode, lhs)
end

-- LazyVim uses these for the floating terminal; old config used them for comments.
del("n", "<C-/>")
del("n", "<C-_>")
del("t", "<C-/>")
del("t", "<C-_>")

map("n", "<C-/>", "<cmd>normal gcc<cr>", { desc = "Toggle comment line", silent = true })
map("n", "<C-_>", "<cmd>normal gcc<cr>", { desc = "Toggle comment line", silent = true })
map("v", "<C-/>", "<cmd>normal gc<cr>", { desc = "Toggle comment lines", silent = true })
map("v", "<C-_>", "<cmd>normal gc<cr>", { desc = "Toggle comment lines", silent = true })

map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })

map("x", "<leader>p", [["_dP]], { desc = "Paste over selection" })
-- Kept from old config. With nowait=true this blocks <leader>d* maps if DAP is installed later.
map({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete to black hole", silent = true, nowait = true })

-- vim-tmux-navigator is dropped. herdr CLI owns cross-pane focus.
local herdr_bin = vim.env.HERDR_BIN_PATH
if not herdr_bin or herdr_bin == "" then
  herdr_bin = "herdr"
end

local function herdr_focus(direction)
  if vim.fn.executable(herdr_bin) == 0 then
    return false
  end
  if not vim.env.HERDR_SOCKET_PATH or vim.env.HERDR_SOCKET_PATH == "" then
    return false
  end
  -- A tmux-backed pane has no CLI navigation here; do not jump out to herdr.
  if vim.env.TMUX and vim.env.TMUX ~= "" then
    return false
  end
  vim.system({ herdr_bin, "pane", "focus", "--direction", direction }, { detach = true })
  return true
end

-- Move inside nvim first; only cross to herdr at the window edge.
local function nvim_move(key)
  local before = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. key)
  return vim.api.nvim_get_current_win() ~= before
end

for i, direction in ipairs({ "left", "down", "up", "right" }) do
  local key = ("hjkl"):sub(i, i)
  map("n", "<C-" .. key .. ">", function()
    if not nvim_move(key) then
      herdr_focus(direction)
    end
  end, { desc = "Focus " .. direction .. " pane" })
end

-- Deprecated with vim-tmux-navigator. herdr has no previous-pane CLI direction.
-- map("n", "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>")
