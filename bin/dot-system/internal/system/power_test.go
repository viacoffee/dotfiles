package system

import "testing"

func TestParsePowerAction(t *testing.T) {
	for _, action := range []PowerAction{PowerLock, PowerSuspend, PowerReboot, PowerShutdown} {
		parsed, err := ParsePowerAction(string(action))
		if err != nil {
			t.Fatalf("ParsePowerAction(%q): %v", action, err)
		}
		if parsed != action {
			t.Fatalf("ParsePowerAction(%q) = %q", action, parsed)
		}
	}

	if _, err := ParsePowerAction("hibernate"); err == nil {
		t.Fatal("ParsePowerAction accepted an unsupported action")
	}
}

func TestPowerCommand(t *testing.T) {
	command, err := powerCommand(PowerShutdown)
	if err != nil {
		t.Fatal(err)
	}
	if command != "dot-cmd-shutdown" {
		t.Fatalf("shutdown command = %q", command)
	}
}

func TestFormatPortRanges(t *testing.T) {
	ports := []int{53317, 80, 81, 443, 80, 82}
	if got := formatPortRanges(ports); got != "80-82, 443, 53317" {
		t.Fatalf("formatPortRanges() = %q", got)
	}
}
