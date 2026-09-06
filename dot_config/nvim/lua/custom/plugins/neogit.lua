---@module 'lazy'
---@type LazySpec
return {
  'NeogitOrg/neogit',
  cmd = 'Neogit',
  lazy = true,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'dlyongemallo/diffview.nvim', -- optional
    'm00qek/baleia.nvim', -- optional
    'nvim-telescope/telescope.nvim', -- optional
  },
  keys = {
    { '<leader>gf', '<cmd>Neogit kind=floating<cr>', desc = 'Show floating Neogit UI' },
    { '<leader>gg', '<cmd>Neogit<cr>', desc = 'Show Neogit UI' },
  },
  opts = {
    graph_style = 'unicode',
    initial_branch_name = 'users/fka/',
    sort_branches = 'topo',
  },
}
