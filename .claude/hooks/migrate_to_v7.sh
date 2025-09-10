#!/bin/bash
#
# Migration Script for Context Engineering v7.0 Unified Hooks
# 
# This script:
# 1. Backs up existing hooks
# 2. Updates settings.json with new unified hooks
# 3. Tests the new system
# 4. Provides rollback capability

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
HOOKS_DIR="$HOME/.claude/hooks"
SETTINGS_FILE="$HOME/.claude/settings.json"
BACKUP_DIR="$HOOKS_DIR/backup_$(date +%Y%m%d_%H%M%S)"
CONTEXT_ENG_DIR="$HOOKS_DIR/context_engineering"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    Context Engineering v7.0 Hooks Migration Tool${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

# Function to create backup
create_backup() {
    echo -e "${YELLOW}📦 Creating backup of existing hooks...${NC}"
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Backup existing hooks
    if [ -d "$HOOKS_DIR" ]; then
        # Backup shell scripts
        for file in "$HOOKS_DIR"/*.sh; do
            if [ -f "$file" ] && [ "$(basename "$file")" != "migrate_to_v7.sh" ] && [ "$(basename "$file")" != "context_activation_hook.sh" ]; then
                cp "$file" "$BACKUP_DIR/" 2>/dev/null || true
                echo "  ✓ Backed up: $(basename "$file")"
            fi
        done
        
        # Backup Python scripts
        for file in "$HOOKS_DIR"/*.py; do
            if [ -f "$file" ]; then
                cp "$file" "$BACKUP_DIR/" 2>/dev/null || true
                echo "  ✓ Backed up: $(basename "$file")"
            fi
        done
    fi
    
    # Backup settings.json
    if [ -f "$SETTINGS_FILE" ]; then
        cp "$SETTINGS_FILE" "$BACKUP_DIR/settings.json.backup"
        echo "  ✓ Backed up: settings.json"
    fi
    
    echo -e "${GREEN}✅ Backup created at: $BACKUP_DIR${NC}"
    echo
}

# Function to check Julia installation
check_julia() {
    echo -e "${YELLOW}🔍 Checking Julia installation...${NC}"
    
    if ! command -v julia &> /dev/null; then
        echo -e "${RED}❌ Julia is not installed!${NC}"
        echo "Please install Julia first:"
        echo "  curl -fsSL https://install.julialang.org | sh"
        exit 1
    fi
    
    JULIA_VERSION=$(julia --version | cut -d' ' -f3)
    echo -e "${GREEN}✅ Julia $JULIA_VERSION found${NC}"
    
    # Check required packages
    echo -e "${YELLOW}📦 Checking Julia packages...${NC}"
    julia -e '
        using Pkg
        required = ["JSON3", "Dates", "SHA", "OrderedCollections"]
        missing_pkgs = String[]
        for pkg in required
            try
                eval(Meta.parse("using $pkg"))
            catch
                push!(missing_pkgs, pkg)
            end
        end
        if !isempty(missing_pkgs)
            println("Installing missing packages: ", join(missing_pkgs, ", "))
            Pkg.add(missing_pkgs)
        else
            println("✅ All required packages installed")
        end
    '
    echo
}

# Function to setup Context Engineering v7.0 files
setup_v7_files() {
    echo -e "${YELLOW}📝 Setting up Context Engineering v7.0 files...${NC}"
    
    # Ensure directory exists
    mkdir -p "$CONTEXT_ENG_DIR/logs"
    mkdir -p "$CONTEXT_ENG_DIR/cache"
    mkdir -p "$CONTEXT_ENG_DIR/data"
    
    # Check if main files exist
    if [ ! -f "$HOOKS_DIR/context_activation_hook.sh" ]; then
        echo -e "${RED}❌ context_activation_hook.sh not found!${NC}"
        echo "Please ensure the unified hook script is in place."
        exit 1
    fi
    
    if [ ! -f "$CONTEXT_ENG_DIR/context_v7_activation_complete.jl" ]; then
        # Use the complete version if available
        if [ -f "$CONTEXT_ENG_DIR/context_v7_activation.jl" ]; then
            echo "  ℹ Using existing context_v7_activation.jl"
        else
            echo -e "${RED}❌ Julia activation module not found!${NC}"
            exit 1
        fi
    else
        # Rename to standard name
        mv "$CONTEXT_ENG_DIR/context_v7_activation_complete.jl" "$CONTEXT_ENG_DIR/context_v7_activation.jl"
        echo "  ✓ Using complete v7.0 activation module"
    fi
    
    # Make shell script executable
    chmod +x "$HOOKS_DIR/context_activation_hook.sh"
    echo "  ✓ Made context_activation_hook.sh executable"
    
    # Create Config.toml if not exists
    if [ ! -f "$CONTEXT_ENG_DIR/Config.toml" ]; then
        cat > "$CONTEXT_ENG_DIR/Config.toml" << 'EOF'
[context]
repo_path = "/home/ubuntu/src/repos/Context-Engineering"
schema_version = "7.0"
auto_activate = true

[performance]
timeout = 5
parallel_workers = 4
memory_limit = 2048
cache_size = 200

[resonance]
target_coefficient = 0.75
balance_target = 0.618

[enhancement]
enable_prompt_enhancement = true
language_priorities = ["julia", "rust", "typescript", "python"]
cache_enhancements = true

[logging]
log_level = "info"
performance_logging = true
EOF
        echo "  ✓ Created Config.toml"
    fi
    
    echo -e "${GREEN}✅ Context Engineering v7.0 files ready${NC}"
    echo
}

# Function to update settings.json
update_settings() {
    echo -e "${YELLOW}⚙️  Updating settings.json with unified hooks...${NC}"
    
    if [ ! -f "$SETTINGS_FILE" ]; then
        echo -e "${RED}❌ settings.json not found at $SETTINGS_FILE${NC}"
        exit 1
    fi
    
    # Create Python script to update JSON
    cat > /tmp/update_settings.py << 'EOF'
import json
import sys

settings_file = sys.argv[1]
hooks_dir = sys.argv[2]

# Read existing settings
with open(settings_file, 'r') as f:
    settings = json.load(f)

# Define new unified hooks configuration
new_hooks = {
    "UserPromptSubmit": [
        {
            "matcher": "",
            "hooks": [
                {
                    "type": "command",
                    "command": f"{hooks_dir}/context_activation_hook.sh --user-prompt"
                }
            ]
        }
    ],
    "SessionStart": [
        {
            "matcher": "",
            "hooks": [
                {
                    "type": "command",
                    "command": f"{hooks_dir}/context_activation_hook.sh --session-start"
                }
            ]
        }
    ],
    "PreToolUse": [
        {
            "matcher": "*",
            "hooks": [
                {
                    "type": "command",
                    "command": f"{hooks_dir}/context_activation_hook.sh --pre-tool"
                }
            ]
        }
    ],
    "PostToolUse": [
        {
            "matcher": "*",
            "hooks": [
                {
                    "type": "command",
                    "command": f"{hooks_dir}/context_activation_hook.sh --post-tool"
                }
            ]
        }
    ],
    "Stop": [
        {
            "matcher": "",
            "hooks": [
                {
                    "type": "command",
                    "command": f"{hooks_dir}/context_activation_hook.sh --stop"
                }
            ]
        }
    ],
    "SubagentStop": [
        {
            "matcher": "",
            "hooks": [
                {
                    "type": "command",
                    "command": f"{hooks_dir}/context_activation_hook.sh --subagent-stop"
                }
            ]
        }
    ],
    "Notification": [
        {
            "matcher": "",
            "hooks": [
                {
                    "type": "command",
                    "command": f"{hooks_dir}/context_activation_hook.sh --notification"
                }
            ]
        }
    ],
    "PreCompact": [
        {
            "matcher": "",
            "hooks": [
                {
                    "type": "command",
                    "command": f"{hooks_dir}/context_activation_hook.sh --pre-compact"
                }
            ]
        }
    ],
    "SessionEnd": [
        {
            "matcher": "",
            "hooks": [
                {
                    "type": "command",
                    "command": f"{hooks_dir}/context_activation_hook.sh --session-end"
                }
            ]
        }
    ]
}

# Update hooks section
settings["hooks"] = new_hooks

# Write updated settings
with open(settings_file, 'w') as f:
    json.dump(settings, f, indent=2)

print("✅ settings.json updated with unified hooks")
EOF
    
    python3 /tmp/update_settings.py "$SETTINGS_FILE" "$HOOKS_DIR"
    rm /tmp/update_settings.py
    
    echo
}

# Function to test hooks
test_hooks() {
    echo -e "${YELLOW}🧪 Testing unified hooks system...${NC}"
    
    # Test SessionStart
    echo "  Testing SessionStart..."
    echo '{"event": "session_start"}' | "$HOOKS_DIR/context_activation_hook.sh" --session-start > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓ SessionStart hook works${NC}"
    else
        echo -e "  ${RED}✗ SessionStart hook failed${NC}"
    fi
    
    # Test UserPromptSubmit
    echo "  Testing UserPromptSubmit..."
    echo '{"prompt": "test prompt"}' | "$HOOKS_DIR/context_activation_hook.sh" --user-prompt > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓ UserPromptSubmit hook works${NC}"
    else
        echo -e "  ${RED}✗ UserPromptSubmit hook failed${NC}"
    fi
    
    # Test PreToolUse
    echo "  Testing PreToolUse..."
    echo '{"tool_name": "Write", "tool_args": {}}' | "$HOOKS_DIR/context_activation_hook.sh" --pre-tool > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓ PreToolUse hook works${NC}"
    else
        echo -e "  ${RED}✗ PreToolUse hook failed${NC}"
    fi
    
    echo -e "${GREEN}✅ Basic hook tests complete${NC}"
    echo
}

# Function to remove old hooks
cleanup_old_hooks() {
    echo -e "${YELLOW}🧹 Cleaning up old hooks (optional)...${NC}"
    echo "Old hooks have been backed up to: $BACKUP_DIR"
    echo
    read -p "Do you want to remove the old hook files? (y/N): " -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # List of old hooks to remove
        OLD_HOOKS=(
            "schemantics_uplift.sh"
            "business_opportunity_detector_julia.sh"
            "error_occurred_hook.sh"
            "schema_uplift_hook.sh"
            "subagent_consolidator_julia.sh"
            "session_analytics_julia.sh"
            "tool_use_pre_hook.sh"
            "tool_use_post_hook.sh"
            "context_changed_hook.sh"
            "autonomous_system.py"
        )
        
        for hook in "${OLD_HOOKS[@]}"; do
            if [ -f "$HOOKS_DIR/$hook" ]; then
                rm "$HOOKS_DIR/$hook"
                echo "  ✓ Removed: $hook"
            fi
        done
        
        echo -e "${GREEN}✅ Old hooks cleaned up${NC}"
    else
        echo "  Old hooks retained (you can manually remove them later)"
    fi
    echo
}

# Function to show rollback instructions
show_rollback_instructions() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    Migration Complete!${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${GREEN}✅ Context Engineering v7.0 Unified Hooks are now active!${NC}"
    echo
    echo "📋 Summary:"
    echo "  • All 9 Claude Code hooks configured"
    echo "  • Julia HPC optimization enabled"
    echo "  • Slash command integration active"
    echo "  • Automatic prompt enhancement enabled"
    echo "  • Field resonance patterns active"
    echo
    echo "🔄 To rollback if needed:"
    echo "  1. Restore settings.json:"
    echo "     cp $BACKUP_DIR/settings.json.backup $SETTINGS_FILE"
    echo "  2. Restore old hooks:"
    echo "     cp $BACKUP_DIR/*.sh $HOOKS_DIR/"
    echo "     cp $BACKUP_DIR/*.py $HOOKS_DIR/"
    echo
    echo "📊 Monitor performance:"
    echo "  • Logs: $CONTEXT_ENG_DIR/logs/"
    echo "  • Config: $CONTEXT_ENG_DIR/Config.toml"
    echo
    echo "🚀 Next steps:"
    echo "  1. Restart Claude Code to activate new hooks"
    echo "  2. Try slash commands like /alignment or /research"
    echo "  3. Monitor logs for any issues"
    echo
}

# Main execution
main() {
    echo "This script will migrate your hooks to Context Engineering v7.0"
    echo "Your existing hooks will be backed up before any changes."
    echo
    read -p "Do you want to proceed? (y/N): " -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Migration cancelled."
        exit 0
    fi
    
    # Run migration steps
    create_backup
    check_julia
    setup_v7_files
    update_settings
    test_hooks
    cleanup_old_hooks
    show_rollback_instructions
}

# Run main function
main