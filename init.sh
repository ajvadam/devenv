#!/bin/bash

set -e

echo "Starting setup..."

# Update packages
sudo apt-get update

# Install prerequisites for Docker and Neovim
sudo apt-get install -y curl software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Install tmux, neovim
sudo apt-get install -y tmux neovim

# Install Docker (Docker Engine + CLI)
if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io

  # Add current user to docker group for permissions
  sudo usermod -aG docker $USER

  echo "Docker installed. You may need to logout/login for group changes."
else
  echo "Docker already installed."
fi

# Create tmux config file
cat > ~/.tmux.conf << 'EOF'
set -g base-index 1
unbind r
bind r source-file ~/.tmux.conf
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
set -g mouse on
unbind C-b
set-option -g prefix C-s
bind C-s send-prefix
bind -n C-k send-keys Up
EOF

echo "tmux config written to ~/.tmux.conf"

# Create Neovim config directory and init.lua
NVIM_CONFIG_DIR="$HOME/.config/nvim"
mkdir -p "$NVIM_CONFIG_DIR"

cat > "$NVIM_CONFIG_DIR/init.lua" << 'EOF'
-- Basic settings
vim.g.mapleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.o.background = "dark"
vim.g.gruvbox_contrast_dark = "hard"

-- Keymaps for C++ compile & run
vim.keymap.set("n", "<C-k>", function()
  vim.cmd("w")
  local filename = vim.fn.expand("%:p")
  local output = vim.fn.expand("%:p:r") .. ".out"
  vim.cmd("!" .. "g++ -std=c++20 " .. filename .. " -o " .. output)
end, { desc = "Save and compile with g++" })

vim.keymap.set("n", "<C-n>", function()
  vim.cmd("w")
  local file = vim.fn.expand("%:p")
  local out = vim.fn.expand("%:p:r") .. ".out"
  local compile_result = vim.fn.system("g++ -std=c++20 " .. file .. " -o " .. out)
  if vim.v.shell_error ~= 0 then
    print("❌ Compilation failed:\n" .. compile_result)
    return
  end

  vim.cmd("botright split")
  vim.cmd("resize 15")
  local term_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(term_buf, "Output")
  vim.api.nvim_win_set_buf(0, term_buf)

  vim.fn.termopen(out, {
    on_exit = function(_, exit_code, _)
      vim.schedule(function()
        local msg = (exit_code == 0)
          and "✅ Program exited successfully"
          or ("⚠️ Program exited with code: " .. exit_code)
        print(msg)

        vim.api.nvim_buf_set_keymap(term_buf, "t", "<CR>", "<C-\\><C-n>:q<CR>", { noremap = true, silent = true })
        vim.api.nvim_buf_set_keymap(term_buf, "n", "<CR>", "<C-\\><C-n>:q<CR>", { noremap = true, silent = true })
      end)
    end,
  })

  vim.cmd("startinsert")
  vim.api.nvim_buf_set_keymap(term_buf, "t", "<Esc>", "<C-\\><C-n>", { noremap = true, silent = true })
end, { desc = "Compile and run C++20 program in terminal" })

vim.keymap.set("n", "<C-j>", function()
  vim.cmd("w")
  local filename = vim.fn.expand("%:p")
  local output = vim.fn.expand("%:p:r") .. ".out"
  vim.cmd("!" .. "g++ " .. filename .. " -o " .. output)
  vim.cmd("silent !" .. output)
end, { desc = "Save, compile, and run with g++" })

-- Bootstrap Paq if not installed
local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/paqs/start/paq-nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  fn.system({'git', 'clone', '--depth=1', 'https://github.com/savq/paq-nvim.git', install_path})
  vim.cmd "packadd paq-nvim"
end

-- Plugins
require "paq" {
  "savq/paq-nvim",
  "morhetz/gruvbox",
  "neovim/nvim-lspconfig",
  { "lervag/vimtex", opt = true },
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  "nvim-lua/plenary.nvim",
  "nvim-telescope/telescope.nvim",
}

pcall(function()
  require('telescope').setup {
    defaults = {
      layout_strategy = "horizontal",
      layout_config = {
        horizontal = { width = 0.9 },
      },
      mappings = {
        i = {
          ["<C-j>"] = "move_selection_next",
          ["<C-k>"] = "move_selection_previous",
        },
      },
    }
  }
end)

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local ok, _ = pcall(vim.cmd, "colorscheme gruvbox")
    if not ok then
      vim.notify("⚠️ Gruvbox not found. Run :PaqInstall and restart Neovim.", vim.log.levels.WARN)
    end
  end
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local ok, builtin = pcall(require, "telescope.builtin")
    if ok then
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find Files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live Grep" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help Tags" })
    else
      vim.notify("Telescope builtin not loaded", vim.log.levels.WARN)
    end
  end,
})
EOF

echo "Neovim config written to $NVIM_CONFIG_DIR/init.lua"

echo "Setup complete! You may need to logout/login for Docker permissions to take effect."

echo "Run 'tmux' to start tmux with your custom config, and open 'nvim' to start Neovim."


