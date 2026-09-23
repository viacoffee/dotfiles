package updatejob

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"sync"
)

type Event struct {
	Stage     string   `json:"stage"`
	State     string   `json:"state"`
	Percent   int      `json:"percent,omitempty"`
	Message   string   `json:"message,omitempty"`
	Completed []string `json:"completed,omitempty"`
	Skipped   []string `json:"skipped,omitempty"`
}

const statePath = "/run/dot-system-update/state.json"

var eventMu sync.Mutex
var percentPattern = regexp.MustCompile(`([0-9]+(?:\.[0-9]+)?)%`)
var completedStages = make(map[string]bool)
var skippedStages = make(map[string]bool)

func Run() error {
	eventMu.Lock()
	clear(completedStages)
	clear(skippedStages)
	eventMu.Unlock()
	_ = os.Remove(statePath)
	if _, err := exec.LookPath("snapper"); err == nil {
		if err := run("snapshot", "snapper", "-c", "root", "create", "-c", "number", "-d", "pre-update"); err != nil {
			return err
		}
	} else {
		writeEvent(Event{Stage: "snapshot", State: "skipped", Message: "Snapper is not installed"})
	}
	if err := runPacman(); err != nil {
		return err
	}
	if err := removeOrphans(); err != nil {
		return err
	}
	writeEvent(Event{Stage: "complete", State: "success"})
	return nil
}

func run(stage, name string, args ...string) error {
	writeEvent(Event{Stage: stage, State: "running"})
	cmd := exec.Command(name, args...)
	cmd.Stdout, cmd.Stderr = eventWriter{stage}, eventWriter{stage}
	if err := cmd.Run(); err != nil {
		writeEvent(Event{Stage: stage, State: "failed", Message: err.Error()})
		return err
	}
	writeEvent(Event{Stage: stage, State: "complete"})
	return nil
}

func runPacman() error {
	stage := "packages"
	writeEvent(Event{Stage: stage, State: "running"})
	cmd := exec.Command("pacman", "-Syu", "--noconfirm", "--color", "never")
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return err
	}
	cmd.Stderr = eventWriter{stage}
	if err = cmd.Start(); err != nil {
		return err
	}
	scanner := bufio.NewScanner(stdout)
	scanner.Buffer(make([]byte, 4096), 1024*1024)
	for scanner.Scan() {
		line := scanner.Text()
		percent := parsePercent(line)
		if percent >= 0 {
			writeEvent(Event{Stage: "download", State: "running", Percent: percent})
		}
		if strings.Contains(line, "installing ") || strings.Contains(line, "upgrading ") {
			writeEvent(Event{Stage: "install", State: "running", Message: strings.TrimSpace(line)})
		}
	}
	if err = scanner.Err(); err != nil {
		_ = cmd.Process.Kill()
		return err
	}
	if err = cmd.Wait(); err != nil {
		writeEvent(Event{Stage: stage, State: "failed", Message: err.Error()})
		return err
	}
	writeEvent(Event{Stage: stage, State: "complete"})
	return nil
}

func removeOrphans() error {
	out, err := exec.Command("pacman", "-Qtdq").Output()
	if err != nil || strings.TrimSpace(string(out)) == "" {
		writeEvent(Event{Stage: "orphans", State: "complete", Message: "No orphaned packages"})
		return nil
	}
	args := append([]string{"-Rns", "--noconfirm"}, strings.Fields(string(out))...)
	return run("orphans", "pacman", args...)
}

func parsePercent(line string) int {
	match := percentPattern.FindStringSubmatch(line)
	if len(match) == 2 {
		value, err := strconv.ParseFloat(match[1], 64)
		if err == nil && value >= 0 && value <= 100 {
			return int(value)
		}
	}
	return -1
}

type eventWriter struct{ stage string }

func (w eventWriter) Write(p []byte) (int, error) {
	for _, line := range strings.FieldsFunc(string(p), func(r rune) bool { return r == '\n' || r == '\r' }) {
		if line != "" {
			if percent := parsePercent(line); percent >= 0 {
				writeEvent(Event{Stage: "download", State: "running", Percent: percent, Message: line})
			} else {
				writeEvent(Event{Stage: w.stage, State: "log", Message: line})
			}
		}
	}
	return len(p), nil
}

func writeEvent(event Event) {
	eventMu.Lock()
	defer eventMu.Unlock()
	if event.State == "complete" || event.State == "success" {
		completedStages[event.Stage] = true
	}
	if event.State == "skipped" {
		skippedStages[event.Stage] = true
	}
	event.Completed = stageNames(completedStages)
	event.Skipped = stageNames(skippedStages)
	data, _ := json.Marshal(event)
	_, _ = fmt.Fprintln(os.Stdout, string(data))
	dir := "/run/dot-system-update"
	if os.MkdirAll(dir, 0755) != nil {
		return
	}
	tmp, err := os.CreateTemp(dir, ".state-*")
	if err != nil {
		return
	}
	name := tmp.Name()
	if _, err = tmp.Write(data); err == nil {
		err = tmp.Chmod(0644)
	}
	if closeErr := tmp.Close(); err == nil {
		err = closeErr
	}
	if err == nil {
		err = os.Rename(name, statePath)
	}
	if err != nil {
		_ = os.Remove(name)
	}
}

func stageNames(stages map[string]bool) []string {
	names := make([]string, 0, len(stages))
	for name := range stages {
		names = append(names, name)
	}
	sort.Strings(names)
	return names
}

func ReadEvent() (Event, error) {
	data, err := os.ReadFile(statePath)
	if err != nil {
		return Event{}, err
	}
	var event Event
	err = json.Unmarshal(data, &event)
	return event, err
}
