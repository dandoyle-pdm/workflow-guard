package config

import (
	"os"
	"path/filepath"

	"gopkg.in/yaml.v3"
)

// Condition represents a condition definition
type Condition struct {
	Type     string                 `yaml:"type"`
	Field    string                 `yaml:"field"`
	Pattern  string                 `yaml:"pattern"`
	Value    string                 `yaml:"value"`
	Operator string                 `yaml:"operator"`
	Flags    []string               `yaml:"flags"`
	All      []Condition            `yaml:"all"`
	Any      []Condition            `yaml:"any"`
	Not      *Condition             `yaml:"not"`
	Ref      string                 `yaml:"ref"`
	Script   string                 `yaml:"script"`
	Timeout  int                    `yaml:"timeout"`
	Builtin  string                 `yaml:"builtin"`
	Params   map[string]interface{} `yaml:"params"`
}

// Action represents an action definition
type Action struct {
	Type       string                 `yaml:"type"`
	Decision   string                 `yaml:"decision"`
	Message    string                 `yaml:"message"`
	Script     string                 `yaml:"script"`
	Async      bool                   `yaml:"async"`
	Timeout    int                    `yaml:"timeout"`
	Actions    []Action               `yaml:"actions"`
	Ref        string                 `yaml:"ref"`
	Params     map[string]interface{} `yaml:"params"`
	Condition  *Condition             `yaml:"condition"`
	Then       *Action                `yaml:"then"`
	Else       *Action                `yaml:"else"`
	Transforms []Transform            `yaml:"transforms"`
}

// Transform represents an input transformation
type Transform struct {
	Field     string `yaml:"field"`
	Operation string `yaml:"operation"`
	Value     string `yaml:"value"`
}

// Trigger defines when a rule should fire
type Trigger struct {
	Event   string `yaml:"event"`
	Matcher string `yaml:"matcher"`
}

// Rule represents a complete rule definition
type Rule struct {
	ID          string     `yaml:"id"`
	Name        string     `yaml:"name"`
	Description string     `yaml:"description"`
	Enabled     bool       `yaml:"enabled"`
	Priority    int        `yaml:"priority"`
	Tags        []string   `yaml:"tags"`
	Trigger     Trigger    `yaml:"trigger"`
	Conditions  *Condition `yaml:"conditions"`
	Actions     []Action   `yaml:"actions"`
}

// Config represents the complete loaded configuration
type Config struct {
	Rules      []Rule               `yaml:"rules"`
	Conditions map[string]Condition `yaml:"conditions"`
	Actions    map[string]Action    `yaml:"actions"`
	ScriptsDir string               `yaml:"-"`
}

// LoadConfig loads and merges YAML configuration from standard paths
func LoadConfig() (*Config, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return nil, err
	}

	// Configuration search paths (in order of precedence)
	configPaths := []string{
		filepath.Join(homeDir, ".claude-hooks"),
		filepath.Join(homeDir, ".claude"),
	}

	// Add project-level config if CLAUDE_PROJECT_DIR is set
	if projectDir := os.Getenv("CLAUDE_PROJECT_DIR"); projectDir != "" {
		configPaths = append(configPaths, filepath.Join(projectDir, ".claude"))
	}

	config := &Config{
		Rules:      []Rule{},
		Conditions: make(map[string]Condition),
		Actions:    make(map[string]Action),
	}

	// Load and merge configs from all paths
	for _, basePath := range configPaths {
		if _, err := os.Stat(basePath); os.IsNotExist(err) {
			continue
		}

		// Load conditions
		condPath := filepath.Join(basePath, "conditions.yaml")
		if conditions, err := loadConditions(condPath); err == nil {
			for k, v := range conditions {
				config.Conditions[k] = v
			}
		}

		// Load actions
		actPath := filepath.Join(basePath, "actions.yaml")
		if actions, err := loadActions(actPath); err == nil {
			for k, v := range actions {
				config.Actions[k] = v
			}
		}

		// Load rules
		rulesPath := filepath.Join(basePath, "rules.yaml")
		if rules, err := loadRules(rulesPath); err == nil {
			config.Rules = append(config.Rules, rules...)
		}
		// Try alternative name
		hooksPath := filepath.Join(basePath, "hooks.yaml")
		if rules, err := loadRules(hooksPath); err == nil {
			config.Rules = append(config.Rules, rules...)
		}

		// Track scripts directory
		scriptsDir := filepath.Join(basePath, "scripts")
		if _, err := os.Stat(scriptsDir); err == nil {
			config.ScriptsDir = scriptsDir
		}
	}

	return config, nil
}

func loadConditions(path string) (map[string]Condition, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	var wrapper struct {
		Conditions map[string]Condition `yaml:"conditions"`
	}
	if err := yaml.Unmarshal(data, &wrapper); err != nil {
		return nil, err
	}

	return wrapper.Conditions, nil
}

func loadActions(path string) (map[string]Action, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	var wrapper struct {
		Actions map[string]Action `yaml:"actions"`
	}
	if err := yaml.Unmarshal(data, &wrapper); err != nil {
		return nil, err
	}

	return wrapper.Actions, nil
}

func loadRules(path string) ([]Rule, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	var wrapper struct {
		Rules []Rule `yaml:"rules"`
	}
	if err := yaml.Unmarshal(data, &wrapper); err != nil {
		return nil, err
	}

	return wrapper.Rules, nil
}
