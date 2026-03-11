{ config, pkgs, ... }:
{
  home.username = "ryanr";
  home.homeDirectory = "/home/ryanr";
  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    # CLI tools
    wget
    dos2unix
    fd
    fzf
    ripgrep
    inotify-tools
    xclip
    lazygit
    tree-sitter

    # Build tools
    gcc
    lld
    autoconf
    m4

    # SCM / dev tools
    gh
    jira-cli
    direnv

    # Node.js (v22 LTS — replaces nvm)
    nodejs_22

    # npm global packages available in nixpkgs
    nodePackages.typescript
    nodePackages.typescript-language-server

    # Claude Code (available directly in nixpkgs)
    claude-code

    # copilot-cli is not in nixpkgs; install imperatively after setup:
    #   npm install -g @githubnext/github-copilot-cli

    # Ruby (replaces rbenv; pin version explicitly here)
    ruby_3_4

    # Python (uv for package management, asdf-managed python for projects)
    uv

    # Rust (managed via rustup)
    rustup

    # Go
    go

    # Lua
    luarocks

    # Browser (matches snap chromium in Ubuntu)
    chromium

    # .NET
    dotnet-sdk_10

    # Java
    jdk21

    # Elixir / Erlang (matched to Ubuntu asdf versions)
    beam.packages.erlang_26.elixir_1_18
  ];

  #
  # Git
  #
  programs.git = {
    enable = true;
    userName = "Ryan Riley";
    userEmail = "ryan.riley@quorumsoftware.com";
    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "nvim";
    };
  };

  #
  # Zsh
  #
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "half-life";
      plugins = [ "git" "node" "ruby" "zsh-syntax-highlighting" "zsh-autosuggestions" ];
    };

    shellAliases = {
      pbcopy = "xclip -selection clipboard";
      pbpaste = "xclip -selection clipboard -o";
    };

    envExtra = ''
      . "$HOME/.cargo/env"
    '';

    initExtra = ''
      # direnv
      eval "$(direnv hook zsh)"

      # OpenSSL flags (for building Erlang/Elixir native extensions)
      export CPPFLAGS="$(pkg-config --cflags openssl 2>/dev/null) $CPPFLAGS"
      export LDFLAGS="$(pkg-config --libs openssl 2>/dev/null) $LDFLAGS"
    '';
  };

  #
  # Neovim — uses your existing ~/.config/nvim LazyVim config
  #
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  #
  # direnv with nix-direnv for per-project Nix shells
  #
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  #
  # SSH — key expected at ~/.ssh/id_ed25519 (copy from Ubuntu or Windows)
  #
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    matchBlocks = {
      "github.com" = {
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  #
  # tmux
  #
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    mouse = true;
    keyMode = "vi";
    prefix = "C-Space";
    baseIndex = 1;
    plugins = with pkgs.tmuxPlugins; [
      sensible
      vim-tmux-navigator
      catppuccin
      yank
    ];
    extraConfig = ''
      set-option -sa terminal-overrides ",xterm*:Tc"
      unbind C-b
      bind C-Space send-prefix
      bind C-d detach

      # Shift Alt vim keys to switch windows
      bind -n M-H previous-window
      bind -n M-L next-window

      set -g pane-base-index 1
      set-window-option -g pane-base-index 1
      set-option -g renumber-windows on

      set -g @catppuccin_flavour 'mocha'

      # vi copy mode bindings
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      # Open panes in current directory
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
    '';
  };

  programs.home-manager.enable = true;
}
