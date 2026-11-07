local ts_ft = {
  "javascript",
  "javascriptreact",
  "javascript.jsx",
  "typescript",
  "typescriptreact",
  "typescript.tsx",
}

-- vite.config.* is deliberately not a marker: ordinary Vite projects may use Prettier.
local oxfmt_markers = { ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts" }
local biome_markers = { "biome.json", "biome.jsonc", ".biome.json", ".biome.jsonc" }
local oxlint_markers = { ".oxlintrc.json", ".oxlintrc.jsonc", "oxlint.config.ts" }
local eslint_markers = {
  ".eslintrc",
  ".eslintrc.js",
  ".eslintrc.cjs",
  ".eslintrc.yaml",
  ".eslintrc.yml",
  ".eslintrc.json",
  "eslint.config.js",
  "eslint.config.mjs",
  "eslint.config.cjs",
  "eslint.config.ts",
  "eslint.config.mts",
  "eslint.config.cts",
}

local function find(filename, markers)
  if not filename or filename == "" then
    return nil
  end
  return vim.fs.find(markers, { path = filename, upward = true })[1]
end

local function has_bin(name)
  return vim.fn.executable(name) == 1 or vim.fn.executable("node_modules/.bin/" .. name) == 1
end

local function available(filename, markers, bin)
  return find(filename, markers) ~= nil and has_bin(bin)
end

local function formatter(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if find(name, oxfmt_markers) then
    return { "oxfmt" }
  end
  if find(name, biome_markers) then
    return { "biome" }
  end
  return { "prettier" }
end

local function lint_condition(name)
  return function(ctx)
    local oxlint = available(ctx.filename, oxlint_markers, "oxlint")
    local biome = available(ctx.filename, biome_markers, "biome")
    local eslint = available(ctx.filename, eslint_markers, "eslint")

    if name == "oxlint" then
      return oxlint
    end
    if name == "biomejs" then
      return biome and not oxlint
    end
    if name == "eslint" then
      return eslint and not oxlint and not biome
    end
    return false
  end
end

return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for _, ft in ipairs(ts_ft) do
        opts.formatters_by_ft[ft] = formatter
      end
    end,
  },
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.events = { "BufWritePost", "BufReadPost" }
      opts.linters_by_ft = opts.linters_by_ft or {}
      for _, ft in ipairs(ts_ft) do
        opts.linters_by_ft[ft] = { "oxlint", "biomejs", "eslint" }
      end
      opts.linters = opts.linters or {}
      opts.linters.oxlint = { condition = lint_condition("oxlint") }
      opts.linters.biomejs = { condition = lint_condition("biomejs") }
      opts.linters.eslint = { condition = lint_condition("eslint") }
    end,
  },
}
