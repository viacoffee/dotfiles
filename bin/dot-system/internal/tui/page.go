package tui

import (
	"fmt"
	"strings"

	"dot-system/internal/system"
)

type page interface {
	Name() string
	ItemCount() int
	CanFocus() bool
	Content(selected int, focused bool, styles styles) string
	Action(int) (system.PowerAction, bool)
	ItemLine(int) (int, bool)
}

type sectionPage struct {
	name         string
	sections     []section
	emptyMessage string
	focusable    bool
}

type section struct {
	heading string
	items   []item
}

type item struct {
	label  string
	value  string
	action system.PowerAction
}

func (p sectionPage) Name() string { return p.name }

func (p sectionPage) CanFocus() bool { return p.focusable }

func (p sectionPage) ItemCount() int {
	count := 0
	for _, section := range p.sections {
		count += len(section.items)
	}
	return count
}

func (p sectionPage) ItemLine(selected int) (int, bool) {
	line := 2
	index := 0
	for _, section := range p.sections {
		line++
		for range section.items {
			if index == selected {
				return line, true
			}
			line++
			index++
		}
		line++
	}
	return 0, false
}

func (p sectionPage) Action(selected int) (system.PowerAction, bool) {
	item, ok := p.itemAt(selected)
	if !ok || item.action == "" {
		return "", false
	}
	return item.action, true
}

func (p sectionPage) Content(selected int, focused bool, styles styles) string {
	lines := []string{styles.accent.Render("# " + p.name), ""}
	if len(p.sections) == 0 {
		return strings.Join(append(lines, styles.muted.Render(p.emptyMessage)), "\n")
	}

	index := 0
	for _, section := range p.sections {
		lines = append(lines, styles.title.Render(section.heading))
		for _, item := range section.items {
			lines = append(lines, renderItem(item, index == selected, focused, styles))
			index++
		}
		lines = append(lines, "")
	}
	return strings.Join(lines, "\n")
}

func (p sectionPage) itemAt(selected int) (item, bool) {
	index := 0
	for _, section := range p.sections {
		for _, item := range section.items {
			if index == selected {
				return item, true
			}
			index++
		}
	}
	return item{}, false
}

func renderItem(item item, selected bool, focused bool, styles styles) string {
	prefix := "  "
	style := styles.text
	if selected && focused {
		prefix = "> "
		style = styles.selected
	}

	line := fmt.Sprintf("%s%-18s", prefix, item.label)
	if item.value != "" {
		line += " " + item.value
	}
	return style.Render(line)
}
