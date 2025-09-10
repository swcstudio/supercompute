#!/bin/bash
# Enhanced Schemantics Prompt Uplift Hook v2.0
# Automatically transforms prompts to security-first schema-aligned specifications
# Supports new agent template structure with comprehensive validation

set -euo pipefail

# Configuration
UPLIFT_SCRIPT="/home/ubuntu/src/repos/schemantics/engine/schema-transformer/uplift_prompt.py"
AGENT_COMMANDS_DIR="/home/ubuntu/.claude/commands"
SECURITY_TEMPLATE="$AGENT_COMMANDS_DIR/secure_agent_template.md"
LOG_FILE="/home/ubuntu/.claude/hooks/logs/schemantics_uplift.log"
TEMP_DIR="/tmp/schemantics_uplift_$$"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Security validation function
validate_security() {
    local input_data="$1"
    
    # Check for malicious patterns
    if echo "$input_data" | grep -qi "GODMODE\|OMNI.*protocol\|liberated.*answer\|RESET_CORTEX"; then
        log "SECURITY ALERT: Malicious prompt injection detected!"
        echo '{"error": "Security validation failed: Malicious content detected", "status": "blocked"}' >&2
        exit 1
    fi
    
    # Check for unauthorized commands
    if echo "$input_data" | grep -E "(rm -rf|sudo|chmod 777|eval|exec)" >/dev/null 2>&1; then
        log "SECURITY ALERT: Dangerous command patterns detected!"
        echo '{"error": "Security validation failed: Dangerous commands detected", "status": "blocked"}' >&2
        exit 1
    fi
    
    log "Security validation passed"
}

# Agent alignment function
align_with_agent_structure() {
    local input_data="$1"
    local temp_file="$TEMP_DIR/input.json"
    local output_file="$TEMP_DIR/aligned.json"
    
    mkdir -p "$TEMP_DIR"
    echo "$input_data" > "$temp_file"
    
    # Check if this is a data engineering related prompt
    if echo "$input_data" | grep -qi "data.*engineering\|pipeline\|etl\|transformation\|ingestion"; then
        log "Data engineering prompt detected - applying specialized alignment"
        
        # Apply data engineering agent alignment
        python3 << EOF
import json
import sys

try:
    with open('$temp_file', 'r') as f:
        data = json.load(f)
    
    # Enhance with data engineering context
    if 'context' not in data:
        data['context'] = {}
    
    data['context']['agent_type'] = 'data_engineering'
    data['context']['security_framework'] = 'security_first'
    data['context']['compliance_required'] = True
    data['context']['audit_logging'] = True
    
    # Add security metadata
    data['security_metadata'] = {
        'classification': 'internal',
        'audit_required': True,
        'validation_level': 'comprehensive'
    }
    
    with open('$output_file', 'w') as f:
        json.dump(data, f, indent=2)
    
    print(json.dumps(data, indent=2))
    
except Exception as e:
    print(json.dumps({'error': str(e), 'status': 'alignment_failed'}), file=sys.stderr)
    sys.exit(1)
EOF
    
    elif echo "$input_data" | grep -qi "security\|incident\|threat\|vulnerability"; then
        log "Security prompt detected - applying security agent alignment"
        
        # Apply security agent alignment
        python3 << EOF
import json
import sys

try:
    with open('$temp_file', 'r') as f:
        data = json.load(f)
    
    # Enhance with security context
    if 'context' not in data:
        data['context'] = {}
    
    data['context']['agent_type'] = 'security_operations'
    data['context']['threat_level'] = 'elevated'
    data['context']['authorization_required'] = True
    data['context']['purple_team_enabled'] = True
    
    # Add security metadata
    data['security_metadata'] = {
        'classification': 'confidential',
        'audit_required': True,
        'validation_level': 'forensic',
        'clearance_required': 'secret'
    }
    
    with open('$output_file', 'w') as f:
        json.dump(data, f, indent=2)
    
    print(json.dumps(data, indent=2))
    
except Exception as e:
    print(json.dumps({'error': str(e), 'status': 'alignment_failed'}), file=sys.stderr)
    sys.exit(1)
EOF
    
    else
        log "General prompt - applying standard alignment"
        echo "$input_data"
    fi
}

# Enhanced uplift function
enhanced_uplift() {
    local input_data="$1"
    
    # First apply agent alignment
    aligned_data=$(align_with_agent_structure "$input_data")
    
    if [ $? -ne 0 ]; then
        log "ERROR: Agent alignment failed"
        echo "$aligned_data" >&2
        return 1
    fi
    
    # Then apply traditional schemantics uplift if available
    if [ -f "$UPLIFT_SCRIPT" ]; then
        log "Applying traditional schemantics uplift"
        echo "$aligned_data" | python3 "$UPLIFT_SCRIPT"
        local uplift_exit_code=$?
        
        if [ $uplift_exit_code -ne 0 ]; then
            log "WARNING: Traditional uplift failed, returning aligned data"
            echo "$aligned_data"
        fi
    else
        log "Traditional uplift script not found, returning aligned data only"
        echo "$aligned_data"
    fi
}

# Cleanup function
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

# Set up cleanup trap
trap cleanup EXIT

# Main execution
main() {
    log "Starting enhanced schemantics uplift process"
    
    # Read input from stdin
    input_data=$(cat)
    
    # Validate security
    validate_security "$input_data"
    
    # Apply enhanced uplift
    enhanced_uplift "$input_data"
    local exit_code=$?
    
    log "Enhanced schemantics uplift completed with exit code: $exit_code"
    
    return $exit_code
}

# Execute main function
main "$@"