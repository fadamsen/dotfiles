---@module 'lazy'
---@type LazySpec
return {
  'coffebar/neovim-project',
  opts = {
    projects = {
      '~/.config/nvim',
      '~/.local/share/chezmoi',
      'C:/Workspace/*',
      'D:/Repos/*/*',
      '~/code/*',
    },
    picker = {
      type = 'telescope',
    },
  },
  init = function() vim.opt.sessionoptions:append 'globals' end,
  dependencies = {
    { 'Shatur/neovim-session-manager' },
    { 'nvim-lua/plenary.nvim' },
    { 'nvim-telescope/telescope.nvim' },
  },
  lazy = false,
  priority = 100,
}
