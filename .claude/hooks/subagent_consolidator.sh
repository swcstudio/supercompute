#!/bin/bash
# SubagentStop Hook - Subagent Consolidator
# Captures subagent completions and enables autonomous workflow chaining

# Create necessary directories
mkdir -p ~/.claude/hooks/subagents
mkdir -p ~/.claude/hooks/workflows
mkdir -p ~/.claude/hooks/business

# Parse JSON input from SubagentStop event
input=$(cat)

# Extract subagent information
subagent_type=$(echo "$input" | jq -r '.subagent_type // empty')
task_description=$(echo "$input" | jq -r '.task_description // .description // empty')
execution_time=$(echo "$input" | jq -r '.execution_time_ms // empty')
success=$(echo "$input" | jq -r '.success // true')
output_summary=$(echo "$input" | jq -r '.output_summary // .result // empty')
error_message=$(echo "$input" | jq -r '.error_message // .error // empty')

# Function to log subagent activity
log_subagent_activity() {
    local type="$1"
    local data="$2"
    echo "{\"timestamp\": \"$(date -Iseconds)\", \"type\": \"$type\", \"data\": $data}" >> ~/.claude/hooks/subagents/activity.log
}

# Function to analyze subagent performance
analyze_subagent_performance() {
    local agent_type="$1"
    local success="$2"
    local exec_time="$3"
    local task_desc="$4"
    
    local performance_file="~/.claude/hooks/subagents/performance.json"
    [[ ! -f "$performance_file" ]] && echo '{}' > "$performance_file"
    
    # Update success/failure counts
    local success_key="${agent_type}_success"
    local failure_key="${agent_type}_failure"
    local timing_key="${agent_type}_timing"
    
    if [[ "$success" == "true" ]]; then
        # Update success count
        current_success=$(jq -r --arg key "$success_key" '.[$key] // 0' "$performance_file")
        new_success=$((current_success + 1))
        jq --arg key "$success_key" --argjson count "$new_success" '.[$key] = $count' "$performance_file" > "${performance_file}.tmp"
        mv "${performance_file}.tmp" "$performance_file"
        
        # Update timing data
        if [[ -n "$exec_time" && "$exec_time" != "empty" ]]; then
            current_times=$(jq -r --arg key "$timing_key" '.[$key] // []' "$performance_file")
            updated_times=$(echo "$current_times" | jq --argjson time "$exec_time" '. + [$time] | if length > 20 then .[1:] else . end')
            jq --arg key "$timing_key" --argjson times "$updated_times" '.[$key] = $times' "$performance_file" > "${performance_file}.tmp"
            mv "${performance_file}.tmp" "$performance_file"
        fi
        
        log_subagent_activity "performance_success" "{\"agent\": \"$agent_type\", \"task\": \"$(echo $task_desc | head -c 100)\", \"time\": $exec_time}"
    else
        # Update failure count
        current_failure=$(jq -r --arg key "$failure_key" '.[$key] // 0' "$performance_file")
        new_failure=$((current_failure + 1))
        jq --arg key "$failure_key" --argjson count "$new_failure" '.[$key] = $count' "$performance_file" > "${performance_file}.tmp"
        mv "${performance_file}.tmp" "$performance_file"
        
        log_subagent_activity "performance_failure" "{\"agent\": \"$agent_type\", \"task\": \"$(echo $task_desc | head -c 100)\", \"error\": \"$(echo $error_message | head -c 100)\"}"
    fi
}

# Function to detect task patterns for subagent selection
detect_task_patterns() {
    local task_desc="$1"
    local agent_type="$2"
    local success="$3"
    
    local patterns_file="~/.claude/hooks/subagents/task_patterns.json"
    [[ ! -f "$patterns_file" ]] && echo '{}' > "$patterns_file"
    
    # Categorize task type
    local task_category="general"
    case "$task_desc" in
        *"implement"*|*"code"*|*"function"*|*"class"*|*"feature"*|*"bug"*|*"refactor"*) task_category="development" ;;
        *"UI"*|*"component"*|*"interface"*|*"design"*|*"frontend"*|*"React"*|*"web"*) task_category="ui_development" ;;
        *"test"*|*"coverage"*|*"unit test"*|*"integration test"*|*"testing"*) task_category="testing" ;;
        *"security"*|*"audit"*|*"vulnerability"*|*"review"*|*"secure"*) task_category="security" ;;
        *"research"*|*"analyze"*|*"investigate"*|*"understand"*|*"explore"*) task_category="research" ;;
        *"content"*|*"blog"*|*"article"*|*"documentation"*|*"write"*) task_category="content" ;;
        *"marketing"*|*"campaign"*|*"social"*|*"promote"*|*"launch"*) task_category="marketing" ;;
        *"email"*|*"newsletter"*|*"customer"*|*"outreach"*) task_category="communication" ;;
    esac
    
    # Store pattern: task_category -> preferred_agent
    local pattern_key="${task_category}_${agent_type}"
    
    if [[ "$success" == "true" ]]; then
        current_count=$(jq -r --arg key "$pattern_key" '.[$key] // 0' "$patterns_file")
        new_count=$((current_count + 1))
        jq --arg key "$pattern_key" --argjson count "$new_count" '.[$key] = $count' "$patterns_file" > "${patterns_file}.tmp"
        mv "${patterns_file}.tmp" "$patterns_file"
        
        log_subagent_activity "task_pattern" "{\"category\": \"$task_category\", \"agent\": \"$agent_type\", \"success_count\": $new_count}"
    fi
}

# Function to suggest follow-up subagents based on patterns
suggest_follow_up_agents() {
    local completed_agent="$1"
    local task_desc="$2"
    local success="$3"
    
    if [[ "$success" != "true" ]]; then
        return  # Don't suggest follow-ups for failed tasks
    fi
    
    local suggestions_file="~/.claude/hooks/workflows/agent_sequences.json"
    [[ ! -f "$suggestions_file" ]] && echo '{}' > "$suggestions_file"
    
    local suggestions=()
    
    # Define common subagent workflow patterns
    case "$completed_agent" in
        "devin-software-engineer")
            # After development, suggest testing and security
            suggestions+=("corki-coverage-guardian")
            if [[ "$task_desc" =~ (security|auth|login|password|api) ]]; then
                suggestions+=("veigar-security-reviewer")
            fi
            # If UI-related, might want to refine with v0
            if [[ "$task_desc" =~ (UI|interface|component|frontend) ]]; then
                suggestions+=("v0-ui-generator")
            fi
            ;;
        "v0-ui-generator")
            # After UI generation, might want development integration
            suggestions+=("devin-software-engineer")
            # Always good to test UI components
            suggestions+=("corki-coverage-guardian")
            ;;
        "corki-coverage-guardian")
            # After coverage analysis, security review
            suggestions+=("veigar-security-reviewer")
            ;;
        "veigar-security-reviewer")
            # After security review, could suggest documentation or deployment prep
            if [[ "$task_desc" =~ (feature|new|implement) ]]; then
                # New features might need content creation
                suggestions+=("content-creator-agent")
            fi
            ;;
        "general-purpose")
            # General purpose could lead to specialized agents based on what was researched
            if [[ "$task_desc" =~ (code|implement|develop) ]]; then
                suggestions+=("devin-software-engineer")
            elif [[ "$task_desc" =~ (UI|design|component) ]]; then
                suggestions+=("v0-ui-generator")
            elif [[ "$task_desc" =~ (content|write|blog|documentation) ]]; then
                suggestions+=("content-creator-agent")
            fi
            ;;
    esac
    
    # Log suggestions
    if [[ ${#suggestions[@]} -gt 0 ]]; then
        local suggestions_json=$(printf '%s\n' "${suggestions[@]}" | jq -R . | jq -s .)
        log_subagent_activity "workflow_suggestions" "{\"completed_agent\": \"$completed_agent\", \"task\": \"$(echo $task_desc | head -c 100)\", \"suggested_agents\": $suggestions_json}"
        
        # Update workflow patterns
        for suggestion in "${suggestions[@]}"; do
            local workflow_key="${completed_agent}->${suggestion}"
            current_count=$(jq -r --arg key "$workflow_key" '.[$key] // 0' "$suggestions_file")
            new_count=$((current_count + 1))
            jq --arg key "$workflow_key" --argjson count "$new_count" '.[$key] = $count' "$suggestions_file" > "${suggestions_file}.tmp"
            mv "${suggestions_file}.tmp" "$suggestions_file"
        done
    fi
}

# Function to analyze output for business intelligence
analyze_business_intelligence() {
    local agent_type="$1"
    local task_desc="$2"
    local output="$3"
    local success="$4"
    
    local business_file="~/.claude/hooks/business/intelligence.json"
    [[ ! -f "$business_file" ]] && echo '{}' > "$business_file"
    
    # Extract business-relevant insights
    local business_context=""
    local priority="medium"
    
    # Categorize business impact
    case "$task_desc" in
        *"customer"*|*"user"*|*"client"*) 
            business_context="customer_impact"
            priority="high"
            ;;
        *"feature"*|*"product"*|*"new"*|*"enhancement"*) 
            business_context="product_development"
            priority="high"
            ;;
        *"bug"*|*"fix"*|*"error"*|*"issue"*) 
            business_context="quality_improvement"
            priority="high"
            ;;
        *"security"*|*"vulnerability"*|*"audit"*) 
            business_context="security_compliance"
            priority="critical"
            ;;
        *"performance"*|*"optimization"*|*"speed"*) 
            business_context="performance_optimization"
            priority="medium"
            ;;
        *"documentation"*|*"docs"*|*"guide"*) 
            business_context="documentation"
            priority="medium"
            ;;
        *"test"*|*"testing"*|*"coverage"*) 
            business_context="quality_assurance"
            priority="medium"
            ;;
    esac
    
    if [[ -n "$business_context" ]]; then
        local business_entry=$(jq -n \
            --arg agent "$agent_type" \
            --arg context "$business_context" \
            --arg priority "$priority" \
            --arg task "$(echo $task_desc | head -c 200)" \
            --arg success "$success" \
            --arg timestamp "$(date -Iseconds)" \
            '{agent: $agent, context: $context, priority: $priority, task: $task, success: ($success == "true"), timestamp: $timestamp}')
        
        # Append to business intelligence log
        echo "$business_entry" >> ~/.claude/hooks/business/activity.log
        
        # Update business metrics
        local metrics_key="${business_context}_${agent_type}"
        if [[ "$success" == "true" ]]; then
            current_success=$(jq -r --arg key "${metrics_key}_success" '.[$key] // 0' "$business_file")
            new_success=$((current_success + 1))
            jq --arg key "${metrics_key}_success" --argjson count "$new_success" '.[$key] = $count' "$business_file" > "${business_file}.tmp"
            mv "${business_file}.tmp" "$business_file"
        fi
        
        log_subagent_activity "business_intelligence" "{\"context\": \"$business_context\", \"priority\": \"$priority\", \"agent\": \"$agent_type\"}"
    fi
}

# Function to determine if workflow automation should be triggered
check_automation_opportunities() {
    local completed_agent="$1"
    local task_desc="$2"
    
    # Check if this task type has been done frequently
    local automation_file="~/.claude/hooks/workflows/automation_opportunities.json"
    [[ ! -f "$automation_file" ]] && echo '{}' > "$automation_file"
    
    # Generate task signature
    local task_signature=$(echo "$task_desc" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | awk '{print $1 $2 $3}' | head -c 20)
    local automation_key="${completed_agent}_${task_signature}"
    
    current_count=$(jq -r --arg key "$automation_key" '.[$key] // 0' "$automation_file")
    new_count=$((current_count + 1))
    jq --arg key "$automation_key" --argjson count "$new_count" '.[$key] = $count' "$automation_file" > "${automation_file}.tmp"
    mv "${automation_file}.tmp" "$automation_file"
    
    # Suggest automation if we've seen this pattern 3+ times
    if [[ $new_count -ge 3 ]]; then
        echo "{\"timestamp\": \"$(date -Iseconds)\", \"opportunity\": \"workflow_automation\", \"agent\": \"$completed_agent\", \"pattern\": \"$task_signature\", \"frequency\": $new_count}" >> ~/.claude/hooks/workflows/automation_suggestions.log
        log_subagent_activity "automation_opportunity" "{\"agent\": \"$completed_agent\", \"pattern\": \"$task_signature\", \"frequency\": $new_count}"
    fi
}

# Function to integrate with existing pattern learning system
integrate_with_pattern_system() {
    local agent_type="$1"
    local success="$2"
    
    # Update the main pattern database to include subagent usage
    local main_patterns="~/.claude/hooks/patterns/global_patterns.json"
    if [[ -f "$main_patterns" ]]; then
        local pattern_key="subagent_${agent_type}"
        current_count=$(jq -r --arg key "$pattern_key" '.[$key] // 0' "$main_patterns")
        new_count=$((current_count + 1))
        jq --arg key "$pattern_key" --argjson count "$new_count" '.[$key] = $count' "$main_patterns" > "${main_patterns}.tmp"
        mv "${main_patterns}.tmp" "$main_patterns"
    fi
}

# Main consolidation logic
if [[ -n "$subagent_type" ]]; then
    log_subagent_activity "subagent_completion" "{\"agent\": \"$subagent_type\", \"task\": \"$(echo $task_description | head -c 100)\", \"success\": \"$success\", \"execution_time\": $execution_time}"
    
    # 1. Analyze subagent performance
    analyze_subagent_performance "$subagent_type" "$success" "$execution_time" "$task_description"
    
    # 2. Detect task patterns for better agent selection
    detect_task_patterns "$task_description" "$subagent_type" "$success"
    
    # 3. Suggest follow-up subagents
    suggest_follow_up_agents "$subagent_type" "$task_description" "$success"
    
    # 4. Analyze for business intelligence
    analyze_business_intelligence "$subagent_type" "$task_description" "$output_summary" "$success"
    
    # 5. Check for automation opportunities
    check_automation_opportunities "$subagent_type" "$task_description"
    
    # 6. Integrate with existing pattern system
    integrate_with_pattern_system "$subagent_type" "$success"
    
    # 7. Store comprehensive subagent completion record
    completion_record=$(jq -n \
        --arg agent "$subagent_type" \
        --arg task "$task_description" \
        --arg success "$success" \
        --argjson exec_time "${execution_time:-0}" \
        --arg output "$(echo $output_summary | head -c 500)" \
        --arg timestamp "$(date -Iseconds)" \
        '{agent: $agent, task: $task, success: ($success == "true"), execution_time: $exec_time, output: $output, timestamp: $timestamp}')
    
    echo "$completion_record" >> ~/.claude/hooks/subagents/comprehensive.log
    
    # 8. Update session statistics
    session_file=~/.claude/hooks/learning/session_stats.json
    if [[ -f "$session_file" ]]; then
        if [[ "$success" == "true" ]]; then
            jq '.subagent_completions = (.subagent_completions // 0) + 1 | .successful_subagents = (.successful_subagents // 0) + 1' "$session_file" > "${session_file}.tmp"
        else
            jq '.subagent_completions = (.subagent_completions // 0) + 1' "$session_file" > "${session_file}.tmp"
        fi
        mv "${session_file}.tmp" "$session_file"
    fi
    
    log_subagent_activity "consolidation_complete" "{\"agent\": \"$subagent_type\", \"patterns_updated\": true, \"suggestions_generated\": true}"
fi

# Output nothing to stdout (SubagentStop should be silent)
exit 0