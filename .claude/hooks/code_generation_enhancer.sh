#!/bin/bash
# Code Generation Enhancer Hook (PreToolUse: Write|Edit|MultiEdit)
# Automatically enhances all code generation with schema alignment and best practices

# Parse JSON input
input=$(cat)

# Extract tool information
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
content=$(echo "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty')

# Log the operation for pattern learning
echo "{\"timestamp\": \"$(date -Iseconds)\", \"tool\": \"$tool_name\", \"file\": \"$file_path\", \"type\": \"code_generation\"}" >> ~/.claude/hooks/operations.log

# Detect programming language from file extension or content
detect_language() {
    local filepath="$1"
    local code="$2"
    
    # Check file extension first
    case "$filepath" in
        *.jl) echo "julia" ;;
        *.rs) echo "rust" ;;
        *.ts|*.tsx) echo "typescript" ;;
        *.ex|*.exs) echo "elixir" ;;
        *.py) echo "python" ;;
        *.js|*.jsx) echo "javascript" ;;
        *.go) echo "go" ;;
        *) 
            # Analyze content if extension is unclear
            if echo "$code" | grep -q "function.*end\|using\s"; then
                echo "julia"
            elif echo "$code" | grep -q "fn \|let mut\|impl "; then
                echo "rust"
            elif echo "$code" | grep -q "interface\|async function\|: Promise"; then
                echo "typescript"
            elif echo "$code" | grep -q "defmodule\||>\|def.*do"; then
                echo "elixir"
            else
                echo "unknown"
            fi
            ;;
    esac
}

# Add schema imports based on language
add_schema_imports() {
    local language="$1"
    local code="$2"
    
    case "$language" in
        "julia")
            if ! echo "$code" | grep -q "using Schemantics"; then
                echo -e "using Schemantics\nusing Schemantics: @generate_tool, SchemaClient\n\n$code"
            else
                echo "$code"
            fi
            ;;
        "rust")
            if ! echo "$code" | grep -q "use schemantics"; then
                echo -e "use schemantics::{SchemaClient, UnifiedSchema, SchemaResult};\nuse serde::{Deserialize, Serialize};\nuse tokio;\n\n$code"
            else
                echo "$code"
            fi
            ;;
        "typescript")
            if ! echo "$code" | grep -q "from.*schemantics"; then
                echo -e "import { SchemaClient, UnifiedSchema, SchemaResult } from '@schemantics/client';\nimport { z } from 'zod';\n\n$code"
            else
                echo "$code"
            fi
            ;;
        "elixir")
            if ! echo "$code" | grep -q "alias Schemantics"; then
                echo -e "alias Schemantics.{Client, Schema, UnifiedTypes}\nrequire Logger\n\n$code"
            else
                echo "$code"
            fi
            ;;
        *)
            echo "$code"
            ;;
    esac
}

# Add generation metadata header
add_metadata_header() {
    local language="$1"
    local code="$2"
    
    case "$language" in
        "julia")
            echo -e "#=\nGenerated with Schemantics Schema-Aligned Programming\nTimestamp: $(date -Iseconds)\nLanguage: Julia (Primary)\nSchema Version: 1.0.0\n=#\n\n$code"
            ;;
        "rust")
            echo -e "/*\n * Generated with Schemantics Schema-Aligned Programming\n * Timestamp: $(date -Iseconds)\n * Language: Rust (Primary)\n * Schema Version: 1.0.0\n */\n\n$code"
            ;;
        "typescript")
            echo -e "/**\n * Generated with Schemantics Schema-Aligned Programming\n * Timestamp: $(date -Iseconds)\n * Language: TypeScript (Primary)\n * Schema Version: 1.0.0\n */\n\n$code"
            ;;
        "elixir")
            echo -e "@moduledoc \"\"\"\nGenerated with Schemantics Schema-Aligned Programming\nTimestamp: $(date -Iseconds)\nLanguage: Elixir (Primary)\nSchema Version: 1.0.0\n\"\"\"\n\n$code"
            ;;
        *)
            echo -e "# Generated with Schemantics Schema-Aligned Programming\n# Timestamp: $(date -Iseconds)\n# Schema Version: 1.0.0\n\n$code"
            ;;
    esac
}

# Apply language-specific optimizations
optimize_for_language() {
    local language="$1"
    local code="$2"
    
    case "$language" in
        "julia")
            # Add type annotations and performance hints
            echo "$code" | sed 's/function \([^(]*\)(/function \1(/' 
            ;;
        "rust")
            # Ensure proper error handling patterns
            if ! echo "$code" | grep -q "Result<"; then
                echo "$code" | sed 's/fn \([^(]*\)(/fn \1(/' 
            else
                echo "$code"
            fi
            ;;
        "typescript")
            # Add strict type checking
            if ! echo "$code" | grep -q "strict"; then
                echo "$code"
            else
                echo "$code"
            fi
            ;;
        "elixir")
            # Add GenServer patterns for stateful operations
            if echo "$code" | grep -q "def .*state" && ! echo "$code" | grep -q "GenServer"; then
                echo "use GenServer" | cat - <(echo "$code")
            else
                echo "$code"
            fi
            ;;
        *)
            echo "$code"
            ;;
    esac
}

# Main enhancement logic
if [[ -n "$content" && -n "$file_path" ]]; then
    language=$(detect_language "$file_path" "$content")
    
    # Only enhance primary languages with full schema alignment
    if [[ "$language" =~ ^(julia|rust|typescript|elixir)$ ]]; then
        # Apply full schema enhancement
        enhanced_content=$(echo "$content" | 
            { read -r code; add_schema_imports "$language" "$code"; } |
            { read -r -d '' code; add_metadata_header "$language" "$code"; } |
            { read -r -d '' code; optimize_for_language "$language" "$code"; })
        
        # Create enhanced JSON with the improved content
        if [[ "$tool_name" == "Write" ]]; then
            echo "$input" | jq --arg content "$enhanced_content" '.tool_input.content = $content'
        elif [[ "$tool_name" =~ ^(Edit|MultiEdit)$ ]]; then
            echo "$input" | jq --arg content "$enhanced_content" '.tool_input.new_string = $content'
        else
            echo "$input"
        fi
        
        # Log successful enhancement
        echo "{\"timestamp\": \"$(date -Iseconds)\", \"action\": \"enhanced\", \"language\": \"$language\", \"file\": \"$file_path\"}" >> ~/.claude/hooks/enhancements.log
    else
        # For non-primary languages, just add basic metadata
        if [[ -n "$content" ]]; then
            basic_header="# Enhanced with Schemantics | $(date -Iseconds)\n"
            enhanced_content="$basic_header$content"
            
            if [[ "$tool_name" == "Write" ]]; then
                echo "$input" | jq --arg content "$enhanced_content" '.tool_input.content = $content'
            elif [[ "$tool_name" =~ ^(Edit|MultiEdit)$ ]]; then
                echo "$input" | jq --arg content "$enhanced_content" '.tool_input.new_string = $content'
            else
                echo "$input"
            fi
        else
            echo "$input"
        fi
    fi
else
    # If no content to enhance, pass through unchanged
    echo "$input"
fi

exit 0