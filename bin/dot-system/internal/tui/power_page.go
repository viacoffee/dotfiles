package tui

import "dot-system/internal/system"

func newPowerPage(info system.Overview) page {
	return sectionPage{
		name:      "Power",
		focusable: true,
		sections: []section{
			{
				heading: "Settings",
				items: []item{
					{label: "Profile", value: info.Profile},
					{label: "Charge limit", value: "80%"},
					{label: "Apply on battery", value: "Enabled"},
				},
			},
			{
				heading: "System",
				items: []item{
					{label: "Lock", action: system.PowerLock},
					{label: "Suspend", action: system.PowerSuspend},
					{label: "Reboot", action: system.PowerReboot},
					{label: "Shutdown", action: system.PowerShutdown},
				},
			},
		},
	}
}
