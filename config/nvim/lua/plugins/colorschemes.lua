local themes = {
  ["oxocarbon"] = true,
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
  -- default theme
  theme = "oxocarbon"
end

return {
  -- { "vague2k/vague.nvim" },
  -- {
  --   "rose-pine/neovim",
  --   name = "rose-pine",
  --   opts = { variant = "moon" },
  -- },
  -- {
  --   "Sequoia-Theme/neovim",
  --   name = "sequoia",
  -- },
  {
    "nyoom-engineering/oxocarbon.nvim",
    build = false,
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = theme },
  },
}
