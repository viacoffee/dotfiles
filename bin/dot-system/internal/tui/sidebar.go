package tui

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
)

func renderSidebar(pages []page, selectedIndex, width int, focused bool, styles styles) string {
	var items strings.Builder
	for index, page := range pages {
		marker := ""
		if page.CanFocus() {
			marker = " +"
		}
		line := "  " + page.Name() + marker
		if index == selectedIndex {
			line = "> " + page.Name() + marker
			if focused {
				items.WriteString(styles.selected.Render(line))
			} else {
				items.WriteString(styles.text.Render(line))
			}
		} else {
			items.WriteString(styles.text.Render(line))
		}
		items.WriteByte('\n')
	}
	return lipgloss.NewStyle().Width(width - 2).PaddingTop(1).Render(items.String())
}
