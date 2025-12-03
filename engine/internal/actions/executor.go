package actions

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/dandoyle-pdm/workflow-guard/engine/internal/conditions"
	"github.com/dandoyle-pdm/workflow-guard/engine/internal/config"
)

// Response represents a hook response
type Response struct {
	ExitCode int
	Decision string // allow, deny, ask
	Message  string
}

// Execute executes an action and returns a response if terminal
func Execute(action *config.Action, event *conditions.HookEvent, cfg *config.Config) *Response {
	if action == nil {
		return nil
	}

	// Handle action reference
	if action.Ref != "" {
		refAction, exists := cfg.Actions[action.Ref]
		if !exists {
			return nil
		}
		// Merge params if provided
		merged := refAction
		if len(action.Params) > 0 {
			if merged.Params == nil {
				merged.Params = make(map[string]interface{})
			}
			for k, v := range action.Params {
				merged.Params[k] = v
			}
		}
		return Execute(&merged, event, cfg)
	}

	switch action.Type {
	case "decision":
		return executeDecision(action, event)
	case "log":
		return executeLog(action, event)
	case "chain":
		return executeChain(action, event, cfg)
	case "conditional":
		return executeConditional(action, event, cfg)
	default:
		return nil
	}
}

func executeDecision(action *config.Action, event *conditions.HookEvent) *Response {
	decision := action.Decision
	message := renderTemplate(action.Message, event, action.Params)

	resp := &Response{}
	switch decision {
	case "deny", "block":
		resp.ExitCode = 2
		resp.Decision = "deny"
		resp.Message = message
	case "allow":
		resp.ExitCode = 0
		resp.Decision = "allow"
	case "ask":
		resp.ExitCode = 0
		resp.Decision = "ask"
		resp.Message = message
	default:
		resp.ExitCode = 0
	}

	return resp
}

func executeLog(action *config.Action, event *conditions.HookEvent) *Response {
	logFile := "~/.claude/logs/hooks.jsonl"
	if action.Params != nil {
		if lf, ok := action.Params["log_file"].(string); ok {
			logFile = lf
		}
	}

	// Expand home directory
	if strings.HasPrefix(logFile, "~/") {
		homeDir, err := os.UserHomeDir()
		if err == nil {
			logFile = filepath.Join(homeDir, logFile[2:])
		}
	}

	// Create directory if needed
	dir := filepath.Dir(logFile)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return nil
	}

	// Create log entry
	entry := map[string]interface{}{
		"timestamp":  time.Now().Format(time.RFC3339),
		"event_type": event.HookType,
		"tool_name":  event.ToolName,
		"tool_input": event.ToolInput,
		"session_id": event.SessionID,
	}

	// Append to log file
	f, err := os.OpenFile(logFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return nil
	}
	defer f.Close()

	data, _ := json.Marshal(entry)
	f.Write(data)
	f.WriteString("\n")

	return nil // Non-terminal action
}

func executeChain(action *config.Action, event *conditions.HookEvent, cfg *config.Config) *Response {
	for _, subAction := range action.Actions {
		// Merge parent params into sub-action params
		if len(action.Params) > 0 {
			if subAction.Params == nil {
				subAction.Params = make(map[string]interface{})
			}
			for k, v := range action.Params {
				// Only add if not already present (sub-action params take precedence)
				if _, exists := subAction.Params[k]; !exists {
					subAction.Params[k] = v
				}
			}
		}

		resp := Execute(&subAction, event, cfg)
		if resp != nil {
			return resp // First terminal action wins
		}
	}
	return nil
}

func executeConditional(action *config.Action, event *conditions.HookEvent, cfg *config.Config) *Response {
	if action.Condition != nil {
		matches := conditions.Evaluate(action.Condition, event, cfg)
		if matches && action.Then != nil {
			return Execute(action.Then, event, cfg)
		} else if !matches && action.Else != nil {
			return Execute(action.Else, event, cfg)
		}
	}
	return nil
}

func renderTemplate(template string, event *conditions.HookEvent, params map[string]interface{}) string {
	result := template

	// Build context from event and params
	context := make(map[string]string)
	context["tool_name"] = event.ToolName
	context["session_id"] = event.SessionID

	// Add tool_input fields
	for k, v := range event.ToolInput {
		context[k] = fmt.Sprintf("%v", v)
	}

	// Add params (override if same key)
	if params != nil {
		for k, v := range params {
			context[k] = fmt.Sprintf("%v", v)
		}
	}

	// Replace {{variable}} with values
	// Do multiple passes to handle nested templates
	for pass := 0; pass < 3; pass++ {
		changed := false
		for key, value := range context {
			placeholder := fmt.Sprintf("{{%s}}", key)
			if strings.Contains(result, placeholder) {
				result = strings.ReplaceAll(result, placeholder, value)
				changed = true
			}
		}
		if !changed {
			break
		}
	}

	return result
}
