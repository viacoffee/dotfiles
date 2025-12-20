return {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    config = true,
    opts = {
        disable_filetype = { "TelescopePrompt" },
        disable_in_visualblock = true,
        enable_check_bracket_line = true
    }
}
