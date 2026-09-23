package tui

import (
	"strings"

	"dot-system/internal/system"
)

type firewallPage struct{ overview system.FirewallOverview }

func newFirewallPage(overview system.FirewallOverview) page {
	return firewallPage{overview: overview}
}

func (firewallPage) Name() string             { return "Firewall" }
func (firewallPage) ItemCount() int           { return 0 }
func (firewallPage) CanFocus() bool           { return false }
func (firewallPage) ItemLine(int) (int, bool) { return 0, false }
func (firewallPage) Action(int) (system.PowerAction, bool) {
	return "", false
}

func (p firewallPage) Content(_ int, _ bool, styles styles) string {
	lines := []string{styles.accent.Render("# Firewall"), ""}
	lines = append(lines,
		styles.title.Render("UFW"),
		"  "+styles.muted.Render("Service: ")+styles.text.Render(p.overview.Service),
		"  "+styles.muted.Render("Enabled: ")+styles.text.Render(p.overview.Enabled),
		"  "+styles.muted.Render("Package: ")+styles.text.Render(p.overview.Version),
		"",
		styles.title.Render("Forwarding"),
		"  "+styles.muted.Render("IPv4: ")+styles.text.Render(p.overview.IPv4Forwarding),
		"  "+styles.muted.Render("IPv6: ")+styles.text.Render(p.overview.IPv6Forwarding),
		"",
		styles.title.Render("Listening ports"),
	)
	for _, port := range p.overview.ListeningPorts {
		lines = append(lines, "  "+styles.text.Render(port))
	}
	return strings.Join(lines, "\n")
}
