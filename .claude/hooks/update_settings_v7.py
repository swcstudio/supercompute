#!/usr/bin/env python3
"""
Update settings.json for Context Engineering v7.0 Unified Hooks
This script safely updates the Claude Code settings to use the new unified hook system.
"""

import json
import sys
import os
from datetime import datetime

def update_settings_for_v7(settings_file="/home/ubuntu/.claude/settings.json"):
    """Update settings.json with Context Engineering v7.0 unified hooks"""
    
    # Check if settings file exists
    if not os.path.exists(settings_file):
        print(f"❌ Settings file not found: {settings_file}")
        return False
    
    # Read current settings
    with open(settings_file, 'r') as f:
        settings = json.load(f)
    
    # Backup current settings
    backup_file = settings_file + f".backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    with open(backup_file, 'w') as f:
        json.dump(settings, f, indent=2)
    print(f"✅ Backed up settings to: {backup_file}")
    
    # Define the unified hooks configuration
    hooks_dir = "/home/ubuntu/.claude/hooks"
    unified_hooks = {
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
                "matcher": "Write,Edit,MultiEdit,Bash,WebFetch,Glob,Grep,Task",
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
    
    # Update the hooks section
    settings["hooks"] = unified_hooks
    
    # Add metadata about the update
    if "metadata" not in settings:
        settings["metadata"] = {}
    
    settings["metadata"]["context_engineering_v7"] = {
        "version": "7.0.0",
        "updated": datetime.now().isoformat(),
        "features": [
            "unified_hooks",
            "julia_hpc",
            "slash_commands",
            "prompt_enhancement",
            "field_resonance"
        ]
    }
    
    # Write updated settings
    with open(settings_file, 'w') as f:
        json.dump(settings, f, indent=2)
    
    print(f"✅ Updated settings.json with Context Engineering v7.0 hooks")
    
    # Display summary
    print("\n📋 Hook Configuration Summary:")
    print("  • SessionStart:     Activates Context v7.0")
    print("  • UserPromptSubmit: Enhances prompts with slash commands")
    print("  • PreToolUse:       Adds context patterns (all tools)")
    print("  • PostToolUse:      Updates knowledge (key tools)")
    print("  • Stop:             Generates session analytics")
    print("  • SubagentStop:     Consolidates subagent results")
    print("  • Notification:     Handles errors and notifications")
    print("  • PreCompact:       Prepares for context compaction")
    print("  • SessionEnd:       Final cleanup and reporting")
    
    return True

if __name__ == "__main__":
    # Allow custom settings file path as argument
    settings_file = sys.argv[1] if len(sys.argv) > 1 else "/home/ubuntu/.claude/settings.json"
    
    success = update_settings_for_v7(settings_file)
    
    if success:
        print("\n🚀 Next steps:")
        print("  1. Restart Claude Code to activate new hooks")
        print("  2. Test with: echo '{\"event\":\"test\"}' | /home/ubuntu/.claude/hooks/context_activation_hook.sh --session-start")
        print("  3. Try slash commands like /alignment or /research")
        sys.exit(0)
    else:
        sys.exit(1)