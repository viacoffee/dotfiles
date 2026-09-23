package tui

import (
	"dot-system/internal/config"
	"github.com/charmbracelet/lipgloss"
)

type styles struct {
	muted, text, title, accent, selected, help, border lipgloss.Style
	success, warning, error                            lipgloss.Style
}

func newStyles(colors config.Colors) styles {
	return styles{
		muted:    lipgloss.NewStyle().Foreground(lipgloss.Color(colors.Muted)),
		text:     lipgloss.NewStyle().Foreground(lipgloss.Color(colors.Text)),
		title:    lipgloss.NewStyle().Foreground(lipgloss.Color(colors.Title)),
		accent:   lipgloss.NewStyle().Foreground(lipgloss.Color(colors.Accent)),
		selected: lipgloss.NewStyle().Foreground(lipgloss.Color(colors.Title)).Bold(true),
		border:   lipgloss.NewStyle().Foreground(lipgloss.Color(colors.Border)),
		help:     lipgloss.NewStyle().Foreground(lipgloss.Color(colors.Help)),
		success:  lipgloss.NewStyle().Foreground(lipgloss.Color("2")),
		warning:  lipgloss.NewStyle().Foreground(lipgloss.Color("3")),
		error:    lipgloss.NewStyle().Foreground(lipgloss.Color("1")),
	}
}
