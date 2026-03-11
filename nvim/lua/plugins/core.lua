return {
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "moon",
      transparent = true,
      terminal_styles = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },
  {
    "zenbones-theme/zenbones.nvim",
    -- Optionally install Lush. Allows for more configuration or extending the colorscheme
    -- If you don't want to install lush, make sure to set g:zenbones_compat = 1
    -- In Vim, compat mode is turned on as Lush only works in Neovim.
    dependencies = "rktjmp/lush.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      -- vim.o.background = "light"
      vim.g.zenbones = {
        darkness = "warm",
        lightness = "bright",
        transparent_background = true,
      }
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "zenbones",
    },
  },
}
