-- LSP servers installed via Nix instead of Mason.
-- Setting mason = false tells LazyVim to skip Mason installation
-- and use the binary already on PATH.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        elixirls = { mason = false },
        erlangls = { mason = false },
        omnisharp = { mason = false },
        terraformls = { mason = false },
      },
    },
  },
}
