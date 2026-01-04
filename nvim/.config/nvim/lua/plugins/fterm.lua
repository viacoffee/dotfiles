return {
    {
        "numToStr/FTerm.nvim",
        config = function()
            local fterm = require("FTerm")
            fterm.setup({
                border = "rounded",
                dimensions = {
                    height = 0.8,
                    width = 0.8,
                },
            })
        end,
    },
    {
        'numToStr/FTerm.nvim',
        name = 'FTerm.LazyGit.nvim',
        config = function()
            local fterm = require("FTerm")
            local lazygit = fterm:new({
                cmd = 'lazygit',
            })

            vim.keymap.set('n', '<A-g>', function() lazygit:toggle() end, {desc = 'Toggle [L]azy[G]it'})
            vim.keymap.set('t', '<A-g>', function() lazygit:toggle() end, {desc = 'Toggle [L]azy[G]it'})
        end,
    }
}
