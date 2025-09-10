#!/usr/bin/env julia
"""
    Context Engineering v7.0 Complete Activation System
    
    Unified HPC-optimized hook system for Claude Code that handles all 9 events:
    1. SessionStart - Activates Context v7.0
    2. UserPromptSubmit - Enhances prompts with slash commands
    3. PreToolUse - Adds context patterns to tools
    4. PostToolUse - Updates knowledge from execution
    5. Stop - Generates session analytics
    6. SubagentStop - Consolidates subagent results
    7. Notification - Handles errors and notifications
    8. PreCompact - Prepares for context compaction
    9. SessionEnd - Final cleanup and reporting
    
    This module consolidates all functionality with optimal performance.
    
    Author: Context Engineering v7.0 System
    Version: 7.0.0-complete
"""
module ContextV7Activation

using JSON3
using Dates
using SHA
using OrderedCollections

# Import subordinate modules
include("unified_hooks.jl")
using .UnifiedHooks

include("user_prompt_enhancer_simple.jl")
using .UserPromptEnhancerSimple

include("slash_commands.jl")
using .SlashCommands

# Export main interface
export process_hook_event, activate_context, get_global_context

# Global context state
mutable struct GlobalContextState
    activated::Bool
    knowledge_nodes::Vector{Any}
    resonance_coefficient::Float64
    active_patterns::Vector{String}
    context_schema::Dict{String, Any}
    activation_time::Union{Nothing, DateTime}
end

# Performance tracking
mutable struct PerformanceTracker
    hook_executions::Int
    cache_hits::Int
    tools_executed::Int
    total_time_ms::Float64
    prompts_enhanced::Int
end

# Initialize global state
const GLOBAL_CONTEXT = GlobalContextState(
    false,
    [],
    0.75,
    [],
    Dict{String, Any}(),
    nothing
)

const PERF_TRACKER = PerformanceTracker(0, 0, 0, 0.0, 0)

# Logging configuration
const LOG_DIR = joinpath(@__DIR__, "logs")
mkpath(LOG_DIR)

"""
    process_hook_event(event_type::String, input_data::Dict{String, Any})
    
    Main entry point for all 9 Claude Code hook events.
    Routes to appropriate handler and tracks performance.
"""
function process_hook_event(event_type::String, input_data::Dict{String, Any})
    start_time = time()
    PERF_TRACKER.hook_executions += 1
    
    # Log event
    log_event("hook_event", Dict(
        "event_type" => event_type,
        "timestamp" => now()
    ))
    
    try
        # Route to appropriate handler
        result = if event_type in ["pre_start", "activate", "session_start"]
            handle_session_start(input_data)
        elseif event_type == "user_prompt_submit"
            handle_user_prompt(input_data)
        elseif event_type == "pre_tool"
            handle_pre_tool(input_data)
        elseif event_type == "post_tool"
            handle_post_tool(input_data)
        elseif event_type == "stop"
            handle_stop(input_data)
        elseif event_type == "subagent_stop"
            handle_subagent_stop(input_data)
        elseif event_type == "notification"
            handle_notification(input_data)
        elseif event_type == "pre_compact"
            handle_pre_compact(input_data)
        elseif event_type == "session_end"
            handle_session_end(input_data)
        elseif event_type == "context_changed"
            handle_context_change(input_data)
        else
            # Unknown event - pass through
            input_data
        end
        
        # Track performance
        elapsed_ms = (time() - start_time) * 1000
        PERF_TRACKER.total_time_ms += elapsed_ms
        
        # Add performance metadata
        result["_performance_ms"] = elapsed_ms
        result["_context_active"] = GLOBAL_CONTEXT.activated
        
        return result
        
    catch e
        @warn "Error processing hook event" event_type=event_type error=e
        # Return input data on error to avoid blocking
        return input_data
    end
end

# ===== Event Handlers =====

"""
    handle_session_start(input_data::Dict{String, Any})
    
    SessionStart event - Activates Context Engineering v7.0
"""
function handle_session_start(input_data::Dict{String, Any})
    @info "🌸 Activating Context Engineering v7.0"
    
    repo_path = get(input_data, "repo_path", "/home/ubuntu/src/repos/Context-Engineering")
    
    if activate_context(repo_path)
        return Dict(
            "status" => "activated",
            "context_version" => "7.0",
            "knowledge_nodes" => length(GLOBAL_CONTEXT.knowledge_nodes),
            "resonance_coefficient" => GLOBAL_CONTEXT.resonance_coefficient,
            "patterns_loaded" => length(GLOBAL_CONTEXT.active_patterns),
            "message" => "Context Engineering v7.0 activated successfully"
        )
    else
        return Dict(
            "status" => "activation_failed",
            "error" => "Could not activate Context v7.0"
        )
    end
end

"""
    handle_user_prompt(input_data::Dict{String, Any})
    
    UserPromptSubmit event - Enhances prompts with slash commands and patterns
"""
function handle_user_prompt(input_data::Dict{String, Any})
    prompt = get(input_data, "prompt", "")
    context = get(input_data, "context", Dict())
    
    # Enhance the prompt using v7.0 patterns
    enhanced = UserPromptEnhancerSimple.enhance_user_prompt_simple(prompt, context)
    
    # Check for slash command
    if startswith(strip(prompt), "/")
        parsed = SlashCommands.parse_slash_command(prompt)
        if parsed !== nothing && !haskey(parsed, "error")
            enhanced["slash_command"] = parsed
            enhanced["agent_routing"] = SlashCommands.route_to_agent(parsed)
            enhanced["command_help"] = SlashCommands.get_command_help(parsed["command"])
        elseif haskey(parsed, "suggestions")
            # Provide command suggestions
            enhanced["command_suggestions"] = parsed["suggestions"]
            enhanced["available_commands"] = SlashCommands.get_all_commands()
        end
    else
        # Suggest relevant slash commands based on intent
        suggestions = SlashCommands.suggest_commands_for_intent(prompt)
        if !isempty(suggestions)
            enhanced["suggested_commands"] = suggestions
        end
    end
    
    # Update metrics
    PERF_TRACKER.prompts_enhanced += 1
    
    log_event("user_prompt_enhanced", Dict(
        "original_length" => length(prompt),
        "enhanced" => true,
        "slash_command" => haskey(enhanced, "slash_command")
    ))
    
    return enhanced
end

"""
    handle_pre_tool(input_data::Dict{String, Any})
    
    PreToolUse event - Adds context patterns to tool arguments
"""
function handle_pre_tool(input_data::Dict{String, Any})
    # Use the unified hooks enhanced version
    result = UnifiedHooks.enhanced_pre_tool_hook(input_data)
    
    # Add v7.0 specific enhancements
    if GLOBAL_CONTEXT.activated
        tool_name = get(input_data, "tool_name", "")
        
        # Add resonance field guidance
        result["resonance_guidance"] = Dict(
            "coefficient" => GLOBAL_CONTEXT.resonance_coefficient,
            "active_patterns" => GLOBAL_CONTEXT.active_patterns[1:min(3, end)]
        )
        
        # Tool-specific v7.0 enhancements
        if tool_name in ["Write", "Edit", "MultiEdit"]
            result["context_patterns"] = Dict(
                "apply_v7_patterns" => true,
                "use_julia_for_hpc" => true,
                "maintain_field_resonance" => true
            )
        end
    end
    
    PERF_TRACKER.tools_executed += 1
    
    return result
end

"""
    handle_post_tool(input_data::Dict{String, Any})
    
    PostToolUse event - Updates knowledge from tool execution
"""
function handle_post_tool(input_data::Dict{String, Any})
    # Use unified hooks for business detection
    result = UnifiedHooks.enhanced_post_tool_hook(input_data)
    
    # Update knowledge graph
    if GLOBAL_CONTEXT.activated
        tool_name = get(input_data, "tool_name", "")
        tool_output = get(input_data, "output", "")
        
        # Extract patterns from output
        patterns = extract_patterns_from_output(tool_output)
        for pattern in patterns
            if !(pattern in GLOBAL_CONTEXT.active_patterns)
                push!(GLOBAL_CONTEXT.active_patterns, pattern)
            end
        end
        
        # Update knowledge nodes
        if tool_name in ["Read", "Glob", "Grep"]
            # File discovery updates knowledge
            push!(GLOBAL_CONTEXT.knowledge_nodes, Dict(
                "type" => "file_discovery",
                "tool" => tool_name,
                "timestamp" => now()
            ))
        end
        
        result["patterns_extracted"] = length(patterns)
        result["knowledge_updated"] => true
    end
    
    return result
end

"""
    handle_stop(input_data::Dict{String, Any})
    
    Stop event - Main conversation stop, generates analytics
"""
function handle_stop(input_data::Dict{String, Any})
    analytics = Dict(
        "status" => "stop",
        "timestamp" => now(),
        "session_metrics" => Dict(
            "tools_executed" => PERF_TRACKER.tools_executed,
            "prompts_enhanced" => PERF_TRACKER.prompts_enhanced,
            "cache_hits" => PERF_TRACKER.cache_hits,
            "hook_executions" => PERF_TRACKER.hook_executions,
            "total_time_ms" => PERF_TRACKER.total_time_ms,
            "avg_time_ms" => PERF_TRACKER.hook_executions > 0 ? 
                PERF_TRACKER.total_time_ms / PERF_TRACKER.hook_executions : 0
        ),
        "context_state" => Dict(
            "activated" => GLOBAL_CONTEXT.activated,
            "knowledge_nodes" => length(GLOBAL_CONTEXT.knowledge_nodes),
            "active_patterns" => length(GLOBAL_CONTEXT.active_patterns),
            "resonance" => GLOBAL_CONTEXT.resonance_coefficient
        )
    )
    
    # Generate productivity score
    productivity_score = calculate_productivity_score()
    analytics["productivity_score"] = productivity_score
    
    # Save session report
    save_session_report(analytics)
    
    log_event("session_stop", analytics)
    
    return merge(input_data, analytics)
end

"""
    handle_subagent_stop(input_data::Dict{String, Any})
    
    SubagentStop event - Consolidates results from subagent
"""
function handle_subagent_stop(input_data::Dict{String, Any})
    subagent_type = get(input_data, "subagent_type", "unknown")
    results = get(input_data, "results", Dict())
    
    consolidation = Dict(
        "status" => "subagent_complete",
        "subagent" => subagent_type,
        "timestamp" => now(),
        "consolidated" => true
    )
    
    # Extract patterns and insights from subagent work
    if !isempty(results)
        patterns = extract_patterns_from_output(JSON3.write(results))
        insights = analyze_subagent_results(subagent_type, results)
        
        # Update global knowledge
        for pattern in patterns
            if !(pattern in GLOBAL_CONTEXT.active_patterns)
                push!(GLOBAL_CONTEXT.active_patterns, pattern)
            end
        end
        
        consolidation["patterns_extracted"] = patterns
        consolidation["insights"] = insights
        consolidation["knowledge_contribution"] = length(patterns)
    end
    
    log_event("subagent_consolidation", consolidation)
    
    return merge(input_data, consolidation)
end

"""
    handle_notification(input_data::Dict{String, Any})
    
    Notification event - Handles errors and system notifications
"""
function handle_notification(input_data::Dict{String, Any})
    notification_type = get(input_data, "type", "info")
    message = get(input_data, "message", "")
    
    response = Dict(
        "status" => "notification_handled",
        "type" => notification_type,
        "timestamp" => now()
    )
    
    # Handle different notification types
    if notification_type == "error"
        error_analysis = analyze_error(message)
        response["error_analysis"] = error_analysis
        response["recovery_suggestions"] = suggest_error_recovery(error_analysis)
        response["severity"] = assess_error_severity(message)
    elseif notification_type == "warning"
        response["warning_handled"] = true
        response["action_required"] = determine_warning_action(message)
    elseif notification_type == "info"
        response["info_logged"] = true
    end
    
    log_event("notification", response)
    
    return merge(input_data, response)
end

"""
    handle_pre_compact(input_data::Dict{String, Any})
    
    PreCompact event - Prepares for context compaction
"""
function handle_pre_compact(input_data::Dict{String, Any})
    # Identify critical context to preserve
    critical_context = Dict(
        "status" => "pre_compact",
        "timestamp" => now(),
        "preserve" => Dict(
            "knowledge_nodes" => filter(is_critical_node, GLOBAL_CONTEXT.knowledge_nodes),
            "resonance_coefficient" => GLOBAL_CONTEXT.resonance_coefficient,
            "active_patterns" => GLOBAL_CONTEXT.active_patterns[1:min(10, end)],
            "context_version" => "7.0"
        ),
        "statistics" => Dict(
            "total_nodes" => length(GLOBAL_CONTEXT.knowledge_nodes),
            "preserved_nodes" => count(is_critical_node, GLOBAL_CONTEXT.knowledge_nodes),
            "total_patterns" => length(GLOBAL_CONTEXT.active_patterns),
            "preserved_patterns" => min(10, length(GLOBAL_CONTEXT.active_patterns))
        )
    )
    
    # Prepare compaction summary
    critical_context["compaction_summary"] = generate_compaction_summary()
    
    log_event("pre_compact", critical_context)
    
    return merge(input_data, critical_context)
end

"""
    handle_session_end(input_data::Dict{String, Any})
    
    SessionEnd event - Final cleanup and reporting
"""
function handle_session_end(input_data::Dict{String, Any})
    # Generate comprehensive session report
    final_report = Dict(
        "status" => "session_complete",
        "timestamp" => now(),
        "duration" => GLOBAL_CONTEXT.activation_time !== nothing ? 
            Dates.value(now() - GLOBAL_CONTEXT.activation_time) / 1000 : 0,
        "final_metrics" => Dict(
            "total_hooks" => PERF_TRACKER.hook_executions,
            "total_tools" => PERF_TRACKER.tools_executed,
            "prompts_enhanced" => PERF_TRACKER.prompts_enhanced,
            "cache_efficiency" => PERF_TRACKER.cache_hits,
            "avg_hook_time_ms" => PERF_TRACKER.hook_executions > 0 ?
                PERF_TRACKER.total_time_ms / PERF_TRACKER.hook_executions : 0
        ),
        "knowledge_growth" => Dict(
            "nodes_created" => length(GLOBAL_CONTEXT.knowledge_nodes),
            "patterns_discovered" => length(GLOBAL_CONTEXT.active_patterns),
            "final_resonance" => GLOBAL_CONTEXT.resonance_coefficient
        ),
        "productivity_score" => calculate_productivity_score(),
        "recommendations" => generate_session_recommendations()
    )
    
    # Save final report
    save_session_report(final_report)
    
    # Reset for next session
    reset_session_state()
    
    log_event("session_end", final_report)
    
    return merge(input_data, final_report)
end

"""
    handle_context_change(input_data::Dict{String, Any})
    
    ContextChanged event - Adjusts resonance field for new context
"""
function handle_context_change(input_data::Dict{String, Any})
    new_context = get(input_data, "new_context", "")
    old_context = get(input_data, "old_context", "")
    
    # Adjust resonance based on context type
    if contains(lowercase(new_context), "security") || contains(lowercase(new_context), "compliance")
        # Increase security focus
        GLOBAL_CONTEXT.resonance_coefficient = max(0.3, GLOBAL_CONTEXT.resonance_coefficient * 0.8)
    elseif contains(lowercase(new_context), "creative") || contains(lowercase(new_context), "innovative")
        # Increase creativity focus
        GLOBAL_CONTEXT.resonance_coefficient = min(0.95, GLOBAL_CONTEXT.resonance_coefficient * 1.2)
    end
    
    response = Dict(
        "status" => "context_adjusted",
        "old_context" => old_context,
        "new_context" => new_context,
        "resonance_adjusted" => true,
        "new_resonance" => GLOBAL_CONTEXT.resonance_coefficient,
        "timestamp" => now()
    )
    
    log_event("context_change", response)
    
    return merge(input_data, response)
end

# ===== Core Functions =====

"""
    activate_context(repo_path::String) -> Bool
    
    Activates Context Engineering v7.0 for the repository
"""
function activate_context(repo_path::String)
    try
        # Load context schema
        schema_path = joinpath(repo_path, "NOCODEv2", "context_v7.0.json")
        if isfile(schema_path)
            GLOBAL_CONTEXT.context_schema = JSON3.read(read(schema_path, String), Dict{String, Any})
        else
            # Use default schema
            GLOBAL_CONTEXT.context_schema = Dict(
                "version" => "7.0",
                "patterns" => [],
                "field" => Dict("resonance" => 0.75)
            )
        end
        
        # Initialize knowledge nodes
        GLOBAL_CONTEXT.knowledge_nodes = []
        
        # Set resonance from schema
        GLOBAL_CONTEXT.resonance_coefficient = get(
            get(GLOBAL_CONTEXT.context_schema, "field", Dict()), 
            "resonance", 
            0.75
        )
        
        # Load active patterns
        patterns_dir = joinpath(repo_path, "20_templates")
        if isdir(patterns_dir)
            for file in readdir(patterns_dir)
                if endswith(file, ".md") || endswith(file, ".json")
                    push!(GLOBAL_CONTEXT.active_patterns, splitext(file)[1])
                end
            end
        end
        
        # Mark as activated
        GLOBAL_CONTEXT.activated = true
        GLOBAL_CONTEXT.activation_time = now()
        
        @info "✅ Context v7.0 activated" patterns=length(GLOBAL_CONTEXT.active_patterns) resonance=GLOBAL_CONTEXT.resonance_coefficient
        
        return true
        
    catch e
        @error "Failed to activate context" error=e
        return false
    end
end

"""
    get_global_context() -> GlobalContextState
    
    Returns the current global context state
"""
function get_global_context()
    return GLOBAL_CONTEXT
end

# ===== Helper Functions =====

function extract_patterns_from_output(output::String)
    patterns = String[]
    
    # Look for common patterns
    if occursin(r"function|module|struct", output)
        push!(patterns, "julia_code_structure")
    end
    if occursin(r"test|Test|@test", output)
        push!(patterns, "testing_pattern")
    end
    if occursin(r"async|@async|@distributed", output)
        push!(patterns, "parallel_computing")
    end
    if occursin(r"context|Context|v7", output)
        push!(patterns, "context_engineering")
    end
    if occursin(r"slash|command|/\w+", output)
        push!(patterns, "slash_command_usage")
    end
    
    return unique(patterns)
end

function analyze_subagent_results(subagent_type::String, results::Dict)
    insights = Dict{String, Any}()
    
    if subagent_type == "v0-ui-generator"
        insights["ui_components"] = get(results, "components_created", 0)
        insights["responsive"] = get(results, "responsive_design", false)
    elseif subagent_type == "devin-software-engineer"
        insights["code_quality"] = get(results, "quality_score", 0)
        insights["tests_written"] = get(results, "tests_created", 0)
    elseif subagent_type == "corki-coverage-guardian"
        insights["coverage_achieved"] = get(results, "coverage_percentage", 0)
        insights["tests_added"] = get(results, "new_tests", 0)
    end
    
    return insights
end

function analyze_error(message::String)
    error_type = if occursin("syntax", lowercase(message))
        "syntax_error"
    elseif occursin("permission", lowercase(message))
        "permission_error"
    elseif occursin("timeout", lowercase(message))
        "timeout_error"
    elseif occursin("not found", lowercase(message))
        "not_found_error"
    else
        "unknown_error"
    end
    
    return Dict(
        "type" => error_type,
        "message" => message,
        "timestamp" => now()
    )
end

function suggest_error_recovery(error_analysis::Dict)
    suggestions = String[]
    error_type = get(error_analysis, "type", "unknown")
    
    if error_type == "syntax_error"
        push!(suggestions, "Check syntax and formatting")
        push!(suggestions, "Verify language version compatibility")
    elseif error_type == "permission_error"
        push!(suggestions, "Check file permissions")
        push!(suggestions, "Verify user access rights")
    elseif error_type == "timeout_error"
        push!(suggestions, "Increase timeout duration")
        push!(suggestions, "Optimize operation performance")
    elseif error_type == "not_found_error"
        push!(suggestions, "Verify file/resource paths")
        push!(suggestions, "Check if resource exists")
    end
    
    return suggestions
end

function assess_error_severity(message::String)
    if occursin(r"fatal|critical", lowercase(message))
        return "critical"
    elseif occursin(r"error", lowercase(message))
        return "high"
    elseif occursin(r"warning", lowercase(message))
        return "medium"
    else
        return "low"
    end
end

function determine_warning_action(message::String)
    if occursin("deprecated", lowercase(message))
        return "Update to newer API/method"
    elseif occursin("performance", lowercase(message))
        return "Consider optimization"
    else
        return "Monitor situation"
    end
end

function is_critical_node(node::Any)
    # Determine if a knowledge node should be preserved during compaction
    if isa(node, Dict)
        node_type = get(node, "type", "")
        return node_type in ["core_pattern", "schema", "critical_path"]
    end
    return false
end

function generate_compaction_summary()
    return Dict(
        "total_items" => length(GLOBAL_CONTEXT.knowledge_nodes) + length(GLOBAL_CONTEXT.active_patterns),
        "preserved_items" => count(is_critical_node, GLOBAL_CONTEXT.knowledge_nodes) + min(10, length(GLOBAL_CONTEXT.active_patterns)),
        "compression_ratio" => 1.0 - (count(is_critical_node, GLOBAL_CONTEXT.knowledge_nodes) / max(1, length(GLOBAL_CONTEXT.knowledge_nodes)))
    )
end

function calculate_productivity_score()
    # Calculate a productivity score based on session metrics
    base_score = 50.0
    
    # Tool usage efficiency
    if PERF_TRACKER.tools_executed > 0
        tool_efficiency = min(100, PERF_TRACKER.tools_executed * 5)
        base_score += tool_efficiency * 0.2
    end
    
    # Prompt enhancement effectiveness
    if PERF_TRACKER.prompts_enhanced > 0
        prompt_effectiveness = min(100, PERF_TRACKER.prompts_enhanced * 10)
        base_score += prompt_effectiveness * 0.2
    end
    
    # Cache efficiency
    if PERF_TRACKER.cache_hits > 0
        cache_efficiency = (PERF_TRACKER.cache_hits / max(1, PERF_TRACKER.hook_executions)) * 100
        base_score += cache_efficiency * 0.1
    end
    
    return round(min(100, base_score), digits=1)
end

function generate_session_recommendations()
    recommendations = String[]
    
    if PERF_TRACKER.cache_hits < PERF_TRACKER.hook_executions * 0.3
        push!(recommendations, "Consider enabling more aggressive caching")
    end
    
    if PERF_TRACKER.prompts_enhanced < 5
        push!(recommendations, "Try using slash commands for better results")
    end
    
    if length(GLOBAL_CONTEXT.active_patterns) < 5
        push!(recommendations, "Explore more repository patterns for enhanced context")
    end
    
    if GLOBAL_CONTEXT.resonance_coefficient < 0.5
        push!(recommendations, "Resonance is low - consider creative exploration")
    elseif GLOBAL_CONTEXT.resonance_coefficient > 0.9
        push!(recommendations, "High resonance - ensure security considerations")
    end
    
    return recommendations
end

function save_session_report(report::Dict)
    report_file = joinpath(LOG_DIR, "session_$(Dates.format(now(), "yyyymmdd_HHMMSS")).json")
    try
        open(report_file, "w") do io
            JSON3.write(io, report)
        end
    catch e
        @warn "Could not save session report" error=e
    end
end

function reset_session_state()
    # Reset performance trackers for next session
    PERF_TRACKER.hook_executions = 0
    PERF_TRACKER.cache_hits = 0
    PERF_TRACKER.tools_executed = 0
    PERF_TRACKER.total_time_ms = 0.0
    PERF_TRACKER.prompts_enhanced = 0
end

function log_event(event_type::String, data::Dict)
    log_entry = Dict(
        "timestamp" => now(),
        "event" => event_type,
        "data" => data
    )
    
    log_file = joinpath(LOG_DIR, "context_v7_events.jsonl")
    try
        open(log_file, "a") do io
            println(io, JSON3.write(log_entry))
        end
    catch e
        @warn "Could not write to log file" error=e
    end
end

end # module