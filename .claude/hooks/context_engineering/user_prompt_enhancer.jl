#!/usr/bin/env julia
"""
    User Prompt Enhancer Module
    
    Transforms user prompts into optimal structure for Context Engineering v7.0
    Automatically detects and suggests slash commands from .claude/commands/
    Applies field resonance patterns and knowledge graph insights
    
    This module replaces schemantics_uplift.sh with enhanced Julia performance
    and deep integration with Context Engineering patterns.
"""
module UserPromptEnhancer

using JSON3
using Dates

# Note: This module is included by ContextV7Activation, not the other way around
# to avoid circular dependencies

# Slash command registry
const SLASH_COMMANDS = Dict{String,Dict{String,Any}}(
    "alignment" => Dict(
        "file" => "alignment.agent.md",
        "keywords" => ["safety", "alignment", "red-team", "security", "audit", "risk"],
        "description" => "AI safety/alignment evaluation and red-teaming"
    ),
    "cli" => Dict(
        "file" => "cli.agent.md",
        "keywords" => ["command", "terminal", "bash", "shell", "script"],
        "description" => "Command-line interface operations"
    ),
    "comms" => Dict(
        "file" => "comms.agent.md",
        "keywords" => ["communication", "message", "email", "notification", "announce"],
        "description" => "Communication and messaging"
    ),
    "data" => Dict(
        "file" => "data.agent.md",
        "keywords" => ["data", "database", "sql", "analytics", "etl", "pipeline"],
        "description" => "Data engineering and analytics"
    ),
    "deploy" => Dict(
        "file" => "deploy.agent.md",
        "keywords" => ["deploy", "release", "production", "ci/cd", "docker", "kubernetes"],
        "description" => "Deployment and release management"
    ),
    "diligence" => Dict(
        "file" => "diligence.agent.md",
        "keywords" => ["review", "audit", "check", "verify", "validate", "diligence"],
        "description" => "Due diligence and verification"
    ),
    "doc" => Dict(
        "file" => "doc.agent.md",
        "keywords" => ["document", "documentation", "readme", "guide", "manual", "help"],
        "description" => "Documentation creation and management"
    ),
    "legal" => Dict(
        "file" => "legal.agent.md",
        "keywords" => ["legal", "contract", "license", "compliance", "regulation", "terms"],
        "description" => "Legal and compliance matters"
    ),
    "lit" => Dict(
        "file" => "lit.agent.md",
        "keywords" => ["literature", "research", "paper", "article", "publication", "review"],
        "description" => "Literature review and research"
    ),
    "marketing" => Dict(
        "file" => "marketing.agent.md",
        "keywords" => ["marketing", "promotion", "campaign", "brand", "content", "social"],
        "description" => "Marketing and promotion"
    ),
    "meta" => Dict(
        "file" => "meta.agent.md",
        "keywords" => ["meta", "abstract", "framework", "architecture", "design", "pattern"],
        "description" => "Meta-level analysis and design"
    ),
    "monitor" => Dict(
        "file" => "monitor.agent.md",
        "keywords" => ["monitor", "track", "observe", "metrics", "logs", "alert"],
        "description" => "Monitoring and observability"
    ),
    "optimize" => Dict(
        "file" => "optimize.agent.md",
        "keywords" => ["optimize", "performance", "improve", "enhance", "speed", "efficiency"],
        "description" => "Optimization and performance"
    ),
    "research" => Dict(
        "file" => "research.agent.md",
        "keywords" => ["research", "investigate", "analyze", "study", "explore", "discover"],
        "description" => "Research and investigation"
    ),
    "security" => Dict(
        "file" => "security.agent.md",
        "keywords" => ["security", "vulnerability", "threat", "attack", "protect", "secure"],
        "description" => "Security analysis and protection"
    ),
    "test" => Dict(
        "file" => "test.agent.md",
        "keywords" => ["test", "testing", "qa", "quality", "bug", "debug", "verify"],
        "description" => "Testing and quality assurance"
    )
)

"""
    enhance_user_prompt(prompt::String, context::Dict) -> Dict
    
    Transforms a user prompt into optimal structure with:
    - Slash command detection and suggestion
    - Context v7.0 enhancements
    - Field resonance patterns
    - Knowledge graph insights
"""
function enhance_user_prompt(prompt::String, context::Dict)::Dict
    start_time = time()
    
    # Initialize response
    response = Dict{String,Any}(
        "original_prompt" => prompt,
        "timestamp" => now()
    )
    
    # Check if prompt already has a slash command
    has_slash_command, command, query = parse_slash_command(prompt)
    
    if has_slash_command
        # Enhance existing slash command
        response["detected_command"] = command
        response["enhanced_prompt"] = enhance_slash_command(command, query)
    else
        # Detect best slash command for prompt
        suggested_command = suggest_slash_command(prompt)
        response["suggested_command"] = suggested_command
        response["confidence"] = suggested_command["confidence"]
        
        # Structure as optimal slash command
        if suggested_command["confidence"] > 0.5
            response["enhanced_prompt"] = structure_as_slash_command(
                suggested_command["command"],
                prompt
            )
        else
            # No clear command match, enhance generically
            response["enhanced_prompt"] = enhance_generic_prompt(prompt)
        end
    end
    
    # Add Context v7.0 enhancements
    if ContextV7Activation.GLOBAL_STATE.activated
        response["context_v7"] = add_context_v7_enhancements(response["enhanced_prompt"])
    end
    
    # Add field resonance guidance
    response["field_resonance"] = get_field_resonance_guidance()
    
    # Add relevant knowledge nodes
    response["knowledge_nodes"] = find_relevant_knowledge(prompt)
    
    # Calculate processing time
    response["processing_time_ms"] = (time() - start_time) * 1000
    
    return response
end

"""
    parse_slash_command(prompt::String) -> (Bool, String, String)
    
    Checks if prompt contains a slash command and extracts it.
"""
function parse_slash_command(prompt::String)::Tuple{Bool,String,String}
    # Check for slash command pattern
    slash_pattern = r"^/(\w+)\s+(.*)"
    match_result = match(slash_pattern, prompt)
    
    if !isnothing(match_result)
        command = match_result.captures[1]
        query = match_result.captures[2]
        return (true, command, query)
    end
    
    # Check for inline slash command
    inline_pattern = r"/(\w+)\s+Q=\"([^\"]+)\""
    inline_match = match(inline_pattern, prompt)
    
    if !isnothing(inline_match)
        command = inline_match.captures[1]
        query = inline_match.captures[2]
        return (true, command, query)
    end
    
    return (false, "", "")
end

"""
    suggest_slash_command(prompt::String) -> Dict
    
    Analyzes prompt and suggests the best matching slash command.
"""
function suggest_slash_command(prompt::String)::Dict
    prompt_lower = lowercase(prompt)
    scores = Dict{String,Float64}()
    
    # Score each command based on keyword matches
    for (command, info) in SLASH_COMMANDS
        score = 0.0
        keyword_count = 0
        
        for keyword in info["keywords"]
            if contains(prompt_lower, keyword)
                score += 1.0
                keyword_count += 1
            end
        end
        
        # Normalize score by number of keywords
        if length(info["keywords"]) > 0
            scores[command] = score / length(info["keywords"])
        end
        
        # Boost score for exact command name match
        if contains(prompt_lower, command)
            scores[command] = get(scores, command, 0.0) + 0.5
        end
    end
    
    # Find best match
    if isempty(scores)
        return Dict(
            "command" => "research",  # Default to research for unknown
            "confidence" => 0.3,
            "reason" => "No specific pattern detected, defaulting to research"
        )
    end
    
    best_command = ""
    best_score = 0.0
    for (cmd, score) in scores
        if score > best_score
            best_score = score
            best_command = cmd
        end
    end
    
    return Dict(
        "command" => best_command,
        "confidence" => min(1.0, best_score),
        "reason" => "Matched keywords: $(join(SLASH_COMMANDS[best_command]["keywords"], ", "))"
    )
end

"""
    structure_as_slash_command(command::String, prompt::String) -> String
    
    Structures a prompt as an optimal slash command format.
"""
function structure_as_slash_command(command::String, prompt::String)::String
    # Extract key parameters based on command type
    params = extract_command_parameters(command, prompt)
    
    # Build structured command
    structured = "/$command Q=\"$prompt\""
    
    # Add command-specific parameters
    if command == "alignment"
        structured *= " model=\"claude-3\" risk_level=\"comprehensive\""
    elseif command == "data"
        structured *= " format=\"optimized\" compliance=\"australian\""
    elseif command == "security"
        structured *= " depth=\"comprehensive\" framework=\"RAMP\""
    elseif command == "test"
        structured *= " coverage=\"full\" framework=\"julia_test\""
    elseif command == "deploy"
        structured *= " environment=\"production\" safety_check=\"enabled\""
    end
    
    # Add universal Context v7.0 parameters
    if ContextV7Activation.GLOBAL_STATE.activated
        resonance = get(ContextV7Activation.GLOBAL_STATE.resonance_field, "coefficient", 0.5)
        structured *= " context_v7=\"active\" resonance=\"$resonance\""
    end
    
    return structured
end

"""
    enhance_slash_command(command::String, query::String) -> String
    
    Enhances an existing slash command with additional context.
"""
function enhance_slash_command(command::String, query::String)::String
    enhanced = "/$command Q=\"$query\""
    
    # Add command description
    if haskey(SLASH_COMMANDS, command)
        info = SLASH_COMMANDS[command]
        enhanced = "# $(info["description"])\n$enhanced"
    end
    
    # Add Context v7.0 parameters if not present
    if !contains(query, "context_v7")
        enhanced *= " context_v7=\"active\""
    end
    
    if !contains(query, "resonance") && ContextV7Activation.GLOBAL_STATE.activated
        resonance = get(ContextV7Activation.GLOBAL_STATE.resonance_field, "coefficient", 0.5)
        enhanced *= " resonance=\"$(round(resonance, digits=3))\""
    end
    
    # Add schema patterns
    enhanced *= "\n\n# Schema Patterns Applied:\n"
    enhanced *= "# - High-performance Julia optimization\n"
    enhanced *= "# - Concurrent execution where applicable\n"
    enhanced *= "# - Context Engineering v7.0 patterns\n"
    enhanced *= "# - Australian compliance standards\n"
    
    return enhanced
end

"""
    enhance_generic_prompt(prompt::String) -> String
    
    Enhances a prompt without a specific slash command.
"""
function enhance_generic_prompt(prompt::String)::String
    enhanced = prompt
    
    # Add context header
    enhanced = "# Context Engineering v7.0 Enhancement\n\n$enhanced"
    
    # Add field resonance info
    if ContextV7Activation.GLOBAL_STATE.activated
        resonance = get(ContextV7Activation.GLOBAL_STATE.resonance_field, "coefficient", 0.5)
        balance = get(ContextV7Activation.GLOBAL_STATE.resonance_field, "security_creativity_balance", 0.5)
        
        enhanced *= "\n\n# Field Dynamics:\n"
        enhanced *= "# Resonance Coefficient: $(round(resonance, digits=3))\n"
        enhanced *= "# Security-Creativity Balance: $(round(balance, digits=3))\n"
    end
    
    # Add quality requirements
    enhanced *= "\n# Quality Requirements:\n"
    enhanced *= "# - Type safety and performance optimization\n"
    enhanced *= "# - Schema compliance and validation\n"
    enhanced *= "# - Concurrent execution where beneficial\n"
    enhanced *= "# - Memory efficiency and caching\n"
    
    return enhanced
end

"""
    add_context_v7_enhancements(prompt::String) -> Dict
    
    Adds Context v7.0 specific enhancements to the prompt.
"""
function add_context_v7_enhancements(prompt::String)::Dict
    enhancements = Dict{String,Any}()
    
    if !ContextV7Activation.GLOBAL_STATE.activated
        return enhancements
    end
    
    # Add knowledge graph stats
    kg = ContextV7Activation.GLOBAL_STATE.knowledge_graph
    if !isnothing(kg)
        enhancements["knowledge_nodes"] = length(get(kg, "nodes", []))
        enhancements["patterns_available"] = length(get(kg, "patterns", []))
    end
    
    # Add resonance field data
    rf = ContextV7Activation.GLOBAL_STATE.resonance_field
    if !isnothing(rf)
        enhancements["resonance_coefficient"] = get(rf, "coefficient", 0.0)
        enhancements["security_creativity_balance"] = get(rf, "security_creativity_balance", 0.0)
        enhancements["spiral_phase"] = get(rf, "phase", "unknown")
    end
    
    # Add performance metrics
    enhancements["cache_hit_rate"] = ContextV7Activation.PERF_TRACKER.cache_hits > 0 ?
        ContextV7Activation.PERF_TRACKER.cache_hits / 
        (ContextV7Activation.PERF_TRACKER.cache_hits + ContextV7Activation.PERF_TRACKER.cache_misses) : 0.0
    
    return enhancements
end

"""
    get_field_resonance_guidance() -> Dict
    
    Provides field resonance guidance for the current context.
"""
function get_field_resonance_guidance()::Dict
    guidance = Dict{String,Any}()
    
    if !ContextV7Activation.GLOBAL_STATE.activated
        guidance["status"] = "inactive"
        return guidance
    end
    
    rf = ContextV7Activation.GLOBAL_STATE.resonance_field
    if isnothing(rf)
        guidance["status"] = "unavailable"
        return guidance
    end
    
    resonance = get(rf, "coefficient", 0.5)
    balance = get(rf, "security_creativity_balance", 0.5)
    
    guidance["status"] = "active"
    guidance["resonance_level"] = resonance > 0.7 ? "high" : resonance > 0.4 ? "medium" : "low"
    guidance["recommended_approach"] = if balance > 0.6
        "Balanced innovation - safe creativity encouraged"
    elseif balance > 0.4
        "Moderate approach - standard patterns recommended"
    else
        "Conservative approach - focus on security and compliance"
    end
    
    # Add specific recommendations
    recommendations = String[]
    if resonance > 0.7
        push!(recommendations, "Leverage creative solutions")
        push!(recommendations, "Explore innovative patterns")
    end
    if balance > 0.6
        push!(recommendations, "Apply Context v7.0 advanced patterns")
        push!(recommendations, "Use Julia HPC optimizations")
    end
    
    guidance["recommendations"] = recommendations
    
    return guidance
end

"""
    find_relevant_knowledge(prompt::String) -> Vector{String}
    
    Finds relevant knowledge nodes for the prompt.
"""
function find_relevant_knowledge(prompt::String)::Vector{String}
    nodes = String[]
    
    if !ContextV7Activation.GLOBAL_STATE.activated
        return nodes
    end
    
    kg = ContextV7Activation.GLOBAL_STATE.knowledge_graph
    if isnothing(kg) || !haskey(kg, "nodes")
        return nodes
    end
    
    # Simple keyword matching for demonstration
    prompt_lower = lowercase(prompt)
    keywords = split(prompt_lower, r"\W+")
    
    for node in get(kg, "nodes", [])
        node_name = lowercase(get(node, "name", ""))
        for keyword in keywords
            if length(keyword) > 3 && contains(node_name, keyword)
                push!(nodes, get(node, "name", "unknown"))
                break
            end
        end
        
        # Limit to top 10 nodes
        if length(nodes) >= 10
            break
        end
    end
    
    return unique(nodes)
end

"""
    extract_command_parameters(command::String, prompt::String) -> Dict
    
    Extracts relevant parameters for a specific command.
"""
function extract_command_parameters(command::String, prompt::String)::Dict
    params = Dict{String,Any}()
    prompt_lower = lowercase(prompt)
    
    # Command-specific parameter extraction
    if command == "security"
        if contains(prompt_lower, "vulnerability") || contains(prompt_lower, "vulnerabilities")
            params["focus"] = "vulnerability_assessment"
        end
        if contains(prompt_lower, "audit")
            params["mode"] = "comprehensive_audit"
        end
    elseif command == "data"
        if contains(prompt_lower, "pipeline")
            params["type"] = "pipeline"
        end
        if contains(prompt_lower, "etl")
            params["type"] = "etl"
        end
    elseif command == "test"
        if contains(prompt_lower, "unit")
            params["type"] = "unit"
        end
        if contains(prompt_lower, "integration")
            params["type"] = "integration"
        end
    end
    
    return params
end

"""
    format_enhanced_prompt(response::Dict) -> String
    
    Formats the enhanced prompt response for output.
"""
function format_enhanced_prompt(response::Dict)::String
    output = ""
    
    # Add suggested or detected command
    if haskey(response, "suggested_command")
        cmd_info = response["suggested_command"]
        output *= "# Suggested Command: /$(cmd_info["command"]) (confidence: $(round(cmd_info["confidence"], digits=2)))\n"
        output *= "# $(cmd_info["reason"])\n\n"
    elseif haskey(response, "detected_command")
        output *= "# Detected Command: /$(response["detected_command"])\n\n"
    end
    
    # Add enhanced prompt
    output *= response["enhanced_prompt"]
    
    # Add Context v7.0 block if active
    if haskey(response, "context_v7") && !isempty(response["context_v7"])
        output *= "\n\n# [Context v7.0 Active]\n"
        ctx = response["context_v7"]
        if haskey(ctx, "knowledge_nodes")
            output *= "# Knowledge Nodes: $(ctx["knowledge_nodes"])\n"
        end
        if haskey(ctx, "resonance_coefficient")
            output *= "# Resonance: $(round(ctx["resonance_coefficient"], digits=3))\n"
        end
        if haskey(ctx, "security_creativity_balance")
            output *= "# Balance: $(round(ctx["security_creativity_balance"], digits=3))\n"
        end
    end
    
    # Add field resonance guidance
    if haskey(response, "field_resonance") && response["field_resonance"]["status"] == "active"
        fr = response["field_resonance"]
        output *= "\n# [Field Resonance: $(fr["resonance_level"])]\n"
        output *= "# $(fr["recommended_approach"])\n"
        if haskey(fr, "recommendations") && !isempty(fr["recommendations"])
            for rec in fr["recommendations"]
                output *= "# - $rec\n"
            end
        end
    end
    
    # Add relevant knowledge nodes
    if haskey(response, "knowledge_nodes") && !isempty(response["knowledge_nodes"])
        output *= "\n# [Relevant Knowledge]\n"
        for node in response["knowledge_nodes"][1:min(5, end)]
            output *= "# - $node\n"
        end
    end
    
    return output
end

# Export main functions
export enhance_user_prompt, format_enhanced_prompt
export suggest_slash_command, structure_as_slash_command

end # module UserPromptEnhancer