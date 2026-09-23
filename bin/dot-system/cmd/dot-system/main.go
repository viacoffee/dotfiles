package main

import (
	"fmt"
	"os"

	"dot-system/internal/cli"
	appconfig "dot-system/internal/config"
	"dot-system/internal/system"
	"dot-system/internal/tui"
)

func main() {
	service := system.Service{}
	if len(os.Args) == 2 {
		if page, ok := tui.PageForCommand(os.Args[1]); ok {
			runTUI(service, page)
			return
		}
	}
	if len(os.Args) > 1 {
		os.Exit(cli.Run(os.Args[1:], service))
	}

	runTUI(service, "")
}

func runTUI(service system.Service, initialPage string) {
	if err := tui.Run(service, appconfig.Load(), initialPage); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
