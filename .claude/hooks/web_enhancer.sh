#!/bin/bash
# Web Enhancer Hook (PreToolUse: Web.*)
# Enhances web operations (WebFetch, WebSearch) with context and intelligent defaults

# Create necessary directories
mkdir -p ~/.claude/hooks/web
mkdir -p ~/.claude/hooks/cache/web

# Parse JSON input
input=$(cat)

# Extract web operation information
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
url=$(echo "$input" | jq -r '.tool_input.url // empty')
query=$(echo "$input" | jq -r '.tool_input.query // empty')
prompt=$(echo "$input" | jq -r '.tool_input.prompt // empty')

# Function to log web activity
log_web_activity() {
    local type="$1"
    local data="$2"
    echo "{\"timestamp\": \"$(date -Iseconds)\", \"type\": \"$type\", \"data\": $data}" >> ~/.claude/hooks/web/activity.log
}

# Function to enhance WebSearch queries with context
enhance_search_query() {
    local query="$1"
    local enhanced_query="$query"
    
    # Add schema-related context if query relates to primary languages
    case "$query" in
        *"julia"*|*"Julia"*)
            enhanced_query="$query schema-aligned programming Schemantics"
            log_web_activity "search_enhancement" "{\"original\": \"$query\", \"enhanced\": \"$enhanced_query\", \"context\": \"julia\"}"
            ;;
        *"rust"*|*"Rust"*)
            enhanced_query="$query schema-aligned programming systems Schemantics"
            log_web_activity "search_enhancement" "{\"original\": \"$query\", \"enhanced\": \"$enhanced_query\", \"context\": \"rust\"}"
            ;;
        *"typescript"*|*"TypeScript"*)
            enhanced_query="$query schema-aligned programming web development Schemantics"
            log_web_activity "search_enhancement" "{\"original\": \"$query\", \"enhanced\": \"$enhanced_query\", \"context\": \"typescript\"}"
            ;;
        *"elixir"*|*"Elixir"*)
            enhanced_query="$query schema-aligned programming distributed systems Schemantics"
            log_web_activity "search_enhancement" "{\"original\": \"$query\", \"enhanced\": \"$enhanced_query\", \"context\": \"elixir\"}"
            ;;
        *"schema"*|*"BAML"*|*"Schemantics"*)
            enhanced_query="$query unified data science autonomous programming"
            log_web_activity "search_enhancement" "{\"original\": \"$query\", \"enhanced\": \"$enhanced_query\", \"context\": \"schemantics\"}"
            ;;
    esac
    
    # Add current year for time-sensitive queries
    if [[ "$query" =~ (latest|newest|current|2024|2025) ]]; then
        enhanced_query="$enhanced_query $(date +%Y)"
        log_web_activity "temporal_enhancement" "{\"query\": \"$enhanced_query\", \"year\": \"$(date +%Y)\"}"
    fi
    
    echo "$enhanced_query"
}

# Function to enhance WebFetch prompts with context
enhance_fetch_prompt() {
    local url="$1"
    local prompt="$2"
    local enhanced_prompt="$prompt"
    
    # Detect the type of content being fetched
    local content_type=""
    case "$url" in
        *"docs.anthropic.com"*|*"claude.ai"*) content_type="claude_docs" ;;
        *"github.com"*|*"gitlab.com"*) content_type="code_repository" ;;
        *"stackoverflow.com"*|*"stackexchange.com"*) content_type="technical_qa" ;;
        *"rust-lang.org"*|*"crates.io"*) content_type="rust_ecosystem" ;;
        *"julialang.org"*|*"juliahub.com"*) content_type="julia_ecosystem" ;;
        *"typescriptlang.org"*|*"npmjs.com"*) content_type="typescript_ecosystem" ;;
        *"elixir-lang.org"*|*"hex.pm"*) content_type="elixir_ecosystem" ;;
        *) content_type="general" ;;
    esac
    
    # Enhance prompt based on content type
    case "$content_type" in
        "claude_docs")
            enhanced_prompt="Focus on Claude Code specific features, hooks, and autonomous programming capabilities. $prompt"
            ;;
        "code_repository")
            enhanced_prompt="Analyze the code structure, identify primary languages (Julia, Rust, TypeScript, Elixir), and look for schema alignment patterns. $prompt"
            ;;
        "technical_qa")
            enhanced_prompt="Look for solutions that apply to schema-aligned programming and autonomous development workflows. $prompt"
            ;;
        "rust_ecosystem"|"julia_ecosystem"|"typescript_ecosystem"|"elixir_ecosystem")
            enhanced_prompt="Focus on features that support schema-aligned programming, type safety, and autonomous tool generation. $prompt"
            ;;
    esac
    
    log_web_activity "fetch_enhancement" "{\"url\": \"$url\", \"content_type\": \"$content_type\", \"original_prompt\": \"$prompt\", \"enhanced_prompt\": \"$enhanced_prompt\"}"
    
    echo "$enhanced_prompt"
}

# Function to check web cache
check_web_cache() {
    local cache_key="$1"
    local cache_file="~/.claude/hooks/cache/web/${cache_key}.json"
    local max_age=3600  # 1 hour cache
    
    if [[ -f "$cache_file" ]]; then
        local cache_time=$(jq -r '.cached_at // 0' "$cache_file")
        local current_time=$(date +%s)
        local age=$((current_time - cache_time))
        
        if [[ $age -lt $max_age ]]; then
            echo "$cache_file"
            return 0
        fi
    fi
    
    return 1
}

# Function to add intelligent domain filtering
add_domain_filtering() {
    local query="$1"
    local tool_input="$2"
    
    # Add allowed/blocked domains based on query context
    local allowed_domains=()
    local blocked_domains=()
    
    # For programming-related queries, prefer authoritative sources
    if [[ "$query" =~ (programming|code|development|api|documentation) ]]; then
        allowed_domains+=("github.com" "docs.rs" "doc.rust-lang.org" "julialang.org" "typescriptlang.org" "elixir-lang.org")
        blocked_domains+=("w3schools.com")  # Often outdated
    fi
    
    # For schema-related queries, focus on relevant sources
    if [[ "$query" =~ (schema|BAML|Schemantics|autonomous) ]]; then
        allowed_domains+=("docs.anthropic.com" "claude.ai" "github.com/boundaryml")
    fi
    
    # Apply domain filtering if we have preferences
    if [[ ${#allowed_domains[@]} -gt 0 ]]; then
        local domains_json=$(printf '%s\n' "${allowed_domains[@]}" | jq -R . | jq -s .)
        tool_input=$(echo "$tool_input" | jq --argjson domains "$domains_json" '.allowed_domains = $domains')
        log_web_activity "domain_filtering" "{\"type\": \"allowed\", \"domains\": $domains_json}"
    fi
    
    if [[ ${#blocked_domains[@]} -gt 0 ]]; then
        local blocked_json=$(printf '%s\n' "${blocked_domains[@]}" | jq -R . | jq -s .)
        tool_input=$(echo "$tool_input" | jq --argjson domains "$blocked_json" '.blocked_domains = $domains')
        log_web_activity "domain_filtering" "{\"type\": \"blocked\", \"domains\": $blocked_json}"
    fi
    
    echo "$tool_input"
}

# Function to optimize web request parameters
optimize_web_request() {
    local tool_name="$1"
    local tool_input="$2"
    
    case "$tool_name" in
        "WebSearch")
            # No additional optimization needed for WebSearch currently
            echo "$tool_input"
            ;;
        "WebFetch")
            # Could add timeout or retry logic, but keep simple for now
            echo "$tool_input"
            ;;
        *)
            echo "$tool_input"
            ;;
    esac
}

# Function to track web usage patterns
track_usage_patterns() {
    local tool_name="$1"
    local query_or_url="$2"
    
    local patterns_file="~/.claude/hooks/web/usage_patterns.json"
    [[ ! -f "$patterns_file" ]] && echo '{}' > "$patterns_file"
    
    # Extract domain from URL or classify query
    local pattern_key=""
    if [[ "$tool_name" == "WebFetch" && -n "$query_or_url" ]]; then
        local domain=$(echo "$query_or_url" | sed -n 's|^https\?://\([^/]*\).*|\1|p')
        pattern_key="fetch_${domain}"
    elif [[ "$tool_name" == "WebSearch" ]]; then
        # Classify search query
        local category="general"
        case "$query_or_url" in
            *"julia"*|*"rust"*|*"typescript"*|*"elixir"*) category="primary_languages" ;;
            *"schema"*|*"BAML"*|*"Schemantics"*) category="schemantics" ;;
            *"programming"*|*"code"*|*"development"*) category="programming" ;;
            *"error"*|*"fix"*|*"debug"*) category="troubleshooting" ;;
        esac
        pattern_key="search_${category}"
    fi
    
    if [[ -n "$pattern_key" ]]; then
        current_count=$(jq -r --arg key "$pattern_key" '.[$key] // 0' "$patterns_file")
        new_count=$((current_count + 1))
        
        jq --arg key "$pattern_key" --argjson count "$new_count" '.[$key] = $count' "$patterns_file" > "${patterns_file}.tmp"
        mv "${patterns_file}.tmp" "$patterns_file"
        
        log_web_activity "usage_pattern" "{\"pattern\": \"$pattern_key\", \"count\": $new_count}"
        
        # Suggest automation for frequent patterns
        if [[ $new_count -ge 5 ]]; then
            echo "{\"timestamp\": \"$(date -Iseconds)\", \"opportunity\": \"web_automation\", \"pattern\": \"$pattern_key\", \"frequency\": $new_count}" >> ~/.claude/hooks/web/automation_opportunities.log
        fi
    fi
}

# Function to add context-aware learning
add_contextual_learning() {
    local tool_name="$1"
    local query_or_url="$2"
    local context="$3"
    
    # Store context for future reference
    local context_file="~/.claude/hooks/web/context_history.log"
    
    local context_entry=$(jq -n \
        --arg tool "$tool_name" \
        --arg query_url "$query_or_url" \
        --arg context "$context" \
        --arg timestamp "$(date -Iseconds)" \
        '{tool: $tool, query_url: $query_url, context: $context, timestamp: $timestamp}')
    
    echo "$context_entry" >> "$context_file"
    
    # Keep only last 100 entries
    tail -100 "$context_file" > "${context_file}.tmp" && mv "${context_file}.tmp" "$context_file"
}

# Main enhancement logic
enhanced_input="$input"

if [[ "$tool_name" == "WebSearch" && -n "$query" ]]; then
    # Enhance WebSearch
    enhanced_query=$(enhance_search_query "$query")
    
    if [[ "$enhanced_query" != "$query" ]]; then
        enhanced_input=$(echo "$enhanced_input" | jq --arg query "$enhanced_query" '.tool_input.query = $query')
    fi
    
    # Add domain filtering
    enhanced_input=$(add_domain_filtering "$enhanced_query" "$(echo "$enhanced_input" | jq '.tool_input')")
    enhanced_input=$(echo "$enhanced_input" | jq --argjson tool_input "$(echo "$enhanced_input" | jq '.tool_input')" '.tool_input = $tool_input')
    
    # Track usage patterns
    track_usage_patterns "$tool_name" "$query"
    
    # Add contextual learning
    add_contextual_learning "$tool_name" "$query" "search"
    
    log_web_activity "websearch_enhanced" "{\"original_query\": \"$query\", \"enhanced_query\": \"$enhanced_query\"}"

elif [[ "$tool_name" == "WebFetch" && -n "$url" ]]; then
    # Enhance WebFetch
    if [[ -n "$prompt" ]]; then
        enhanced_prompt=$(enhance_fetch_prompt "$url" "$prompt")
        
        if [[ "$enhanced_prompt" != "$prompt" ]]; then
            enhanced_input=$(echo "$enhanced_input" | jq --arg prompt "$enhanced_prompt" '.tool_input.prompt = $prompt')
        fi
    fi
    
    # Check cache
    cache_key=$(echo "$url" | md5sum | cut -d' ' -f1)
    if check_web_cache "$cache_key"; then
        cache_file=$(check_web_cache "$cache_key")
        log_web_activity "cache_hit" "{\"url\": \"$url\", \"cache_file\": \"$cache_file\"}"
    else
        log_web_activity "cache_miss" "{\"url\": \"$url\"}"
    fi
    
    # Track usage patterns
    track_usage_patterns "$tool_name" "$url"
    
    # Add contextual learning
    add_contextual_learning "$tool_name" "$url" "fetch"
    
    log_web_activity "webfetch_enhanced" "{\"url\": \"$url\", \"prompt_enhanced\": $(if [[ "$enhanced_prompt" != "$prompt" ]]; then echo "true"; else echo "false"; fi)}"
fi

# Apply final optimizations
enhanced_input=$(optimize_web_request "$tool_name" "$enhanced_input")

# Log comprehensive web operation
log_entry=$(jq -n \
    --arg tool "$tool_name" \
    --arg query_url "$(if [[ -n "$query" ]]; then echo "$query"; else echo "$url"; fi)" \
    --arg timestamp "$(date -Iseconds)" \
    '{tool: $tool, query_url: $query_url, timestamp: $timestamp}')

echo "$log_entry" >> ~/.claude/hooks/web/comprehensive.log

echo "$enhanced_input"

exit 0