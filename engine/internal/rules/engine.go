package rules

import (
	"regexp"
	"sort"

	"github.com/dandoyle-pdm/workflow-guard/engine/internal/actions"
	"github.com/dandoyle-pdm/workflow-guard/engine/internal/conditions"
	"github.com/dandoyle-pdm/workflow-guard/engine/internal/config"
)

// Dispatch evaluates rules and returns a response
func Dispatch(event *conditions.HookEvent, cfg *config.Config) *actions.Response {
	// Filter enabled rules
	enabledRules := []config.Rule{}
	for _, rule := range cfg.Rules {
		if rule.Enabled {
			enabledRules = append(enabledRules, rule)
		}
	}

	// Sort by priority (higher first)
	sort.Slice(enabledRules, func(i, j int) bool {
		return enabledRules[i].Priority > enabledRules[j].Priority
	})

	// Evaluate rules in priority order
	for _, rule := range enabledRules {
		if !matchesTrigger(&rule, event) {
			continue
		}

		// Check conditions
		if rule.Conditions != nil {
			if !conditions.Evaluate(rule.Conditions, event, cfg) {
				continue
			}
		}

		// Execute actions
		for _, action := range rule.Actions {
			resp := actions.Execute(&action, event, cfg)
			if resp != nil {
				return resp // Terminal action
			}
		}
	}

	// No terminal action - continue normally
	return &actions.Response{ExitCode: 0}
}

func matchesTrigger(rule *config.Rule, event *conditions.HookEvent) bool {
	// Check event type
	if rule.Trigger.Event != "" && rule.Trigger.Event != event.HookType {
		return false
	}

	// Check tool matcher (regex)
	if rule.Trigger.Matcher != "" {
		matched, err := regexp.MatchString(rule.Trigger.Matcher, event.ToolName)
		if err != nil || !matched {
			return false
		}
	}

	return true
}
