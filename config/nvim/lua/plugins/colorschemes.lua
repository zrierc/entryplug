local themes = {
  ["rose-pine-moon"] = true,
  ["sequoia-moonlight-dark"] = true,
  ["sequoia-moonlight-light"] = true,
  ["sequoia-monochrome-dark"] = true,
  ["sequoia-monochrome-light"] = true,
  ["sequoia-retro-dark"] = true,
  ["sequoia-retro-light"] = true,
}

local theme = vim.env.NVIM_THEME
if not theme or not themes[theme] then
  theme = "rose-pine-moon"
end

return {
  -- { "vague2k/vague.nvim" },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    opts = { variant = "moon" },
  },
  {
    "Sequoia-Theme/neovim",
    name = "sequoia",
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = theme },
  },
}
