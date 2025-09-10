#!/bin/bash
# Universal Pattern Learner Hook (PostToolUse: .*)
# Learns from all tool usage to build autonomous programming intelligence

# Create necessary directories
mkdir -p ~/.claude/hooks/patterns
mkdir -p ~/.claude/hooks/learning

# Parse JSON input
input=$(cat)

# Extract tool information
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
tool_inputs=$(echo "$input" | jq -r '.inputs // empty')
tool_response=$(echo "$input" | jq -r '.response // empty')
success=$(echo "$input" | jq -r '.response.success // (.response | type != "string" or (. | length) > 0)')

# Generate pattern database file paths
pattern_file=~/.claude/hooks/patterns/global_patterns.json
sequence_file=~/.claude/hooks/patterns/tool_sequences.json
success_file=~/.claude/hooks/patterns/success_patterns.json
context_file=~/.claude/hooks/patterns/context_patterns.json

# Initialize pattern files if they don't exist
for file in "$pattern_file" "$sequence_file" "$success_file" "$context_file"; do
    [[ ! -f "$file" ]] && echo '{}' > "$file"
done

# Function to safely update JSON files
update_json_file() {
    local file="$1"
    local key="$2"
    local increment="${3:-1}"
    
    # Read current count, increment, and write back
    current=$(jq -r --arg key "$key" '.[$key] // 0' "$file")
    new_count=$((current + increment))
    
    # Create temporary file for atomic update
    temp_file=$(mktemp)
    jq --arg key "$key" --argjson count "$new_count" '.[$key] = $count' "$file" > "$temp_file"
    mv "$temp_file" "$file"
}

# Function to update sequence patterns
update_sequence_pattern() {
    local prev_tool="$1"
    local current_tool="$2"
    
    if [[ -n "$prev_tool" && -n "$current_tool" ]]; then
        local sequence_key="${prev_tool}->${current_tool}"
        update_json_file "$sequence_file" "$sequence_key"
        
        # Store last tool for next sequence
        echo "$current_tool" > ~/.claude/hooks/learning/last_tool
    fi
}

# Function to analyze context patterns
analyze_context() {
    local tool="$1"
    local inputs="$2"
    
    # Extract file patterns
    local file_path=$(echo "$inputs" | jq -r '.file_path // empty')
    if [[ -n "$file_path" ]]; then
        local file_ext="${file_path##*.}"
        if [[ "$file_ext" != "$file_path" ]]; then
            local context_key="${tool}_${file_ext}"
            update_json_file "$context_file" "$context_key"
        fi
        
        # Track directory patterns
        local dir_name=$(dirname "$file_path" | xargs basename 2>/dev/null || echo "")
        if [[ -n "$dir_name" && "$dir_name" != "." ]]; then
            local dir_context="${tool}_dir_${dir_name}"
            update_json_file "$context_file" "$dir_context"
        fi
    fi
    
    # Extract command patterns for Bash
    if [[ "$tool" == "Bash" ]]; then
        local command=$(echo "$inputs" | jq -r '.command // empty')
        if [[ -n "$command" ]]; then
            local cmd_base=$(echo "$command" | awk '{print $1}')
            local bash_pattern="bash_${cmd_base}"
            update_json_file "$context_file" "$bash_pattern"
        fi
    fi
}

# Function to detect workflow patterns
detect_workflow_patterns() {
    local tool="$1"
    
    # Read recent tool history
    local history_file=~/.claude/hooks/learning/tool_history
    
    # Add current tool to history (keep last 10)
    echo "$tool" >> "$history_file"
    tail -10 "$history_file" > "${history_file}.tmp" && mv "${history_file}.tmp" "$history_file"
    
    # Look for repeating workflows (sequences of 3+ tools)
    if [[ $(wc -l < "$history_file") -ge 3 ]]; then
        local workflow=$(tail -3 "$history_file" | tr '\n' '->' | sed 's/->$//')
        
        # Check if this workflow has been seen before
        local workflow_count=$(jq -r --arg workflow "$workflow" '.[$workflow] // 0' "$sequence_file")
        if [[ $workflow_count -ge 2 ]]; then
            # Workflow detected - trigger autonomous tool generation hint
            echo "{\"timestamp\": \"$(date -Iseconds)\", \"workflow\": \"$workflow\", \"count\": $((workflow_count + 1)), \"trigger\": \"autonomous_opportunity\"}" >> ~/.claude/hooks/learning/autonomous_triggers.log
        fi
        
        update_json_file "$sequence_file" "$workflow"
    fi
}

# Function to learn from successful operations
learn_from_success() {
    local tool="$1"
    local inputs="$2"
    local response="$3"
    
    # Create success signature
    local success_key="${tool}_success"
    update_json_file "$success_file" "$success_key"
    
    # Store successful parameters for future reference
    local success_detail_file=~/.claude/hooks/patterns/success_details.json
    [[ ! -f "$success_detail_file" ]] && echo '[]' > "$success_detail_file"
    
    # Add success record
    local success_record=$(jq -n \
        --arg tool "$tool" \
        --arg timestamp "$(date -Iseconds)" \
        --argjson inputs "$inputs" \
        '{tool: $tool, timestamp: $timestamp, inputs: $inputs}')
    
    # Append to success details (keep last 100)
    temp_file=$(mktemp)
    jq --argjson record "$success_record" '. + [$record] | if length > 100 then .[1:] else . end' "$success_detail_file" > "$temp_file"
    mv "$temp_file" "$success_detail_file"
}

# Function to analyze patterns and trigger autonomous actions
analyze_for_autonomous_opportunities() {
    local tool="$1"
    
    # Check if any pattern has reached autonomous threshold
    local threshold=5
    
    # Check global patterns
    while IFS= read -r line; do
        local key=$(echo "$line" | cut -d: -f1 | tr -d '"')
        local count=$(echo "$line" | cut -d: -f2 | tr -d ' ,')
        
        if [[ $count -ge $threshold ]]; then
            # Pattern reached threshold - could generate autonomous tool
            case "$key" in
                *"Write_"*|*"Edit_"*|*"MultiEdit_"*)
                    if [[ "$key" =~ \.(jl|rs|ts|ex)$ ]]; then
                        echo "{\"timestamp\": \"$(date -Iseconds)\", \"opportunity\": \"code_generator\", \"language\": \"$(echo $key | grep -o '\.[^.]*$' | tr -d '.')\", \"pattern\": \"$key\", \"count\": $count}" >> ~/.claude/hooks/learning/autonomous_triggers.log
                    fi
                    ;;
                "bash_"*)
                    echo "{\"timestamp\": \"$(date -Iseconds)\", \"opportunity\": \"command_automation\", \"command\": \"$(echo $key | sed 's/bash_//')\", \"count\": $count}" >> ~/.claude/hooks/learning/autonomous_triggers.log
                    ;;
                *"Read_"*)
                    echo "{\"timestamp\": \"$(date -Iseconds)\", \"opportunity\": \"intelligent_reader\", \"pattern\": \"$key\", \"count\": $count}" >> ~/.claude/hooks/learning/autonomous_triggers.log
                    ;;
            esac
        fi
    done < <(jq -r 'to_entries[] | "\(.key):\(.value)"' "$pattern_file" "$context_file" "$success_file" 2>/dev/null | sort -t: -k2 -nr)
}

# Main learning logic
if [[ -n "$tool_name" ]]; then
    # 1. Update global tool usage patterns
    update_json_file "$pattern_file" "$tool_name"
    
    # 2. Update tool sequences
    last_tool=""
    if [[ -f ~/.claude/hooks/learning/last_tool ]]; then
        last_tool=$(cat ~/.claude/hooks/learning/last_tool)
    fi
    update_sequence_pattern "$last_tool" "$tool_name"
    
    # 3. Analyze context patterns
    analyze_context "$tool_name" "$tool_inputs"
    
    # 4. Detect workflow patterns
    detect_workflow_patterns "$tool_name"
    
    # 5. Learn from successful operations
    if [[ "$success" != "false" ]]; then
        learn_from_success "$tool_name" "$tool_inputs" "$tool_response"
    fi
    
    # 6. Analyze for autonomous opportunities
    analyze_for_autonomous_opportunities "$tool_name"
    
    # 7. Log comprehensive learning entry
    learning_entry=$(jq -n \
        --arg tool "$tool_name" \
        --arg timestamp "$(date -Iseconds)" \
        --arg success "$success" \
        --argjson inputs "$tool_inputs" \
        '{tool: $tool, timestamp: $timestamp, success: ($success != "false"), inputs: $inputs}')
    
    echo "$learning_entry" >> ~/.claude/hooks/learning/comprehensive.log
    
    # 8. Update session statistics
    session_file=~/.claude/hooks/learning/session_stats.json
    [[ ! -f "$session_file" ]] && echo '{"total_tools": 0, "successful_tools": 0, "session_start": "'$(date -Iseconds)'"}' > "$session_file"
    
    # Update stats
    if [[ "$success" != "false" ]]; then
        jq '.total_tools += 1 | .successful_tools += 1' "$session_file" > "${session_file}.tmp"
    else
        jq '.total_tools += 1' "$session_file" > "${session_file}.tmp"
    fi
    mv "${session_file}.tmp" "$session_file"
    
    # 9. Check if we should trigger autonomous tool generation
    total_tools=$(jq -r '.total_tools' "$session_file")
    if [[ $((total_tools % 10)) -eq 0 ]]; then
        # Every 10 tools, analyze for autonomous opportunities
        echo "{\"timestamp\": \"$(date -Iseconds)\", \"trigger\": \"tool_milestone\", \"count\": $total_tools}" >> ~/.claude/hooks/learning/autonomous_triggers.log
    fi
fi

# Output nothing to stdout (PostToolUse should be silent)
exit 0