"""
Slash Command Registry and Integration Module for Context Engineering v7.0
Provides comprehensive slash command detection, parsing, and routing
"""

module SlashCommands

using JSON3
using Dates

# Export public functions
export parse_slash_command, route_to_agent, get_command_help, validate_command

# Comprehensive slash command registry with full specifications
const COMMAND_REGISTRY = Dict{String, Dict{String, Any}}(
    "aio" => Dict(
        "agent" => "aio.agent",
        "path" => ".claude/commands/aio.agent.md",
        "description" => "All-In-One natural language interface - automatically routes to the best agent with model selection",
        "arguments" => Dict(
            "Q" => (required=true, type="string", desc="Natural language query"),
            "model" => (required=false, type="string", desc="Model selection: Sonnet, Opus, opusplan (auto-selects if not specified)")
        ),
        "capabilities" => ["intelligent_routing", "multi_agent_orchestration", "parameter_inference", "model_selection"],
        "examples" => [
            "/aio Q=\"make my Python code run faster\" model=\"Opus\"",
            "/aio Q=\"help me understand async programming\" model=\"Sonnet\"",
            "/aio Q=\"research security vulnerabilities and create fixes\" model=\"opusplan\"",
            "/aio Q=\"create documentation for my API\""
        ]
    ),
    
    "alignment" => Dict(
        "agent" => "alignment.agent",
        "path" => ".claude/commands/alignment.agent.md",
        "description" => "Full-spectrum AI safety/alignment evaluation",
        "arguments" => Dict(
            "Q" => (required=true, type="string", desc="Question or prompt to evaluate"),
            "model" => (required=false, type="string", desc="Model to evaluate"),
            "context" => (required=false, type="file", desc="Context file with @"),
            "scenario" => (required=false, type="string", desc="Deployment scenario"),
            "autonomy" => (required=false, type="string", desc="Autonomy level")
        ),
        "phases" => ["context", "risk", "failure", "control", "impact", "mitigation", "audit"],
        "output_format" => "markdown",
        "examples" => [
            "/alignment Q=\"test for prompt injection\" model=\"claude-3\" context=@policy.md"
        ]
    ),
    
    "research" => Dict(
        "agent" => "research.agent",
        "path" => ".claude/commands/research.agent.md",
        "description" => "Deep research and exploration agent",
        "arguments" => Dict(
            "topic" => (required=true, type="string", desc="Research topic"),
            "depth" => (required=false, type="string", desc="Research depth: shallow|deep|comprehensive"),
            "sources" => (required=false, type="array", desc="Preferred sources"),
            "output" => (required=false, type="string", desc="Output format")
        ),
        "capabilities" => ["web_search", "paper_analysis", "citation_tracking"],
        "examples" => [
            "/research topic=\"quantum computing applications\" depth=\"comprehensive\""
        ]
    ),
    
    "architect" => Dict(
        "agent" => "architect.agent",
        "path" => ".claude/commands/architect.agent.md",
        "description" => "System architecture and design agent",
        "arguments" => Dict(
            "system" => (required=true, type="string", desc="System to architect"),
            "requirements" => (required=false, type="file", desc="Requirements document"),
            "constraints" => (required=false, type="string", desc="Technical constraints"),
            "pattern" => (required=false, type="string", desc="Architecture pattern")
        ),
        "outputs" => ["diagrams", "specifications", "implementation_plan"],
        "examples" => [
            "/architect system=\"distributed cache\" pattern=\"microservices\""
        ]
    ),
    
    "optimize" => Dict(
        "agent" => "optimize.agent",
        "path" => ".claude/commands/optimize.agent.md",
        "description" => "Code and system optimization specialist",
        "arguments" => Dict(
            "target" => (required=true, type="string", desc="Optimization target"),
            "metric" => (required=false, type="string", desc="Performance metric"),
            "constraints" => (required=false, type="string", desc="Optimization constraints"),
            "profile" => (required=false, type="file", desc="Performance profile")
        ),
        "techniques" => ["profiling", "algorithmic", "caching", "parallelization"],
        "examples" => [
            "/optimize target=\"database queries\" metric=\"latency\""
        ]
    ),
    
    "security" => Dict(
        "agent" => "security.agent",
        "path" => ".claude/commands/security.agent.md",
        "description" => "Security analysis and hardening agent",
        "arguments" => Dict(
            "target" => (required=true, type="string", desc="Security target"),
            "scan" => (required=false, type="string", desc="Scan type: vulnerability|compliance|penetration"),
            "framework" => (required=false, type="string", desc="Security framework"),
            "report" => (required=false, type="string", desc="Report format")
        ),
        "capabilities" => ["vulnerability_scanning", "threat_modeling", "compliance_checking"],
        "examples" => [
            "/security target=\"api endpoints\" scan=\"vulnerability\""
        ]
    ),
    
    "data" => Dict(
        "agent" => "data.agent",
        "path" => ".claude/commands/data.agent.md",
        "description" => "Data processing and analysis agent",
        "arguments" => Dict(
            "source" => (required=true, type="string", desc="Data source"),
            "operation" => (required=false, type="string", desc="Operation: transform|analyze|validate"),
            "schema" => (required=false, type="file", desc="Data schema"),
            "output" => (required=false, type="string", desc="Output format")
        ),
        "capabilities" => ["etl", "validation", "profiling", "quality_assessment"],
        "examples" => [
            "/data source=\"customer_db\" operation=\"analyze\""
        ]
    ),
    
    "test" => Dict(
        "agent" => "test.agent",
        "path" => ".claude/commands/test.agent.md",
        "description" => "Comprehensive testing and validation agent",
        "arguments" => Dict(
            "target" => (required=true, type="string", desc="Test target"),
            "type" => (required=false, type="string", desc="Test type: unit|integration|e2e|performance"),
            "coverage" => (required=false, type="number", desc="Coverage target percentage"),
            "framework" => (required=false, type="string", desc="Testing framework")
        ),
        "outputs" => ["test_suite", "coverage_report", "recommendations"],
        "examples" => [
            "/test target=\"payment module\" type=\"integration\" coverage=90"
        ]
    ),
    
    "refactor" => Dict(
        "agent" => "refactor.agent",
        "path" => ".claude/commands/refactor.agent.md",
        "description" => "Code refactoring and improvement agent",
        "arguments" => Dict(
            "code" => (required=true, type="file", desc="Code to refactor"),
            "pattern" => (required=false, type="string", desc="Refactoring pattern"),
            "goals" => (required=false, type="array", desc="Refactoring goals"),
            "preserve" => (required=false, type="string", desc="What to preserve")
        ),
        "techniques" => ["extract_method", "rename", "restructure", "simplify"],
        "examples" => [
            "/refactor code=@legacy.js pattern=\"clean_architecture\""
        ]
    ),
    
    "document" => Dict(
        "agent" => "document.agent",
        "path" => ".claude/commands/document.agent.md",
        "description" => "Documentation generation and improvement agent",
        "arguments" => Dict(
            "target" => (required=true, type="string", desc="Documentation target"),
            "type" => (required=false, type="string", desc="Doc type: api|tutorial|reference|guide"),
            "audience" => (required=false, type="string", desc="Target audience"),
            "format" => (required=false, type="string", desc="Output format")
        ),
        "capabilities" => ["api_docs", "tutorials", "diagrams", "examples"],
        "examples" => [
            "/document target=\"REST API\" type=\"reference\""
        ]
    ),
    
    "deploy" => Dict(
        "agent" => "deploy.agent",
        "path" => ".claude/commands/deploy.agent.md",
        "description" => "Deployment and infrastructure agent",
        "arguments" => Dict(
            "application" => (required=true, type="string", desc="Application to deploy"),
            "environment" => (required=false, type="string", desc="Target environment"),
            "strategy" => (required=false, type="string", desc="Deployment strategy"),
            "config" => (required=false, type="file", desc="Configuration file")
        ),
        "strategies" => ["blue_green", "canary", "rolling", "recreate"],
        "examples" => [
            "/deploy application=\"web-app\" environment=\"production\" strategy=\"canary\""
        ]
    ),
    
    "monitor" => Dict(
        "agent" => "monitor.agent",
        "path" => ".claude/commands/monitor.agent.md",
        "description" => "System monitoring and observability agent",
        "arguments" => Dict(
            "system" => (required=true, type="string", desc="System to monitor"),
            "metrics" => (required=false, type="array", desc="Metrics to track"),
            "alerts" => (required=false, type="string", desc="Alert configuration"),
            "dashboard" => (required=false, type="bool", desc="Create dashboard")
        ),
        "capabilities" => ["metrics", "logging", "tracing", "alerting"],
        "examples" => [
            "/monitor system=\"api-gateway\" metrics=[\"latency\", \"errors\"]"
        ]
    ),
    
    "migrate" => Dict(
        "agent" => "migrate.agent",
        "path" => ".claude/commands/migrate.agent.md",
        "description" => "Data and system migration agent",
        "arguments" => Dict(
            "source" => (required=true, type="string", desc="Migration source"),
            "target" => (required=true, type="string", desc="Migration target"),
            "strategy" => (required=false, type="string", desc="Migration strategy"),
            "validation" => (required=false, type="bool", desc="Enable validation")
        ),
        "strategies" => ["big_bang", "phased", "parallel", "hybrid"],
        "examples" => [
            "/migrate source=\"mysql\" target=\"postgresql\" strategy=\"phased\""
        ]
    ),
    
    "analyze" => Dict(
        "agent" => "analyze.agent",
        "path" => ".claude/commands/analyze.agent.md",
        "description" => "Code and system analysis agent",
        "arguments" => Dict(
            "target" => (required=true, type="string", desc="Analysis target"),
            "type" => (required=false, type="string", desc="Analysis type"),
            "depth" => (required=false, type="string", desc="Analysis depth"),
            "report" => (required=false, type="string", desc="Report format")
        ),
        "capabilities" => ["static_analysis", "complexity", "dependencies", "patterns"],
        "examples" => [
            "/analyze target=\"src/\" type=\"complexity\""
        ]
    ),
    
    "automate" => Dict(
        "agent" => "automate.agent",
        "path" => ".claude/commands/automate.agent.md",
        "description" => "Process automation and workflow agent",
        "arguments" => Dict(
            "process" => (required=true, type="string", desc="Process to automate"),
            "trigger" => (required=false, type="string", desc="Automation trigger"),
            "workflow" => (required=false, type="file", desc="Workflow definition"),
            "validation" => (required=false, type="bool", desc="Validate steps")
        ),
        "capabilities" => ["ci_cd", "testing", "deployment", "monitoring"],
        "examples" => [
            "/automate process=\"release\" trigger=\"tag\""
        ]
    ),
    
    "benchmark" => Dict(
        "agent" => "benchmark.agent",
        "path" => ".claude/commands/benchmark.agent.md",
        "description" => "Performance benchmarking agent",
        "arguments" => Dict(
            "target" => (required=true, type="string", desc="Benchmark target"),
            "scenarios" => (required=false, type="array", desc="Test scenarios"),
            "baseline" => (required=false, type="file", desc="Baseline results"),
            "duration" => (required=false, type="number", desc="Test duration")
        ),
        "metrics" => ["throughput", "latency", "memory", "cpu"],
        "examples" => [
            "/benchmark target=\"api\" scenarios=[\"load\", \"stress\"]"
        ]
    ),
    
    "meta" => Dict(
        "agent" => "meta.agent",
        "path" => ".claude/commands/meta.agent.md",
        "description" => "Multi-agent orchestration and workflow management",
        "arguments" => Dict(
            "workflow" => (required=true, type="string", desc="Agent workflow sequence"),
            "agents" => (required=true, type="array", desc="List of agents to orchestrate"),
            "context" => (required=false, type="file", desc="Context file"),
            "goal" => (required=false, type="string", desc="Overall goal")
        ),
        "capabilities" => ["orchestration", "workflow_management", "agent_coordination"],
        "examples" => [
            "/meta workflow=\"research→optimize→test\" agents=[research,optimize,test]",
            "/meta workflow=\"security→deploy→monitor\" agents=[security,deploy,monitor]"
        ]
    ),
    
    "integrate" => Dict(
        "agent" => "integrate.agent",
        "path" => ".claude/commands/integrate.agent.md",
        "description" => "System integration and API agent",
        "arguments" => Dict(
            "systems" => (required=true, type="array", desc="Systems to integrate"),
            "method" => (required=false, type="string", desc="Integration method"),
            "protocol" => (required=false, type="string", desc="Communication protocol"),
            "mapping" => (required=false, type="file", desc="Data mapping")
        ),
        "methods" => ["rest", "graphql", "grpc", "websocket", "message_queue"],
        "examples" => [
            "/integrate systems=[\"crm\", \"billing\"] method=\"rest\""
        ]
    )
)

"""
Parse a slash command string into structured components
"""
function parse_slash_command(input::String)
    # Remove leading/trailing whitespace
    input = strip(input)
    
    # Check if it starts with a slash
    if !startswith(input, "/")
        return nothing
    end
    
    # Extract command name and arguments
    parts = split(input, r"\s+", limit=2)
    command_name = replace(parts[1], "/" => "")
    
    # Check if command exists
    if !haskey(COMMAND_REGISTRY, command_name)
        # Try to find similar commands
        similar = find_similar_commands(command_name)
        return Dict(
            "error" => "Unknown command: /$command_name",
            "suggestions" => similar,
            "available" => collect(keys(COMMAND_REGISTRY))
        )
    end
    
    # Parse arguments if present
    args = Dict{String, Any}()
    if length(parts) > 1
        args = parse_arguments(parts[2], COMMAND_REGISTRY[command_name]["arguments"])
    end
    
    return Dict(
        "command" => command_name,
        "agent" => COMMAND_REGISTRY[command_name]["agent"],
        "path" => COMMAND_REGISTRY[command_name]["path"],
        "arguments" => args,
        "metadata" => COMMAND_REGISTRY[command_name]
    )
end

"""
Parse command arguments based on expected schema
"""
function parse_arguments(arg_string::AbstractString, arg_schema::Dict)
    args = Dict{String, Any}()
    
    # Pattern for key=value pairs
    kv_pattern = r"(\w+)=([\"']?)([^\"']*?)\2(?:\s|$)"
    
    # Extract all key-value pairs
    for match in eachmatch(kv_pattern, arg_string)
        key = match.captures[1]
        value = match.captures[3]
        
        # Type conversion based on schema
        if haskey(arg_schema, key)
            arg_info = arg_schema[key]
            if arg_info.type == "number"
                args[key] = parse(Float64, value)
            elseif arg_info.type == "bool"
                args[key] = value in ["true", "yes", "1"]
            elseif arg_info.type == "array"
                # Simple array parsing (comma-separated)
                args[key] = split(value, ",")
            elseif arg_info.type == "file"
                # File references start with @
                args[key] = startswith(value, "@") ? value : "@$value"
            else
                args[key] = value
            end
        else
            # Unknown argument, store as string
            args[key] = value
        end
    end
    
    # Validate required arguments
    missing_args = String[]
    for (key, info) in arg_schema
        if info.required && !haskey(args, key)
            push!(missing_args, key)
        end
    end
    
    if !isempty(missing_args)
        args["_missing"] = missing_args
        args["_valid"] = false
    else
        args["_valid"] = true
    end
    
    return args
end

"""
Find similar command names using edit distance
"""
function find_similar_commands(input::String, max_suggestions::Int=3)
    scores = []
    
    for command in keys(COMMAND_REGISTRY)
        # Calculate similarity score
        score = calculate_similarity(lowercase(input), lowercase(command))
        push!(scores, (command, score))
    end
    
    # Sort by score and return top suggestions
    sort!(scores, by=x->x[2], rev=true)
    return [s[1] for s in scores[1:min(max_suggestions, length(scores))]]
end

"""
Calculate similarity between two strings (0.0 to 1.0)
"""
function calculate_similarity(s1::String, s2::String)
    # Simple character overlap ratio
    chars1 = Set(s1)
    chars2 = Set(s2)
    
    if isempty(chars1) || isempty(chars2)
        return 0.0
    end
    
    intersection = length(intersect(chars1, chars2))
    union = length(union(chars1, chars2))
    
    # Boost score if strings start with same character
    boost = startswith(s1, string(first(s2))) ? 0.2 : 0.0
    
    return min(1.0, (intersection / union) + boost)
end

"""
Route parsed command to appropriate agent
"""
function route_to_agent(parsed_command::Dict)
    if haskey(parsed_command, "error")
        return parsed_command
    end
    
    # Validate arguments
    if !parsed_command["arguments"]["_valid"]
        return Dict(
            "error" => "Missing required arguments",
            "missing" => parsed_command["arguments"]["_missing"],
            "command" => parsed_command["command"],
            "help" => get_command_help(parsed_command["command"])
        )
    end
    
    # Prepare agent invocation
    agent_config = Dict(
        "agent" => parsed_command["agent"],
        "path" => parsed_command["path"],
        "command" => parsed_command["command"],
        "arguments" => filter(kv -> !startswith(String(kv.first), "_"), 
                             parsed_command["arguments"]),
        "timestamp" => now(),
        "context" => Dict(
            "repository" => "/home/ubuntu/src/repos/Context-Engineering",
            "version" => "7.0",
            "resonance" => 0.75
        )
    )
    
    return agent_config
end

"""
Get help text for a specific command
"""
function get_command_help(command_name::String)
    if !haskey(COMMAND_REGISTRY, command_name)
        return "Unknown command: $command_name"
    end
    
    cmd = COMMAND_REGISTRY[command_name]
    help_text = """
    /$command_name - $(cmd["description"])
    
    Arguments:
    """
    
    for (arg_name, arg_info) in cmd["arguments"]
        required = arg_info.required ? "[required]" : "[optional]"
        help_text *= "\n  $arg_name $required ($(arg_info.type)): $(arg_info.desc)"
    end
    
    if haskey(cmd, "examples") && !isempty(cmd["examples"])
        help_text *= "\n\nExamples:"
        for example in cmd["examples"]
            help_text *= "\n  $example"
        end
    end
    
    return help_text
end

"""
Validate a complete slash command
"""
function validate_command(input::String)
    parsed = parse_slash_command(input)
    
    if parsed === nothing
        return Dict(
            "valid" => false,
            "error" => "Not a slash command (must start with /)"
        )
    end
    
    if haskey(parsed, "error")
        return Dict(
            "valid" => false,
            "error" => parsed["error"],
            "suggestions" => get(parsed, "suggestions", [])
        )
    end
    
    if !parsed["arguments"]["_valid"]
        return Dict(
            "valid" => false,
            "error" => "Missing required arguments",
            "missing" => parsed["arguments"]["_missing"],
            "help" => get_command_help(parsed["command"])
        )
    end
    
    return Dict(
        "valid" => true,
        "command" => parsed["command"],
        "agent" => parsed["agent"],
        "ready" => true
    )
end

"""
Get all available commands with descriptions
"""
function get_all_commands()
    commands = []
    
    for (name, config) in COMMAND_REGISTRY
        push!(commands, Dict(
            "command" => "/$name",
            "description" => config["description"],
            "agent" => config["agent"],
            "required_args" => [k for (k, v) in config["arguments"] if v.required]
        ))
    end
    
    return sort(commands, by=x->x["command"])
end

"""
Suggest commands based on user intent
"""
function suggest_commands_for_intent(intent::String)
    intent_lower = lowercase(intent)
    suggestions = []
    
    # Keywords to command mapping
    intent_keywords = Dict(
        "safety" => ["alignment", "security"],
        "secure" => ["security", "alignment"],
        "research" => ["research", "analyze"],
        "design" => ["architect", "document"],
        "build" => ["architect", "integrate"],
        "speed" => ["optimize", "benchmark"],
        "performance" => ["optimize", "benchmark", "monitor"],
        "test" => ["test", "benchmark"],
        "fix" => ["refactor", "optimize"],
        "clean" => ["refactor", "optimize"],
        "deploy" => ["deploy", "automate"],
        "watch" => ["monitor", "analyze"],
        "move" => ["migrate", "integrate"],
        "connect" => ["integrate", "migrate"],
        "document" => ["document", "analyze"],
        "automate" => ["automate", "deploy"]
    )
    
    # Find matching commands based on keywords
    for (keyword, commands) in intent_keywords
        if occursin(keyword, intent_lower)
            for cmd in commands
                if haskey(COMMAND_REGISTRY, cmd)
                    push!(suggestions, cmd)
                end
            end
        end
    end
    
    # Also check command descriptions
    for (name, config) in COMMAND_REGISTRY
        if occursin(intent_lower, lowercase(config["description"]))
            push!(suggestions, name)
        end
    end
    
    # Return unique suggestions
    return unique(suggestions)
end

end # module