return {
    --{
    --    "xiyaowong/transparent.nvim",
    --    lazy = false,
    --    config = function()
    --        require("transparent").setup({
    --            enable = true,
    --            -- table: default groups
    --            groups = {
    --                'Normal', 'NormalNC', 'Comment', 'Constant', 'Special', 'Identifier',
    --                'Statement', 'PreProc', 'Type', 'Underlined', 'Todo', 'String', 'Function',
    --                'Conditional', 'Repeat', 'Operator', 'Structure', 'LineNr', 'NonText',
    --                'SignColumn', 'StatusLine', 'StatusLineNC', 'EndOfBuffer',
    --            },
    --            -- table: additional groups that should be cleared
    --            extra_groups = {},
    --            -- table: groups you don't want to clear
    --            extra_groups = {
    --                "NvimTreeNormal",
    --                "NeoTreeNormal",
    --                "NeoTreeNormalNC",
    --            },
    --            -- function: code to be executed after highlight groups are cleared
    --            -- Also the user event "TransparentClear" will be triggered
    --            on_clear = function() end,
    --        })
    --    end,
    --},
    {
        "nvimdev/indentmini.nvim",
        config = function()
            require("indentmini").setup()
        end,
    }
}
