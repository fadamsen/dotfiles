---@module 'lazy'
---@type LazySpec
return {
  'folke/snacks.nvim',
  lazy = false,
  priority = 1000,
  ---@type snacks.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    bigfile = { enabled = true },
    git = { enabled = true },
    gitbrowse = { enabled = true },
    toggle = { enabled = true },
  },
}
