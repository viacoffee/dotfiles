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
    },
    {
        "Darazaki/indent-o-matic",
        config = function()
            require('indent-o-matic').setup({
                -- The values indicated here are the defaults
                -- Number of lines without indentation before giving up (use -1 for infinite)
                max_lines = 2048,
                -- Space indentations that should be detected
                standard_widths = { 2, 4, 8 },
                -- Skip multi-line comments and strings (more accurate detection but less performant)
                skip_multiline = true,
            })
        end,
    },
}
