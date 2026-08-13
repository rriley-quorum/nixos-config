{ config, pkgs, pkgs-unstable, ... }:
{
  wsl = {
    enable = true;
    defaultUser = "ryanr";
    # Re-register WSLInterop after systemd-binfmt clears it at boot.
    # Without this, no Windows .exe runs (Exec format error) - breaks
    # browser launch for az login and all other Windows interop.
    interop.register = true;
  };

  # az login (and any tool honoring $BROWSER) opens the Windows browser.
  environment.sessionVariables.BROWSER = "wslview";

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (pyfinal: pyprev: {
          msal = pyprev.msal.overridePythonAttrs (old: rec {
            version = "1.34.0";
            src = final.fetchPypi {
              pname = "msal";
              inherit version;
              hash = "sha256-drqDtxbqWm11sCecCsNToOBbggyh9mgsDrf0UZDEPC8=";
            };
          });
        })
      ];
    })
  ];

  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
    download-buffer-size = 524288000; # 500 MiB
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.extraOptions = ''
    min-free = ${toString (100 * 1024 * 1024)}
    max-free = ${toString (1024 * 1024 * 1024)}
  '';

  security.sudo.wheelNeedsPassword = false;

  users.users.ryanr = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "docker" ];
  };

  virtualisation.docker.enable = true;
  virtualisation.docker.package = pkgs.docker_29;

  system.activationScripts.dockerDesktopCompat = ''
    mkdir -p /bin /usr/bin
    ln -sf /run/current-system/sw/bin/whoami /usr/bin/whoami
    for bin in ${pkgs.coreutils}/bin/*; do
      name=$(basename "$bin")
      ln -sf "$bin" "/usr/bin/$name"
      ln -sf "$bin" "/bin/$name"
    done
  '';

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      unixODBC
    ];
  };

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
    extraSpecialArgs = { inherit pkgs-unstable; };
    users.ryanr = import ./home.nix;
  };

  system.stateVersion = "25.11";

  # CVE-2026-31431
  boot.blacklistedKernelModules = [ "algif_aead" ];
}
