#!/bin/bash
set -e

REPO_URL="https://github.com/ajvadam/devenv"
CLONE_DIR="$HOME/.devenv-temp"

echo "🔧 Detected user: $USER"
echo "🧠 Adapting for GitHub Codespaces if necessary..."

# Ensure script is run as codespace user, not root
if [ "$USER" = "root" ]; then
    echo "❌ Do not run this script as root. Please run as your user in Codespaces."
    exit 1
fi

echo "📦 Updating apt and installing core tools..."
sudo apt update
sudo apt install -y git curl ca-certificates gnupg lsb-release neovim tmux

# === Docker Setup ===
echo "🐳 Installing Docker (official repo)..."

# Remove conflicts if present
sudo apt remove -y docker.io containerd || true

# Add Docker’s official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "🔒 Adding $USER to docker group..."
sudo usermod -aG docker "$USER"

# Apply group changes immediately (won't require logout in Codespaces)
newgrp docker <<EOF
echo "✅ Docker group applied"
EOF

# === Config Files Setup ===
echo "📁 Cloning config files from $REPO_URL"
rm -rf "$CLONE_DIR"
git clone "$REPO_URL" "$CLONE_DIR"

echo "📝 Installing Neovim config..."
mkdir -p ~/.config/nvim
cp "$CLONE_DIR/vimconfig.lua" ~/.config/nvim/init.lua

echo "📝 Installing tmux config..."
cp "$CLONE_DIR/tmux.conf" ~/.tmux.conf

echo "🧹 Cleaning up temp files..."
rm -rf "$CLONE_DIR"

echo "✅ All set! Your environment is ready."

