#!/bin/bash
# PostToolUse Hook - Julia Business Opportunity Detection
# Analyzes all tool usage for business automation opportunities

# Ensure Julia is available
if ! command -v julia &> /dev/null; then
    exit 0  # Silently skip if Julia not available
fi

# Create necessary directories
mkdir -p ~/.claude/hooks/julia_business_automation/{logs,data,temp}

# Parse JSON input from PostToolUse event
input=$(cat)

# Extract tool usage information
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
tool_output=$(echo "$input" | jq -r '.tool_output // empty')
execution_time_ms=$(echo "$input" | jq -r '.execution_time_ms // 0')
success=$(echo "$input" | jq -r '.success // true')
user_context=$(echo "$input" | jq -r '.user_context // empty')

# Only process significant tool usage (avoid noise)
if [[ -z "$tool_name" ]] || [[ "$tool_name" == "Read" && ${#tool_output} -lt 1000 ]]; then
    exit 0
fi

# Log tool usage for business analysis
timestamp=$(date -Iseconds)
tool_usage_log=$(jq -n \
    --arg ts "$timestamp" \
    --arg tool "$tool_name" \
    --arg output "$(echo "$tool_output" | head -c 500)" \
    --arg exec_time "$execution_time_ms" \
    --arg success "$success" \
    --arg context "$(echo "$user_context" | head -c 200)" \
    '{
        timestamp: $ts,
        event: "tool_usage",
        tool_name: $tool,
        tool_output_preview: $output,
        execution_time_ms: ($exec_time | tonumber),
        success: ($success == "true"),
        user_context: $context
    }')

# Save to tool usage log
echo "$tool_usage_log" >> ~/.claude/hooks/julia_business_automation/logs/tool_usage.jsonl

# Detect business opportunities from tool patterns
business_opportunity=""

case "$tool_name" in
    "Write"|"Edit"|"MultiEdit")
        # Code changes might need documentation, testing, or announcements
        if echo "$tool_output" | grep -qi "feature\|function\|class\|component"; then
            business_opportunity='{"type":"code_completion_opportunity","domain":"content","confidence":0.70,"actions":["documentation","testing","announcement"]}'
        fi
        ;;
    "Bash")
        # Deployment or testing might need customer communication
        if echo "$tool_output" | grep -qi "deploy\|release\|test\|build"; then
            business_opportunity='{"type":"deployment_opportunity","domain":"customer_success","confidence":0.65,"actions":["customer_notification","performance_monitoring"]}'
        fi
        ;;
    "WebFetch")
        # Research might lead to content creation opportunities
        if echo "$user_context" | grep -qi "research\|analyze\|market\|competitor"; then
            business_opportunity='{"type":"research_content_opportunity","domain":"marketing","confidence":0.75,"actions":["content_creation","competitive_analysis"]}'
        fi
        ;;
    "Glob"|"Grep")
        # Code analysis might need refactoring communication
        if echo "$tool_output" | grep -qi "TODO\|FIXME\|deprecated\|legacy"; then
            business_opportunity='{"type":"code_improvement_opportunity","domain":"operations","confidence":0.60,"actions":["refactoring_plan","technical_debt_communication"]}'
        fi
        ;;
esac

# If business opportunity detected, trigger Julia analysis
if [[ -n "$business_opportunity" ]]; then
    # Create temporary analysis input
    temp_input=$(mktemp)
    
    analysis_data=$(jq -n \
        --arg ts "$timestamp" \
        --arg tool "$tool_name" \
        --argjson opportunity "$business_opportunity" \
        --arg context "$user_context" \
        '{
            timestamp: $ts,
            trigger_tool: $tool,
            opportunity: $opportunity,
            context: $context,
            source: "tool_usage_analysis"
        }')
    
    echo "$analysis_data" > "$temp_input"
    
    # Execute Enhanced Julia business opportunity analysis with Foundation Modules
    julia_opportunity_script="/home/ubuntu/.claude/hooks/julia_business_automation/enhanced_opportunity_analyzer.jl"
    
    # Try enhanced version first, fallback to original if needed
    if julia --project=/home/ubuntu/.claude/hooks/julia_business_automation \
            "$julia_opportunity_script" "$temp_input" 2>/dev/null; then
        
        # Log successful opportunity analysis
        success_log=$(jq -n \
            --arg ts "$(date -Iseconds)" \
            --arg tool "$tool_name" \
            --argjson opp "$business_opportunity" \
            '{
                timestamp: $ts,
                event: "opportunity_analysis_triggered",
                trigger_tool: $tool,
                opportunity_type: $opp.type,
                status: "success"
            }')
        echo "$success_log" >> ~/.claude/hooks/julia_business_automation/logs/opportunity_analysis.jsonl
    fi
    
    # Clean up
    rm -f "$temp_input"
fi

# Update tool usage statistics for business intelligence
tool_stats_file=~/.claude/hooks/julia_business_automation/data/tool_usage_stats.json

# Atomic update of tool statistics
(
    flock -x 200
    
    if [[ -f "$tool_stats_file" ]]; then
        current_stats=$(cat "$tool_stats_file")
    else
        current_stats='{}'
    fi
    
    updated_stats=$(echo "$current_stats" | jq \
        --arg tool "$tool_name" \
        --argjson exec_time "${execution_time_ms:-0}" \
        --argjson is_success "$([ "$success" == "true" ] && echo true || echo false)" \
        '
        .[$tool] = (.[$tool] // {"count": 0, "total_time_ms": 0, "successes": 0}) |
        .[$tool].count += 1 |
        .[$tool].total_time_ms += $exec_time |
        if $is_success then .[$tool].successes += 1 else . end |
        .[$tool].success_rate = (.[$tool].successes / .[$tool].count) |
        .[$tool].avg_time_ms = (.[$tool].total_time_ms / .[$tool].count)
        ')
    
    echo "$updated_stats" > "$tool_stats_file"
    
) 200>"$tool_stats_file.lock"

# Silently exit (PostToolUse hooks should not produce output)
exit 0