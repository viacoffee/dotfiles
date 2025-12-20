# Helper functions
category() {
    gum style --foreground=212 --bold --padding "1 2" "//$1"
}

sub_category() {
    gum style --trim --foreground=5 "...$1"
}

success() {
    gum style --trim --foreground=4 "$1"
}

error() {
    gum style --trim --foreground=1 "Error: $1..."
}

rmvoid() {
    rm -rf $1 2>/dev/null
}
