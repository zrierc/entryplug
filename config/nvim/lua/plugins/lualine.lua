local function has_lsp()
  return #vim.lsp.get_clients({ bufnr = 0 }) > 0
end

local function lsp_name()
  local client = vim.lsp.get_clients({ bufnr = 0 })[1]
  return client and client.name or ""
end

return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    local colorscheme = vim.g.colors_name or vim.env.NVIM_THEME or "oxocarbon"

    opts.options = opts.options or {}
    opts.options.theme = colorscheme:find("^rose%-pine") and "rose-pine" or "auto"
    opts.options.component_separators = { left = "│", right = "│" }
    opts.options.section_separators = { left = "", right = "" }

    opts.sections.lualine_y = {
      {
        lsp_name,
        cond = has_lsp,
        padding = { left = 1, right = 1 },
      },
      {
        "fileformat",
        cond = function()
          return not has_lsp()
        end,
      },
      {
        "fileencoding",
        cond = function()
          return not has_lsp()
        end,
      },
    }

    opts.sections.lualine_z = {
      { "progress", separator = " ", padding = { left = 1, right = 0 } },
      { "location", padding = { left = 0, right = 1 } },
    }

    return opts
  end,
}
