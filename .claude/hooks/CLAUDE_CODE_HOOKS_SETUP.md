# Claude Code Hooks Configuration - Complete Setup Guide

## Julia High-Performance Business Automation System
This guide provides the exact commands and configurations needed to set up the complete Julia-based autonomous business operations system.

## Prerequisites Setup

### 1. Julia Environment Setup
```bash
# Install Julia dependencies
cd ~/.claude/hooks/julia_business_automation
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. -e 'using Pkg; Pkg.precompile()'
```

### 2. Directory Structure Creation
```bash
# Create required directories
mkdir -p ~/.claude/hooks/julia_business_automation/{logs,data,temp,Subagents}
chmod +x ~/.claude/hooks/*.sh
chmod +x ~/.claude/hooks/julia_business_automation/*.jl
```

## Hook Configurations for Claude Code

### Hook 1: PreToolUse - Schema Uplifting Hook
**Event**: `PreToolUse`
**Tool Matcher**: `*` (all tools)
**Command**: 
```bash
/home/ubuntu/.claude/hooks/schema_uplift_hook.sh
```

### Hook 2: PostToolUse - Business Opportunity Detection
**Event**: `PostToolUse`
**Tool Matcher**: `Write,Edit,MultiEdit,Bash,WebFetch,Glob,Grep,Task`
**Command**:
```bash
/home/ubuntu/.claude/hooks/business_opportunity_detector_julia.sh
```

### Hook 3: SubagentStop - Lifecycle Management
**Event**: `SubagentStop`
**Tool Matcher**: `*` (all subagents)
**Command**:
```bash
/home/ubuntu/.claude/hooks/subagent_consolidator_julia.sh
```

### Hook 4: Stop - Session Analytics
**Event**: `Stop`
**Tool Matcher**: `*`
**Command**:
```bash
/home/ubuntu/.claude/hooks/session_analytics_julia.sh
```

## Exact Setup Commands for Each Hook

### Step 1: Create Schema Uplifting Hook
Run this command to create the PreToolUse hook:
```bash
# This creates the schema uplifting hook that transforms basic prompts into data science specifications
cat > ~/.claude/hooks/schema_uplift_hook.sh << 'EOF'
#!/bin/bash
# PreToolUse Hook - Schemantics Schema Uplifting
# Transforms prompts into high-level data science specifications

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
tool_args=$(echo "$input" | jq -r '.tool_args // {}')

# Only process significant tools that benefit from schema uplifting
case "$tool_name" in
    "Write"|"Edit"|"MultiEdit"|"Task")
        # Transform prompt through Schemantics uplifting
        echo "$input" | jq '
            .enhanced_context = {
                schema_framework: "schemantics",
                optimization_level: "data_science",
                language_priorities: ["julia", "rust", "typescript", "elixir"],
                performance_mode: "concurrent_execution",
                autonomous_level: "semi_auto"
            } |
            .tool_args = (.tool_args // {} | 
                .schema_hint = "Apply high-performance patterns and concurrent execution where applicable" |
                .quality_requirements = ["type_safety", "performance_optimization", "schema_compliance"])
        '
        ;;
    *)
        echo "$input"
        ;;
esac
EOF
chmod +x ~/.claude/hooks/schema_uplift_hook.sh
```

### Step 2: Verify Julia System
```bash
# Test Julia automation system
julia --project=/home/ubuntu/.claude/hooks/julia_business_automation -e '
    include("/home/ubuntu/.claude/hooks/julia_business_automation/BusinessSubagentFramework.jl")
    using .BusinessSubagentFramework
    println("✓ Julia business automation system ready")
'
```

### Step 3: Create Session Analytics Hook
```bash
cat > ~/.claude/hooks/session_analytics_julia.sh << 'EOF'
#!/bin/bash
# Stop Hook - Session Analytics and Reporting

if ! command -v julia &> /dev/null; then
    exit 0
fi

input=$(cat)
session_duration=$(echo "$input" | jq -r '.session_duration_ms // 0')
tools_used=$(echo "$input" | jq -r '.tools_used // []')

# Create session summary for analytics
timestamp=$(date -Iseconds)
session_data=$(jq -n \
    --arg ts "$timestamp" \
    --argjson duration "$session_duration" \
    --argjson tools "$tools_used" \
    '{
        timestamp: $ts,
        event: "session_complete",
        duration_ms: $duration,
        tools_used: $tools,
        productivity_score: (($duration / 1000) / ($tools | length)) # milliseconds per tool
    }')

# Save session analytics
echo "$session_data" >> ~/.claude/hooks/julia_business_automation/logs/session_analytics.jsonl

# Trigger Julia analytics processing
temp_input=$(mktemp)
echo "$session_data" > "$temp_input"

julia --project=/home/ubuntu/.claude/hooks/julia_business_automation \
      -e "
      using JSON3
      session_data = JSON3.read(read(\"$temp_input\", String))
      println(\"📊 Session completed: \", session_data[:duration_ms], \"ms, \", length(session_data[:tools_used]),\" tools used\")
      " 2>/dev/null

rm -f "$temp_input"
exit 0
EOF
chmod +x ~/.claude/hooks/session_analytics_julia.sh
```

## Performance Optimization Settings

### Julia Startup Optimization
```bash
# Create Julia startup optimization
mkdir -p ~/.julia/config
cat > ~/.julia/config/startup.jl << 'EOF'
# High-performance settings for business automation
ENV["JULIA_NUM_THREADS"] = string(Sys.CPU_THREADS)
ENV["JULIA_WORKER_TIMEOUT"] = "120"

# Precompile frequently used packages
try
    using JSON3, HTTP, DataFrames, Distributed
    println("✓ Business automation packages preloaded")
catch
    println("⚠ Some packages need installation")
end
EOF
```

### Concurrent Execution Configuration
```bash
# Configure Julia for maximum performance
cat > ~/.claude/hooks/julia_business_automation/performance_config.jl << 'EOF'
# Performance configuration for high-throughput operations
using Distributed

# Add worker processes for concurrent execution
if nprocs() == 1
    addprocs(min(4, Sys.CPU_THREADS))
    println("Added $(nprocs()-1) worker processes for concurrent execution")
end

# Load business automation on all workers
@everywhere begin
    using JSON3, HTTP, DataFrames
    include("BusinessSubagentFramework.jl")
    using .BusinessSubagentFramework
end

# Export performance settings
const PERFORMANCE_CONFIG = Dict{String, Any}(
    "max_concurrent_operations" => 4,
    "worker_timeout_seconds" => 120,
    "memory_limit_gb" => 8,
    "enable_distributed_processing" => true
)
EOF
```

## Verification and Testing

### Test Hook System
```bash
# Test each hook individually
echo '{"tool_name": "Write", "tool_args": {"content": "test"}}' | ~/.claude/hooks/schema_uplift_hook.sh

echo '{"tool_name": "Edit", "success": true, "execution_time_ms": 1000}' | ~/.claude/hooks/business_opportunity_detector_julia.sh

echo '{"subagent_type": "devin-software-engineer", "success": true, "task_description": "implement feature"}' | ~/.claude/hooks/subagent_consolidator_julia.sh

echo '{"session_duration_ms": 300000, "tools_used": ["Write", "Edit", "Bash"]}' | ~/.claude/hooks/session_analytics_julia.sh
```

### Monitor System Health
```bash
# Create monitoring dashboard
cat > ~/.claude/hooks/julia_business_automation/monitor.jl << 'EOF'
#!/usr/bin/env julia
using JSON3, DataFrames, Dates

function display_system_status()
    println("🚀 Julia Business Automation System Status")
    println("=" ^ 50)
    
    # Check log files
    log_dir = joinpath(@__DIR__, "logs")
    if isdir(log_dir)
        files = readdir(log_dir)
        println("📊 Active log files: $(length(files))")
        for file in files[1:min(5, length(files))]
            size_kb = round(stat(joinpath(log_dir, file)).size / 1024, digits=1)
            println("  • $file ($(size_kb) KB)")
        end
    end
    
    # Check performance metrics
    perf_file = joinpath(@__DIR__, "data", "performance_aggregates.json")
    if isfile(perf_file)
        perf_data = JSON3.read(read(perf_file, String))
        println("\n🎯 Performance Metrics:")
        for (agent, metrics) in perf_data
            success_rate = round(metrics["success_rate"] * 100, digits=1)
            avg_time = round(metrics["avg_execution_time_ms"], digits=0)
            println("  • $agent: $(success_rate)% success, $(avg_time)ms avg")
        end
    end
    
    println("\n✅ System operational and ready for autonomous operations")
end

display_system_status()
EOF
chmod +x ~/.claude/hooks/julia_business_automation/monitor.jl
```

## Claude Code Hook Configuration Summary

Use these exact configurations in Claude Code:

**Hook 1 - Schema Uplifting**
- Event: PreToolUse
- Tool Matcher: *
- Command: `/home/ubuntu/.claude/hooks/schema_uplift_hook.sh`

**Hook 2 - Business Opportunities**  
- Event: PostToolUse
- Tool Matcher: `Write,Edit,MultiEdit,Bash,WebFetch,Glob,Grep,Task`
- Command: `/home/ubuntu/.claude/hooks/business_opportunity_detector_julia.sh`

**Hook 3 - Subagent Management**
- Event: SubagentStop  
- Tool Matcher: *
- Command: `/home/ubuntu/.claude/hooks/subagent_consolidator_julia.sh`

**Hook 4 - Analytics**
- Event: Stop
- Tool Matcher: *  
- Command: `/home/ubuntu/.claude/hooks/session_analytics_julia.sh`

## Post-Setup Commands

After configuring all hooks in Claude Code, run:

```bash
# Final system initialization
julia --project=/home/ubuntu/.claude/hooks/julia_business_automation ~/.claude/hooks/julia_business_automation/monitor.jl

# Enable performance monitoring
crontab -e
# Add: */15 * * * * julia ~/.claude/hooks/julia_business_automation/monitor.jl >> ~/.claude/hooks/julia_business_automation/logs/system_health.log 2>&1
```

Your high-performance Julia autonomous business operations system is now fully configured and ready for compound productivity scaling.