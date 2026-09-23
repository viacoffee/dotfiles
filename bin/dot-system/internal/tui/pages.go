package tui

import "dot-system/internal/system"

func newPages(info system.Overview, firewall system.FirewallOverview) []page {
	return []page{
		newOverviewPage(info),
		newPowerPage(info),
		newFirewallPage(firewall),
		newPlaceholderPage("Snapshots"),
		&updatePage{},
	}
}

func PageForCommand(command string) (string, bool) {
	pages := map[string]string{
		"power":     "Power",
		"firewall":  "Firewall",
		"snapshots": "Snapshots",
		"update":    "System update",
	}
	page, ok := pages[command]
	return page, ok
}

func pageIndex(pages []page, name string) int {
	for index, page := range pages {
		if page.Name() == name {
			return index
		}
	}
	return 0
}
