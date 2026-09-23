package updatejob

import "testing"

func TestParsePercent(t *testing.T) {
	for _, test := range []struct {
		line string
		want int
	}{
		{" 42%", 42},
		{"download progress 42.9%", 42},
		{"100% complete", 100},
		{"not a percentage", -1},
		{"101%", -1},
	} {
		if got := parsePercent(test.line); got != test.want {
			t.Errorf("parsePercent(%q) = %d, want %d", test.line, got, test.want)
		}
	}
}
