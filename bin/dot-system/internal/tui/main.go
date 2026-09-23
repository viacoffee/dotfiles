package tui

import (
	"dot-system/internal/updatejob"
	"fmt"
	"os/exec"
	"strings"
	"time"

	"dot-system/internal/config"
	"dot-system/internal/system"
	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type focusArea uint8

const (
	focusSidebar focusArea = iota
	focusContent
)

type model struct {
	width, height int
	focus         focusArea
	selectedPage  int
	selectedItems []int
	overview      system.Overview
	pages         []page
	styles        styles
	viewport      viewport.Model
	pendingAction system.PowerAction
	status        string
	confirmUpdate bool
	pollAttempts  int
}

type sudoResult struct {
	phase string
	err   error
}
type updatePollMsg struct {
	event updatejob.Event
	err   error
}

type powerActionResult struct {
	action system.PowerAction
	err    error
}

func Run(service system.Service, appConfig config.Config, initialPage string) error {
	overview := service.Overview()
	pages := newPages(overview, service.FirewallOverview())
	selectedPage := pageIndex(pages, initialPage)
	_, err := tea.NewProgram(
		model{
			overview:      overview,
			pages:         pages,
			selectedPage:  selectedPage,
			selectedItems: make([]int, len(pages)),
			styles:        newStyles(appConfig.Colors),
		},
		tea.WithAltScreen(),
	).Run()
	return err
}

func (m model) Init() tea.Cmd { return nil }

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case updatePollMsg:
		if msg.err == nil {
			m.pollAttempts = 0
			if page, ok := m.currentPage().(*updatePage); ok {
				recordUpdateEvent(page, msg.event)
			}
			if msg.event.State == "success" || msg.event.State == "failed" {
				if page, ok := m.currentPage().(*updatePage); ok {
					page.running = false
					page.complete = true
					if msg.event.State == "failed" {
						page.err = fmt.Errorf("%s", msg.event.Message)
					}
				}
				m.refreshContent()
				return m, nil
			}
		}
		m.pollAttempts++
		if m.pollAttempts >= 600 {
			if page, ok := m.currentPage().(*updatePage); ok {
				page.running = false
				page.complete = true
				page.err = fmt.Errorf("update service did not report progress")
			}
			m.refreshContent()
			return m, nil
		}
		m.refreshContent()
		return m, tea.Tick(500*time.Millisecond, func(time.Time) tea.Msg {
			event, err := updatejob.ReadEvent()
			return updatePollMsg{event: event, err: err}
		})
	case sudoResult:
		if msg.err != nil {
			m.confirmUpdate = false
			m.status = fmt.Sprintf("%s failed: %v", msg.phase, msg.err)
			m.refreshContent()
			return m, nil
		}
		if msg.phase == "sudo authentication" {
			return m, tea.ExecProcess(
				exec.Command("sudo", "-n", "systemctl", "start", "--no-block", "dot-system-update.service"),
				func(err error) tea.Msg { return sudoResult{phase: "starting update service", err: err} },
			)
		}
		m.confirmUpdate = false
		m.pollAttempts = 0
		if page, ok := m.currentPage().(*updatePage); ok {
			page.running = true
			m.refreshContent()
			return m, tea.Tick(500*time.Millisecond, func(time.Time) tea.Msg {
				event, err := updatejob.ReadEvent()
				return updatePollMsg{event: event, err: err}
			})
		}
		return m, nil
	case powerActionResult:
		m.pendingAction = ""
		if page, ok := m.currentPage().(*updatePage); ok && msg.action == system.PowerReboot {
			page.rebooting = false
			page.rebootErr = msg.err
			m.refreshContent()
			return m, nil
		}
		if msg.err != nil {
			m.status = fmt.Sprintf("%s failed: %v", msg.action, msg.err)
		}
		m.refreshContent()
		return m, nil
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
		m.resizeViewport()
		return m, nil
	case tea.KeyMsg:
		if cmd, handled := m.handleKey(msg.String()); handled {
			return m, cmd
		}
	}

	if m.focus == focusContent {
		var cmd tea.Cmd
		m.viewport, cmd = m.viewport.Update(msg)
		return m, cmd
	}
	return m, nil
}

func (m *model) handleKey(key string) (tea.Cmd, bool) {
	if page, ok := m.currentPage().(*updatePage); ok && page.running {
		return nil, true
	}
	if page, ok := m.currentPage().(*updatePage); ok && page.complete && page.err == nil {
		switch key {
		case "y":
			page.rebooting = true
			page.rebootErr = nil
			m.refreshContent()
			return func() tea.Msg {
				return powerActionResult{action: system.PowerReboot, err: system.RunPowerAction(system.PowerReboot)}
			}, true
		case "n":
			page.rebootDeclined = true
			m.refreshContent()
			return nil, true
		}
	}
	if m.confirmUpdate {
		switch key {
		case "esc", "n":
			m.confirmUpdate = false
			m.refreshContent()
			return nil, true
		case "y":
			return tea.ExecProcess(
				exec.Command("sudo", "-v"),
				func(err error) tea.Msg { return sudoResult{phase: "sudo authentication", err: err} },
			), true
		}
		return nil, true
	}
	if m.pendingAction != "" {
		switch key {
		case "esc", "n":
			m.pendingAction = ""
			m.refreshContent()
			return nil, true
		case "enter", "y":
			action := m.pendingAction
			return func() tea.Msg {
				return powerActionResult{action: action, err: system.RunPowerAction(action)}
			}, true
		}
		return nil, true
	}

	switch key {
	case "q", "ctrl+c":
		return tea.Quit, true
	case "tab":
		if m.focus == focusSidebar && m.currentPage().CanFocus() {
			m.focus = focusContent
		} else {
			m.focus = focusSidebar
		}
		m.refreshContent()
		return nil, true
	case "esc":
		if m.focus == focusContent {
			m.focus = focusSidebar
			m.refreshContent()
			return nil, true
		}
		return tea.Quit, true
	case "left", "h":
		if m.focus == focusContent {
			m.focus = focusSidebar
			m.refreshContent()
		}
		return nil, true
	case "right", "l":
		if m.focus == focusSidebar && m.currentPage().CanFocus() {
			m.focus = focusContent
			m.refreshContent()
			return nil, true
		}
	case "enter":
		if page, ok := m.currentPage().(*updatePage); ok && m.focus == focusContent {
			if !page.complete {
				m.confirmUpdate = true
				m.refreshContent()
				return nil, true
			}
			return nil, true
		}
		if m.focus == focusSidebar && m.currentPage().CanFocus() {
			m.focus = focusContent
			m.refreshContent()
			return nil, true
		}
		if m.focus == focusContent {
			if action, ok := m.currentPage().Action(m.selectedItems[m.selectedPage]); ok {
				m.pendingAction = action
				m.refreshContent()
			}
			return nil, true
		}
	case "up", "k":
		m.moveSelection(-1)
		return nil, true
	case "down", "j":
		m.moveSelection(1)
		return nil, true
	}
	return nil, false
}

func (m *model) moveSelection(delta int) {
	if m.focus == focusSidebar {
		m.selectedPage = clamp(m.selectedPage+delta, 0, len(m.pages)-1)
		m.refreshContent()
		return
	}

	page := m.currentPage()
	index := clamp(m.selectedItems[m.selectedPage]+delta, 0, page.ItemCount()-1)
	m.selectedItems[m.selectedPage] = index
	m.refreshContent()
	m.revealSelectedItem()
}

func (m *model) resizeViewport() {
	frameWidth := min(max(m.width-8, 70), 110)
	frameHeight := min(max(m.height-4, 20), 42)
	contentWidth := frameWidth - 25
	m.viewport.Width = contentWidth - 4
	m.viewport.Height = frameHeight - 5
	m.refreshContent()
}

func (m *model) refreshContent() {
	if m.viewport.Width == 0 {
		return
	}
	if m.confirmUpdate {
		m.viewport.SetContent(m.styles.title.Render("Confirm system update") + "\n\n" + m.styles.text.Render("Start the update? Navigation will be locked.") + "\n\n" + m.styles.help.Render("[y] Yes   [n/Esc] No"))
		return
	}
	if m.pendingAction != "" {
		m.viewport.SetContent(m.confirmationContent())
		return
	}
	content := m.currentPage().Content(
		m.selectedItems[m.selectedPage],
		m.focus == focusContent,
		m.styles,
	)
	if m.status != "" {
		content += "\n\n" + m.styles.error.Render(m.status)
	}
	m.viewport.SetContent(content)
}

func (m *model) revealSelectedItem() {
	selectedLine, ok := m.currentPage().ItemLine(m.selectedItems[m.selectedPage])
	if !ok {
		return
	}
	if selectedLine < m.viewport.YOffset {
		m.viewport.YOffset = selectedLine
	}
	if selectedLine >= m.viewport.YOffset+m.viewport.Height {
		m.viewport.YOffset = selectedLine - m.viewport.Height + 1
	}
}

func (m model) currentPage() page {
	return m.pages[m.selectedPage]
}

func (m model) View() string {
	if m.width == 0 {
		return ""
	}
	frameWidth := min(max(m.width-8, 70), 110)
	frameHeight := min(max(m.height-4, 20), 42)
	sidebarWidth := 24
	contentWidth := frameWidth - sidebarWidth - 1

	titleText := m.styles.title.Bold(true).Render("dot-system")
	header := lipgloss.JoinHorizontal(lipgloss.Top, titleText, lipgloss.NewStyle().Width(frameWidth-lipgloss.Width(titleText)).Align(lipgloss.Right).Render(m.styles.muted.Render("v0.1.0")))
	sidebar := renderSidebar(m.pages, m.selectedPage, sidebarWidth, m.focus == focusSidebar, m.styles)
	content := lipgloss.NewStyle().Width(contentWidth).PaddingLeft(4).PaddingTop(1).Render(m.viewport.View())
	separator := m.styles.border.Render(strings.Repeat("│\n", frameHeight-5))
	body := lipgloss.JoinHorizontal(lipgloss.Top, sidebar, separator, content)
	help := lipgloss.NewStyle().Width(frameWidth).Align(lipgloss.Center).Render(m.styles.help.Render(m.helpText()))
	frame := lipgloss.JoinVertical(lipgloss.Left, header, m.styles.border.Render("──"), body, help)
	frame = lipgloss.NewStyle().Width(frameWidth).Height(frameHeight).Render(frame)
	return lipgloss.NewStyle().Width(m.width).Height(m.height).Align(lipgloss.Center, lipgloss.Center).Render(frame)
}

func (m model) confirmationContent() string {
	return m.styles.title.Render("Confirm power action") + "\n\n" +
		m.styles.text.Render(fmt.Sprintf("Run %q?", m.pendingAction)) + "\n\n" +
		m.styles.help.Render("[y] Yes   [n/Esc] No")
}

func (m model) helpText() string {
	if m.confirmUpdate {
		m.viewport.SetContent(m.styles.title.Render("Confirm system update") + "\n\n" + m.styles.text.Render("Start the update? Navigation will be locked.") + "\n\n" + m.styles.help.Render("[y] Yes   [n/Esc] No"))
		return "[y] Yes   [n/Esc] No"
	}
	if m.pendingAction != "" {
		return "[y] Yes   [n/Esc] No"
	}
	if m.focus == focusContent {
		return "[↑/↓] Select   [Tab/Esc] Sidebar   [q] Quit"
	}
	return "[↑/↓] Navigate   [Enter/Tab] Select   [q] Quit"
}

func clamp(value, minValue, maxValue int) int {
	if value < minValue {
		return minValue
	}
	if value > maxValue {
		return maxValue
	}
	return value
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
