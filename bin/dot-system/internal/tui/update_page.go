package tui

import (
	"fmt"
	"strings"

	"dot-system/internal/system"
	"dot-system/internal/updatejob"
)

var updateStageOrder = []string{"snapshot", "packages", "orphans", "complete"}

func recordUpdateEvent(page *updatePage, event updatejob.Event) {
	page.event = event
	if page.completed == nil {
		page.completed = make(map[string]bool)
	}
	if page.skipped == nil {
		page.skipped = make(map[string]bool)
	}
	for _, stage := range event.Completed {
		page.completed[stage] = true
	}
	for _, stage := range event.Skipped {
		page.skipped[stage] = true
	}

	stage := event.Stage
	if stage == "download" || stage == "install" {
		stage = "packages"
	}
	currentIndex := -1
	for index, knownStage := range updateStageOrder {
		if stage == knownStage {
			currentIndex = index
			break
		}
	}
	if currentIndex < 0 {
		return
	}
	completedThrough := currentIndex - 1
	if event.State == "complete" || event.State == "success" {
		completedThrough = currentIndex
	}
	if event.State == "failed" {
		completedThrough = currentIndex - 1
	}
	if event.State == "success" {
		completedThrough = len(updateStageOrder) - 1
	}
	for index := 0; index <= completedThrough; index++ {
		page.completed[updateStageOrder[index]] = true
	}
}

type updatePage struct {
	running, complete bool
	rebooting         bool
	rebootDeclined    bool
	err               error
	rebootErr         error
	event             updatejob.Event
	completed         map[string]bool
	skipped           map[string]bool
}

func (*updatePage) Name() string                          { return "System update" }
func (*updatePage) ItemCount() int                        { return 1 }
func (*updatePage) CanFocus() bool                        { return true }
func (*updatePage) ItemLine(int) (int, bool)              { return 2, true }
func (*updatePage) Action(int) (system.PowerAction, bool) { return "", false }

func (p *updatePage) Content(_ int, focused bool, s styles) string {
	title := s.accent.Render("# System update")
	if p.running || p.complete {
		content := p.renderStages(title, s)
		if p.event.Stage == "download" {
			width := 30
			filled := width * p.event.Percent / 100
			content += "\n\n" + s.accent.Render("["+strings.Repeat("█", filled)+strings.Repeat("░", width-filled)+"]") + s.text.Render(fmt.Sprintf(" %d%%", p.event.Percent))
		}
		if p.event.Message != "" {
			content += "\n" + s.muted.Render(p.event.Message)
		}
		if p.err != nil {
			return content + "\n\n" + s.error.Render("Update failed: "+p.err.Error())
		}
		if p.running {
			return content
		}
		if p.rebooting {
			return content + "\n\n" + s.title.Render("Rebooting…")
		}
		if p.rebootErr != nil {
			return content + "\n\n" + s.error.Render("Reboot failed: "+p.rebootErr.Error()) + "\n" + s.warning.Render("[y] Retry   [n] Skip")
		}
		if p.rebootDeclined {
			return content + "\n\n" + s.warning.Render("Reboot skipped.")
		}
		return content + "\n\n" + s.warning.Render("Reboot now? [y] Yes   [n] No")
	}
	line := "  Start update"
	if focused {
		line = "> Start update"
		return title + "\n\n" + s.selected.Render(line)
	}
	return title + "\n\n" + s.text.Render(line)
}

func (p *updatePage) renderStages(title string, s styles) string {
	steps := []struct{ key, label string }{
		{"snapshot", "Creating pre-update snapshot"},
		{"packages", "Updating system packages"},
		{"orphans", "Removing orphaned packages"},
		{"complete", "Finishing up"},
	}
	lines := []string{title, ""}
	for _, step := range steps {
		icon, style := "○", s.muted
		if p.completed[step.key] {
			icon, style = "✓", s.success
		} else if p.skipped[step.key] {
			icon, style = "–", s.muted
		} else if p.event.State == "failed" && (p.event.Stage == step.key || (step.key == "packages" && (p.event.Stage == "download" || p.event.Stage == "install"))) {
			icon, style = "×", s.error
		} else if p.event.Stage == step.key || (step.key == "packages" && (p.event.Stage == "download" || p.event.Stage == "install")) {
			icon, style = "›", s.selected
		}
		lines = append(lines, style.Render(icon+"  "+step.label))
	}
	return strings.Join(lines, "\n")
}
