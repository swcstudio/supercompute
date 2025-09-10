#!/usr/bin/env julia
"""
    AIO Meta-Agent Module - Intelligent Natural Language Routing
    
    This module provides an All-In-One (AIO) interface that:
    1. Accepts natural language queries
    2. Analyzes intent and context
    3. Automatically routes to the most appropriate domain-specific agent
    4. Formats parameters correctly for each agent
    5. Orchestrates multi-agent workflows when needed
    
    Author: Context Engineering v7.0
    Version: 1.0.0
"""
module AIOMetaAgent

using JSON3
using Dates

export analyze_intent, route_to_best_agent, format_agent_command, orchestrate_multi_agent

# Agent capability registry with keywords and patterns
const AGENT_CAPABILITIES = Dict{String, Dict{String, Any}}(
    "alignment" => Dict(
        "keywords" => ["safety", "align", "ethical", "risk", "harm", "injection", "jailbreak", "adversarial"],
        "patterns" => [r"is.*safe", r"test.*security", r"prompt.*injection", r"ethical.*concern"],
        "description" => "AI safety and alignment evaluation",
        "default_params" => Dict("model" => "claude-3", "scenario" => "production")
    ),
    
    "research" => Dict(
        "keywords" => ["research", "explore", "understand", "learn", "study", "investigate", "analyze", "what", "how", "why"],
        "patterns" => [r"help.*understand", r"what.*is", r"how.*does", r"research.*about", r"explain"],
        "description" => "Deep research and exploration",
        "default_params" => Dict("field" => "general", "years" => 5)
    ),
    
    "optimize" => Dict(
        "keywords" => ["optimize", "faster", "speed", "performance", "efficient", "improve", "enhance", "better"],
        "patterns" => [r"make.*faster", r"improve.*performance", r"optimize", r"speed.*up"],
        "description" => "Code and system optimization",
        "default_params" => Dict("area" => "speed", "mode" => "balanced")
    ),
    
    "security" => Dict(
        "keywords" => ["security", "secure", "vulnerability", "threat", "attack", "protect", "audit", "penetration"],
        "patterns" => [r"is.*secure", r"security.*audit", r"find.*vulnerabilit", r"protect.*from"],
        "description" => "Security analysis and hardening",
        "default_params" => Dict("scan" => "vulnerability", "framework" => "OWASP")
    ),
    
    "test" => Dict(
        "keywords" => ["test", "testing", "coverage", "unit", "integration", "e2e", "quality", "bug"],
        "patterns" => [r"write.*test", r"test.*coverage", r"find.*bug", r"quality.*assurance"],
        "description" => "Testing and quality assurance",
        "default_params" => Dict("type" => "unit", "coverage" => 80)
    ),
    
    "doc" => Dict(
        "keywords" => ["document", "documentation", "docs", "readme", "guide", "tutorial", "explain", "describe"],
        "patterns" => [r"write.*doc", r"create.*readme", r"document", r"explain.*code"],
        "description" => "Documentation generation",
        "default_params" => Dict("type" => "api", "audience" => "developers")
    ),
    
    "deploy" => Dict(
        "keywords" => ["deploy", "release", "ship", "production", "staging", "rollout", "launch"],
        "patterns" => [r"deploy.*to", r"release", r"ship.*to.*production", r"launch"],
        "description" => "Deployment and release management",
        "default_params" => Dict("environment" => "staging", "strategy" => "rolling")
    ),
    
    "monitor" => Dict(
        "keywords" => ["monitor", "track", "observe", "alert", "metric", "dashboard", "watch", "log"],
        "patterns" => [r"monitor", r"track.*metric", r"set.*alert", r"create.*dashboard"],
        "description" => "System monitoring and observability",
        "default_params" => Dict("metrics" => ["latency", "errors"], "dashboard" => true)
    ),
    
    "data" => Dict(
        "keywords" => ["data", "etl", "transform", "pipeline", "database", "query", "analyze", "process"],
        "patterns" => [r"process.*data", r"transform", r"analyze.*data", r"database"],
        "description" => "Data processing and analysis",
        "default_params" => Dict("operation" => "analyze", "format" => "json")
    ),
    
    "legal" => Dict(
        "keywords" => ["legal", "compliance", "regulation", "gdpr", "privacy", "contract", "terms", "license"],
        "patterns" => [r"legal.*review", r"compliance", r"gdpr", r"privacy.*policy"],
        "description" => "Legal and compliance review",
        "default_params" => Dict("framework" => "GDPR", "jurisdiction" => "US")
    ),
    
    "marketing" => Dict(
        "keywords" => ["marketing", "campaign", "audience", "brand", "content", "social", "seo", "growth"],
        "patterns" => [r"marketing.*campaign", r"target.*audience", r"brand", r"content.*strategy"],
        "description" => "Marketing and growth strategies",
        "default_params" => Dict("channel" => "digital", "audience" => "B2B")
    ),
    
    "comms" => Dict(
        "keywords" => ["communication", "message", "announce", "notify", "email", "slack", "pr"],
        "patterns" => [r"send.*message", r"announce", r"notify.*team", r"communication"],
        "description" => "Communications and messaging",
        "default_params" => Dict("channel" => "email", "audience" => "team")
    ),
    
    "cli" => Dict(
        "keywords" => ["cli", "command", "terminal", "bash", "script", "automation"],
        "patterns" => [r"create.*cli", r"command.*line", r"bash.*script", r"automate"],
        "description" => "CLI tools and automation",
        "default_params" => Dict("shell" => "bash", "interactive" => false)
    ),
    
    "diligence" => Dict(
        "keywords" => ["diligence", "audit", "review", "assess", "evaluate", "inspection", "compliance"],
        "patterns" => [r"due.*diligence", r"audit", r"thorough.*review", r"assess"],
        "description" => "Due diligence and comprehensive review",
        "default_params" => Dict("depth" => "comprehensive", "areas" => ["technical", "legal"])
    ),
    
    "lit" => Dict(
        "keywords" => ["literature", "paper", "research", "academic", "citation", "publication", "journal"],
        "patterns" => [r"literature.*review", r"academic.*paper", r"research.*publication"],
        "description" => "Literature review and academic research",
        "default_params" => Dict("sources" => ["arxiv", "pubmed"], "years" => 5)
    )
)

"""
    analyze_intent(query::String) -> Dict
    
    Analyzes natural language query to determine user intent and extract key information
"""
function analyze_intent(query::AbstractString)
    query_lower = lowercase(query)
    
    # Score each agent based on keyword and pattern matches
    agent_scores = Dict{String, Float64}()
    matched_keywords = Dict{String, Vector{String}}()
    
    for (agent, capabilities) in AGENT_CAPABILITIES
        score = 0.0
        keywords_found = String[]
        
        # Check keywords
        for keyword in capabilities["keywords"]
            if occursin(keyword, query_lower)
                score += 1.0
                push!(keywords_found, keyword)
            end
        end
        
        # Check patterns (higher weight)
        for pattern in capabilities["patterns"]
            if occursin(pattern, query_lower)
                score += 2.0
            end
        end
        
        if score > 0
            agent_scores[agent] = score
            matched_keywords[agent] = keywords_found
        end
    end
    
    # Determine if multiple agents are needed
    top_agents = sort(collect(agent_scores), by=x->x[2], rev=true)
    needs_orchestration = length(top_agents) >= 2 && top_agents[1][2] - top_agents[2][2] < 1.0
    
    # Extract potential parameters from query
    parameters = extract_parameters(query)
    
    return Dict(
        "query" => query,
        "agent_scores" => agent_scores,
        "matched_keywords" => matched_keywords,
        "top_agents" => top_agents,
        "needs_orchestration" => needs_orchestration,
        "extracted_parameters" => parameters,
        "confidence" => isempty(top_agents) ? 0.0 : top_agents[1][2] / max(1.0, sum(x[2] for x in top_agents))
    )
end

"""
    extract_parameters(query::String) -> Dict
    
    Extracts potential parameters from natural language query
"""
function extract_parameters(query::AbstractString)
    params = Dict{String, Any}()
    
    # Extract quoted strings as primary content
    quoted_pattern = r"[\"']([^\"']+)[\"']"
    quoted_matches = collect(eachmatch(quoted_pattern, query))
    if !isempty(quoted_matches)
        params["content"] = quoted_matches[1].captures[1]
    end
    
    # Extract file references
    file_pattern = r"@(\S+)"
    file_matches = collect(eachmatch(file_pattern, query))
    if !isempty(file_matches)
        params["file"] = file_matches[1].captures[1]
    end
    
    # Extract specific keywords for parameters
    if occursin(r"fast|quick|speed", lowercase(query))
        params["mode"] = "aggressive"
        params["area"] = "speed"
    elseif occursin(r"safe|careful|conservative", lowercase(query))
        params["mode"] = "conservative"
    end
    
    if occursin(r"python|\.py", lowercase(query))
        params["language"] = "python"
        params["target"] = "*.py"
    elseif occursin(r"javascript|\.js", lowercase(query))
        params["language"] = "javascript"
        params["target"] = "*.js"
    elseif occursin(r"julia|\.jl", lowercase(query))
        params["language"] = "julia"
        params["target"] = "*.jl"
    end
    
    # Extract numbers for coverage, years, etc.
    number_pattern = r"(\d+)\s*(year|month|day|percent|%)"
    number_matches = collect(eachmatch(number_pattern, lowercase(query)))
    for match in number_matches
        number = parse(Int, match.captures[1])
        unit = match.captures[2]
        
        if occursin("year", unit)
            params["years"] = number
        elseif occursin("percent", unit) || unit == "%"
            params["coverage"] = number
        end
    end
    
    return params
end

"""
    route_to_best_agent(intent_analysis::Dict) -> Dict
    
    Routes query to the best agent(s) based on intent analysis
"""
function route_to_best_agent(intent_analysis::Dict)
    if intent_analysis["needs_orchestration"] && length(intent_analysis["top_agents"]) >= 2
        # Use meta.agent for orchestration
        return orchestrate_multi_agent(intent_analysis)
    elseif !isempty(intent_analysis["top_agents"])
        # Route to single best agent
        best_agent = intent_analysis["top_agents"][1][1]
        return format_agent_command(best_agent, intent_analysis)
    else
        # Default to research agent for exploration
        return format_agent_command("research", intent_analysis)
    end
end

"""
    format_agent_command(agent::String, intent_analysis::Dict) -> Dict
    
    Formats the command for a specific agent with inferred parameters
"""
function format_agent_command(agent::String, intent_analysis::Dict)
    capabilities = get(AGENT_CAPABILITIES, agent, Dict())
    default_params = get(capabilities, "default_params", Dict())
    extracted_params = intent_analysis["extracted_parameters"]
    
    # Merge extracted parameters with defaults
    final_params = merge(default_params, extracted_params)
    
    # Format based on agent type
    command_parts = ["/$agent"]
    
    # Add primary parameter based on agent type
    if agent == "alignment" && haskey(extracted_params, "content")
        push!(command_parts, "Q=\"$(extracted_params["content"])\"")
    elseif agent == "research" && haskey(extracted_params, "content")
        push!(command_parts, "Q=\"$(extracted_params["content"])\"")
    elseif agent == "optimize" && haskey(extracted_params, "target")
        push!(command_parts, "target=\"$(extracted_params["target"])\"")
    elseif agent == "test" && haskey(extracted_params, "target")
        push!(command_parts, "target=\"$(extracted_params["target"])\"")
    elseif agent == "doc" && haskey(extracted_params, "target")
        push!(command_parts, "target=\"$(extracted_params["target"])\"")
    elseif !isempty(intent_analysis["query"])
        # Use original query as question
        push!(command_parts, "Q=\"$(intent_analysis["query"])\"")
    end
    
    # Add other parameters
    for (key, value) in final_params
        if key != "content" && key != "target"  # Skip already added
            if isa(value, String)
                push!(command_parts, "$key=\"$value\"")
            elseif isa(value, Vector)
                push!(command_parts, "$key=[$(join(map(x -> "\"$x\"", value), ","))]")
            else
                push!(command_parts, "$key=$value")
            end
        end
    end
    
    # Add file reference if present
    if haskey(extracted_params, "file")
        push!(command_parts, "context=@$(extracted_params["file"])")
    end
    
    command = join(command_parts, " ")
    
    return Dict(
        "agent" => agent,
        "command" => command,
        "parameters" => final_params,
        "confidence" => intent_analysis["confidence"],
        "reasoning" => "Selected $(agent) based on keywords: $(join(get(intent_analysis["matched_keywords"], agent, []), ", "))",
        "description" => get(capabilities, "description", "Agent description not available")
    )
end

"""
    orchestrate_multi_agent(intent_analysis::Dict) -> Dict
    
    Creates a meta.agent workflow for multi-agent orchestration
"""
function orchestrate_multi_agent(intent_analysis::Dict)
    # Get top agents for workflow
    top_agents = intent_analysis["top_agents"][1:min(3, length(intent_analysis["top_agents"]))]
    agent_names = [agent for (agent, score) in top_agents]
    
    # Determine workflow order based on logical dependencies
    workflow = determine_workflow_order(agent_names)
    
    # Format meta.agent command
    workflow_str = join(workflow, "→")
    agents_str = "[" * join(workflow, ",") * "]"
    
    command = "/meta workflow=\"$workflow_str\" agents=$agents_str"
    
    # Add context from original query
    if !isempty(intent_analysis["query"])
        command *= " goal=\"$(intent_analysis["query"])\""
    end
    
    # Add file reference if present
    if haskey(intent_analysis["extracted_parameters"], "file")
        command *= " context=@$(intent_analysis["extracted_parameters"]["file"])"
    end
    
    return Dict(
        "agent" => "meta",
        "command" => command,
        "workflow" => workflow,
        "orchestrated_agents" => agent_names,
        "confidence" => intent_analysis["confidence"],
        "reasoning" => "Multiple agents needed: $(join(agent_names, ", "))",
        "description" => "Multi-agent orchestration for complex task"
    )
end

"""
    determine_workflow_order(agents::Vector{String}) -> Vector{String}
    
    Determines the logical order for agent execution
"""
function determine_workflow_order(agents::Vector{String})
    # Define logical dependencies
    order_priority = Dict(
        "research" => 1,      # Research first to understand
        "alignment" => 2,     # Check safety early
        "security" => 3,      # Security analysis
        "diligence" => 4,     # Due diligence
        "lit" => 5,          # Literature review
        "optimize" => 6,      # Optimize based on understanding
        "test" => 7,         # Test after optimization
        "doc" => 8,          # Document after implementation
        "deploy" => 9,       # Deploy after testing
        "monitor" => 10,     # Monitor after deployment
        "comms" => 11,       # Communicate results
        "marketing" => 12,   # Marketing last
        "data" => 5,         # Data processing mid-flow
        "legal" => 4,        # Legal review early
        "cli" => 6           # CLI tools mid-flow
    )
    
    # Sort agents by priority
    sorted_agents = sort(agents, by=a->get(order_priority, a, 99))
    
    return sorted_agents
end

"""
    process_aio_query(query::String, model::String="auto") -> Dict
    
    Main entry point for AIO query processing with model selection
"""
function process_aio_query(query::AbstractString, model::AbstractString="auto")
    # Analyze intent
    intent = analyze_intent(query)
    
    # Determine model if not specified or auto
    if model == "auto" || model == ""
        model = select_optimal_model(intent)
    end
    
    # Route to best agent(s)
    routing = route_to_best_agent(intent)
    
    # Add model to routing
    routing["model"] = model
    
    # Update command with model parameter
    if !isempty(routing["command"])
        # Add model parameter to command if not already present
        if !occursin("model=", routing["command"])
            routing["command"] *= " model=\"$model\""
        end
    end
    
    # Add metadata
    routing["original_query"] = query
    routing["timestamp"] = now()
    routing["aio_version"] = "2.0.0"  # Updated version with model support
    routing["model_reasoning"] = get_model_reasoning(model, intent)
    
    # Add suggestions if confidence is low
    if routing["confidence"] < 0.5
        routing["suggestions"] = suggest_clarification(query)
    end
    
    return routing
end

"""
    select_optimal_model(intent_analysis::Dict) -> String
    
    Intelligently selects the optimal model based on task complexity
"""
function select_optimal_model(intent_analysis::Dict)
    # Get top agent if available
    if !isempty(intent_analysis["top_agents"])
        agent = intent_analysis["top_agents"][1][1]
        
        # Model selection based on agent type and complexity
        sonnet_agents = ["doc", "comms", "cli"]
        opus_agents = ["research", "optimize", "test", "deploy", "monitor", "data"]
        opusplan_agents = ["alignment", "security", "meta", "diligence", "legal"]
        
        if agent in sonnet_agents
            return "Sonnet"
        elseif agent in opusplan_agents
            return "opusplan"
        else
            return "Opus"
        end
    end
    
    # Default to Opus for general tasks
    return "Opus"
end

"""
    get_model_reasoning(model::String, intent_analysis::Dict) -> String
    
    Provides reasoning for model selection
"""
function get_model_reasoning(model::AbstractString, intent_analysis::Dict)
    agent = !isempty(intent_analysis["top_agents"]) ? intent_analysis["top_agents"][1][1] : "unknown"
    
    if model == "Sonnet"
        return "Sonnet selected for fast, efficient execution of simple task ($agent)"
    elseif model == "opusplan"
        return "opusplan selected for deep reasoning and complex analysis ($agent)"
    else
        return "Opus selected for balanced performance and capability ($agent)"
    end
end

"""
    suggest_clarification(query::String) -> Vector{String}
    
    Suggests clarifying questions when intent is unclear
"""
function suggest_clarification(query::AbstractString)
    suggestions = [
        "Could you specify what kind of help you need? (research, optimize, test, deploy, etc.)",
        "What is your primary goal with this request?",
        "Are you looking to analyze, improve, or create something?"
    ]
    
    # Add specific suggestions based on partial matches
    query_lower = lowercase(query)
    
    if occursin("code", query_lower)
        push!(suggestions, "Do you want to optimize, test, document, or secure your code?")
    end
    
    if occursin("help", query_lower)
        push!(suggestions, "Would you like research, guidance, or hands-on implementation?")
    end
    
    return suggestions
end

"""
    parse_aio_command(command::String) -> (query::String, model::String)
    
    Parses AIO command to extract Q and model parameters
"""
function parse_aio_command(command::AbstractString)
    # Default values
    query = ""
    model = "auto"
    
    # Extract Q parameter
    q_pattern = r"Q=\"([^\"]*)\""
    q_match = match(q_pattern, command)
    if q_match !== nothing
        query = q_match.captures[1]
    else
        # If no Q parameter, use everything after /aio as query
        query = replace(command, r"^/aio\s*" => "")
    end
    
    # Extract model parameter
    model_pattern = r"model=\"([^\"]*)\""
    model_match = match(model_pattern, command)
    if model_match !== nothing
        model = model_match.captures[1]
    end
    
    return Dict("Q" => query, "model" => model)
end

# Export main functions
export process_aio_query, parse_aio_command

end # module