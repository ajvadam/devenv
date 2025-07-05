-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.o.background = "dark"
vim.g.gruvbox_contrast_dark = "hard"

-- Keymap: Save and compile C++ with g++
vim.keymap.set("n", "<C-k>", function()
  vim.cmd("w")
  local filename = vim.fn.expand("%:p")
  local output = vim.fn.expand("%:p:r") .. ".out"
  vim.cmd("!" .. "g++ -std=c++20 " .. filename .. " -o " .. output)
end, { desc = "Save and compile with g++" })

-- Keymap: Compile and run C++ in split terminal
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

-- Keymap: Save, compile and run with g++ (quick and silent)
vim.keymap.set("n", "<C-j>", function()
  vim.cmd("w")
  local filename = vim.fn.expand("%:p")
  local output = vim.fn.expand("%:p:r") .. ".out"
  vim.cmd("!" .. "g++ " .. filename .. " -o " .. output)
  vim.cmd("silent !" .. output)
end, { desc = "Save, compile, and run with g++" })









-- Keymap: Run current Python file in terminal split
vim.keymap.set("n", "<C-e>", function()
  vim.cmd("w")
  local file = vim.fn.expand("%:p")

  -- Open terminal split
  vim.cmd("botright split")
  vim.cmd("resize 15")
  local term_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(term_buf, "Python Output")
  vim.api.nvim_win_set_buf(0, term_buf)

  -- Run the Python script
  vim.fn.termopen("python " .. file, {
    on_exit = function(_, exit_code, _)
      vim.schedule(function()
        local msg = (exit_code == 0)
          and "✅ Python script exited successfully"
          or ("⚠️ Python exited with code: " .. exit_code)
        print(msg)

        -- Add <CR> to quit
        vim.api.nvim_buf_set_keymap(term_buf, "t", "<CR>", "<C-\\><C-n>:q<CR>", { noremap = true, silent = true })
        vim.api.nvim_buf_set_keymap(term_buf, "n", "<CR>", "<C-\\><C-n>:q<CR>", { noremap = true, silent = true })
      end)
    end,
  })

  vim.cmd("startinsert")
  vim.api.nvim_buf_set_keymap(term_buf, "t", "<Esc>", "<C-\\><C-n>", { noremap = true, silent = true })
end, { desc = "Run Python file in terminal split" })






-- Bootstrap Paq if not installed
local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/paqs/start/paq-nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  fn.system({'git', 'clone', '--depth=1', 'https://github.com/savq/paq-nvim.git', install_path})
  vim.cmd "packadd paq-nvim"
end

-- Plugins
require "paq" {
  "savq/paq-nvim",                         -- Let Paq manage itself
  "morhetz/gruvbox",                       -- Gruvbox theme
  "neovim/nvim-lspconfig",                 -- LSP support
  { "lervag/vimtex", opt = true },         -- LaTeX
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  "nvim-lua/plenary.nvim",                 -- Dependency for Telescope
  "nvim-telescope/telescope.nvim",         -- Telescope itself
}

-- Setup Telescope safely
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

-- Gruvbox colorscheme loading on VimEnter
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local ok, _ = pcall(vim.cmd, "colorscheme gruvbox")
    if not ok then
      vim.notify("⚠️ Gruvbox not found. Run :PaqInstall and restart Neovim.", vim.log.levels.WARN)
    end
  end
})

-- Defer Telescope keymaps until VimEnter to avoid loading errors
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local ok, builtin = pcall(require, 'telescope.builtin')
    if ok then
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = "Find Files" })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep,  { desc = "Live Grep" })
      vim.keymap.set('n', '<leader>fb', builtin.buffers,    { desc = "Buffers" })
      vim.keymap.set('n', '<leader>fh', builtin.help_tags,  { desc = "Help Tags" })
    else
      vim.notify("Telescope builtin not found, keymaps not set", vim.log.levels.WARN)
    end
  end
})  -- ✅ ← This `)` was missing

