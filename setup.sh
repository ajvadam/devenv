#!/bin/bash

set -e

REPO_URL="https://github.com/ajvadam/devenv"
CLONE_DIR="$HOME/.devenv-temp"

echo "===> Updating packages..."
sudo apt update

echo "===> Installing base tools (Neovim, tmux, git, curl)..."
sudo apt install -y neovim tmux git curl ca-certificates gnupg lsb-release

echo "===> Installing Docker from official Docker repo..."

# Remove conflicting packages if needed
sudo apt remove -y docker.io containerd

# Add Docker’s official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update

# Install Docker Engine
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker "$USER"

echo "===> Cloning config repo from $REPO_URL..."
rm -rf "$CLONE_DIR"
git clone "$REPO_URL" "$CLONE_DIR"

echo "===> Applying Neovim config..."
mkdir -p ~/.config/nvim
cp "$CLONE_DIR/vimconfig.lua" ~/.config/nvim/init.lua

echo "===> Applying tmux config..."
cp "$CLONE_DIR/tmux.conf" ~/.tmux.conf

echo "===> Cleaning up..."
rm -rf "$CLONE_DIR"

echo "✅ Done. You may need to reboot or run 'newgrp docker' to use Docker without sudo."

