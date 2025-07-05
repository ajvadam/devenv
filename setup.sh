#!/bin/bash
set -e

REPO_URL="https://github.com/ajvadam/devenv"
CLONE_DIR="$HOME/.devenv-temp"

echo "🔧 Starting setup..."

if [ "$USER" = "root" ]; then
  echo "❌ Please run this script as a non-root user with sudo privileges."
  exit 1
fi

echo "📦 Updating apt package lists..."
sudo apt update

echo "📦 Installing prerequisites (git, curl, ca-certificates, gnupg, lsb-release, neovim, tmux)..."
sudo apt install -y ca-certificates curl gnupg lsb-release git neovim tmux

read -rp "Do you want to install Docker? (y/N) " install_docker

if [[ "$install_docker" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo "⚠️ Removing conflicting moby packages if any..."
  sudo dpkg --remove --force-remove-reinstreq moby-tini || true
  sudo dpkg --remove --force-remove-reinstreq moby-engine || true
  sudo dpkg --remove --force-remove-reinstreq moby-cli || true

  sudo apt purge -y moby-tini moby-engine moby-cli docker.io containerd || true
  sudo apt autoremove -y
  sudo apt clean

  echo "🐳 Setting up Docker official repo..."
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update

  echo "📦 Installing Docker packages..."
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  echo "🔒 Adding $USER to docker group..."
  sudo usermod -aG docker "$USER"

  newgrp docker <<EOF
echo "✅ Docker group applied for $USER"
EOF
else
  echo "ℹ️ Skipping Docker installation."
fi

echo "📁 Cloning your config repo from $REPO_URL..."
rm -rf "$CLONE_DIR"
git clone "$REPO_URL" "$CLONE_DIR"

echo "📝 Copying Neovim config..."
mkdir -p ~/.config/nvim
cp "$CLONE_DIR/vimconfig.lua" ~/.config/nvim/init.lua

echo "📝 Copying tmux config..."
cp "$CLONE_DIR/tmux.conf" ~/.tmux.conf

echo "🧹 Cleaning up temporary files..."
rm -rf "$CLONE_DIR"

echo "✅ Setup complete! You may need to restart your terminal or run 'newgrp docker' if Docker was installed."
