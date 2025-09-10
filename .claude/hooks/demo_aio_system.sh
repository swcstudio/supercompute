#!/bin/bash
#
# AIO Meta-Agent System Demonstration
# Shows natural language to agent routing in action

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

clear

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         ${CYAN}🤖 AIO Meta-Agent Natural Language Interface Demo${BLUE}          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Before AIO:${NC} Users needed to know specific agent syntax:"
echo -e "  ${RED}❌${NC} /optimize target=\"code.py\" area=\"speed\" mode=\"balanced\""
echo -e "  ${RED}❌${NC} /research Q=\"async programming\" field=\"programming\" years=5"
echo -e "  ${RED}❌${NC} /meta workflow=\"research→optimize\" agents=[research,optimize]"
echo

echo -e "${GREEN}With AIO:${NC} Just use natural language!"
echo -e "  ${GREEN}✅${NC} /aio make my code faster"
echo -e "  ${GREEN}✅${NC} /aio help me understand async programming"
echo -e "  ${GREEN}✅${NC} /aio research and optimize my code"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# Function to demonstrate routing
demo_routing() {
    local query="$1"
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│ USER INPUT:${NC} $query"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    
    # Process with AIO
    result=$(julia -e "
        include(\"$HOME/.claude/hooks/context_engineering/aio_meta_agent.jl\")
        using .AIOMetaAgent
        
        result = process_aio_query(\"$query\")
        
        println(\"Agent: \", result[\"agent\"])
        println(\"Command: \", result[\"command\"])
        println(\"Confidence: \", round(result[\"confidence\"], digits=2))
        println(\"Reasoning: \", get(result, \"reasoning\", \"Automatic routing\"))
    " 2>/dev/null)
    
    echo -e "${MAGENTA}🔍 AIO Analysis:${NC}"
    echo "$result" | while IFS= read -r line; do
        echo "   $line"
    done
    echo
}

# Demonstrate various queries
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                      DEMONSTRATION EXAMPLES${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
echo

# Example 1: Simple optimization
demo_routing "make my Python code run faster"

# Example 2: Security check
demo_routing "check if my API endpoints are secure"

# Example 3: Documentation
demo_routing "create documentation for my REST API"

# Example 4: Complex multi-agent
demo_routing "analyze security vulnerabilities and write tests for them"

# Example 5: Research query
demo_routing "help me understand how async/await works in JavaScript"

# Example 6: Deployment
demo_routing "deploy my application to production safely"

echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                        KEY FEATURES${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
echo

echo -e "${GREEN}✨ Natural Language Understanding${NC}"
echo "   • No need to learn agent-specific syntax"
echo "   • Automatic intent detection"
echo "   • Context-aware parameter extraction"
echo

echo -e "${GREEN}🎯 Intelligent Routing${NC}"
echo "   • 16 specialized agents available"
echo "   • Confidence-based selection"
echo "   • Multi-agent orchestration when needed"
echo

echo -e "${GREEN}🔧 Automatic Parameter Formatting${NC}"
echo "   • Extracts files, targets, and options"
echo "   • Applies sensible defaults"
echo "   • Validates parameter compatibility"
echo

echo -e "${GREEN}🚀 Production Ready${NC}"
echo "   • Integrated with Context Engineering v7.0"
echo "   • Julia HPC performance"
echo "   • Full audit trail and logging"
echo

echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                     AVAILABLE AGENTS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
echo

# List available agents
echo -e "${CYAN}Domain-Specific Agents:${NC}"
echo "  • ${YELLOW}alignment${NC} - AI safety and ethics evaluation"
echo "  • ${YELLOW}research${NC} - Deep research and exploration"
echo "  • ${YELLOW}optimize${NC} - Code and system optimization"
echo "  • ${YELLOW}security${NC} - Security analysis and hardening"
echo "  • ${YELLOW}test${NC} - Testing and quality assurance"
echo "  • ${YELLOW}doc${NC} - Documentation generation"
echo "  • ${YELLOW}deploy${NC} - Deployment and release management"
echo "  • ${YELLOW}monitor${NC} - System monitoring and observability"
echo "  • ${YELLOW}data${NC} - Data processing and ETL"
echo "  • ${YELLOW}legal${NC} - Legal and compliance review"
echo "  • ${YELLOW}marketing${NC} - Marketing and growth strategies"
echo "  • ${YELLOW}comms${NC} - Communications and messaging"
echo "  • ${YELLOW}cli${NC} - CLI tools and automation"
echo "  • ${YELLOW}diligence${NC} - Due diligence and audit"
echo "  • ${YELLOW}lit${NC} - Literature and academic research"
echo "  • ${YELLOW}meta${NC} - Multi-agent orchestration"
echo

echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                        NEXT STEPS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
echo

echo -e "${GREEN}🔧 To activate the complete system:${NC}"
echo
echo "  1. ${CYAN}Run the migration:${NC}"
echo "     ${YELLOW}bash /home/ubuntu/.claude/hooks/migrate_to_v7.sh${NC}"
echo
echo "  2. ${CYAN}Test the system:${NC}"
echo "     ${YELLOW}bash /home/ubuntu/.claude/hooks/test_v7_hooks.sh${NC}"
echo
echo "  3. ${CYAN}Restart Claude Code${NC}"
echo
echo "  4. ${CYAN}Try natural language commands:${NC}"
echo "     ${YELLOW}/aio make my Python code run faster${NC}"
echo "     ${YELLOW}/aio help me understand async programming${NC}"
echo "     ${YELLOW}/aio analyze security and write tests${NC}"
echo

echo -e "${GREEN}📚 Documentation:${NC}"
echo "  • AIO Agent: /home/ubuntu/.claude/commands/aio.agent.md"
echo "  • Context v7 Summary: /home/ubuntu/.claude/hooks/CONTEXT_V7_HOOKS_SUMMARY.md"
echo "  • Migration Guide: /home/ubuntu/.claude/hooks/UNIFIED_HOOKS_README.md"
echo

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ${GREEN}✅ AIO Meta-Agent System Ready!${BLUE}                                   ║${NC}"
echo -e "${BLUE}║  ${CYAN}Natural language → Intelligent routing → Perfect execution${BLUE}        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"