---@module 'lazy'
---@type LazySpec
return {
  'wsdjeg/rooter.nvim',
  opts = {
    command = 'cd',
    project_non_root = 'current',
    root_patterns = {
      '.git/',
      '.jj/',
      '.nvimroot',
    },
  },
}
