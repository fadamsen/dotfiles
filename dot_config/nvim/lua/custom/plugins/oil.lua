---@module 'lazy'
---@type LazySpec
return {
  'stevearc/oil.nvim',
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    default_file_explorer = false,
    view_options = {
      show_hidden = true,
      is_hidden_file = function(name, bufnr)
        local m = name:match '^%.'
        return m ~= nil
      end,
      is_always_hidden = function(name, bufnr)
        if name == '.git' then return true end

        return false
      end,
    },
  },
  dependencies = {
    { 'nvim-tree/nvim-web-devicons' },
    {
      'malewicz1337/oil-git.nvim',
      opts = {
        show_directory_highlights = false,
        show_file_highlights = true,
        show_ignored_files = true,
      },
    },
  },
  lazy = false,
}
