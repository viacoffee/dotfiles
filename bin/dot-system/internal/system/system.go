package system

import (
	"fmt"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
)

type Overview struct {
	Kernel  string
	Uptime  string
	Battery string
	Profile string
	Storage string
	Network string
}

type Service struct{}

func (Service) Overview() Overview {
	return Overview{
		Kernel:  commandOutput("uname", "-r"),
		Uptime:  uptime(),
		Battery: battery(),
		Profile: commandOutput("powerprofilesctl", "get"),
		Storage: storage(),
		Network: network(),
	}
}

func commandOutput(name string, args ...string) string {
	output, err := exec.Command(name, args...).Output()
	if err != nil {
		return "unknown"
	}
	return strings.TrimSpace(string(output))
}

func uptime() string {
	contents, err := os.ReadFile("/proc/uptime")
	if err != nil {
		return "unknown"
	}

	fields := strings.Fields(string(contents))
	if len(fields) == 0 {
		return "unknown"
	}
	seconds, err := strconv.ParseFloat(fields[0], 64)
	if err != nil {
		return "unknown"
	}

	return fmt.Sprintf("%dd %02dh %02dm", int(seconds)/86400, int(seconds)%86400/3600, int(seconds)%3600/60)
}

func battery() string {
	paths, err := filepath.Glob("/sys/class/power_supply/BAT*/capacity")
	if err != nil || len(paths) == 0 {
		return "unavailable"
	}

	level := strings.TrimSpace(string(readFile(paths[0])))
	statusPath := filepath.Join(filepath.Dir(paths[0]), "status")
	status := strings.ToLower(strings.TrimSpace(string(readFile(statusPath))))
	return level + "% - " + status
}

func storage() string {
	output, err := exec.Command("df", "-hP", "/").Output()
	if err != nil {
		return "unknown"
	}

	lines := strings.Split(strings.TrimSpace(string(output)), "\n")
	if len(lines) < 2 {
		return "unknown"
	}
	fields := strings.Fields(lines[len(lines)-1])
	if len(fields) < 5 {
		return "unknown"
	}
	return fields[2] + " / " + fields[1] + " (" + fields[4] + ")"
}

func network() string {
	output, err := exec.Command("ip", "-brief", "address", "show", "up").Output()
	if err != nil {
		return "unknown"
	}

	var interfaces []string
	for _, line := range strings.Split(strings.TrimSpace(string(output)), "\n") {
		fields := strings.Fields(line)
		if len(fields) >= 2 && fields[0] != "lo" {
			interfaces = append(interfaces, fields[0]+" ("+fields[1]+")")
		}
	}
	if len(interfaces) == 0 {
		return "offline"
	}
	return strings.Join(interfaces, ", ")
}

func readFile(path string) []byte {
	contents, _ := os.ReadFile(path)
	return contents
}

type PowerAction string

const (
	PowerLock     PowerAction = "lock"
	PowerSuspend  PowerAction = "suspend"
	PowerReboot   PowerAction = "reboot"
	PowerShutdown PowerAction = "shutdown"
)

func ParsePowerAction(value string) (PowerAction, error) {
	action := PowerAction(value)
	switch action {
	case PowerLock, PowerSuspend, PowerReboot, PowerShutdown:
		return action, nil
	default:
		return "", fmt.Errorf("unknown power action: %s", value)
	}
}

func RunPowerAction(action PowerAction) error {
	command, err := powerCommand(action)
	if err != nil {
		return err
	}
	return exec.Command(command).Run()
}

func powerCommand(action PowerAction) (string, error) {
	switch action {
	case PowerLock:
		return "dot-cmd-lock", nil
	case PowerSuspend:
		return "dot-cmd-suspend", nil
	case PowerReboot:
		return "dot-cmd-reboot", nil
	case PowerShutdown:
		return "dot-cmd-shutdown", nil
	default:
		return "", fmt.Errorf("unknown power action: %s", action)
	}
}

type FirewallOverview struct {
	Service        string
	Enabled        string
	Version        string
	IPv4Forwarding string
	IPv6Forwarding string
	ListeningPorts []string
}

func (Service) FirewallOverview() FirewallOverview {
	return FirewallOverview{
		Service:        commandStatus("systemctl", "is-active", "ufw.service"),
		Enabled:        commandStatus("systemctl", "is-enabled", "ufw.service"),
		Version:        ufwVersion(),
		IPv4Forwarding: sysctlValue("net.ipv4.ip_forward"),
		IPv6Forwarding: sysctlValue("net.ipv6.conf.all.forwarding"),
		ListeningPorts: listeningPorts(),
	}
}

func commandStatus(name string, args ...string) string {
	output, err := exec.Command(name, args...).Output()
	value := strings.TrimSpace(string(output))
	if value != "" {
		return value
	}
	if err != nil {
		return "unavailable"
	}
	return "unknown"
}

func ufwVersion() string {
	output, err := exec.Command("pacman", "-Q", "ufw").Output()
	if err != nil {
		return "not installed"
	}
	return strings.TrimSpace(string(output))
}

func sysctlValue(name string) string {
	return commandStatus("sysctl", "-n", name)
}

func listeningPorts() []string {
	output, err := exec.Command("ss", "-H", "-tuln").Output()
	if err != nil {
		return []string{"unavailable"}
	}

	portsByProtocol := make(map[string][]int)
	for _, line := range strings.Split(strings.TrimSpace(string(output)), "\n") {
		fields := strings.Fields(line)
		if len(fields) < 5 {
			continue
		}
		protocol := strings.TrimSuffix(fields[0], "6")
		if protocol != "tcp" && protocol != "udp" {
			continue
		}
		_, port, err := net.SplitHostPort(fields[4])
		if err != nil {
			continue
		}
		value, err := strconv.Atoi(port)
		if err != nil {
			continue
		}
		portsByProtocol[protocol] = append(portsByProtocol[protocol], value)
	}

	var summaries []string
	for _, protocol := range []string{"tcp", "udp"} {
		ports := portsByProtocol[protocol]
		if len(ports) == 0 {
			continue
		}
		summaries = append(summaries, strings.ToUpper(protocol)+": "+formatPortRanges(ports))
	}
	if len(summaries) == 0 {
		return []string{"none"}
	}
	return summaries
}

func formatPortRanges(ports []int) string {
	sort.Ints(ports)

	unique := ports[:0]
	for _, port := range ports {
		if len(unique) == 0 || unique[len(unique)-1] != port {
			unique = append(unique, port)
		}
	}

	var ranges []string
	for start := 0; start < len(unique); {
		end := start
		for end+1 < len(unique) && unique[end+1] == unique[end]+1 {
			end++
		}
		if start == end {
			ranges = append(ranges, strconv.Itoa(unique[start]))
		} else {
			ranges = append(ranges, fmt.Sprintf("%d-%d", unique[start], unique[end]))
		}
		start = end + 1
	}
	return strings.Join(ranges, ", ")
}
