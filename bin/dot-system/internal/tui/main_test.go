package tui

import (
	"strings"
	"testing"

	"dot-system/internal/system"
	"dot-system/internal/updatejob"
	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
)

func TestNavigationPreservesPageSelection(t *testing.T) {
	model := model{
		overview:      system.Overview{Profile: "balanced"},
		pages:         newPages(system.Overview{Profile: "balanced"}, system.FirewallOverview{}),
		selectedItems: make([]int, 6),
	}

	model = updateModel(t, model, tea.WindowSizeMsg{Width: 120, Height: 40})
	model = updateModel(t, model, tea.KeyMsg{Type: tea.KeyDown})
	if model.selectedPage != 1 {
		t.Fatalf("selected page = %d, want Power page", model.selectedPage)
	}

	model = updateModel(t, model, tea.KeyMsg{Type: tea.KeyEnter})
	if model.focus != focusContent {
		t.Fatal("content should receive focus")
	}

	model = updateModel(t, model, tea.KeyMsg{Type: tea.KeyDown})
	if model.selectedItems[1] != 1 {
		t.Fatalf("selected Power setting = %d, want 1", model.selectedItems[1])
	}

	model = updateModel(t, model, tea.KeyMsg{Type: tea.KeyEsc})
	if model.focus != focusSidebar {
		t.Fatal("escape should return focus to the sidebar")
	}
}

func updateModel(t *testing.T, current model, message tea.Msg) model {
	t.Helper()
	updated, _ := current.Update(message)
	return updated.(model)
}

func TestLeftDoesNotExitFromSidebar(t *testing.T) {
	current := model{
		pages:         newPages(system.Overview{}, system.FirewallOverview{}),
		selectedItems: make([]int, 6),
	}

	updated, command := current.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune("h")})
	if command != nil {
		t.Fatal("h should not quit when the sidebar has focus")
	}
	if updated.(model).focus != focusSidebar {
		t.Fatal("h should keep sidebar focus")
	}
}

func TestPowerActionRequiresConfirmation(t *testing.T) {
	current := model{
		focus:         focusContent,
		selectedPage:  1,
		pages:         newPages(system.Overview{}, system.FirewallOverview{}),
		selectedItems: make([]int, 6),
	}
	current.selectedItems[1] = 3

	updated, command := current.Update(tea.KeyMsg{Type: tea.KeyEnter})
	if command != nil {
		t.Fatal("opening a confirmation should not execute the action")
	}
	if updated.(model).pendingAction != system.PowerLock {
		t.Fatal("lock action should require confirmation")
	}
}

func TestFirewallPageCannotReceiveFocus(t *testing.T) {
	current := model{
		selectedPage:  3,
		pages:         newPages(system.Overview{}, system.FirewallOverview{}),
		selectedItems: make([]int, 6),
	}

	updated, _ := current.Update(tea.KeyMsg{Type: tea.KeyEnter})
	if updated.(model).focus != focusSidebar {
		t.Fatal("Firewall page should remain read-only")
	}
}

func TestUnfocusedContentHasNoSelectionMarker(t *testing.T) {
	page := newOverviewPage(system.Overview{Kernel: "test"})
	content := page.Content(0, false, styles{})
	if strings.Contains(content, "> Kernel") {
		t.Fatal("unfocused page content should not render a selection marker")
	}
}

func TestSidebarMarksFocusablePages(t *testing.T) {
	pages := newPages(system.Overview{}, system.FirewallOverview{})
	sidebar := renderSidebar(pages, 1, 24, true, styles{})
	if !strings.Contains(sidebar, "> Power +") {
		t.Fatal("Power page should be marked as focusable")
	}
	if strings.Contains(sidebar, "Firewall +") {
		t.Fatal("Firewall page should not be marked as focusable")
	}
}

func TestCompletedUpdateKeepsStagesAndUsesYesNoRebootPrompt(t *testing.T) {
	page := &updatePage{
		complete: true,
		completed: map[string]bool{
			"snapshot": true,
			"packages": true,
			"orphans":  true,
			"complete": true,
		},
	}
	content := page.Content(0, false, styles{})
	for _, expected := range []string{"Creating pre-update snapshot", "Updating system packages", "Removing orphaned packages", "Finishing up", "[y] Yes", "[n] No"} {
		if !strings.Contains(content, expected) {
			t.Errorf("completed update content missing %q", expected)
		}
	}
	if strings.Contains(content, "Press Enter") {
		t.Fatal("completed update should not prompt reboot with Enter")
	}
}

func TestCompletedUpdateEnterDoesNotReboot(t *testing.T) {
	pages := newPages(system.Overview{}, system.FirewallOverview{})
	update := pages[4].(*updatePage)
	update.complete = true
	current := model{focus: focusContent, selectedPage: 4, pages: pages, selectedItems: make([]int, len(pages))}
	command, handled := current.handleKey("enter")
	if !handled || command != nil || update.rebooting {
		t.Fatal("Enter should not start a reboot")
	}
}

func TestSuccessfulUpdateReconstructsCompletedStages(t *testing.T) {
	page := &updatePage{}
	recordUpdateEvent(page, updatejob.Event{Stage: "complete", State: "success"})
	for _, stage := range updateStageOrder {
		if !page.completed[stage] {
			t.Errorf("successful completion did not retain stage %q", stage)
		}
	}
}

func TestPageForCommand(t *testing.T) {
	page, ok := PageForCommand("firewall")
	if !ok || page != "Firewall" {
		t.Fatalf("PageForCommand(firewall) = %q, %t", page, ok)
	}
	if _, ok := PageForCommand("status"); ok {
		t.Fatal("status should remain a CLI command")
	}
}

func TestUpdateConfirmationRequiresExplicitYes(t *testing.T) {
	pages := newPages(system.Overview{}, system.FirewallOverview{})
	current := model{focus: focusContent, selectedPage: 4, pages: pages, selectedItems: make([]int, len(pages)), viewport: viewport.Model{Width: 80, Height: 20}}
	current.refreshContent()
	current.confirmUpdate = true
	if _, handled := current.handleKey("enter"); !handled || !current.confirmUpdate {
		t.Fatal("Enter should not confirm the update")
	}
	if command, handled := current.handleKey("y"); !handled || command == nil {
		t.Fatal("y should start the authorization step")
	}
	page := current.currentPage().(*updatePage)
	if page.running {
		t.Fatal("update must not lock the UI before authorization succeeds")
	}
}
