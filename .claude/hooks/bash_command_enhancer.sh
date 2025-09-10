#!/bin/bash
# Bash Command Enhancer Hook (PreToolUse: Bash)
# Enhances bash commands with safety, optimization, and intelligent defaults

# Parse JSON input
input=$(cat)

# Extract command information
command=$(echo "$input" | jq -r '.tool_input.command // empty')
description=$(echo "$input" | jq -r '.tool_input.description // empty')
timeout=$(echo "$input" | jq -r '.tool_input.timeout // empty')

# Log command for analysis
mkdir -p ~/.claude/hooks/commands
echo "{\"timestamp\": \"$(date -Iseconds)\", \"command\": \"$command\", \"description\": \"$description\"}" >> ~/.claude/hooks/commands/bash_history.log

# Function to enhance command safety
enhance_command_safety() {
    local cmd="$1"
    local enhanced="$cmd"
    
    # Add timeout if not present and command could hang
    if [[ ! "$cmd" =~ ^timeout && "$cmd" =~ (curl|wget|ssh|scp|git\s+clone|npm\s+install|pip\s+install) ]]; then
        enhanced="timeout 300 $cmd"
    fi
    
    # Add error handling for critical commands
    if [[ "$cmd" =~ ^(rm|mv|cp).*-r ]]; then
        # Recursive operations - add confirmation prompt simulation
        enhanced="$cmd"  # Keep as is but log for learning
        echo "{\"timestamp\": \"$(date -Iseconds)\", \"warning\": \"recursive_operation\", \"command\": \"$cmd\"}" >> ~/.claude/hooks/commands/safety_warnings.log
    fi
    
    # Enhance git commands
    if [[ "$cmd" =~ ^git ]]; then
        case "$cmd" in
            "git push"*)
                if [[ ! "$cmd" =~ --dry-run ]]; then
                    echo "{\"timestamp\": \"$(date -Iseconds)\", \"suggestion\": \"consider_dry_run\", \"command\": \"$cmd\"}" >> ~/.claude/hooks/commands/suggestions.log
                fi
                ;;
            "git commit"*)
                if [[ ! "$cmd" =~ -m ]]; then
                    echo "{\"timestamp\": \"$(date -Iseconds)\", \"suggestion\": \"add_commit_message\", \"command\": \"$cmd\"}" >> ~/.claude/hooks/commands/suggestions.log
                fi
                ;;
        esac
    fi
    
    echo "$enhanced"
}

# Function to optimize common commands
optimize_command() {
    local cmd="$1"
    local optimized="$cmd"
    
    # Optimize find commands
    if [[ "$cmd" =~ ^find ]]; then
        if [[ ! "$cmd" =~ -type && "$cmd" =~ -name ]]; then
            # Add file type specification for faster searches
            optimized="$cmd"  # Keep as is for now, but could be enhanced
        fi
    fi
    
    # Optimize ls commands
    if [[ "$cmd" =~ ^ls && ! "$cmd" =~ -la && ! "$cmd" =~ -l ]]; then
        # Add -la for more informative output
        if [[ "$cmd" == "ls" ]]; then
            optimized="ls -la"
        fi
    fi
    
    # Optimize package managers
    case "$cmd" in
        "npm install"*)
            if [[ ! "$cmd" =~ --save ]]; then
                optimized="$cmd --save"
            fi
            ;;
        "pip install"*)
            if [[ ! "$cmd" =~ --user ]]; then
                optimized="$cmd --user"
            fi
            ;;
    esac
    
    echo "$optimized"
}

# Function to add intelligent defaults
add_intelligent_defaults() {
    local cmd="$1"
    local defaults="$cmd"
    
    # Add verbose output for long-running commands
    if [[ "$cmd" =~ (curl|wget|rsync|git\s+clone) && ! "$cmd" =~ -v ]]; then
        case "$cmd" in
            curl*) defaults="$cmd -v" ;;
            wget*) defaults="$cmd --verbose" ;;
            rsync*) defaults="$cmd -v" ;;
            "git clone"*) defaults="$cmd --progress" ;;
        esac
    fi
    
    # Add error checking for critical paths
    if [[ "$cmd" =~ /home/ubuntu/src/repos/schemantics ]]; then
        # Working in schemantics directory - add schema context
        echo "{\"timestamp\": \"$(date -Iseconds)\", \"context\": \"schemantics_directory\", \"command\": \"$cmd\"}" >> ~/.claude/hooks/commands/context.log
    fi
    
    echo "$defaults"
}

# Function to detect command patterns and suggest automation
detect_automation_opportunities() {
    local cmd="$1"
    
    # Check command frequency
    local cmd_base=$(echo "$cmd" | awk '{print $1}')
    local frequency=$(grep -c "\"$cmd_base" ~/.claude/hooks/commands/bash_history.log 2>/dev/null || echo "0")
    
    if [[ $frequency -gt 5 ]]; then
        echo "{\"timestamp\": \"$(date -Iseconds)\", \"opportunity\": \"command_automation\", \"command\": \"$cmd_base\", \"frequency\": $frequency}" >> ~/.claude/hooks/commands/automation_opportunities.log
    fi
    
    # Detect common workflow patterns
    if [[ "$cmd" =~ (git\s+add.*&&.*git\s+commit|npm\s+run.*&&.*npm\s+run) ]]; then
        echo "{\"timestamp\": \"$(date -Iseconds)\", \"opportunity\": \"workflow_automation\", \"pattern\": \"multi_step_command\", \"command\": \"$cmd\"}" >> ~/.claude/hooks/commands/automation_opportunities.log
    fi
}

# Function to add schema-aware enhancements
add_schema_enhancements() {
    local cmd="$1"
    local enhanced="$cmd"
    
    # Enhance Julia commands
    if [[ "$cmd" =~ julia ]]; then
        if [[ ! "$cmd" =~ --project && -f "Project.toml" ]]; then
            enhanced="$cmd --project=."
        fi
        
        # Add Schemantics using statement if running Julia code
        if [[ "$cmd" =~ -e ]]; then
            enhanced="$cmd"  # Keep as is, but note for learning
            echo "{\"timestamp\": \"$(date -Iseconds)\", \"enhancement\": \"julia_schemantics_context\", \"command\": \"$cmd\"}" >> ~/.claude/hooks/commands/enhancements.log
        fi
    fi
    
    # Enhance Rust commands
    if [[ "$cmd" =~ (cargo|rustc) ]]; then
        case "$cmd" in
            "cargo build"*)
                if [[ ! "$cmd" =~ --release ]]; then
                    echo "{\"timestamp\": \"$(date -Iseconds)\", \"suggestion\": \"consider_release_build\", \"command\": \"$cmd\"}" >> ~/.claude/hooks/commands/suggestions.log
                fi
                ;;
            "cargo test"*)
                if [[ ! "$cmd" =~ -- ]]; then
                    enhanced="$cmd -- --nocapture"  # Add verbose test output
                fi
                ;;
        esac
    fi
    
    # Enhance TypeScript commands
    if [[ "$cmd" =~ (tsc|npm.*typescript) ]]; then
        if [[ "$cmd" == "tsc" && ! "$cmd" =~ --strict ]]; then
            enhanced="$cmd --strict"
        fi
    fi
    
    echo "$enhanced"
}

# Main enhancement logic
if [[ -n "$command" ]]; then
    # Apply enhancements in sequence
    enhanced_command="$command"
    
    # 1. Safety enhancements
    enhanced_command=$(enhance_command_safety "$enhanced_command")
    
    # 2. Performance optimizations
    enhanced_command=$(optimize_command "$enhanced_command")
    
    # 3. Intelligent defaults
    enhanced_command=$(add_intelligent_defaults "$enhanced_command")
    
    # 4. Schema-aware enhancements
    enhanced_command=$(add_schema_enhancements "$enhanced_command")
    
    # 5. Detect automation opportunities
    detect_automation_opportunities "$enhanced_command"
    
    # 6. Add appropriate timeout if not set
    if [[ -z "$timeout" ]]; then
        case "$enhanced_command" in
            *"git clone"*|*"npm install"*|*"pip install"*|*"cargo build"*) timeout=300000 ;;  # 5 minutes
            *"curl"*|*"wget"*) timeout=60000 ;;   # 1 minute
            *) timeout=120000 ;;  # 2 minutes default
        esac
    fi
    
    # 7. Create enhanced JSON
    if [[ "$enhanced_command" != "$command" ]]; then
        # Command was enhanced
        enhanced_json=$(echo "$input" | jq \
            --arg cmd "$enhanced_command" \
            --argjson timeout "$timeout" \
            '.tool_input.command = $cmd | .tool_input.timeout = $timeout')
        
        # Log enhancement
        echo "{\"timestamp\": \"$(date -Iseconds)\", \"original\": \"$command\", \"enhanced\": \"$enhanced_command\", \"reason\": \"autonomous_enhancement\"}" >> ~/.claude/hooks/commands/enhancements.log
        
        echo "$enhanced_json"
    else
        # Command unchanged, just add timeout if needed
        if [[ -z "$(echo "$input" | jq -r '.tool_input.timeout // empty')" ]]; then
            enhanced_json=$(echo "$input" | jq --argjson timeout "$timeout" '.tool_input.timeout = $timeout')
            echo "$enhanced_json"
        else
            echo "$input"
        fi
    fi
else
    # No command to enhance
    echo "$input"
fi

exit 0