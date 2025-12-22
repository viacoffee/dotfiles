return {
    'nvim-treesitter/nvim-treesitter',
    version = false,
    build = ':TSUpdate',
    lazy = false,
    main = 'nvim-treesitter.configs',
    branch = "master",
    opts = {
        ensure_installed = {
            'bash',
            'c',
            'diff',
            'html',
            'lua',
            'luadoc',
            'markdown',
            'markdown_inline',
            'query',
            'vim',
            'vimdoc',
            "python",
            "css",
            "ruby"
        },
        -- Autoinstall languages that are not installed
        auto_install = true,
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = { 'ruby' },
        },
        indent = { enable = true, disable = { 'ruby' } },
        config = function(_, opts)
            local status_ok, configs = pcall(require, "nvim-tree-sitter.configs")
            if not status_ok then
                return
            end
            configs.setup(opts)
        end,
    },
}
