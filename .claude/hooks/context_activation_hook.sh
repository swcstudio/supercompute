#!/bin/bash
# Context Engineering v7.0 - Unified Hook Entry Point
# 
# This is the master shell script that routes all Claude Code hook events
# to the Julia-based Context Engineering v7.0 activation system.
# 
# Supports all 9 Claude Code hook events:
#   --user-prompt        # UserPromptSubmit event
#   --session-start      # SessionStart event  
#   --pre-tool          # PreToolUse event
#   --post-tool         # PostToolUse event
#   --stop              # Stop event
#   --subagent-stop     # SubagentStop event
#   --notification      # Notification event
#   --pre-compact       # PreCompact event
#   --session-end       # SessionEnd event

# Configuration
JULIA_PROJECT_DIR="$HOME/.claude/hooks/context_engineering"
CONTEXT_REPO="${CONTEXT_REPO:-/home/ubuntu/src/repos/Context-Engineering}"
LOG_DIR="$HOME/.claude/hooks/context_engineering/logs"
JULIA_BIN="${JULIA_BIN:-julia}"

# Ensure directories exist
mkdir -p "$LOG_DIR"

# Check if Julia is available
if ! command -v "$JULIA_BIN" &> /dev/null; then
    echo '{"status": "error", "message": "Julia not found. Please install Julia for Context Engineering v7.0"}' >&2
    exit 1
fi

# Parse event type from arguments or environment
EVENT_TYPE=""
case "$1" in
    --user-prompt|--userpromptsubmit)
        EVENT_TYPE="user_prompt_submit"
        ;;
    --session-start|--sessionstart)
        EVENT_TYPE="session_start"
        ;;
    --pre-tool|--pretooluse)
        EVENT_TYPE="pre_tool"
        ;;
    --post-tool|--posttooluse)
        EVENT_TYPE="post_tool"
        ;;
    --stop)
        EVENT_TYPE="stop"
        ;;
    --subagent-stop|--subagentstop)
        EVENT_TYPE="subagent_stop"
        ;;
    --notification)
        EVENT_TYPE="notification"
        ;;
    --pre-compact|--precompact)
        EVENT_TYPE="pre_compact"
        ;;
    --session-end|--sessionend)
        EVENT_TYPE="session_end"
        ;;
    --activate|--pre-start)  # Legacy support
        EVENT_TYPE="session_start"
        ;;
    --context-changed)  # Legacy support
        EVENT_TYPE="context_changed"
        ;;
    *)
        # Try to detect from Claude Code hook environment
        if [ -n "$CLAUDE_HOOK_EVENT" ]; then
            EVENT_TYPE="$CLAUDE_HOOK_EVENT"
        else
            EVENT_TYPE="unknown"
        fi
        ;;
esac

# Read input JSON from stdin
if [ -t 0 ]; then
    # No stdin, create minimal input
    INPUT_JSON='{"event": "'$EVENT_TYPE'", "timestamp": "'$(date -Iseconds)'"}'
else
    INPUT_JSON=$(cat)
fi

# Add event type to JSON if not present
INPUT_JSON=$(echo "$INPUT_JSON" | jq --arg event "$EVENT_TYPE" '. + {event_type: $event}')

# Add repository path to JSON
INPUT_JSON=$(echo "$INPUT_JSON" | jq --arg repo "$CONTEXT_REPO" '. + {repo_path: $repo}')

# Create temporary file for input (Julia will read this)
TEMP_INPUT=$(mktemp /tmp/claude_hook_input_XXXXXX.json)
echo "$INPUT_JSON" > "$TEMP_INPUT"

# Execute Julia hook with timeout and error handling
JULIA_OUTPUT=$(timeout 5s "$JULIA_BIN" --project="$JULIA_PROJECT_DIR" --startup-file=no -e "
    # Load the Context v7.0 activation module
    try
        # Add project path if needed
        if !in(\"$JULIA_PROJECT_DIR\", LOAD_PATH)
            push!(LOAD_PATH, \"$JULIA_PROJECT_DIR\")
        end
        
        # Include the module - try complete version first, fallback to standard
        if isfile(\"$JULIA_PROJECT_DIR/context_v7_activation_complete.jl\")
            include(\"$JULIA_PROJECT_DIR/context_v7_activation_complete.jl\")
        else
            include(\"$JULIA_PROJECT_DIR/context_v7_activation.jl\")
        end
        using .ContextV7Activation
        
        # Read input
        using JSON3
        input_data = JSON3.read(read(\"$TEMP_INPUT\", String), Dict{String, Any})
        
        # Process hook event
        result = process_hook_event(\"$EVENT_TYPE\", input_data)
        
        # Output result as JSON
        println(JSON3.write(result))
        
    catch e
        # Error handling - output valid JSON error
        using JSON3
        error_result = Dict(
            \"status\" => \"error\",
            \"error\" => string(e),
            \"event_type\" => \"$EVENT_TYPE\"
        )
        println(JSON3.write(error_result))
        exit(1)
    end
" 2>"$LOG_DIR/julia_errors.log")

JULIA_EXIT_CODE=$?

# Clean up temp file
rm -f "$TEMP_INPUT"

# Handle timeout or execution errors
if [ $JULIA_EXIT_CODE -eq 124 ]; then
    echo '{"status": "timeout", "message": "Julia execution timed out after 5 seconds"}' >&2
    exit 1
elif [ $JULIA_EXIT_CODE -ne 0 ]; then
    # Log error and return fallback
    echo "Julia execution failed with code $JULIA_EXIT_CODE" >> "$LOG_DIR/hook_errors.log"
    
    # For PreToolUse, pass through original input to avoid blocking
    if [ "$EVENT_TYPE" = "pre_tool" ]; then
        echo "$INPUT_JSON"
    else
        echo '{"status": "julia_error", "event_type": "'$EVENT_TYPE'"}' >&2
    fi
    exit 0  # Don't fail the hook chain
fi

# Validate Julia output is valid JSON
if echo "$JULIA_OUTPUT" | jq . >/dev/null 2>&1; then
    # Valid JSON - output it
    echo "$JULIA_OUTPUT"
else
    # Invalid JSON - log and provide fallback
    echo "Invalid JSON from Julia: $JULIA_OUTPUT" >> "$LOG_DIR/hook_errors.log"
    
    # For PreToolUse, pass through original input
    if [ "$EVENT_TYPE" = "pre_tool" ]; then
        echo "$INPUT_JSON"
    else
        echo '{"status": "invalid_output", "event_type": "'$EVENT_TYPE'"}'
    fi
fi

# Log successful execution for monitoring
echo "$(date -Iseconds) - Hook executed: $EVENT_TYPE" >> "$LOG_DIR/hook_executions.log"

exit 0