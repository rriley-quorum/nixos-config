{ config, pkgs, ... }:
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

  clang18 = pkgs.runCommand "clang-18-compiler" { } ''
    mkdir -p $out/bin
    ln -s ${pkgs.clang_18}/bin/clang $out/bin/clang
    ln -s ${pkgs.clang_18}/bin/clang++ $out/bin/clang++
  '';

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
    cmake
    clang18
    ninja

    gh
    acli
    ksm
    direnv
    (azure-cli.withExtensions [ azure-cli-extensions.azure-devops azure-cli-extensions.containerapp ])

    pkgs.dejavu_fonts
    pkgs.jetbrains-mono

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

    chromedriver

    plantuml
    graphviz
    asciinema
    asciinema-agg
    ffmpeg

    icu

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

    keychain
    wslu

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
      rebuild = "sudo nixos-rebuild switch --flake /home/ryanr/nix-config#nixos";
      lm-models = "curl -s $LM_API/v1/models | jq '.data[].id'";
    };

    envExtra = ''
      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
      export LM_API="http://100.96.10.15:1234"
    '';

    initContent = ''
      claude-local() {
        local model="qwen/qwen3-coder-30b"
        local args=()
        while [[ $# -gt 0 ]]; do
          if [[ $1 == --model ]]; then
            model="$2"; shift 2
          else
            args+=("$1"); shift
          fi
        done
        ANTHROPIC_BASE_URL=http://100.96.10.15:1234 \
        ANTHROPIC_AUTH_TOKEN=lmstudio \
        claude --model "$model" "''${args[@]}"
      }

      eval "$(keychain --eval --quiet ~/.ssh/id_ed25519)"

      eval "$(direnv hook zsh)"

      export LD_LIBRARY_PATH="${pkgs.icu}/lib:$LD_LIBRARY_PATH"

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

  programs.chromium = {
    enable = true;
    extensions = [
      { id = "fcoeoabgfenejglbffodgkkbkcdhcgfn"; } # Claude in Chrome
    ];
  };

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

  systemd.user.services.cleanup = {
    Unit.Description = "Run daily cleanup script";
    Service = {
      Type = "oneshot";
      ExecStart = "/home/ryanr/Code/scripts/cleanup.sh";
    };
  };

  systemd.user.timers.cleanup = {
    Unit.Description = "Daily cleanup timer";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  programs.home-manager.enable = true;
}
