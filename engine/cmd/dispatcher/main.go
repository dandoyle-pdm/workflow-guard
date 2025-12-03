package main

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/dandoyle-pdm/workflow-guard/engine/internal/conditions"
	"github.com/dandoyle-pdm/workflow-guard/engine/internal/config"
	"github.com/dandoyle-pdm/workflow-guard/engine/internal/rules"
)

func main() {
	// Fail-safe: On any error, exit 0 (continue normally)
	defer func() {
		if r := recover(); r != nil {
			fmt.Fprintf(os.Stderr, "Hook engine panic: %v\n", r)
			os.Exit(0)
		}
	}()

	// Load configuration
	cfg, err := config.LoadConfig()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to load config: %v\n", err)
		os.Exit(0) // Fail-safe
	}

	// Parse event from stdin
	var event conditions.HookEvent
	if err := json.NewDecoder(os.Stdin).Decode(&event); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to parse event: %v\n", err)
		os.Exit(0) // Fail-safe
	}

	// Store raw data for field access
	event.Raw = make(map[string]interface{})
	event.Raw["hook_type"] = event.HookType
	event.Raw["tool_name"] = event.ToolName
	event.Raw["session_id"] = event.SessionID
	event.Raw["tool_input"] = event.ToolInput

	// Also check environment for hook type
	if envHookType := os.Getenv("CLAUDE_HOOK_TYPE"); envHookType != "" {
		event.HookType = envHookType
		event.Raw["hook_type"] = envHookType
	}

	// Dispatch to rule engine
	response := rules.Dispatch(&event, cfg)

	// Output response
	if response.Decision != "" {
		output := map[string]string{
			"permissionDecision": response.Decision,
		}
		if response.Message != "" {
			output["message"] = response.Message
		}
		json.NewEncoder(os.Stdout).Encode(output)
	}

	os.Exit(response.ExitCode)
}
