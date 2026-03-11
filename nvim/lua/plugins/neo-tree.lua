return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      visible = true,
      show_hidden_count = true,
      hide_dotfiles = false,
      hide_gitignored = true,
      hide_by_name = {
        ".gitignore",
        ".gitattributes",
      },
      never_show = {
        ".DS_Store",
        ".git",
        ".idea",
        ".nuget",
        ".paket",
        ".vscode",
        "node_modules",
        "packages",
        "thumbs.db",
      },
    },
  },
}
