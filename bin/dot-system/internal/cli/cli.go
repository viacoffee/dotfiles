package cli

import (
	"fmt"
	"os"

	"dot-system/internal/system"
)

func Run(args []string, service system.Service) int {
	if isHelpRequest(args) {
		printUsage()
		return 0
	}
	if len(args) == 1 && args[0] == "status" {
		fmt.Print(formatOverview(service.Overview()))
		return 0
	}
	if len(args) == 2 && args[0] == "power" {
		action, err := system.ParsePowerAction(args[1])
		if err != nil {
			printUsage()
			return 2
		}
		if err := system.RunPowerAction(action); err != nil {
			fmt.Fprintln(os.Stderr, err)
			return 1
		}
		return 0
	}

	printUsage()
	return 2
}

func formatOverview(info system.Overview) string {
	return fmt.Sprintf("System\n  Kernel: %s\n  Uptime: %s\n\nPower\n  Battery: %s\n  Profile: %s\n\nStorage\n  Root: %s\n\nNetwork\n  Status: %s\n", info.Kernel, info.Uptime, info.Battery, info.Profile, info.Storage, info.Network)
}

func printUsage() {
	fmt.Fprintln(os.Stderr, "Usage: dot-system [status | power <lock|suspend|reboot|shutdown>]")
}

func isHelpRequest(args []string) bool {
	if len(args) == 0 {
		return false
	}
	switch args[len(args)-1] {
	case "help", "--help", "-h":
		return true
	default:
		return false
	}
}
