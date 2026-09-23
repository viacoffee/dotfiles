package config

import (
	"os"
	"path/filepath"

	"github.com/BurntSushi/toml"
)

type Config struct {
	Colors Colors `toml:"colors"`
}
type Colors struct{ Muted, Border, Text, Title, Accent, Help string }

func Load() Config {
	result := Config{Colors: Colors{Muted: "8", Border: "8", Text: "7", Title: "15", Accent: "3", Help: "8"}}
	dir := os.Getenv("XDG_CONFIG_HOME")
	if dir == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			return result
		}
		dir = filepath.Join(home, ".config")
	}
	file, err := os.Open(filepath.Join(dir, "dot-system", "config.toml"))
	if err != nil {
		return result
	}
	defer file.Close()
	var user Config
	if _, err := toml.NewDecoder(file).Decode(&user); err != nil {
		return result
	}
	if user.Colors.Muted != "" {
		result.Colors.Muted = user.Colors.Muted
	}
	if user.Colors.Border != "" {
		result.Colors.Border = user.Colors.Border
	}
	if user.Colors.Text != "" {
		result.Colors.Text = user.Colors.Text
	}
	if user.Colors.Title != "" {
		result.Colors.Title = user.Colors.Title
	}
	if user.Colors.Accent != "" {
		result.Colors.Accent = user.Colors.Accent
	}
	if user.Colors.Help != "" {
		result.Colors.Help = user.Colors.Help
	}
	return result
}
