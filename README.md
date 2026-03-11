# NixOS WSL2 Configuration

A flake-based NixOS configuration for WSL2 using [NixOS-WSL](https://github.com/nix-community/NixOS-WSL), targeting NixOS 25.11.

## Structure

```
.
├── flake.nix           # Entry point — declares inputs and wires everything together
├── configuration.nix   # System-level config (user, WSL options, activation scripts)
└── home.nix            # User-level config via home-manager (packages, dotfiles, programs)
```

---

## The Nix Language

Nix configs are written in the **Nix expression language**. Key syntax to know:

- `{ ... }:` — a **function** that takes an attribute set as its argument; almost every config file is a function
- `with pkgs;` — brings all attributes of `pkgs` into scope so you can write `ripgrep` instead of `pkgs.ripgrep`
- `''...''` — multi-line strings
- `# comment` — line comments
- Lists use `[ ]` with space-separated values (no commas): `[ "git" "zsh" ]`
- Attribute sets use `{ key = value; }` with semicolons

---

## `flake.nix`

The entry point. Declares where to fetch things from and what to produce.

```
inputs  →  where to download dependencies (like package.json)
outputs →  what to build from those inputs
```

**Inputs:**
- `nixpkgs` — the package repository (replaces apt, brew, etc.)
- `nixos-wsl` — WSL2-specific NixOS modules from nix-community
- `home-manager` — declarative user environment and dotfile management
- `inputs.nixpkgs.follows = "nixpkgs"` — pins all inputs to the same nixpkgs version to avoid duplication

All three are pinned to the **25.11 stable** release to ensure consistency.

**Outputs** define a NixOS system configuration assembled from three modules: the WSL module, home-manager, and `configuration.nix`.

---

## `configuration.nix`

System-level configuration — runs as root, affects the whole OS.

### WSL options
```nix
wsl = {
  enable = true;
  defaultUser = "youruser";
  nativeSystemd = true;        # enables systemd (daemons, services, etc.)
  interop.includePath = false; # keeps Windows PATH out of the Nix environment
};
```

### Nix settings
```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```
Enables the modern `nix` CLI and flakes — technically experimental but universally used.

### User
```nix
users.users.youruser = {
  isNormalUser = true;
  shell = pkgs.zsh;
  extraGroups = [ "wheel" ]; # wheel = sudo access
};
programs.zsh.enable = true; # must be enabled system-wide to be a valid login shell
```

### Activation scripts
Shell snippets that run on every `nixos-rebuild switch`, before services start. Used here to create symlinks pointing at the Windows user profile (e.g. `.aws`, `.azure`).

### `system.stateVersion`
A compatibility marker for stateful system defaults — **set once on install and never changed**, regardless of future upgrades.

### home-manager wiring
```nix
home-manager = {
  useGlobalPkgs = true;    # shares the system nixpkgs with home-manager
  useUserPackages = true;  # installs user packages into the system profile
  users.youruser = import ./home.nix;
};
```

---

## `home.nix`

User-level configuration managed by [home-manager](https://github.com/nix-community/home-manager). Everything under `~`.

### `home.packages`
A list of packages installed into the user profile. Each is an isolated path in the Nix store (`/nix/store/<hash>-<name>/`) — no version conflicts, no global pollution.

### `programs.*`
Declarative program configuration. home-manager writes the dotfiles for you:

| Block | What it manages |
|---|---|
| `programs.git` | `~/.gitconfig` |
| `programs.zsh` | `~/.zshrc`, `~/.zshenv`, oh-my-zsh |
| `programs.tmux` | `~/.tmux.conf` + plugin installation |
| `programs.neovim` | installs neovim, sets as default editor |
| `programs.fzf` | installs fzf + wires `Ctrl+R`/`Ctrl+T`/`Alt+C` into zsh |
| `programs.direnv` | installs direnv + hooks into zsh |
| `programs.ssh` | `~/.ssh/config` |

### `programs.direnv` + `nix-direnv`
With `nix-direnv.enable = true`, placing a `flake.nix` or `shell.nix` in any project directory and `cd`-ing into it automatically activates that project's exact toolchain — no version manager juggling per project.

### `home.stateVersion`
Same semantics as `system.stateVersion` — set once on install, never changed.

---

## Applying Changes

```bash
# Edit a config file
nvim /etc/nixos/home.nix

# Apply it
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

No `apt install`, `brew install`, or manual dotfile edits. Every change is declarative and tracked in version control.

### Rollback

Every rebuild creates a new system generation. To roll back:
```bash
sudo nixos-rebuild switch --rollback

# Or pick a specific generation
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
sudo nixos-rebuild switch --to-generation <n>
```

### Updating packages (within 25.11)

```bash
sudo nix flake update   # re-resolves flake.lock to latest commits on pinned branches
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

### Upgrading to a new NixOS release

1. Check [NixOS-WSL releases](https://github.com/nix-community/NixOS-WSL/releases) for the matching tag
2. Update `flake.nix` — change the nixpkgs channel, nixos-wsl tag, and home-manager branch
3. Update `system.stateVersion` and `home.stateVersion`
4. Run `sudo nix flake update && sudo nixos-rebuild switch --flake /etc/nixos#nixos`

---

## Initial Setup

```bash
# 1. Import NixOS-WSL (PowerShell)
wsl --import NixOS "$env:USERPROFILE\NixOS" nixos-wsl.tar.gz --version 2
wsl -d NixOS

# 2. Clone this repo
sudo nix --extra-experimental-features "nix-command flakes" run nixpkgs#git -- \
  clone <this-repo> /etc/nixos

# 3. Apply configuration
sudo nixos-rebuild switch --flake /etc/nixos#nixos \
  --extra-experimental-features "nix-command flakes"

# 4. Copy SSH keys from Windows mount
cp /mnt/c/Users/<windowsuser>/.ssh/id_ed25519 ~/.ssh/
cp /mnt/c/Users/<windowsuser>/.ssh/id_ed25519.pub ~/.ssh/
chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_ed25519

# 5. Set as default WSL distro (PowerShell)
wsl --set-default NixOS
```
