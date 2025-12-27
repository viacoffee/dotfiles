return {
    'AlexvZyl/nordic.nvim',
    lazy = false,
    priority = 1000,
    config = function()
        require("nordic").load({
            cursorline = {
                theme = "dark",
            },
            telescope = {
                style = "classic",
            },
            bold_keywords = true,
            transparent = {
                -- Enable transparent background.
                bg = false,
            },
        })
    end,
}
