#!/bin/bash
set -e

REPO_URL="https://github.com/ajvadam/devenv"
CLONE_DIR="$HOME/.devenv-temp"

echo "🔧 Starting setup..."

# Ensure not running as root
if [ "$USER" = "root" ]; then
  echo "❌ Please run this script as a non-root user with sudo privileges."
  exit 1
fi

echo "📦 Updating apt package lists..."
sudo apt update

echo "⚠️ Forcing removal of conflicting moby packages if any (may fix half-installed states)..."
sudo dpkg --remove --force-remove-reinstreq moby-tini || true
sudo dpkg --remove --force-remove-reinstreq moby-engine || true
sudo dpkg --remove --force-remove-reinstreq moby-cli || true

echo "🔍 Removing moby packages and docker.io to avoid conflicts..."
sudo apt purge -y moby-tini moby-engine moby-cli docker.io containerd || true

echo "🧹 Autoremoving unused packages..."
sudo apt autoremove -y

echo "🧹 Cleaning apt cache..."
sudo apt clean

echo "📦 Installing prerequisites for Docker repo..."
sudo apt install -y ca-certificates curl gnupg lsb-release git neovim tmux

echo "🐳 Setting up Docker official repo..."

sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "📦 Updating apt again after adding Docker repo..."
sudo apt update

echo "📦 Installing Docker packages..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "🔒 Adding $USER to docker group..."
sudo usermod -aG docker "$USER"

# Apply docker group to current shell session
newgrp docker <<EOF
echo "✅ Docker group applied for $USER"
EOF

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

echo "✅ Setup complete! You may need to restart your terminal or run 'newgrp docker' again for Docker permissions to apply."

