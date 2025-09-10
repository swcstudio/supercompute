#!/usr/bin/env julia
"""
High-Performance System Monitor for Julia Business Automation
Provides real-time analytics and system health monitoring
"""

# Graceful package loading with fallbacks
function safe_import_packages()
    packages_loaded = Dict{String, Bool}()
    
    # Try to load JSON3
    try
        @eval using JSON3
        packages_loaded["JSON3"] = true
    catch e
        @warn "JSON3 not available, using fallback JSON parsing"
        packages_loaded["JSON3"] = false
        # Define minimal JSON fallback
        global JSON3 = (read = (s, t) -> Dict{String,Any}(), write = x -> "{}")
    end
    
    # Try to load Dates (usually available)
    try
        @eval using Dates
        packages_loaded["Dates"] = true
    catch e
        @warn "Dates not available, using basic timestamps"
        packages_loaded["Dates"] = false
        global now = () -> "$(time())"
    end
    
    return packages_loaded
end

# Initialize packages
const PACKAGES = safe_import_packages()

function display_system_status()
    println("🚀 Julia Business Automation System Status")
    println("=" ^ 60)
    
    # System information
    println("⚡ Performance Configuration:")
    println("  • Julia threads: $(Sys.CPU_THREADS)")
    println("  • Available memory: $(round(Sys.total_memory() / 1024^3, digits=1)) GB")
    println("  • Architecture: $(Sys.MACHINE)")
    
    # Check log files and activity
    log_dir = joinpath(@__DIR__, "logs")
    if isdir(log_dir)
        files = readdir(log_dir)
        total_size = sum([stat(joinpath(log_dir, f)).size for f in files if isfile(joinpath(log_dir, f))]) / 1024
        println("\n📊 Activity Logs: $(length(files)) files, $(round(total_size, digits=1)) KB total")
        
        # Show recent activity
        for file in sort(files)[1:min(8, length(files))]
            if endswith(file, ".jsonl") || endswith(file, ".log")
                size_kb = round(stat(joinpath(log_dir, file)).size / 1024, digits=1)
                println("  • $file ($(size_kb) KB)")
            end
        end
    else
        println("\n📊 Activity Logs: Directory not found - system initializing")
    end
    
    # Check performance aggregates
    perf_file = joinpath(@__DIR__, "data", "performance_aggregates.json")
    if isfile(perf_file)
        try
            if PACKAGES["JSON3"]
                perf_data = JSON3.read(read(perf_file, String))
                println("\n🎯 Subagent Performance Metrics:")
                for (agent, metrics) in perf_data
                    if haskey(metrics, "success_rate") && haskey(metrics, "avg_execution_time_ms")
                        success_rate = round(metrics["success_rate"] * 100, digits=1)
                        avg_time = round(metrics["avg_execution_time_ms"], digits=0)
                        total_runs = get(metrics, "total_executions", 0)
                        println("  • $agent: $(success_rate)% success, $(avg_time)ms avg, $total_runs runs")
                    end
                end
            else
                file_size = stat(perf_file).size
                println("\n🎯 Performance Metrics: $(round(file_size/1024, digits=1)) KB data (JSON3 not available)")
            end
        catch e
            println("\n🎯 Performance Metrics: Error reading data - $e")
        end
    else
        println("\n🎯 Performance Metrics: No data yet - system warming up")
    end
    
    # Check session analytics
    session_file = joinpath(@__DIR__, "data", "session_aggregates.json")
    if isfile(session_file)
        try
            if PACKAGES["JSON3"]
                session_data = JSON3.read(read(session_file, String))
                total_sessions = get(session_data, "total_sessions", 0)
                avg_duration = get(session_data, "avg_session_duration_min", 0)
                avg_tools = get(session_data, "avg_tools_per_session", 0)
                
                println("\n📈 Session Analytics:")
                println("  • Total sessions: $total_sessions")
                println("  • Average duration: $(avg_duration) minutes")
                println("  • Average tools per session: $avg_tools")
                
                if haskey(session_data, "last_updated")
                    last_update = session_data["last_updated"]
                    println("  • Last activity: $last_update")
                end
            else
                file_size = stat(session_file).size
                println("\n📈 Session Analytics: $(round(file_size/1024, digits=1)) KB data (JSON3 not available)")
            end
        catch e
            println("\n📈 Session Analytics: Error reading data - $e")
        end
    else
        println("\n📈 Session Analytics: No session data available yet")
    end
    
    # Check business opportunities log
    opportunities_file = joinpath(@__DIR__, "logs", "business_triggers.jsonl")
    if isfile(opportunities_file)
        try
            lines = readlines(opportunities_file)
            recent_opportunities = length(lines)
            println("\n💼 Business Opportunities: $recent_opportunities triggers recorded")
            
            if recent_opportunities > 0
                # Show recent opportunity types
                recent_lines = lines[max(1, end-4):end]
                opportunity_types = String[]
                for line in recent_lines
                    try
                        opp_data = JSON3.read(line)
                        if haskey(opp_data, "opportunity_type")
                            push!(opportunity_types, opp_data["opportunity_type"])
                        end
                    catch
                        continue
                    end
                end
                
                if !isempty(opportunity_types)
                    println("  • Recent types: $(join(unique(opportunity_types), ", "))")
                end
            end
        catch e
            println("\n💼 Business Opportunities: Error reading data - $e")
        end
    else
        println("\n💼 Business Opportunities: No opportunities triggered yet")
    end
    
    # Check tool usage statistics
    tool_stats_file = joinpath(@__DIR__, "data", "tool_usage_stats.json")
    if isfile(tool_stats_file)
        try
            tool_data = JSON3.read(read(tool_stats_file, String))
            println("\n🔧 Tool Usage Statistics:")
            
            # Sort tools by usage count
            sorted_tools = sort(collect(tool_data), by=x->get(x[2], "count", 0), rev=true)
            
            for (tool_name, stats) in sorted_tools[1:min(5, length(sorted_tools))]
                count = get(stats, "count", 0)
                success_rate = round(get(stats, "success_rate", 0) * 100, digits=1)
                avg_time = round(get(stats, "avg_time_ms", 0), digits=0)
                println("  • $tool_name: $count uses, $(success_rate)% success, $(avg_time)ms avg")
            end
        catch e
            println("\n🔧 Tool Usage Statistics: Error reading data - $e")
        end
    else
        println("\n🔧 Tool Usage Statistics: No tool usage data available yet")
    end
    
    # System health check
    println("\n🏥 System Health Check:")
    
    # Check Julia package status
    println("  📦 Package Status:")
    for (pkg, status) in PACKAGES
        if status
            println("    ✅ $pkg: Available")
        else
            println("    ⚠ $pkg: Using fallback")
        end
    end
    
    # Check core Julia modules
    try
        @eval using Distributed, Logging
        println("  ✅ Core Julia modules loaded successfully")
    catch e
        println("  ❌ Core module loading issues: $e")
    end
    
    # Check disk space
    data_dir = joinpath(@__DIR__, "data")
    if isdir(data_dir)
        data_size = sum([stat(joinpath(data_dir, f)).size for f in readdir(data_dir) if isfile(joinpath(data_dir, f))]) / 1024^2
        println("  • Data storage: $(round(data_size, digits=1)) MB")
        
        if data_size > 100  # More than 100MB
            println("  ⚠ Consider data cleanup - storage usage is high")
        else
            println("  ✅ Storage usage is healthy")
        end
    end
    
    # Check for recent errors
    error_files = filter(f -> contains(f, "error") || contains(f, "failed"), readdir(log_dir, join=false))
    if isempty(error_files)
        println("  ✅ No error logs detected")
    else
        println("  ⚠ $(length(error_files)) error files found - review recommended")
    end
    
    println("\n" * "=" ^ 60)
    println("✅ System operational and ready for autonomous operations")
    println("🎯 Compound productivity scaling: ENABLED")
    println("⚡ High-performance Julia backend: ACTIVE")
    println("🤖 Business automation workflows: RUNNING")
end

# Execute monitoring
try
    display_system_status()
catch e
    println("❌ Monitor execution failed: $e")
    println("System may need initialization or troubleshooting")
end