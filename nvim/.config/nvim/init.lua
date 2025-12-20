-- "minimal" neovim config
--

-- Transparency
--vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
--vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
--vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })

-- Leader
vim.g.mapleader = ","      -- Set leader to comma
vim.g.maplocalleader = "," -- Again, but "newer"

-- include lazy
require("config.lazy")
require("config.keymaps")
require("config.options")
require("config.keymaps")

-- Theme
vim.cmd("colorscheme onedark")

-- Create undo directory if it doesn't exist
local undodir = vim.fn.expand("~/.vim/undodir")
if vim.fn.isdirectory(undodir) == 0 then
    vim.fn.mkdir(undodir, "p")
end
