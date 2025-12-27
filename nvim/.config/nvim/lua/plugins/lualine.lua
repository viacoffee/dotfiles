return {
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            require('lualine').setup({
                options= {
                    theme = 'nordic'
                },
                sections = {
                    lualine_a = {'mode'},
                    lualine_b = {'branch', 'diff', 'diagnostics'},
                    lualine_c = {
                        {
                            'filename',
                            path = 3,
                            shorting_target = 40,
                        },
                    },
                    lualine_x = {'filetype'},
                    lualine_y = {'progress'},
                    lualine_z = {'location'}
                },
            })
        end
    }
}
