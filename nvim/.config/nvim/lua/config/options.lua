-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.numberwidth = 6
vim.opt.cursorline = true
vim.opt.wrap = false
vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 8

-- Indentation
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true

-- File handling
vim.opt.backup = false                            -- Don't create backup files
vim.opt.writebackup = false                       -- Don't create backup before writing
vim.opt.swapfile = false                          -- swapfiles... really? who uses these?
vim.opt.undofile = true                           -- Presistent undo
vim.opt.undodir = vim.fn.expand("~/.vim/undodir") -- Undo directory
vim.opt.updatetime = 300                          -- Faster completion
vim.opt.timeoutlen = 500                          -- Key timeout duration
vim.opt.ttimeoutlen = 0                           -- Key code timeout
vim.opt.autoread = true                           -- Auto reload files changed outside vim
vim.opt.autowrite = false                         -- Don't auto save
-- Behavior
vim.opt.hidden = true                             -- Allow hidden buffers
vim.opt.errorbells = false                        -- No more cowbell
vim.opt.backspace = "indent,eol,start"            -- Allow backspacing over everything in insert mode
vim.opt.autochdir = false                         -- Disable directory auto change
vim.opt.iskeyword:append("-")                     -- Treat dash as part of words
vim.opt.path:append("**")                         -- Include subdirectories in search
vim.opt.selection = "exclusive"                   -- Selection Behavior
vim.opt.mouse = "a"                               -- Enable mouse
vim.opt.clipboard = ""                            -- Disable system clipboard
vim.opt.modifiable = true                         -- Allow buffer modifications
vim.opt.encoding = "UTF-8"                        -- Set encoding
-- Splits
vim.opt.splitbelow = true                         -- Horizontal splits go below
vim.opt.splitright = true                         -- Vertical splits go right
-- Clipboard
vim.api.nvim_set_option("clipboard", "unnamedplus")
