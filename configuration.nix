{ config, pkgs, ... }:
{
  wsl = {
    enable = true;
    defaultUser = "ryanr";
    nativeSystemd = true;
    interop = {
      enable = true;
      includePath = false; # keep Nix PATH clean from Windows PATH
    };
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow ryanr to use sudo
  security.sudo.wheelNeedsPassword = false;

  users.users.ryanr = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
  };

  programs.zsh.enable = true;

  # Symlink .aws and .azure to Windows user profile (matches Ubuntu setup)
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
    users.ryanr = import ./home.nix;
  };

  system.stateVersion = "24.05";
}
