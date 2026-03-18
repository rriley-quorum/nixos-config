{ config, pkgs, beads, ... }:
{
  wsl = {
    enable = true;
    defaultUser = "ryanr";
  };

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    download-buffer-size = 524288000; # 500 MiB
  };

  security.sudo.wheelNeedsPassword = false;

  users.users.ryanr = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "docker" ];
  };

  virtualisation.docker.enable = true;

  system.activationScripts.dockerDesktopCompat = ''
    mkdir -p /usr/bin
    ln -sf /run/current-system/sw/bin/whoami /usr/bin/whoami
  '';

  programs.nix-ld.enable = true;

  programs.zsh.enable = true;

  system.activationScripts.windowsCredentials = ''
    WINDOWS_HOME="/mnt/c/Users/ryan.riley"
    USER_HOME="/home/ryanr"

    if [ ! -L "$USER_HOME/.aws" ] && [ -d "$WINDOWS_HOME/.aws" ]; then
      ln -sf "$WINDOWS_HOME/.aws" "$USER_HOME/.aws"
    fi

    if [ ! -L "$USER_HOME/.azure" ] && [ -d "$WINDOWS_HOME/.azure" ]; then
      ln -sf "$WINDOWS_HOME/.azure" "$USER_HOME/.azure"
    fi
  '';

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit beads; };
    users.ryanr = import ./home.nix;
  };

  system.stateVersion = "25.11";
}
