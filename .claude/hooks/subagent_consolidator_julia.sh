#!/bin/bash
# SubagentStop Hook - High-Performance Julia Business Automation Trigger
# Captures subagent completions and triggers autonomous Julia business workflows

# Ensure Julia is available
if ! command -v julia &> /dev/null; then
    echo "Error: Julia not found. Please install Julia for high-performance business automation." >&2
    exit 1
fi

# Create necessary directories
mkdir -p ~/.claude/hooks/julia_business_automation/{logs,data,temp}

# Parse JSON input from SubagentStop event
input=$(cat)

# Extract subagent information
subagent_type=$(echo "$input" | jq -r '.subagent_type // empty')
task_description=$(echo "$input" | jq -r '.task_description // .description // empty')
execution_time_ms=$(echo "$input" | jq -r '.execution_time_ms // empty')
success=$(echo "$input" | jq -r '.success // true')
output_summary=$(echo "$input" | jq -r '.output_summary // .result // empty')
error_message=$(echo "$input" | jq -r '.error_message // .error // empty')

# Log subagent completion with timestamp
timestamp=$(date -Iseconds)
log_entry=$(jq -n \
    --arg ts "$timestamp" \
    --arg agent "$subagent_type" \
    --arg task "$task_description" \
    --arg exec_time "$execution_time_ms" \
    --arg success "$success" \
    --arg output "$output_summary" \
    --arg error "$error_message" \
    '{
        timestamp: $ts,
        event: "subagent_completion",
        subagent_type: $agent,
        task_description: $task,
        execution_time_ms: ($exec_time | tonumber // 0),
        success: ($success == "true"),
        output_summary: $output,
        error_message: $error
    }')

# Save to comprehensive log
echo "$log_entry" >> ~/.claude/hooks/julia_business_automation/logs/subagent_completions.jsonl

# Only proceed with automation if we have valid subagent data
if [[ -n "$subagent_type" && -n "$task_description" ]]; then
    # Execute Enhanced Julia business automation with Foundation Modules
    julia_automation_script="/home/ubuntu/.claude/hooks/julia_business_automation/enhanced_autonomous_trigger.jl"
    
    # Create temporary input file for Julia
    temp_input=$(mktemp)
    echo "$log_entry" > "$temp_input"
    
    # Execute Julia automation with error handling
    if julia --project=/home/ubuntu/.claude/hooks/julia_business_automation \
            "$julia_automation_script" "$temp_input" 2>/dev/null; then
        
        # Log successful automation trigger
        success_log=$(jq -n \
            --arg ts "$(date -Iseconds)" \
            --arg agent "$subagent_type" \
            '{
                timestamp: $ts,
                event: "julia_automation_triggered",
                subagent_type: $agent,
                status: "success"
            }')
        echo "$success_log" >> ~/.claude/hooks/julia_business_automation/logs/automation_triggers.jsonl
    else
        # Log automation failure but don't fail the hook
        failure_log=$(jq -n \
            --arg ts "$(date -Iseconds)" \
            --arg agent "$subagent_type" \
            '{
                timestamp: $ts,
                event: "julia_automation_failed",
                subagent_type: $agent,
                status: "failed"
            }')
        echo "$failure_log" >> ~/.claude/hooks/julia_business_automation/logs/automation_triggers.jsonl
    fi
    
    # Clean up temporary file
    rm -f "$temp_input"
fi

# Update performance statistics (high-performance processing)
if [[ "$success" == "true" ]]; then
    # Increment success counter using atomic file operations
    success_file=~/.claude/hooks/julia_business_automation/data/success_count
    flock "$success_file" bash -c "echo \$(((\$(cat '$success_file' 2>/dev/null || echo 0) + 1)))" > "$success_file"
else
    # Increment failure counter
    failure_file=~/.claude/hooks/julia_business_automation/data/failure_count
    flock "$failure_file" bash -c "echo \$(((\$(cat '$failure_file' 2>/dev/null || echo 0) + 1)))" > "$failure_file"
fi

# Update daily metrics
date_key=$(date +%Y%m%d)
daily_file=~/.claude/hooks/julia_business_automation/data/daily_metrics_$date_key.json

# Create or update daily metrics atomically
(
    flock -x 200
    if [[ -f "$daily_file" ]]; then
        current_data=$(cat "$daily_file")
    else
        current_data='{"date":"'$date_key'","completions":0,"successful":0,"failed":0,"total_execution_time_ms":0}'
    fi
    
    updated_data=$(echo "$current_data" | jq \
        --argjson exec_time "${execution_time_ms:-0}" \
        --argjson is_success "$([ "$success" == "true" ] && echo true || echo false)" \
        '
        .completions += 1 |
        .total_execution_time_ms += $exec_time |
        if $is_success then .successful += 1 else .failed += 1 end
        ')
    
    echo "$updated_data" > "$daily_file"
) 200>"$daily_file.lock"

# Output nothing to stdout (SubagentStop should be silent)
exit 0