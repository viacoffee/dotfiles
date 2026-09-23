package main

import (
	"dot-system/internal/updatejob"
	"os"
)

func main() {
	if len(os.Args) != 1 || os.Geteuid() != 0 {
		os.Exit(2)
	}
	if err := updatejob.Run(); err != nil {
		os.Exit(1)
	}
}
