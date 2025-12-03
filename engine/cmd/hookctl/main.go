package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"

	"github.com/dandoyle-pdm/workflow-guard/engine/internal/conditions"
	"github.com/dandoyle-pdm/workflow-guard/engine/internal/config"
	"github.com/dandoyle-pdm/workflow-guard/engine/internal/rules"
)

func main() {
	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	command := os.Args[1]

	switch command {
	case "list":
		cmdList()
	case "test":
		if len(os.Args) < 3 {
			fmt.Println("Usage: hookctl test <event.json>")
			os.Exit(1)
		}
		cmdTest(os.Args[2])
	case "config":
		if len(os.Args) < 3 {
			fmt.Println("Usage: hookctl config <show|validate>")
			os.Exit(1)
		}
		switch os.Args[2] {
		case "show":
			cmdConfigShow()
		case "validate":
			cmdConfigValidate()
		default:
			fmt.Println("Unknown config command:", os.Args[2])
			os.Exit(1)
		}
	default:
		fmt.Println("Unknown command:", command)
		printUsage()
		os.Exit(1)
	}
}

func printUsage() {
	fmt.Println("hookctl - Claude Hooks Engine CLI")
	fmt.Println()
	fmt.Println("Usage:")
	fmt.Println("  hookctl list               List all loaded rules")
	fmt.Println("  hookctl test <event.json>  Test rule matching against event file")
	fmt.Println("  hookctl config show        Show configuration sources")
	fmt.Println("  hookctl config validate    Validate configuration")
}

func cmdList() {
	cfg, err := config.LoadConfig()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to load config: %v\n", err)
		os.Exit(1)
	}

	fmt.Println()
	fmt.Println(strings.Repeat("=", 60))
	fmt.Printf(" Active Rules (%d total)\n", len(cfg.Rules))
	fmt.Println(strings.Repeat("=", 60))
	fmt.Println()

	for _, rule := range cfg.Rules {
		if !rule.Enabled {
			continue
		}

		priorityBar := strings.Repeat("█", min(rule.Priority/10, 10))
		fmt.Printf("[%3d] %s\n", rule.Priority, priorityBar)
		fmt.Printf("  ID: %s\n", rule.ID)
		fmt.Printf("  Name: %s\n", rule.Name)
		fmt.Printf("  Trigger: %s → %s\n", rule.Trigger.Event, rule.Trigger.Matcher)
		if len(rule.Tags) > 0 {
			fmt.Printf("  Tags: %s\n", strings.Join(rule.Tags, ", "))
		}
		fmt.Printf("  Actions: %d\n", len(rule.Actions))
		fmt.Println()
	}

	// Summary
	events := make(map[string]bool)
	tags := make(map[string]bool)
	for _, rule := range cfg.Rules {
		if rule.Enabled {
			events[rule.Trigger.Event] = true
			for _, tag := range rule.Tags {
				tags[tag] = true
			}
		}
	}

	eventList := []string{}
	for e := range events {
		eventList = append(eventList, e)
	}
	tagList := []string{}
	for t := range tags {
		tagList = append(tagList, t)
	}

	fmt.Printf("Events covered: %s\n", strings.Join(eventList, ", "))
	fmt.Printf("Tags used: %s\n", strings.Join(tagList, ", "))
	fmt.Printf("Conditions defined: %d\n", len(cfg.Conditions))
	fmt.Printf("Actions defined: %d\n", len(cfg.Actions))
}

func cmdTest(eventFile string) {
	// Load config
	cfg, err := config.LoadConfig()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to load config: %v\n", err)
		os.Exit(1)
	}

	// Load event file
	data, err := os.ReadFile(eventFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to read event file: %v\n", err)
		os.Exit(1)
	}

	var event conditions.HookEvent
	if err := json.Unmarshal(data, &event); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to parse event JSON: %v\n", err)
		os.Exit(1)
	}

	// Prepare raw data
	event.Raw = make(map[string]interface{})
	event.Raw["hook_type"] = event.HookType
	event.Raw["tool_name"] = event.ToolName
	event.Raw["session_id"] = event.SessionID
	event.Raw["tool_input"] = event.ToolInput

	fmt.Println()
	fmt.Println(strings.Repeat("=", 60))
	fmt.Printf(" Testing: %s\n", eventFile)
	fmt.Println(strings.Repeat("=", 60))
	fmt.Println()

	fmt.Println("Event:")
	fmt.Printf("  Type: %s\n", event.HookType)
	fmt.Printf("  Tool: %s\n", event.ToolName)
	inputJSON, _ := json.MarshalIndent(event.ToolInput, "  ", "  ")
	fmt.Printf("  Input: %s\n\n", string(inputJSON))

	// Dispatch
	response := rules.Dispatch(&event, cfg)

	fmt.Println("Result:")
	fmt.Printf("  Exit Code: %d\n", response.ExitCode)
	if response.Decision != "" {
		fmt.Printf("  Decision: %s\n", response.Decision)
	}
	if response.Message != "" {
		fmt.Printf("  Message: %s\n", response.Message)
	}

	os.Exit(response.ExitCode)
}

func cmdConfigShow() {
	homeDir, _ := os.UserHomeDir()
	configPaths := []string{
		homeDir + "/.claude-hooks",
		homeDir + "/.claude",
	}

	if projectDir := os.Getenv("CLAUDE_PROJECT_DIR"); projectDir != "" {
		configPaths = append(configPaths, projectDir+"/.claude")
	}

	fmt.Println()
	fmt.Println(strings.Repeat("=", 60))
	fmt.Println(" Configuration Sources (in precedence order)")
	fmt.Println(strings.Repeat("=", 60))
	fmt.Println()

	for i, path := range configPaths {
		_, err := os.Stat(path)
		exists := err == nil
		status := "✗"
		if exists {
			status = "✓"
		}

		fmt.Printf("%d. [%s] %s\n", i+1, status, path)

		if exists {
			yamlFiles := []string{"rules.yaml", "hooks.yaml", "conditions.yaml", "actions.yaml"}
			for _, yamlFile := range yamlFiles {
				filePath := path + "/" + yamlFile
				if info, err := os.Stat(filePath); err == nil {
					fmt.Printf("       └─ %s (%d bytes)\n", yamlFile, info.Size())
				}
			}
		}
	}

	fmt.Println()

	// Load and show merged config
	cfg, err := config.LoadConfig()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to load config: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("Merged Configuration:")
	fmt.Printf("  Rules: %d\n", len(cfg.Rules))
	fmt.Printf("  Conditions: %d\n", len(cfg.Conditions))
	fmt.Printf("  Actions: %d\n", len(cfg.Actions))
	if cfg.ScriptsDir != "" {
		fmt.Printf("  Scripts: %s\n", cfg.ScriptsDir)
	}
}

func cmdConfigValidate() {
	fmt.Println()
	fmt.Println(strings.Repeat("=", 60))
	fmt.Println(" Validating Configuration")
	fmt.Println(strings.Repeat("=", 60))
	fmt.Println()

	cfg, err := config.LoadConfig()
	if err != nil {
		fmt.Printf("✗ Failed to load config: %v\n", err)
		os.Exit(1)
	}

	errors := []string{}
	warnings := []string{}

	// Check for referenced conditions that don't exist
	for _, rule := range cfg.Rules {
		checkConditionRefs(rule.Conditions, cfg.Conditions, rule.ID, &errors)
	}

	// Check for referenced actions that don't exist
	for _, rule := range cfg.Rules {
		for _, action := range rule.Actions {
			if action.Ref != "" {
				if _, exists := cfg.Actions[action.Ref]; !exists {
					errors = append(errors, fmt.Sprintf("Rule '%s' references unknown action: %s", rule.ID, action.Ref))
				}
			}
		}
	}

	// Print results
	if len(errors) > 0 {
		fmt.Println("ERRORS:")
		for _, err := range errors {
			fmt.Printf("  ✗ %s\n", err)
		}
		fmt.Println()
	}

	if len(warnings) > 0 {
		fmt.Println("WARNINGS:")
		for _, warn := range warnings {
			fmt.Printf("  ⚠ %s\n", warn)
		}
		fmt.Println()
	}

	if len(errors) == 0 && len(warnings) == 0 {
		fmt.Println("✓ Configuration is valid!")
	}

	if len(errors) > 0 {
		os.Exit(1)
	}
}

func checkConditionRefs(cond *config.Condition, available map[string]config.Condition, ruleID string, errors *[]string) {
	if cond == nil {
		return
	}

	if cond.Ref != "" {
		if _, exists := available[cond.Ref]; !exists {
			*errors = append(*errors, fmt.Sprintf("Rule '%s' references unknown condition: %s", ruleID, cond.Ref))
		}
	}

	for _, c := range cond.All {
		checkConditionRefs(&c, available, ruleID, errors)
	}
	for _, c := range cond.Any {
		checkConditionRefs(&c, available, ruleID, errors)
	}
	if cond.Not != nil {
		checkConditionRefs(cond.Not, available, ruleID, errors)
	}
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
