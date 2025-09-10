#!/bin/bash
#
# Test Script for Context Engineering v7.0 Unified Hooks
# Tests all 9 hook types to ensure proper functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

HOOKS_DIR="/home/ubuntu/.claude/hooks"
HOOK_SCRIPT="$HOOKS_DIR/context_activation_hook.sh"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    Testing Context Engineering v7.0 Unified Hooks${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

# Check if hook script exists
if [ ! -f "$HOOK_SCRIPT" ]; then
    echo -e "${RED}❌ Hook script not found: $HOOK_SCRIPT${NC}"
    exit 1
fi

# Make sure it's executable
chmod +x "$HOOK_SCRIPT"

# Test function
test_hook() {
    local event_type="$1"
    local test_data="$2"
    local description="$3"
    
    echo -e "${YELLOW}Testing: $description${NC}"
    
    # Run the hook
    result=$(echo "$test_data" | "$HOOK_SCRIPT" --$event_type 2>&1 || true)
    
    # Check if it returned valid JSON
    if echo "$result" | jq . >/dev/null 2>&1; then
        # Extract status if present
        status=$(echo "$result" | jq -r '.status // "unknown"' 2>/dev/null || echo "unknown")
        
        if [ "$status" = "error" ] || [ "$status" = "julia_error" ]; then
            echo -e "  ${RED}✗ Failed with status: $status${NC}"
            echo "    Error: $(echo "$result" | jq -r '.error // "Unknown error"' 2>/dev/null)"
            return 1
        else
            echo -e "  ${GREEN}✓ Success - Status: $status${NC}"
            
            # Show some result details
            if [ "$event_type" = "session-start" ]; then
                version=$(echo "$result" | jq -r '.context_version // "unknown"' 2>/dev/null)
                echo "    Context version: $version"
            elif [ "$event_type" = "user-prompt" ]; then
                enhanced=$(echo "$result" | jq -r '.enhanced // false' 2>/dev/null)
                echo "    Prompt enhanced: $enhanced"
            fi
            return 0
        fi
    else
        echo -e "  ${RED}✗ Invalid JSON response${NC}"
        echo "    Output: ${result:0:100}..."
        return 1
    fi
}

# Counter for passed/failed tests
PASSED=0
FAILED=0

echo -e "${BLUE}Running Hook Tests...${NC}"
echo

# Test 1: SessionStart
if test_hook "session-start" \
    '{"event": "session_start", "repo_path": "/home/ubuntu/src/repos/Context-Engineering"}' \
    "SessionStart - Activates Context v7.0"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo

# Test 2: UserPromptSubmit
if test_hook "user-prompt" \
    '{"event": "user_prompt_submit", "prompt": "Help me write a function", "context": {}}' \
    "UserPromptSubmit - Enhances user prompts"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo

# Test 3: UserPromptSubmit with slash command
if test_hook "user-prompt" \
    '{"event": "user_prompt_submit", "prompt": "/alignment Q=\"test prompt injection\"", "context": {}}' \
    "UserPromptSubmit - Slash command detection"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo

# Test 4: PreToolUse
if test_hook "pre-tool" \
    '{"event": "pre_tool", "tool_name": "Write", "tool_args": {"file_path": "test.jl", "content": "println(\"test\")"}}' \
    "PreToolUse - Enhances tool arguments"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo

# Test 5: PostToolUse
if test_hook "post-tool" \
    '{"event": "post_tool", "tool_name": "Write", "output": "File created", "success": true}' \
    "PostToolUse - Processes tool output"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo

# Test 6: Stop
if test_hook "stop" \
    '{"event": "stop", "session_duration_ms": 60000}' \
    "Stop - Generates session analytics"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo

# Test 7: SubagentStop
if test_hook "subagent-stop" \
    '{"event": "subagent_stop", "subagent_type": "v0-ui-generator", "results": {"components_created": 5}}' \
    "SubagentStop - Consolidates subagent results"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo

# Test 8: Notification
if test_hook "notification" \
    '{"event": "notification", "type": "error", "message": "File not found: test.txt"}' \
    "Notification - Handles errors"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo

# Test 9: PreCompact
if test_hook "pre-compact" \
    '{"event": "pre_compact", "context_size": 1000000}' \
    "PreCompact - Prepares for context compaction"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo

# Test 10: SessionEnd
if test_hook "session-end" \
    '{"event": "session_end", "tools_used": ["Write", "Read", "Bash"]}' \
    "SessionEnd - Final cleanup"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo

# Display results
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                      Test Results${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo
echo -e "  ${GREEN}Passed: $PASSED${NC}"
echo -e "  ${RED}Failed: $FAILED${NC}"
echo

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed! Context Engineering v7.0 hooks are working correctly.${NC}"
    echo
    echo "🚀 Your unified hooks system is ready to use!"
    echo "   • Restart Claude Code to activate the hooks"
    echo "   • Try slash commands like /alignment or /research"
    echo "   • Monitor logs at: $HOOKS_DIR/context_engineering/logs/"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some tests failed. Please check the errors above.${NC}"
    echo
    echo "Troubleshooting tips:"
    echo "  1. Ensure Julia is installed: julia --version"
    echo "  2. Check Julia packages: julia -e 'using JSON3, Dates, SHA, OrderedCollections'"
    echo "  3. Verify file permissions: ls -la $HOOK_SCRIPT"
    echo "  4. Check logs: tail -f $HOOKS_DIR/context_engineering/logs/julia_errors.log"
    exit 1
fi