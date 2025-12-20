-- Various keymaps

local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- Save file
keymap.set("n", "<leader>s", ":w<CR>", { desc = "Save file" })

-- Close file
keymap.set("n", "<leader>q", ":q<CR>", opts)

-- Clear search highlighting
keymap.set("n", "<leader>/", ":nohl<CR>")

-- Increment/decrement
keymap.set("n", "+", "<C-a>")
keymap.set("n", "-", "<C-x>")

-- Open Neotree
keymap.set("n", "<leader>nt", "<Cmd>Neotree toggle reveal<CR>")

-- Open Telescope
keymap.set("n", "<leader>f", ":Telescope find_files hidden=true<CR>")

-- Toggle FTerm
vim.api.nvim_create_user_command('FTermToggle', require('FTerm').toggle, { bang = true })
keymap.set("n", "<A-t>", "<CMD>FTermToggle<CR>")
keymap.set("t", "<A-t>", "<CMD>FTermToggle<CR>")

-- Indent handling
keymap.set('v', '<', '<gv', opts)
keymap.set('v', '>', '>gv', opts)
keymap.set('n', '<', '<<', opts)
keymap.set('n', '>', '>>', opts)
