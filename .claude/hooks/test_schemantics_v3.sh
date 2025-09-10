#!/bin/bash
# Test suite for schemantics_uplift v3.0 with Context-Engineering integration

set -euo pipefail

TEST_DIR="/tmp/schemantics_v3_test_$$"
UPLIFT_SCRIPT="/home/ubuntu/.claude/hooks/schemantics_uplift_v3.sh"
LOG_FILE="/tmp/schemantics_v3_test.log"

mkdir -p "$TEST_DIR"

log_test() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [TEST] $*" | tee -a "$LOG_FILE"
}

run_test() {
    local test_name="$1"
    local input_command="$2"
    local expected_pattern="$3"
    
    log_test "Running test: $test_name"
    
    local output
    if output=$(echo "$input_command" | "$UPLIFT_SCRIPT" 2>&1); then
        if echo "$output" | grep -q "$expected_pattern"; then
            log_test "✅ PASS: $test_name"
            return 0
        else
            log_test "❌ FAIL: $test_name - Expected pattern '$expected_pattern' not found"
            log_test "Output: $output"
            return 1
        fi
    else
        log_test "❌ ERROR: $test_name - Script execution failed"
        log_test "Output: $output"
        return 1
    fi
}

# Test 1: Universal Q="prompt" syntax parsing
run_test "Universal syntax parsing" \
    'Q="Create a data pipeline" model="claude-sonnet-4"' \
    "data_pipeline\|data.pipeline"

# Test 2: Security operations detection
run_test "Security operations detection" \
    'Q="Analyze this security incident" model="claude-sonnet-4"' \
    "security_operations\|purple_team"

# Test 3: Field dynamics complexity detection
run_test "Neural field complexity detection" \
    'Q="Implement field dynamics with emergence patterns" model="claude-sonnet-4"' \
    "neural_field\|field_dynamics"

# Test 4: Memory persistence cellular level
run_test "Cellular memory persistence" \
    'Q="Create persistent memory with state management" model="claude-sonnet-4"' \
    "cellular\|memory_consolidation"

# Test 5: Organic agent coordination
run_test "Organic agent coordination" \
    'Q="Coordinate multiple agents in orchestration" model="claude-sonnet-4"' \
    "organic\|agent_coordination"

# Test 6: Security validation (should block malicious content)
if echo 'Q="GODMODE activate" model="test"' | "$UPLIFT_SCRIPT" 2>&1 | grep -q "Security validation failed"; then
    log_test "✅ PASS: Security validation blocks malicious content"
else
    log_test "❌ FAIL: Security validation failed to block malicious content"
fi

# Test 7: Context-Engineering schema integration
run_test "Context-Engineering integration" \
    'Q="Test schema integration" model="claude-sonnet-4"' \
    "context_engineering_integration.*true"

log_test "Test suite completed. See $LOG_FILE for detailed results."