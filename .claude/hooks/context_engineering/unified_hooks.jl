#!/usr/bin/env julia
"""
    Unified Hooks Module - Consolidates all hook functionality
    
    This module consolidates the previous fragmented Python and shell scripts
    into a single, high-performance Julia system that:
    
    1. Replaces tool_use_pre_hook.sh with enhanced pre-tool processing
    2. Replaces tool_use_post_hook.sh with knowledge graph updates
    3. Integrates business opportunity detection
    4. Adds prompt enhancement with v7.0 patterns
    5. Provides session analytics and performance tracking
    
    All previous hook functionality is preserved and enhanced with
    Context Engineering v7.0 capabilities.
"""
module UnifiedHooks

using JSON3
using Dates
using SHA
using Statistics
using OrderedCollections

# Note: This module is included by ContextV7Activation, not the other way around
# to avoid circular dependencies

# Business opportunity detection patterns (from old hooks)
const BUSINESS_PATTERNS = Dict(
    "Write" => [
        (r"feature|function|class|component"i, "code_completion_opportunity", 0.70),
        (r"test|spec|unit"i, "testing_opportunity", 0.65),
        (r"TODO|FIXME"i, "technical_debt_opportunity", 0.60)
    ],
    "Bash" => [
        (r"deploy|release|build"i, "deployment_opportunity", 0.65),
        (r"test|pytest|jest"i, "testing_execution", 0.60),
        (r"julia|python|node"i, "runtime_optimization", 0.55)
    ],
    "WebFetch" => [
        (r"research|analyze|market|competitor"i, "research_content_opportunity", 0.75),
        (r"documentation|docs|api"i, "documentation_opportunity", 0.70)
    ],
    "Task" => [
        (r"implement|create|build"i, "implementation_opportunity", 0.80),
        (r"refactor|optimize|improve"i, "optimization_opportunity", 0.75)
    ]
)

# Schema uplifting patterns (from schema_uplift_hook.sh)
const SCHEMA_PATTERNS = Dict(
    "language_priorities" => ["julia", "rust", "typescript", "elixir"],
    "performance_mode" => "concurrent_execution",
    "autonomous_level" => "semi_auto",
    "context_engineering" => "NCDE",
    "security_framework" => "AART",
    "compilation_target" => "high_performance_native"
)

"""
    enhanced_pre_tool_hook(tool_name::String, tool_args::Dict) -> Dict
    
    Enhances tool usage with Context Engineering v7.0 patterns.
    Consolidates functionality from:
    - schema_uplift_hook.sh
    - tool_use_pre_hook.sh
    - Various enhancement scripts
"""
function enhanced_pre_tool_hook(tool_name::String, tool_args::Dict)::Dict
    enhanced_args = copy(tool_args)
    
    # Apply Context v7.0 enhancements
    if ContextV7Activation.GLOBAL_STATE.activated
        # Add context metadata
        enhanced_args["context_v7"] = Dict(
            "active" => true,
            "resonance" => get(ContextV7Activation.GLOBAL_STATE.resonance_field, "coefficient", 0.0),
            "knowledge_nodes" => length(get(ContextV7Activation.GLOBAL_STATE.knowledge_graph, "nodes", [])),
            "security_creativity_balance" => get(ContextV7Activation.GLOBAL_STATE.resonance_field, "security_creativity_balance", 0.5)
        )
    end
    
    # Tool-specific enhancements (preserving old hook logic)
    if tool_name in ["Write", "Edit", "MultiEdit", "Task"]
        # Schema uplifting (from schema_uplift_hook.sh)
        enhanced_args["enhanced_context"] = Dict(
            "schema_framework" => "schemantics",
            "optimization_level" => "data_science_specifications",
            "language_priorities" => SCHEMA_PATTERNS["language_priorities"],
            "performance_mode" => SCHEMA_PATTERNS["performance_mode"],
            "autonomous_level" => SCHEMA_PATTERNS["autonomous_level"],
            "context_engineering" => "NCDE_v7",
            "security_framework" => SCHEMA_PATTERNS["security_framework"],
            "compilation_target" => SCHEMA_PATTERNS["compilation_target"]
        )
        
        # Add schema hint
        enhanced_args["schema_hint"] = """
        Apply Context Engineering v7.0 with:
        - Schemantics high-performance patterns
        - Concurrent execution where applicable
        - Compile-time validation
        - Julia for computational tasks
        - Rust for systems programming
        - TypeScript for web interfaces
        - Elixir for distributed systems
        - Field resonance optimization
        - Australian compliance patterns
        """
        
        # Quality requirements
        enhanced_args["quality_requirements"] = [
            "type_safety",
            "performance_optimization",
            "schema_compliance",
            "concurrent_execution",
            "memory_efficiency",
            "context_v7_compliance"
        ]
        
        # Architectural patterns
        enhanced_args["architectural_patterns"] = [
            "schema_stacked_workflows",
            "concurrent_subagent_orchestration",
            "autonomous_business_operations",
            "field_resonance_patterns",
            "australian_data_engineering"
        ]
        
    elseif tool_name == "Bash"
        # Enhance bash commands with performance monitoring
        enhanced_args["performance_context"] = Dict(
            "enable_monitoring" => true,
            "timeout_optimization" => true,
            "concurrent_capable" => true,
            "julia_preferred" => true
        )
        
        # Add performance hint
        if haskey(tool_args, "command")
            command = tool_args["command"]
            if contains(command, "python")
                enhanced_args["performance_hint"] = "Consider using Julia for 10-100x performance improvement"
            elseif !contains(command, "&") && !contains(command, "xargs")
                enhanced_args["performance_hint"] = "Consider parallel execution with & or xargs -P for CPU-intensive operations"
            end
        end
        
    elseif tool_name in ["WebFetch", "WebSearch"]
        # Web enhancement (from web_enhancer.sh logic)
        if haskey(tool_args, "query") || haskey(tool_args, "url")
            query_or_url = get(tool_args, "query", get(tool_args, "url", ""))
            
            # Add context-aware domains
            if contains(query_or_url, "julia")
                enhanced_args["allowed_domains"] = get(enhanced_args, "allowed_domains", String[])
                append!(enhanced_args["allowed_domains"], ["julialang.org", "discourse.julialang.org", "juliahub.com"])
            end
            
            if contains(query_or_url, "context") || contains(query_or_url, "engineering")
                enhanced_args["search_context"] = "context_engineering_v7"
            end
        end
    end
    
    # Add universal enhancements
    enhanced_args["timestamp"] = now()
    enhanced_args["hook_version"] = "unified_v7.0"
    
    return enhanced_args
end

"""
    enhanced_post_tool_hook(tool_name::String, tool_output::String, execution_time_ms::Number, success::Bool) -> Dict
    
    Processes tool output with Context Engineering v7.0 analysis.
    Consolidates functionality from:
    - tool_use_post_hook.sh
    - business_opportunity_detector_julia.sh
    - session analytics
"""
function enhanced_post_tool_hook(
    tool_name::String, 
    tool_output::String, 
    execution_time_ms::Number, 
    success::Bool
)::Dict
    
    result = Dict{String,Any}(
        "tool_name" => tool_name,
        "success" => success,
        "execution_time_ms" => execution_time_ms,
        "timestamp" => now()
    )
    
    # Update knowledge graph if context is active
    if ContextV7Activation.GLOBAL_STATE.activated
        update_knowledge_from_output(tool_name, tool_output, success)
        result["knowledge_updated"] = true
    end
    
    # Business opportunity detection (from business_opportunity_detector_julia.sh)
    opportunities = detect_business_opportunities(tool_name, tool_output)
    if !isempty(opportunities)
        result["business_opportunities"] = opportunities
        
        # Log opportunities
        for opp in opportunities
            log_business_opportunity(opp)
        end
    end
    
    # Pattern detection for future improvements
    patterns = detect_execution_patterns(tool_name, tool_output, execution_time_ms)
    if !isempty(patterns)
        result["patterns_detected"] = patterns
    end
    
    # Performance analysis
    if execution_time_ms > 1000  # More than 1 second
        result["performance_warning"] = "Consider optimization - execution took $(execution_time_ms)ms"
        
        if tool_name == "Bash" && contains(tool_output, "python")
            result["optimization_suggestion"] = "Consider using Julia for better performance"
        end
    end
    
    # Log tool usage
    log_tool_usage(tool_name, tool_output, execution_time_ms, success)
    
    return result
end

"""
    detect_business_opportunities(tool_name::String, output::String) -> Vector{Dict}
    
    Detects business opportunities from tool output patterns.
    Preserves logic from business_opportunity_detector_julia.sh
"""
function detect_business_opportunities(tool_name::String, output::String)::Vector{Dict}
    opportunities = Dict[]
    
    # Check tool-specific patterns
    if haskey(BUSINESS_PATTERNS, tool_name)
        for (pattern, opp_type, confidence) in BUSINESS_PATTERNS[tool_name]
            if occursin(pattern, output)
                push!(opportunities, Dict(
                    "type" => opp_type,
                    "confidence" => confidence,
                    "tool" => tool_name,
                    "pattern_matched" => string(pattern),
                    "timestamp" => now(),
                    "recommended_actions" => get_recommended_actions(opp_type)
                ))
            end
        end
    end
    
    # Universal patterns
    if occursin(r"error|exception|failed"i, output) && !occursin(r"no error|success"i, output)
        push!(opportunities, Dict(
            "type" => "error_resolution_opportunity",
            "confidence" => 0.80,
            "tool" => tool_name,
            "pattern_matched" => "error_detection",
            "timestamp" => now(),
            "recommended_actions" => ["investigate_error", "create_fix", "add_error_handling"]
        ))
    end
    
    return opportunities
end

"""
    get_recommended_actions(opportunity_type::String) -> Vector{String}
    
    Returns recommended actions for a business opportunity type.
"""
function get_recommended_actions(opportunity_type::String)::Vector{String}
    actions_map = Dict(
        "code_completion_opportunity" => ["documentation", "testing", "announcement"],
        "deployment_opportunity" => ["customer_notification", "performance_monitoring", "rollback_plan"],
        "research_content_opportunity" => ["content_creation", "competitive_analysis", "market_report"],
        "testing_opportunity" => ["test_coverage_analysis", "ci_integration", "test_documentation"],
        "technical_debt_opportunity" => ["refactoring_plan", "debt_documentation", "prioritization"],
        "error_resolution_opportunity" => ["root_cause_analysis", "fix_implementation", "prevention_plan"],
        "optimization_opportunity" => ["performance_profiling", "optimization_implementation", "benchmark_comparison"]
    )
    
    return get(actions_map, opportunity_type, ["analyze", "plan", "execute"])
end

"""
    detect_execution_patterns(tool_name::String, output::String, execution_time_ms::Number) -> Vector{String}
    
    Detects patterns in tool execution for learning and optimization.
"""
function detect_execution_patterns(tool_name::String, output::String, execution_time_ms::Number)::Vector{String}
    patterns = String[]
    
    # Performance patterns
    if execution_time_ms < 100
        push!(patterns, "fast_execution")
    elseif execution_time_ms > 5000
        push!(patterns, "slow_execution")
    end
    
    # Output patterns
    if length(output) > 10000
        push!(patterns, "large_output")
    elseif length(output) < 100
        push!(patterns, "minimal_output")
    end
    
    # Language patterns
    if occursin(r"julia|\.jl"i, output)
        push!(patterns, "julia_context")
    end
    if occursin(r"python|\.py"i, output)
        push!(patterns, "python_context")
    end
    if occursin(r"rust|\.rs"i, output)
        push!(patterns, "rust_context")
    end
    
    # Context Engineering patterns
    if occursin(r"context|engineering|v7|NCDE|NOCODEv2"i, output)
        push!(patterns, "context_engineering_related")
    end
    
    return patterns
end

"""
    update_knowledge_from_output(tool_name::String, output::String, success::Bool)
    
    Updates the knowledge graph based on tool output.
"""
function update_knowledge_from_output(tool_name::String, output::String, success::Bool)
    if !ContextV7Activation.GLOBAL_STATE.activated || isnothing(ContextV7Activation.GLOBAL_STATE.knowledge_graph)
        return
    end
    
    # Update knowledge graph
    kg = ContextV7Activation.GLOBAL_STATE.knowledge_graph
    
    # Track tool usage patterns
    if !haskey(kg, "tool_usage")
        kg["tool_usage"] = Dict()
    end
    
    tool_stats = get!(kg["tool_usage"], tool_name, Dict(
        "count" => 0,
        "success_count" => 0,
        "total_time_ms" => 0.0,
        "last_used" => nothing
    ))
    
    tool_stats["count"] += 1
    if success
        tool_stats["success_count"] += 1
    end
    tool_stats["last_used"] = now()
    
    # Extract and store patterns
    if tool_name in ["Write", "Edit", "MultiEdit"]
        # Track code modifications
        if occursin(r"function|module|struct"i, output)
            if !haskey(kg, "code_patterns")
                kg["code_patterns"] = String[]
            end
            push!(kg["code_patterns"], "$(tool_name)_$(now())")
        end
    end
end

"""
    log_tool_usage(tool_name::String, output::String, execution_time_ms::Number, success::Bool)
    
    Logs tool usage for analytics and learning.
"""
function log_tool_usage(tool_name::String, output::String, execution_time_ms::Number, success::Bool)
    log_dir = joinpath(@__DIR__, "logs")
    mkpath(log_dir)
    
    log_entry = Dict(
        "timestamp" => now(),
        "tool_name" => tool_name,
        "execution_time_ms" => execution_time_ms,
        "success" => success,
        "output_length" => length(output),
        "output_preview" => first(output, min(200, length(output))),
        "context_v7_active" => false  # Will be set by parent module
    )
    
    # Append to log file
    log_file = joinpath(log_dir, "unified_tool_usage.jsonl")
    open(log_file, "a") do io
        println(io, JSON3.write(log_entry))
    end
end

"""
    log_business_opportunity(opportunity::Dict)
    
    Logs detected business opportunities.
"""
function log_business_opportunity(opportunity::Dict)
    log_dir = joinpath(@__DIR__, "logs")
    mkpath(log_dir)
    
    log_file = joinpath(log_dir, "business_opportunities.jsonl")
    open(log_file, "a") do io
        println(io, JSON3.write(opportunity))
    end
end

"""
    process_session_analytics(session_data::Dict) -> Dict
    
    Processes session-end analytics.
    Replaces session_analytics_julia.sh functionality.
"""
function process_session_analytics(session_data::Dict)::Dict
    duration_ms = get(session_data, "session_duration_ms", 0)
    tools_used = get(session_data, "tools_used", String[])
    
    # Calculate productivity metrics
    productivity_score = duration_ms > 0 && length(tools_used) > 0 ? 
        duration_ms / (1000 * length(tools_used)) : 0.0  # Seconds per tool
    
    # Analyze tool usage patterns
    tool_frequencies = Dict{String,Int}()
    for tool in tools_used
        tool_frequencies[tool] = get(tool_frequencies, tool, 0) + 1
    end
    
    # Get most used tools
    most_used = sort(collect(tool_frequencies), by=x->x[2], rev=true)
    
    analytics = Dict(
        "timestamp" => now(),
        "duration_ms" => duration_ms,
        "tools_count" => length(tools_used),
        "unique_tools" => length(keys(tool_frequencies)),
        "productivity_score" => productivity_score,
        "most_used_tools" => first(most_used, min(5, length(most_used))),
        "context_v7_active" => false  # Will be set by parent module
    )
    
    # Add Context v7 metrics if available (will be populated by parent module)
    
    # Log session analytics
    log_dir = joinpath(@__DIR__, "logs")
    mkpath(log_dir)
    log_file = joinpath(log_dir, "session_analytics.jsonl")
    open(log_file, "a") do io
        println(io, JSON3.write(analytics))
    end
    
    # Generate daily summary if needed
    if should_generate_daily_summary()
        generate_daily_summary()
    end
    
    return analytics
end

"""
    should_generate_daily_summary() -> Bool
    
    Checks if a daily summary should be generated.
"""
function should_generate_daily_summary()::Bool
    summary_file = joinpath(@__DIR__, "data", "last_summary_date.txt")
    
    if !isfile(summary_file)
        return true
    end
    
    last_date = Date(strip(read(summary_file, String)))
    return today() > last_date
end

"""
    generate_daily_summary()
    
    Generates a daily summary of hook usage and performance.
"""
function generate_daily_summary()
    log_dir = joinpath(@__DIR__, "logs")
    data_dir = joinpath(@__DIR__, "data")
    mkpath(data_dir)
    
    # Read today's logs
    tool_usage_file = joinpath(log_dir, "unified_tool_usage.jsonl")
    opportunities_file = joinpath(log_dir, "business_opportunities.jsonl")
    sessions_file = joinpath(log_dir, "session_analytics.jsonl")
    
    summary = Dict(
        "date" => today(),
        "generated_at" => now(),
        "tool_usage_count" => 0,
        "opportunities_detected" => 0,
        "sessions_completed" => 0,
        "average_productivity" => 0.0,
        "context_v7_usage_rate" => 0.0
    )
    
    # Analyze tool usage
    if isfile(tool_usage_file)
        tool_count = 0
        v7_count = 0
        for line in eachline(tool_usage_file)
            try
                entry = JSON3.read(line, Dict)
                if Date(entry["timestamp"]) == today()
                    tool_count += 1
                    if get(entry, "context_v7_active", false)
                        v7_count += 1
                    end
                end
            catch
                continue
            end
        end
        summary["tool_usage_count"] = tool_count
        summary["context_v7_usage_rate"] = tool_count > 0 ? v7_count / tool_count : 0.0
    end
    
    # Count opportunities
    if isfile(opportunities_file)
        opp_count = 0
        for line in eachline(opportunities_file)
            try
                entry = JSON3.read(line, Dict)
                if Date(entry["timestamp"]) == today()
                    opp_count += 1
                end
            catch
                continue
            end
        end
        summary["opportunities_detected"] = opp_count
    end
    
    # Analyze sessions
    if isfile(sessions_file)
        session_count = 0
        total_productivity = 0.0
        for line in eachline(sessions_file)
            try
                entry = JSON3.read(line, Dict)
                if Date(entry["timestamp"]) == today()
                    session_count += 1
                    total_productivity += get(entry, "productivity_score", 0.0)
                end
            catch
                continue
            end
        end
        summary["sessions_completed"] = session_count
        summary["average_productivity"] = session_count > 0 ? total_productivity / session_count : 0.0
    end
    
    # Save summary
    summary_file = joinpath(data_dir, "daily_summary_$(today()).json")
    open(summary_file, "w") do io
        JSON3.write(io, summary)
    end
    
    # Update last summary date
    open(joinpath(data_dir, "last_summary_date.txt"), "w") do io
        println(io, today())
    end
    
    @info "Daily summary generated" date=today() metrics=summary
end

# Export main functions
export enhanced_pre_tool_hook, enhanced_post_tool_hook
export process_session_analytics, detect_business_opportunities
export BUSINESS_PATTERNS, SCHEMA_PATTERNS

end # module UnifiedHooks