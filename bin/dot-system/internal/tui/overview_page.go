package tui

import "dot-system/internal/system"

func newOverviewPage(info system.Overview) page {
	return sectionPage{
		name: "Overview",
		sections: []section{
			{heading: "System", items: []item{{label: "Kernel", value: info.Kernel}, {label: "Uptime", value: info.Uptime}}},
			{heading: "Power", items: []item{{label: "Battery", value: info.Battery}, {label: "Profile", value: info.Profile}}},
			{heading: "Storage", items: []item{{label: "Root", value: info.Storage}}},
			{heading: "Network", items: []item{{label: "Status", value: info.Network}}},
		},
	}
}
