#!/bin/bash

set -e  # Stop if any command fails

REPO_URL="https://github.com/ajvadam/devenv"
CLONE_DIR="$HOME/.devenv-temp"

echo "===> Updating system packages..."
sudo apt update

echo "===> Installing Neovim, tmux, Docker, and git..."
sudo apt install -y neovim tmux docker.io git curl

echo "===> Starting and enabling Docker service..."
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

echo "===> Cleaning up temp files..."
rm -rf "$CLONE_DIR"

echo "✅ Setup complete."

echo "⚠️ You may need to log out and back in (or run 'newgrp docker') for Docker group changes to apply."

