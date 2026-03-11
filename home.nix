{ config, pkgs, ... }:
{
  home.username = "ryanr";
  home.homeDirectory = "/home/ryanr";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    wget
    dos2unix
    fd
    ripgrep
    inotify-tools
    xclip
    lazygit
    tree-sitter

    gcc
    lld
    autoconf
    m4

    gh
    jira-cli-go
    direnv

    nodejs_22
    nodePackages.typescript
    nodePackages.typescript-language-server
    claude-code

    ruby_4_0

    uv
    python312

    rustup

    go

    luarocks

    docker

    chromium

    dotnet-sdk_10

    jdk21

    beam26Packages.elixir
  ];

  programs.git = {
    enable = true;
    settings = {
      user.name = "Ryan Riley";
      user.email = "ryan.riley@quorumsoftware.com";
      init.defaultBranch = "main";
      core.editor = "nvim";
    };
  };

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

    initContent = ''
      eval "$(direnv hook zsh)"

      export CPPFLAGS="$(pkg-config --cflags openssl 2>/dev/null) $CPPFLAGS"
      export LDFLAGS="$(pkg-config --libs openssl 2>/dev/null) $LDFLAGS"
    '';
  };

  programs.fzf.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  xdg.configFile."nvim/init.lua".source = ./nvim/init.lua;
  xdg.configFile."nvim/lua".source = ./nvim/lua;
  xdg.configFile."nvim/lazyvim.json".source = ./nvim/lazyvim.json;
  xdg.configFile."nvim/stylua.toml".source = ./nvim/stylua.toml;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "github.com" = {
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        extraOptions.AddKeysToAgent = "yes";
      };
    };
  };

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

      bind -n M-H previous-window
      bind -n M-L next-window

      set -g pane-base-index 1
      set-window-option -g pane-base-index 1
      set-option -g renumber-windows on

      set -g @catppuccin_flavour 'mocha'

      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
    '';
  };

  programs.home-manager.enable = true;
}
