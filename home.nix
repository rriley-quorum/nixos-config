{ config, pkgs, beads, ... }:
let
  acli = pkgs.stdenv.mkDerivation rec {
    pname = "acli";
    version = "latest";
    src = pkgs.fetchurl {
      url = "https://acli.atlassian.com/linux/latest/acli_linux_amd64/acli";
      sha256 = "16da9fm7fp43ixhx5vja53cisxdv110sxgzyg73x1flyrx7j242g";
    };
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/acli
      chmod +x $out/bin/acli
    '';
  };

  ksm = pkgs.stdenv.mkDerivation rec {
    pname = "keeper-secrets-manager-cli";
    version = "1.2.0";
    src = pkgs.fetchurl {
      url = "https://github.com/Keeper-Security/secrets-manager/releases/download/ksm-cli-${version}/keeper-secrets-manager-cli-linux-${version}.tar.gz";
      sha256 = "5d7738729af6f09fadc330945d198cba98e66b33c7ca8acd96d981be4fb16e69";
    };
    sourceRoot = ".";
    installPhase = ''
      mkdir -p $out/bin
      cp ksm $out/bin/ksm
      chmod +x $out/bin/ksm
    '';
  };

  beadsPkg =
    let
      bdBase = pkgs.buildGoModule {
        pname = "beads";
        version = "0.61.0";
        src = beads;
        subPackages = [ "cmd/bd" ];
        doCheck = false;
        vendorHash = "sha256-Dre32o9CRnBhHjfnJD7SDwLA6b3zWJa1eFowf+nikO8=";
        postPatch = ''
          goVer="$(go env GOVERSION | sed 's/^go//')"
          go mod edit -go="$goVer"
          sed -i "s|## explicit; go [0-9][0-9.]*|## explicit; go $goVer|g" vendor/modules.txt
        '';
        nativeBuildInputs = [ pkgs.git ];
      };
    in
    pkgs.stdenv.mkDerivation {
      pname = "beads";
      version = bdBase.version;
      phases = [ "installPhase" ];
      installPhase = ''
        mkdir -p $out/bin
        cp ${bdBase}/bin/bd $out/bin/bd
        ln -s bd $out/bin/beads
        mkdir -p $out/share/zsh/site-functions
        $out/bin/bd completion zsh > $out/share/zsh/site-functions/_bd
      '';
    };
in
{
  home.username = "ryanr";
  home.homeDirectory = "/home/ryanr";
  home.stateVersion = "25.11";

  home.sessionPath = [ "$HOME/.local/bin" "$HOME/.dotnet/tools" ];

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
    acli
    ksm
    direnv
    (azure-cli.withExtensions [ azure-cli-extensions.azure-devops ])

    nodejs_22
    nodePackages.typescript
    nodePackages.typescript-language-server
    claude-code
    github-copilot-cli

    ruby_4_0

    uv
    python312

    rustup

    go

    luarocks

    docker

    chromium
    chromedriver

    (with dotnetCorePackages; combinePackages [
      sdk_8_0
      sdk_9_0
      sdk_10_0
    ])
    fsautocomplete
    fantomas
    powershell

    jdk21

    beam26Packages.elixir
    beam26Packages.elixir-ls
    erlang-language-platform
    omnisharp-roslyn
    terraform-ls

    postgresql

    dolt
    beadsPkg

    sqlite
    mycli

    jq
    yq
    httpie
    mkcert
    watchexec
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
      plugins = [ "git" "node" "ruby" ];
    };

    shellAliases = {
      pbcopy = "xclip -selection clipboard";
      pbpaste = "xclip -selection clipboard -o";
    };

    envExtra = ''
      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
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
