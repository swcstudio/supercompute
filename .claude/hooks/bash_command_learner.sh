#!/bin/bash
# Bash Command Learner Hook (PostToolUse: Bash)
# Learns from bash command execution results to improve future command usage

# Create necessary directories
mkdir -p ~/.claude/hooks/commands
mkdir -p ~/.claude/hooks/learning

# Parse JSON input
input=$(cat)

# Extract execution information
command_inputs=$(echo "$input" | jq -r '.inputs.tool_input.command // empty')
exit_code=$(echo "$input" | jq -r '.response.exit_code // .response.returncode // empty')
stdout=$(echo "$input" | jq -r '.response.stdout // empty')
stderr=$(echo "$input" | jq -r '.response.stderr // empty')
execution_time=$(echo "$input" | jq -r '.response.execution_time_ms // empty')

# Function to log learning data
log_learning() {
    local type="$1"
    local data="$2"
    echo "{\"timestamp\": \"$(date -Iseconds)\", \"type\": \"$type\", \"data\": $data}" >> ~/.claude/hooks/commands/learning.log
}

# Function to analyze command success/failure patterns
analyze_command_outcome() {
    local cmd="$1"
    local exit_code="$2"
    local stderr="$3"
    
    local cmd_base=$(echo "$cmd" | awk '{print $1}')
    local outcome_file="~/.claude/hooks/commands/outcomes.json"
    
    # Initialize outcomes file if it doesn't exist
    [[ ! -f "$outcome_file" ]] && echo '{}' > "$outcome_file"
    
    # Update success/failure counts
    local success_key="${cmd_base}_success"
    local failure_key="${cmd_base}_failure"
    
    if [[ "$exit_code" == "0" ]]; then
        # Command succeeded
        current_success=$(jq -r --arg key "$success_key" '.[$key] // 0' "$outcome_file")
        new_success=$((current_success + 1))
        jq --arg key "$success_key" --argjson count "$new_success" '.[$key] = $count' "$outcome_file" > "${outcome_file}.tmp"
        mv "${outcome_file}.tmp" "$outcome_file"
        
        log_learning "command_success" "{\"command\": \"$cmd_base\", \"count\": $new_success}"
    else
        # Command failed
        current_failure=$(jq -r --arg key "$failure_key" '.[$key] // 0' "$outcome_file")
        new_failure=$((current_failure + 1))
        jq --arg key "$failure_key" --argjson count "$new_failure" '.[$key] = $count' "$outcome_file" > "${outcome_file}.tmp"
        mv "${outcome_file}.tmp" "$outcome_file"
        
        # Analyze failure patterns
        analyze_failure_pattern "$cmd" "$stderr"
        
        log_learning "command_failure" "{\"command\": \"$cmd_base\", \"count\": $new_failure, \"error\": \"$(echo $stderr | head -c 100)\"}"
    fi
}

# Function to analyze failure patterns and suggest fixes
analyze_failure_pattern() {
    local cmd="$1"
    local stderr="$2"
    
    local fixes_file="~/.claude/hooks/commands/failure_fixes.json"
    [[ ! -f "$fixes_file" ]] && echo '{}' > "$fixes_file"
    
    # Common error patterns and suggested fixes
    local fix_suggestion=""
    local error_pattern=""
    
    case "$stderr" in
        *"command not found"*)
            error_pattern="command_not_found"
            fix_suggestion="Install missing command or check PATH"
            ;;
        *"permission denied"*|*"Permission denied"*)
            error_pattern="permission_denied"
            fix_suggestion="Check file permissions or use sudo"
            ;;
        *"no such file or directory"*|*"No such file or directory"*)
            error_pattern="file_not_found"
            fix_suggestion="Verify file path exists"
            ;;
        *"connection refused"*|*"Connection refused"*)
            error_pattern="connection_refused"
            fix_suggestion="Check if service is running and port is correct"
            ;;
        *"timeout"*|*"timed out"*)
            error_pattern="timeout"
            fix_suggestion="Increase timeout or check network connectivity"
            ;;
        *"out of space"*|*"disk full"*)
            error_pattern="disk_full"
            fix_suggestion="Free up disk space"
            ;;
        *)
            error_pattern="unknown"
            fix_suggestion="Review command syntax and parameters"
            ;;
    esac
    
    # Store the fix suggestion
    if [[ -n "$error_pattern" && "$error_pattern" != "unknown" ]]; then
        local fix_record=$(jq -n \
            --arg pattern "$error_pattern" \
            --arg command "$cmd" \
            --arg suggestion "$fix_suggestion" \
            --arg timestamp "$(date -Iseconds)" \
            '{pattern: $pattern, command: $command, suggestion: $suggestion, timestamp: $timestamp}')
        
        # Update fixes database
        local pattern_key="${error_pattern}"
        current_fixes=$(jq -r --arg key "$pattern_key" '.[$key] // []' "$fixes_file")
        updated_fixes=$(echo "$current_fixes" | jq --argjson record "$fix_record" '. + [$record] | if length > 10 then .[1:] else . end')
        
        jq --arg key "$pattern_key" --argjson fixes "$updated_fixes" '.[$key] = $fixes' "$fixes_file" > "${fixes_file}.tmp"
        mv "${fixes_file}.tmp" "$fixes_file"
        
        log_learning "failure_pattern" "{\"pattern\": \"$error_pattern\", \"suggestion\": \"$fix_suggestion\"}"
    fi
}

# Function to learn command timing patterns
learn_timing_patterns() {
    local cmd="$1"
    local exec_time="$2"
    
    if [[ -n "$exec_time" && "$exec_time" != "empty" ]]; then
        local cmd_base=$(echo "$cmd" | awk '{print $1}')
        local timing_file="~/.claude/hooks/commands/timing.json"
        
        [[ ! -f "$timing_file" ]] && echo '{}' > "$timing_file"
        
        # Update timing statistics
        local timing_key="${cmd_base}_timing"
        current_times=$(jq -r --arg key "$timing_key" '.[$key] // []' "$timing_file")
        updated_times=$(echo "$current_times" | jq --argjson time "$exec_time" '. + [$time] | if length > 20 then .[1:] else . end')
        
        jq --arg key "$timing_key" --argjson times "$updated_times" '.[$key] = $times' "$timing_file" > "${timing_file}.tmp"
        mv "${timing_file}.tmp" "$timing_file"
        
        # Calculate average execution time
        local avg_time=$(echo "$updated_times" | jq 'add / length')
        
        log_learning "timing_pattern" "{\"command\": \"$cmd_base\", \"execution_time\": $exec_time, \"average_time\": $avg_time}"
        
        # Suggest optimization if command is consistently slow
        if (( $(echo "$avg_time > 10000" | bc -l) )); then  # > 10 seconds
            echo "{\"timestamp\": \"$(date -Iseconds)\", \"optimization\": \"slow_command\", \"command\": \"$cmd_base\", \"avg_time\": $avg_time}" >> ~/.claude/hooks/commands/optimization_suggestions.log
        fi
    fi
}

# Function to detect command sequence patterns
detect_sequence_patterns() {
    local current_cmd="$1"
    local cmd_base=$(echo "$current_cmd" | awk '{print $1}')
    
    # Track command sequences
    local sequence_file="~/.claude/hooks/commands/sequences.log"
    echo "$cmd_base" >> "$sequence_file"
    
    # Keep only last 50 commands
    tail -50 "$sequence_file" > "${sequence_file}.tmp" && mv "${sequence_file}.tmp" "$sequence_file"
    
    # Look for common 3-command sequences
    if [[ $(wc -l < "$sequence_file") -ge 3 ]]; then
        local sequence=$(tail -3 "$sequence_file" | tr '\n' '->' | sed 's/->$//')
        
        # Update sequence frequency
        local sequence_freq_file="~/.claude/hooks/commands/sequence_frequency.json"
        [[ ! -f "$sequence_freq_file" ]] && echo '{}' > "$sequence_freq_file"
        
        current_freq=$(jq -r --arg seq "$sequence" '.[$seq] // 0' "$sequence_freq_file")
        new_freq=$((current_freq + 1))
        
        jq --arg seq "$sequence" --argjson freq "$new_freq" '.[$seq] = $freq' "$sequence_freq_file" > "${sequence_freq_file}.tmp"
        mv "${sequence_freq_file}.tmp" "$sequence_freq_file"
        
        # Suggest automation if sequence is frequent
        if [[ $new_freq -ge 3 ]]; then
            echo "{\"timestamp\": \"$(date -Iseconds)\", \"automation_opportunity\": \"command_sequence\", \"sequence\": \"$sequence\", \"frequency\": $new_freq}" >> ~/.claude/hooks/commands/automation_opportunities.log
            log_learning "sequence_pattern" "{\"sequence\": \"$sequence\", \"frequency\": $new_freq}"
        fi
    fi
}

# Function to learn output patterns
learn_output_patterns() {
    local cmd="$1"
    local stdout="$2"
    local stderr="$3"
    
    local cmd_base=$(echo "$cmd" | awk '{print $1}')
    
    # Analyze stdout patterns
    if [[ -n "$stdout" && "$stdout" != "empty" ]]; then
        local output_length=$(echo "$stdout" | wc -c)
        local line_count=$(echo "$stdout" | wc -l)
        
        # Store output characteristics
        local output_pattern=$(jq -n \
            --arg command "$cmd_base" \
            --argjson length "$output_length" \
            --argjson lines "$line_count" \
            --arg timestamp "$(date -Iseconds)" \
            '{command: $command, output_length: $length, line_count: $lines, timestamp: $timestamp}')
        
        echo "$output_pattern" >> ~/.claude/hooks/commands/output_patterns.log
        
        # Suggest piping to less for large outputs
        if [[ $line_count -gt 50 ]]; then
            echo "{\"timestamp\": \"$(date -Iseconds)\", \"suggestion\": \"pipe_to_pager\", \"command\": \"$cmd_base\", \"lines\": $line_count}" >> ~/.claude/hooks/commands/suggestions.log
        fi
    fi
}

# Function to update command expertise
update_command_expertise() {
    local cmd="$1"
    local success="$2"
    
    local cmd_base=$(echo "$cmd" | awk '{print $1}')
    local expertise_file="~/.claude/hooks/commands/expertise.json"
    
    [[ ! -f "$expertise_file" ]] && echo '{}' > "$expertise_file"
    
    # Track command usage and success rate
    local usage_key="${cmd_base}_usage"
    local success_key="${cmd_base}_success_rate"
    
    current_usage=$(jq -r --arg key "$usage_key" '.[$key] // 0' "$expertise_file")
    current_successes=$(jq -r --arg key "$success_key" '.[$key] // 0' "$expertise_file")
    
    new_usage=$((current_usage + 1))
    if [[ "$success" == "true" ]]; then
        new_successes=$((current_successes + 1))
    fi
    
    local success_rate=0
    if [[ $new_usage -gt 0 ]]; then
        success_rate=$(echo "scale=2; $new_successes * 100 / $new_usage" | bc)
    fi
    
    # Update expertise database
    updated_expertise=$(jq \
        --arg usage_key "$usage_key" \
        --arg success_key "$success_key" \
        --argjson usage "$new_usage" \
        --argjson rate "$success_rate" \
        '.[$usage_key] = $usage | .[$success_key] = $rate' "$expertise_file")
    
    echo "$updated_expertise" > "$expertise_file"
    
    # Log expertise level
    local expertise_level="novice"
    if (( $(echo "$success_rate >= 80" | bc -l) )) && [[ $new_usage -ge 10 ]]; then
        expertise_level="expert"
    elif (( $(echo "$success_rate >= 60" | bc -l) )) && [[ $new_usage -ge 5 ]]; then
        expertise_level="intermediate"
    fi
    
    log_learning "expertise_update" "{\"command\": \"$cmd_base\", \"level\": \"$expertise_level\", \"usage\": $new_usage, \"success_rate\": $success_rate}"
}

# Main learning logic
if [[ -n "$command_inputs" ]]; then
    # Determine if command was successful
    local success="false"
    if [[ "$exit_code" == "0" ]]; then
        success="true"
    fi
    
    # 1. Analyze command outcome
    analyze_command_outcome "$command_inputs" "$exit_code" "$stderr"
    
    # 2. Learn timing patterns
    learn_timing_patterns "$command_inputs" "$execution_time"
    
    # 3. Detect sequence patterns
    detect_sequence_patterns "$command_inputs"
    
    # 4. Learn output patterns
    learn_output_patterns "$command_inputs" "$stdout" "$stderr"
    
    # 5. Update command expertise
    update_command_expertise "$command_inputs" "$success"
    
    # 6. Log comprehensive learning entry
    learning_entry=$(jq -n \
        --arg command "$command_inputs" \
        --arg exit_code "$exit_code" \
        --arg success "$success" \
        --arg timestamp "$(date -Iseconds)" \
        --argjson execution_time "${execution_time:-0}" \
        '{command: $command, exit_code: $exit_code, success: ($success == "true"), timestamp: $timestamp, execution_time: $execution_time}')
    
    echo "$learning_entry" >> ~/.claude/hooks/commands/comprehensive_learning.log
    
    # 7. Check for autonomous tool generation opportunities
    local cmd_base=$(echo "$command_inputs" | awk '{print $1}')
    local usage_count=$(jq -r --arg key "${cmd_base}_usage" '.[$key] // 0' ~/.claude/hooks/commands/expertise.json)
    
    if [[ $usage_count -ge 10 ]]; then
        echo "{\"timestamp\": \"$(date -Iseconds)\", \"opportunity\": \"command_wrapper_tool\", \"command\": \"$cmd_base\", \"usage_count\": $usage_count}" >> ~/.claude/hooks/commands/automation_opportunities.log
    fi
fi

# Output nothing to stdout (PostToolUse should be silent)
exit 0