-- save file
vim.keymap.set("n", "<leader>s", ":w<CR>", { desc = "Save file" })
-- <leader>/ turn off search highlighting
vim.keymap.set("n", "<leader>/", ":nohl<CR>")
-- open Neotree
vim.keymap.set("n", "<leader>nt", "<Cmd>Neotree toggle reveal<CR>")
-- <leader>/ turn off search highlighting
vim.keymap.set("n", "<leader>/", ":nohl<CR>")
-- telescope
vim.keymap.set("n", "<leader>f", ":Telescope find_files hidden=true<CR>")

-- FTerm
vim.api.nvim_create_user_command('FTermToggle', require('FTerm').toggle, { bang = true })
vim.keymap.set("n", "<A-t>", "<CMD>FTermToggle<CR>")
vim.keymap.set("t", "<A-t>", "<CMD>FTermToggle<CR>")
