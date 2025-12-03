package conditions

import (
	"fmt"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/dandoyle-pdm/workflow-guard/engine/internal/config"
)

// HookEvent represents an incoming hook event
type HookEvent struct {
	HookType  string                 `json:"hook_type"`
	ToolName  string                 `json:"tool_name"`
	ToolInput map[string]interface{} `json:"tool_input"`
	SessionID string                 `json:"session_id"`
	Raw       map[string]interface{} `json:"-"`
}

// Evaluate evaluates a condition against a hook event
func Evaluate(cond *config.Condition, event *HookEvent, cfg *config.Config) bool {
	if cond == nil {
		return true // Empty condition always matches
	}

	// Handle condition reference
	if cond.Ref != "" {
		refCond, exists := cfg.Conditions[cond.Ref]
		if !exists {
			return false
		}
		// Merge referenced condition with any overrides
		merged := mergeCondition(refCond, *cond)
		return Evaluate(&merged, event, cfg)
	}

	// Compound conditions
	if len(cond.All) > 0 {
		for _, c := range cond.All {
			if !Evaluate(&c, event, cfg) {
				return false
			}
		}
		return true
	}

	if len(cond.Any) > 0 {
		for _, c := range cond.Any {
			if Evaluate(&c, event, cfg) {
				return true
			}
		}
		return false
	}

	if cond.Not != nil {
		return !Evaluate(cond.Not, event, cfg)
	}

	// Field-based conditions
	fieldValue := getFieldValue(event.Raw, cond.Field)

	switch cond.Type {
	case "regex":
		return evaluateRegex(cond, fieldValue)
	case "glob":
		return evaluateGlob(cond, fieldValue)
	case "equals":
		return evaluateEquals(cond, fieldValue)
	case "exists":
		return fieldValue != nil
	default:
		return false
	}
}

func mergeCondition(base config.Condition, override config.Condition) config.Condition {
	// Start with base, apply non-empty overrides
	result := base
	if override.Type != "" {
		result.Type = override.Type
	}
	if override.Field != "" {
		result.Field = override.Field
	}
	if override.Pattern != "" {
		result.Pattern = override.Pattern
	}
	if override.Value != "" {
		result.Value = override.Value
	}
	if override.Operator != "" {
		result.Operator = override.Operator
	}
	if len(override.Flags) > 0 {
		result.Flags = override.Flags
	}
	return result
}

func getFieldValue(data map[string]interface{}, fieldPath string) interface{} {
	if fieldPath == "" {
		return nil
	}

	parts := strings.Split(fieldPath, ".")
	var current interface{} = data

	for _, part := range parts {
		m, ok := current.(map[string]interface{})
		if !ok {
			return nil
		}
		current = m[part]
		if current == nil {
			return nil
		}
	}

	return current
}

func evaluateRegex(cond *config.Condition, fieldValue interface{}) bool {
	if fieldValue == nil {
		return false
	}

	valueStr := fmt.Sprintf("%v", fieldValue)
	flags := 0
	for _, flag := range cond.Flags {
		if flag == "ignorecase" {
			flags = 1 // Use (?i) flag
		}
	}

	pattern := cond.Pattern
	if flags == 1 {
		pattern = "(?i)" + pattern
	}

	matched, err := regexp.MatchString(pattern, valueStr)
	if err != nil {
		return false
	}
	return matched
}

func evaluateGlob(cond *config.Condition, fieldValue interface{}) bool {
	if fieldValue == nil {
		return false
	}

	valueStr := fmt.Sprintf("%v", fieldValue)
	matched, err := filepath.Match(cond.Pattern, filepath.Base(valueStr))
	if err != nil {
		return false
	}

	// Also check full path match for patterns with **
	if strings.Contains(cond.Pattern, "**") {
		// Simple ** implementation
		pattern := strings.ReplaceAll(cond.Pattern, "**", "*")
		if m, _ := filepath.Match(pattern, valueStr); m {
			return true
		}
	}

	return matched
}

func evaluateEquals(cond *config.Condition, fieldValue interface{}) bool {
	if fieldValue == nil {
		return false
	}

	fieldStr := fmt.Sprintf("%v", fieldValue)
	valueStr := cond.Value
	operator := cond.Operator
	if operator == "" {
		operator = "equals"
	}

	switch operator {
	case "equals":
		return fieldStr == valueStr
	case "startswith":
		return strings.HasPrefix(fieldStr, valueStr)
	case "endswith":
		return strings.HasSuffix(fieldStr, valueStr)
	case "contains":
		return strings.Contains(fieldStr, valueStr)
	default:
		return false
	}
}
