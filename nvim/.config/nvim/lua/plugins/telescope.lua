return {
    'nvim-telescope/telescope.nvim', tag = 'v0.2.0',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
        defaults = {
            file_ignore_patterns = { ".git" },
            layout_strategy = 'horizontal',
            layout_config = {
                horizontal = {
                    prompt_position = "top",
                    preview_width = 0.6,
                },
            },
        }
    },
}
