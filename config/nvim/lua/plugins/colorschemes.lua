return {
  -- { "vague2k/vague.nvim" },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    opts = { variant = "moon" },
    config = function(_, opts)
      require("rose-pine").setup(opts)
      vim.cmd("colorscheme rose-pine-moon")
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "rose-pine-moon" },
  },
}
