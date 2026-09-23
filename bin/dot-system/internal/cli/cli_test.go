package cli

import "testing"

func TestHelpRequests(t *testing.T) {
	for _, args := range [][]string{{"help"}, {"--help"}, {"power", "help"}} {
		if !isHelpRequest(args) {
			t.Fatalf("isHelpRequest(%q) = false", args)
		}
	}
}
