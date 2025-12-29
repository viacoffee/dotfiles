return {
    {
        "nvimdev/indentmini.nvim",
        config = function()
            require("indentmini").setup()
        end,
    },
    {
        "Darazaki/indent-o-matic",
        config = function()
            require("indent-o-matic").setup({
                max_lines = 2048,
                standard_widths = { 2, 4, 8 },
                skip_multiline = true,
            })
        end,
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup({
                options = {
                    theme = "nordic",
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = { "filetype" },
                    lualine_c = {
                        {
                            "filename",
                            path = 3,
                            shortening_target = 40,
                        },
                    },
                    lualine_x = { "diagnostics" },
                    lualine_y = { "diff" },
                    lualine_z = { "branch" },
                },
            })
        end,
    },
}
