return {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
    },
    opts = {
        filesystem = {
            show_directory_items = false,
            filtered_items = {
                visible = true,
                show_hidden_count = true,
                hide_dotfiles = false,
                hide_gitignored = true,
                hide_by_name = {
                    ".github",
                    ".gitignore",
                    "package-lock.json",
                    ".changeset",
                    ".prettierrc.json",
                    ".git/"
                },
                never_show = {},
            },
        },
        window = {
            mappings = {
                ["x"] = "close_node",
                ["i"] = "open_vsplit",
                ["s"] = "open_split",
            }
        }
    }
}
