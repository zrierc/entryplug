local WORD_COUNT = 1
local aliases = {}

local function gods_word()
  if vim.fn.executable("gshuf") == 0 then
    return "somewhere"
  end

  local ok, result = pcall(function()
    return vim.system({ "gshuf", "-n", tostring(WORD_COUNT), "/usr/share/dict/words" }, { text = true }):wait(1000)
  end)

  if not ok or not result or result.code ~= 0 then
    return "somewhere"
  end

  local words = vim.split(result.stdout or "", "\n", { trimempty = true })
  return #words > 0 and table.concat(words, " ") or "somewhere"
end

local function larp(opts)
  opts = opts or {}
  local key = opts.workspace or opts.workspace_dir or "unknown"
  -- keep the alias stable while nvim is open
  aliases[key] = aliases[key] or gods_word()
  return "Larp in " .. aliases[key]
end

return {
  "vyfor/cord.nvim",
  opts = {
    editor = {
      client = "neovim",
      tooltip = "god's in heaven all's right with the world 🍁",
    },
    display = {
      theme = "void",
      flavor = "dark",
    },
    idle = {
      details = "AFK",
    },
    text = {
      workspace = larp,
    },
  },
}
