#!/usr/bin/env bash
set -euo pipefail

cd /home/ryanr/nix-config

# Update flake inputs
echo "Updating flake inputs..."
nix flake update

# Fetch latest copilot-cli release
echo "Checking copilot-cli latest version..."
release=$(gh release view --repo github/copilot-cli --json tagName -q '.tagName')
version="${release#v}"

# Check if already at this version
current_version=$(grep -A1 'pname = "copilot-cli"' home.nix | grep version | sed 's/.*version = "\(.*\)".*/\1/')
if [ "$current_version" = "$version" ]; then
  echo "copilot-cli already at version $version"
else
  echo "Updating copilot-cli from $current_version to $version..."

  # Download and hash
  tmpdir=$(mktemp -d)
  trap "rm -rf $tmpdir" EXIT
  cd "$tmpdir"
  wget -q "https://github.com/github/copilot-cli/releases/download/v${version}/copilot-linux-x64.tar.gz"
  hash=$(nix hash file copilot-linux-x64.tar.gz)
  cd /home/ryanr/nix-config

  # Update home.nix
  sed -i "/pname = \"copilot-cli\"/,/};/ s/version = \"[^\"]*\"/version = \"${version}\"/" home.nix
  sed -i "/pname = \"copilot-cli\"/,/};/ s|sha256 = \"sha256-[^\"]*\"|sha256 = \"${hash}\"|" home.nix
fi

# Commit changes
git add flake.lock home.nix 2>/dev/null || true
git commit -m "chore: update flake and copilot-cli" || true

# Rebuild
echo "Rebuilding..."
rebuild
