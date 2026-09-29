---@module 'lazy'
---@type LazySpec
return {
  'NicholasZolton/neojj',
  version = '^1.0.0',
  lazy = true,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'dlyongemallo/diffview.nvim', -- optional
    'nvim-telescope/telescope.nvim', -- optional
  },
  cmd = 'Neojj',
  keys = {
    { '<leader>vj', '<cmd>Neojj<cr>', desc = 'Show Neojj UI' },
  },
}
