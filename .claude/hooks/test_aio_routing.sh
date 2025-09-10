#!/bin/bash
#
# Test Script for AIO Meta-Agent Routing System
# Tests natural language to agent routing capabilities

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}         AIO Meta-Agent Routing Test Suite${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

# Test function for Julia AIO module
test_aio_routing() {
    local query="$1"
    local expected_agent="$2"
    local description="$3"
    
    echo -e "${YELLOW}Testing: $description${NC}"
    echo -e "  Query: \"$query\""
    
    # Run Julia test
    result=$(julia -e "
        include(\"$HOME/.claude/hooks/context_engineering/aio_meta_agent.jl\")
        using .AIOMetaAgent
        using JSON3
        
        result = process_aio_query(\"$query\")
        println(JSON3.write(result))
    " 2>&1 || true)
    
    if echo "$result" | jq . >/dev/null 2>&1; then
        # Extract agent and command
        agent=$(echo "$result" | jq -r '.agent // "unknown"')
        command=$(echo "$result" | jq -r '.command // "none"')
        confidence=$(echo "$result" | jq -r '.confidence // 0')
        
        echo -e "  Routed to: ${CYAN}$agent${NC}"
        echo -e "  Command: $command"
        echo -e "  Confidence: $confidence"
        
        if [ "$agent" = "$expected_agent" ]; then
            echo -e "  ${GREEN}✓ Correct routing${NC}"
            return 0
        else
            echo -e "  ${RED}✗ Expected: $expected_agent, Got: $agent${NC}"
            return 1
        fi
    else
        echo -e "  ${RED}✗ Failed to process query${NC}"
        echo "  Error: $result"
        return 1
    fi
}

# Counter for passed/failed tests
PASSED=0
FAILED=0

echo -e "${BLUE}Running AIO Routing Tests...${NC}"
echo

# Test 1: Simple optimization query
if test_aio_routing \
    "make my Python code run faster" \
    "optimize" \
    "Simple optimization request"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo

# Test 2: Security analysis query
if test_aio_routing \
    "check if my code is secure" \
    "security" \
    "Security analysis request"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo

# Test 3: Research query
if test_aio_routing \
    "help me understand how async programming works" \
    "research" \
    "Research and learning request"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo

# Test 4: Testing query
if test_aio_routing \
    "write unit tests for my functions" \
    "test" \
    "Test creation request"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo

# Test 5: Documentation query
if test_aio_routing \
    "create documentation for my API" \
    "doc" \
    "Documentation generation request"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo

# Test 6: Multi-agent query
if test_aio_routing \
    "research security issues and create tests" \
    "meta" \
    "Multi-agent orchestration request"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo

# Test 7: Deployment query
if test_aio_routing \
    "deploy my application to production" \
    "deploy" \
    "Deployment request"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo

# Test 8: Monitoring query
if test_aio_routing \
    "set up monitoring and alerts" \
    "monitor" \
    "Monitoring setup request"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo

# Test 9: Data processing query
if test_aio_routing \
    "process and analyze this data" \
    "data" \
    "Data processing request"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo

# Test 10: Ambiguous query (should default to research)
if test_aio_routing \
    "I need help with something" \
    "research" \
    "Ambiguous query (fallback test)"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo

# Display results
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    Test Results${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo
echo -e "  ${GREEN}Passed: $PASSED${NC}"
echo -e "  ${RED}Failed: $FAILED${NC}"
echo

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All AIO routing tests passed!${NC}"
    echo
    echo "🚀 The AIO meta-agent is ready to use!"
    echo
    echo "Example usage:"
    echo "  /aio make my code faster"
    echo "  /aio help me understand this error"
    echo "  /aio write tests and documentation"
    echo
else
    echo -e "${YELLOW}⚠️  Some tests failed. Review the routing logic.${NC}"
fi

# Show example of actual hook integration
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}              Testing Hook Integration${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

# Test with actual hook system
echo "Testing AIO with hook system..."
test_query='{"event": "user_prompt_submit", "prompt": "/aio make my Python code run faster", "context": {}}'
echo "$test_query" | $HOME/.claude/hooks/context_activation_hook.sh --user-prompt 2>&1 | jq '.slash_command_detected // "none"' || echo "Hook test skipped (requires full activation)"

echo
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                 Next Steps${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo
echo "To fully activate the AIO system:"
echo
echo "  1. Run migration:"
echo "     ${CYAN}bash /home/ubuntu/.claude/hooks/migrate_to_v7.sh${NC}"
echo
echo "  2. Test system:"
echo "     ${CYAN}bash /home/ubuntu/.claude/hooks/test_v7_hooks.sh${NC}"
echo
echo "  3. Restart Claude Code"
echo
echo "  4. Try natural language commands:"
echo "     ${CYAN}/aio make my Python code run faster${NC}"
echo "     ${CYAN}/aio help me understand async programming${NC}"
echo "     ${CYAN}/aio analyze security and write tests${NC}"
echo
echo "The AIO agent will automatically:"
echo "  • Understand your intent"
echo "  • Route to the best agent(s)"
echo "  • Format parameters correctly"
echo "  • Orchestrate multi-agent workflows"
echo
exit 0