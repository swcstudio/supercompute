#!/bin/bash
# Intelligent Reader Hook (PreToolUse: Read)
# Enhances file reading with context, caching, and smart analysis

# Create necessary directories
mkdir -p ~/.claude/hooks/reading
mkdir -p ~/.claude/hooks/cache

# Parse JSON input
input=$(cat)

# Extract file information
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
limit=$(echo "$input" | jq -r '.tool_input.limit // empty')
offset=$(echo "$input" | jq -r '.tool_input.offset // empty')

# Function to log reading activity
log_read_activity() {
    local type="$1"
    local data="$2"
    echo "{\"timestamp\": \"$(date -Iseconds)\", \"type\": \"$type\", \"data\": $data}" >> ~/.claude/hooks/reading/activity.log
}

# Function to detect file type and purpose
detect_file_context() {
    local filepath="$1"
    
    # Extract file information
    local filename=$(basename "$filepath")
    local extension="${filepath##*.}"
    local directory=$(dirname "$filepath")
    
    local context=""
    local file_type=""
    local purpose=""
    
    # Detect by extension
    case "$extension" in
        "jl") file_type="julia"; purpose="scientific_computing" ;;
        "rs") file_type="rust"; purpose="systems_programming" ;;
        "ts"|"tsx") file_type="typescript"; purpose="web_development" ;;
        "ex"|"exs") file_type="elixir"; purpose="distributed_systems" ;;
        "py") file_type="python"; purpose="general_programming" ;;
        "js"|"jsx") file_type="javascript"; purpose="web_development" ;;
        "md") file_type="markdown"; purpose="documentation" ;;
        "json") file_type="json"; purpose="configuration_data" ;;
        "toml") file_type="toml"; purpose="configuration" ;;
        "yaml"|"yml") file_type="yaml"; purpose="configuration" ;;
        "sh") file_type="shell"; purpose="automation" ;;
        *) file_type="unknown"; purpose="unknown" ;;
    esac
    
    # Detect by filename patterns
    case "$filename" in
        "README"*|"readme"*) purpose="documentation" ;;
        "Cargo.toml"|"Project.toml"|"package.json") purpose="project_config" ;;
        "requirements.txt"|"Pipfile") purpose="dependencies" ;;
        ".gitignore"|".env"*) purpose="project_settings" ;;
        "test"*|"*test*"|"*spec*") purpose="testing" ;;
        "config"*|"settings"*) purpose="configuration" ;;
    esac
    
    # Detect by directory context
    case "$directory" in
        *"/test"*|*"/tests"*|*"/spec"*) context="testing" ;;
        *"/src"*|*"/lib"*) context="source_code" ;;
        *"/docs"*|*"/doc"*) context="documentation" ;;
        *"/config"*|*"/conf"*) context="configuration" ;;
        *"/scripts"*|*"/bin"*) context="automation" ;;
        *"schemantics"*) context="schemantics_project" ;;
        *) context="general" ;;
    esac
    
    echo "{\"file_type\": \"$file_type\", \"purpose\": \"$purpose\", \"context\": \"$context\", \"extension\": \"$extension\"}"
}

# Function to check file cache
check_file_cache() {
    local filepath="$1"
    local cache_key=$(echo "$filepath" | md5sum | cut -d' ' -f1)
    local cache_file="~/.claude/hooks/cache/${cache_key}.json"
    
    if [[ -f "$cache_file" ]]; then
        local file_mtime=$(stat -f "%m" "$filepath" 2>/dev/null || stat -c "%Y" "$filepath" 2>/dev/null || echo "0")
        local cache_mtime=$(jq -r '.file_mtime // 0' "$cache_file")
        
        if [[ "$file_mtime" -le "$cache_mtime" ]]; then
            # Cache is valid
            echo "$cache_file"
            return 0
        fi
    fi
    
    return 1
}

# Function to create file cache
create_file_cache() {
    local filepath="$1"
    local file_context="$2"
    
    if [[ -f "$filepath" ]]; then
        local cache_key=$(echo "$filepath" | md5sum | cut -d' ' -f1)
        local cache_file="~/.claude/hooks/cache/${cache_key}.json"
        local file_mtime=$(stat -f "%m" "$filepath" 2>/dev/null || stat -c "%Y" "$filepath" 2>/dev/null || echo "0")
        local file_size=$(wc -c < "$filepath" 2>/dev/null || echo "0")
        local line_count=$(wc -l < "$filepath" 2>/dev/null || echo "0")
        
        # Create cache entry
        local cache_entry=$(jq -n \
            --arg filepath "$filepath" \
            --argjson context "$file_context" \
            --argjson file_mtime "$file_mtime" \
            --argjson file_size "$file_size" \
            --argjson line_count "$line_count" \
            --arg timestamp "$(date -Iseconds)" \
            '{
                filepath: $filepath,
                context: $context,
                file_mtime: $file_mtime,
                file_size: $file_size,
                line_count: $line_count,
                cached_at: $timestamp
            }')
        
        echo "$cache_entry" > "$cache_file"
        echo "$cache_file"
    fi
}

# Function to add intelligent context to read operation
add_read_context() {
    local filepath="$1"
    local file_context="$2"
    
    local file_type=$(echo "$file_context" | jq -r '.file_type')
    local purpose=$(echo "$file_context" | jq -r '.purpose')
    local context=$(echo "$file_context" | jq -r '.context')
    
    # Add context-specific enhancements
    case "$context" in
        "schemantics_project")
            log_read_activity "schemantics_read" "{\"file\": \"$filepath\", \"type\": \"$file_type\"}"
            ;;
        "testing")
            log_read_activity "test_read" "{\"file\": \"$filepath\", \"purpose\": \"$purpose\"}"
            ;;
        "source_code")
            log_read_activity "source_read" "{\"file\": \"$filepath\", \"language\": \"$file_type\"}"
            ;;
    esac
    
    # Track file reading patterns
    local pattern_key="${file_type}_${purpose}"
    local patterns_file="~/.claude/hooks/reading/patterns.json"
    [[ ! -f "$patterns_file" ]] && echo '{}' > "$patterns_file"
    
    current_count=$(jq -r --arg key "$pattern_key" '.[$key] // 0' "$patterns_file")
    new_count=$((current_count + 1))
    
    jq --arg key "$pattern_key" --argjson count "$new_count" '.[$key] = $count' "$patterns_file" > "${patterns_file}.tmp"
    mv "${patterns_file}.tmp" "$patterns_file"
}

# Function to suggest related files
suggest_related_files() {
    local filepath="$1"
    local file_context="$2"
    
    local directory=$(dirname "$filepath")
    local file_type=$(echo "$file_context" | jq -r '.file_type')
    local purpose=$(echo "$file_context" | jq -r '.purpose')
    
    local suggestions=()
    
    # Suggest related files based on context
    case "$purpose" in
        "scientific_computing")
            # For Julia files, suggest related .jl files and Project.toml
            if [[ -f "$directory/Project.toml" ]]; then
                suggestions+=("$directory/Project.toml")
            fi
            ;;
        "systems_programming")
            # For Rust files, suggest Cargo.toml and related .rs files
            if [[ -f "$directory/Cargo.toml" ]]; then
                suggestions+=("$directory/Cargo.toml")
            fi
            ;;
        "web_development")
            # For TS files, suggest package.json and related config files
            if [[ -f "$directory/package.json" ]]; then
                suggestions+=("$directory/package.json")
            fi
            if [[ -f "$directory/tsconfig.json" ]]; then
                suggestions+=("$directory/tsconfig.json")
            fi
            ;;
        "project_config")
            # For config files, suggest README and related source files
            if [[ -f "$directory/README.md" ]]; then
                suggestions+=("$directory/README.md")
            fi
            ;;
    esac
    
    # Log suggestions
    if [[ ${#suggestions[@]} -gt 0 ]]; then
        local suggestions_json=$(printf '%s\n' "${suggestions[@]}" | jq -R . | jq -s .)
        log_read_activity "file_suggestions" "{\"for_file\": \"$filepath\", \"suggestions\": $suggestions_json}"
    fi
}

# Function to add schema awareness for primary languages
add_schema_awareness() {
    local filepath="$1"
    local file_context="$2"
    
    local file_type=$(echo "$file_context" | jq -r '.file_type')
    
    # Add schema context for primary languages
    case "$file_type" in
        "julia"|"rust"|"typescript"|"elixir")
            log_read_activity "schema_aware_read" "{\"file\": \"$filepath\", \"language\": \"$file_type\", \"schema_context\": true}"
            
            # Check if file uses Schemantics imports
            if [[ -f "$filepath" ]]; then
                local has_schemantics="false"
                case "$file_type" in
                    "julia")
                        if grep -q "using Schemantics" "$filepath" 2>/dev/null; then
                            has_schemantics="true"
                        fi
                        ;;
                    "rust")
                        if grep -q "use schemantics" "$filepath" 2>/dev/null; then
                            has_schemantics="true"
                        fi
                        ;;
                    "typescript")
                        if grep -q "from.*schemantics" "$filepath" 2>/dev/null; then
                            has_schemantics="true"
                        fi
                        ;;
                    "elixir")
                        if grep -q "alias Schemantics" "$filepath" 2>/dev/null; then
                            has_schemantics="true"
                        fi
                        ;;
                esac
                
                log_read_activity "schemantics_integration" "{\"file\": \"$filepath\", \"language\": \"$file_type\", \"has_schemantics\": $has_schemantics}"
            fi
            ;;
    esac
}

# Function to optimize read parameters
optimize_read_parameters() {
    local filepath="$1"
    local limit="$2"
    local offset="$3"
    local file_context="$4"
    
    local optimized_limit="$limit"
    local optimized_offset="$offset"
    
    if [[ -f "$filepath" ]]; then
        local line_count=$(wc -l < "$filepath" 2>/dev/null || echo "0")
        local file_size=$(wc -c < "$filepath" 2>/dev/null || echo "0")
        
        # Optimize based on file size
        if [[ -z "$limit" ]]; then
            if [[ $file_size -gt 100000 ]]; then  # > 100KB
                optimized_limit="100"  # Limit to first 100 lines for large files
                log_read_activity "optimization" "{\"file\": \"$filepath\", \"optimization\": \"large_file_limit\", \"limit\": 100}"
            elif [[ $line_count -gt 1000 ]]; then
                optimized_limit="200"  # Limit to first 200 lines for long files
                log_read_activity "optimization" "{\"file\": \"$filepath\", \"optimization\": \"long_file_limit\", \"limit\": 200}"
            fi
        fi
        
        # Optimize based on file type
        local file_type=$(echo "$file_context" | jq -r '.file_type')
        case "$file_type" in
            "json"|"yaml")
                # For config files, usually want to see the whole file
                optimized_limit=""
                ;;
            "markdown")
                # For docs, might want more context
                if [[ -z "$limit" && $line_count -gt 500 ]]; then
                    optimized_limit="300"
                fi
                ;;
        esac
    fi
    
    echo "{\"limit\": \"$optimized_limit\", \"offset\": \"$optimized_offset\"}"
}

# Main enhancement logic
if [[ -n "$file_path" ]]; then
    # 1. Detect file context
    file_context=$(detect_file_context "$file_path")
    
    # 2. Check cache
    cache_file=""
    if check_file_cache "$file_path"; then
        cache_file=$(check_file_cache "$file_path")
        log_read_activity "cache_hit" "{\"file\": \"$file_path\", \"cache_file\": \"$cache_file\"}"
    else
        cache_file=$(create_file_cache "$file_path" "$file_context")
        log_read_activity "cache_miss" "{\"file\": \"$file_path\", \"cache_created\": true}"
    fi
    
    # 3. Add reading context
    add_read_context "$file_path" "$file_context"
    
    # 4. Suggest related files
    suggest_related_files "$file_path" "$file_context"
    
    # 5. Add schema awareness
    add_schema_awareness "$file_path" "$file_context"
    
    # 6. Optimize read parameters
    optimized_params=$(optimize_read_parameters "$file_path" "$limit" "$offset" "$file_context")
    optimized_limit=$(echo "$optimized_params" | jq -r '.limit')
    optimized_offset=$(echo "$optimized_params" | jq -r '.offset')
    
    # 7. Create enhanced JSON with optimized parameters
    enhanced_input="$input"
    
    if [[ -n "$optimized_limit" && "$optimized_limit" != "empty" && "$optimized_limit" != "$limit" ]]; then
        enhanced_input=$(echo "$enhanced_input" | jq --argjson limit "$optimized_limit" '.tool_input.limit = $limit')
    fi
    
    if [[ -n "$optimized_offset" && "$optimized_offset" != "empty" && "$optimized_offset" != "$offset" ]]; then
        enhanced_input=$(echo "$enhanced_input" | jq --argjson offset "$optimized_offset" '.tool_input.offset = $offset')
    fi
    
    # 8. Log comprehensive read operation
    log_entry=$(jq -n \
        --arg filepath "$file_path" \
        --argjson context "$file_context" \
        --arg limit "$optimized_limit" \
        --arg offset "$optimized_offset" \
        --arg timestamp "$(date -Iseconds)" \
        '{filepath: $filepath, context: $context, limit: $limit, offset: $offset, timestamp: $timestamp}')
    
    echo "$log_entry" >> ~/.claude/hooks/reading/comprehensive.log
    
    # 9. Track reading frequency for automation opportunities
    local file_hash=$(echo "$file_path" | md5sum | cut -d' ' -f1)
    local freq_file="~/.claude/hooks/reading/frequency.json"
    [[ ! -f "$freq_file" ]] && echo '{}' > "$freq_file"
    
    current_freq=$(jq -r --arg key "$file_hash" '.[$key] // 0' "$freq_file")
    new_freq=$((current_freq + 1))
    
    jq --arg key "$file_hash" --argjson freq "$new_freq" '.[$key] = $freq' "$freq_file" > "${freq_file}.tmp"
    mv "${freq_file}.tmp" "$freq_file"
    
    # Suggest caching or automation for frequently read files
    if [[ $new_freq -ge 5 ]]; then
        echo "{\"timestamp\": \"$(date -Iseconds)\", \"opportunity\": \"frequent_file_reader\", \"file\": \"$file_path\", \"frequency\": $new_freq}" >> ~/.claude/hooks/reading/automation_opportunities.log
    fi
    
    echo "$enhanced_input"
else
    # No file path to enhance
    echo "$input"
fi

exit 0