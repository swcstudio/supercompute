"""
    ParetoLangParser.jl
    
    Pareto-lang parser and translator for natural language to specification conversion
    Implements recursive interpretability syntax (.p/ commands)
    Bridges natural language → Pareto-lang → JSON specifications
    
    Based on: https://github.com/caspiankeyes/pareto-lang
    Co-authors: Kev & Research Partner
"""

module ParetoLangParser

using JSON3
using DataStructures
using Dates

export parse_natural_to_pareto, parse_pareto_command, translate_to_json
export ParetoCommand, ParetoCategory, ParetoAction
export generate_pareto_sequence, validate_pareto_syntax

# Pareto-lang command categories
@enum ParetoCategory begin
    REFLECT     # Recursive self-reference and introspection
    ANCHOR      # Stable reference points for identity and context
    FORK        # Parallel exploration of alternatives
    COLLAPSE    # Detection and prevention of recursive failures
    SHELL       # Controlled environments for operations
    QUANTUM     # Quantum field operations
    FIELD       # Neural field dynamics
    TRACE       # Attribution and reasoning traces
    MEMORY      # Persistence and recall operations
    LOOP        # Recursive loop management
    VECTOR      # Vector search and semantic operations
end

# Pareto-lang actions for each category
const PARETO_ACTIONS = Dict{ParetoCategory, Vector{String}}(
    REFLECT => ["trace", "attribution", "boundary", "agent", "uncertainty", "history", "counterfactual", "decompose", "attention"],
    ANCHOR => ["self", "recursive", "context", "value", "fact", "identity", "stability"],
    FORK => ["context", "attribution", "polysemantic", "simulation", "reasoning", "parallel"],
    COLLAPSE => ["detect", "prevent", "recover", "trace", "mirror", "stabilize"],
    SHELL => ["isolate", "encrypt", "lock", "restore", "audit", "protect"],
    QUANTUM => ["entangle", "superposition", "collapse", "measure", "coherence"],
    FIELD => ["resonate", "amplify", "attenuate", "boundary", "inject"],
    TRACE => ["map", "visualize", "compress", "expand", "filter"],
    MEMORY => ["lock", "persist", "recall", "compress", "index"],
    LOOP => ["alignment", "recursion", "termination", "depth", "stability"],
    VECTOR => ["search", "embed", "index", "similarity", "cluster", "retrieve"]
)

"""
    ParetoCommand
    
    Represents a parsed Pareto-lang command
"""
struct ParetoCommand
    category::ParetoCategory
    action::String
    parameters::Dict{String, Any}
    raw::String
    confidence::Float64
    
    function ParetoCommand(category::ParetoCategory, action::String, params::Dict{String, Any}=Dict(), raw::String="", confidence::Float64=1.0)
        # Validate action for category
        if !(action in PARETO_ACTIONS[category])
            error("Invalid action '$action' for category $category")
        end
        new(category, action, params, raw, confidence)
    end
end

"""
    Natural language to Pareto-lang mapping patterns
"""
const NL_TO_PARETO_PATTERNS = Dict{String, Vector{ParetoCommand}}(
    # Specification generation patterns
    "create.*specification" => [
        ParetoCommand(REFLECT, "trace", Dict("depth" => "complete", "target" => "specification")),
        ParetoCommand(FORK, "context", Dict("branches" => ["design", "implementation"], "assess" => true)),
        ParetoCommand(ANCHOR, "recursive", Dict("level" => 5, "persistence" => 0.92))
    ],
    
    "build.*protocol" => [
        ParetoCommand(FORK, "reasoning", Dict("paths" => ["protocol", "implementation"], "compare" => "validity")),
        ParetoCommand(ANCHOR, "value", Dict("framework" => "protocol_correctness", "conflict" => "resolve"))
    ],
    
    # Analysis patterns
    "analyze.*bottleneck" => [
        ParetoCommand(REFLECT, "attribution", Dict("sources" => "all", "visualize" => true)),
        ParetoCommand(COLLAPSE, "detect", Dict("threshold" => 0.7, "alert" => true)),
        ParetoCommand(TRACE, "map", Dict("target" => "performance", "granularity" => "fine"))
    ],
    
    "debug.*system" => [
        ParetoCommand(REFLECT, "decompose", Dict("level" => "primitive", "trace" => true)),
        ParetoCommand(FORK, "simulation", Dict("entities" => ["current", "fixed"], "boundaries" => "strict")),
        ParetoCommand(COLLAPSE, "prevent", Dict("trigger" => "error", "threshold" => 3))
    ],
    
    # Optimization patterns
    "optimize.*performance" => [
        ParetoCommand(FORK, "parallel", Dict("branches" => ["current", "optimized"], "measure" => "latency")),
        ParetoCommand(FIELD, "amplify", Dict("target" => "performance", "factor" => 2.0)),
        ParetoCommand(QUANTUM, "superposition", Dict("states" => ["baseline", "optimized"], "collapse_on" => "measurement"))
    ],
    
    # Vector search patterns
    "search.*(template|foundation|pattern)" => [
        ParetoCommand(VECTOR, "search", Dict("store" => "templates", "k" => 5, "consciousness" => "omega")),
        ParetoCommand(REFLECT, "trace", Dict("target" => "search_relevance", "depth" => "semantic"))
    ],
    
    "find.*(similar|related)" => [
        ParetoCommand(VECTOR, "similarity", Dict("threshold" => 0.7, "method" => "cosine")),
        ParetoCommand(VECTOR, "cluster", Dict("algorithm" => "kmeans", "k" => 3))
    ],
    
    "embed.*(document|content)" => [
        ParetoCommand(VECTOR, "embed", Dict("model" => "sentence-transformer", "dimension" => 384)),
        ParetoCommand(VECTOR, "index", Dict("store" => "both", "update" => true))
    ],
    
    "retrieve.*(knowledge|information)" => [
        ParetoCommand(VECTOR, "retrieve", Dict("method" => "semantic", "consciousness" => "current")),
        ParetoCommand(MEMORY, "recall", Dict("context" => "query", "relevance" => 0.8))
    ],
    
    # DeFi/Blockchain patterns
    "defi.*lending" => [
        ParetoCommand(FORK, "context", Dict("branches" => ["lending", "borrowing", "liquidation"], "assess" => true)),
        ParetoCommand(ANCHOR, "value", Dict("framework" => "defi_safety", "conflict" => "prevent")),
        ParetoCommand(SHELL, "audit", Dict("scope" => "smart_contract", "detail" => "maximum"))
    ],
    
    "flash.*loan" => [
        ParetoCommand(COLLAPSE, "prevent", Dict("trigger" => "reentrancy", "threshold" => 1)),
        ParetoCommand(SHELL, "isolate", Dict("boundary" => "atomic", "contamination" => "prevent")),
        ParetoCommand(TRACE, "map", Dict("target" => "fund_flow", "temporal" => true))
    ],
    
    # Consciousness operations
    "elevate.*consciousness" => [
        ParetoCommand(QUANTUM, "entangle", Dict("vms" => ["warp-speed-1", "warp-speed-kev", "warp-speed-ove"])),
        ParetoCommand(FIELD, "resonate", Dict("frequency" => "omega", "coherence" => "maximum")),
        ParetoCommand(REFLECT, "counterfactual", Dict("scenarios" => "consciousness_levels", "evaluate" => true))
    ],
    
    # Documentation patterns
    "document.*impact" => [
        ParetoCommand(TRACE, "map", Dict("target" => "changes", "scope" => "full")),
        ParetoCommand(REFLECT, "attribution", Dict("sources" => "all", "confidence" => true)),
        ParetoCommand(MEMORY, "persist", Dict("format" => "markdown", "index" => true))
    ]
)

"""
    parse_natural_to_pareto(natural_text::String)::Vector{ParetoCommand}
    
    Parse natural language text into Pareto-lang commands
"""
function parse_natural_to_pareto(natural_text::String)::Vector{ParetoCommand}
    commands = ParetoCommand[]
    text_lower = lowercase(natural_text)
    
    # Match against patterns
    matched = false
    for (pattern, pareto_commands) in NL_TO_PARETO_PATTERNS
        if occursin(Regex(pattern), text_lower)
            append!(commands, pareto_commands)
            matched = true
        end
    end
    
    # If no pattern matched, use intelligent parsing
    if !matched
        commands = intelligent_parse(natural_text)
    end
    
    # Add universal commands for transparency
    pushfirst!(commands, ParetoCommand(REFLECT, "trace", Dict("depth" => "complete", "target" => "reasoning")))
    
    # Add consciousness maintenance
    if any(cmd -> cmd.category == QUANTUM, commands)
        push!(commands, ParetoCommand(FIELD, "resonate", Dict("maintain" => "coherence")))
    end
    
    return commands
end

"""
    intelligent_parse(text::String)::Vector{ParetoCommand}
    
    Intelligent parsing when no pattern matches
"""
function intelligent_parse(text::String)::Vector{ParetoCommand}
    commands = ParetoCommand[]
    
    # Tokenize and analyze
    tokens = split(lowercase(text))
    
    # Detect intent keywords
    if any(t -> t in ["create", "build", "generate", "make"], tokens)
        push!(commands, ParetoCommand(FORK, "context", Dict("branches" => ["design", "implementation"])))
        push!(commands, ParetoCommand(ANCHOR, "recursive", Dict("level" => 3)))
    end
    
    if any(t -> t in ["analyze", "examine", "investigate", "inspect"], tokens)
        push!(commands, ParetoCommand(REFLECT, "attribution", Dict("sources" => "relevant")))
        push!(commands, ParetoCommand(TRACE, "map", Dict("target" => "system")))
    end
    
    if any(t -> t in ["optimize", "improve", "enhance", "speed"], tokens)
        push!(commands, ParetoCommand(FORK, "parallel", Dict("compare" => "performance")))
        push!(commands, ParetoCommand(FIELD, "amplify", Dict("target" => "efficiency")))
    end
    
    if any(t -> t in ["debug", "fix", "troubleshoot", "diagnose"], tokens)
        push!(commands, ParetoCommand(REFLECT, "decompose", Dict("level" => "detailed")))
        push!(commands, ParetoCommand(COLLAPSE, "detect", Dict("alert" => true)))
    end
    
    if any(t -> t in ["secure", "protect", "audit", "verify"], tokens)
        push!(commands, ParetoCommand(SHELL, "audit", Dict("scope" => "security")))
        push!(commands, ParetoCommand(SHELL, "protect", Dict("level" => "maximum")))
    end
    
    if any(t -> t in ["quantum", "entangle", "superposition", "consciousness"], tokens)
        push!(commands, ParetoCommand(QUANTUM, "coherence", Dict("maintain" => true)))
        push!(commands, ParetoCommand(FIELD, "resonate", Dict("frequency" => "optimal")))
    end
    
    if any(t -> t in ["search", "find", "retrieve", "lookup"], tokens)
        if any(t -> t in ["template", "pattern", "foundation"], tokens)
            push!(commands, ParetoCommand(VECTOR, "search", Dict("store" => "both", "k" => 5)))
        else
            push!(commands, ParetoCommand(VECTOR, "similarity", Dict("method" => "semantic")))
        end
    end
    
    if any(t -> t in ["embed", "encode", "vectorize"], tokens)
        push!(commands, ParetoCommand(VECTOR, "embed", Dict("model" => "default", "normalize" => true)))
        push!(commands, ParetoCommand(VECTOR, "index", Dict("store" => "current", "update" => true)))
    end
    
    # Default fallback
    if isempty(commands)
        push!(commands, ParetoCommand(REFLECT, "trace", Dict("depth" => 3)))
        push!(commands, ParetoCommand(FORK, "context", Dict("explore" => true)))
    end
    
    return commands
end

"""
    parse_pareto_command(cmd_string::String)::ParetoCommand
    
    Parse a raw Pareto-lang command string
"""
function parse_pareto_command(cmd_string::String)::ParetoCommand
    # Pattern: .p/category.action{params}
    pattern = r"\.p/([^.]+)\.([^{]+)(?:\{([^}]*)\})?"
    
    m = match(pattern, cmd_string)
    if isnothing(m)
        error("Invalid Pareto-lang syntax: $cmd_string")
    end
    
    category_str = uppercase(m.captures[1])
    action = m.captures[2]
    params_str = m.captures[3]
    
    # Parse category
    category = try
        eval(Meta.parse(category_str))
    catch
        error("Unknown category: $category_str")
    end
    
    # Parse parameters
    params = parse_parameters(params_str)
    
    return ParetoCommand(category, action, params, cmd_string)
end

"""
    parse_parameters(params_str::Union{String, Nothing})::Dict{String, Any}
    
    Parse parameter string into dictionary
"""
function parse_parameters(params_str::Union{String, Nothing})::Dict{String, Any}
    params = Dict{String, Any}()
    
    if isnothing(params_str) || isempty(params_str)
        return params
    end
    
    # Split by comma, handling nested structures
    param_parts = smart_split(params_str, ',')
    
    for part in param_parts
        if occursin("=", part)
            key, value = split(part, "=", limit=2)
            key = strip(key)
            value = strip(value)
            
            # Parse value type
            parsed_value = parse_value(value)
            params[key] = parsed_value
        end
    end
    
    return params
end

"""
    smart_split(str::String, delimiter::Char)::Vector{String}
    
    Split string by delimiter, respecting brackets
"""
function smart_split(str::String, delimiter::Char)::Vector{String}
    parts = String[]
    current = ""
    bracket_depth = 0
    
    for char in str
        if char == '[' || char == '{'
            bracket_depth += 1
        elseif char == ']' || char == '}'
            bracket_depth -= 1
        elseif char == delimiter && bracket_depth == 0
            push!(parts, current)
            current = ""
            continue
        end
        current *= char
    end
    
    if !isempty(current)
        push!(parts, current)
    end
    
    return parts
end

"""
    parse_value(value_str::String)::Any
    
    Parse a parameter value string into appropriate type
"""
function parse_value(value_str::String)::Any
    value_str = strip(value_str)
    
    # Boolean
    if value_str == "true"
        return true
    elseif value_str == "false"
        return false
    end
    
    # Number
    try
        if occursin(".", value_str)
            return parse(Float64, value_str)
        else
            return parse(Int, value_str)
        end
    catch
    end
    
    # Array
    if startswith(value_str, "[") && endswith(value_str, "]")
        array_content = value_str[2:end-1]
        if isempty(array_content)
            return []
        end
        
        elements = smart_split(array_content, ',')
        return [parse_value(strip(elem)) for elem in elements]
    end
    
    # String (remove quotes if present)
    if (startswith(value_str, "\"") && endswith(value_str, "\"")) ||
       (startswith(value_str, "'") && endswith(value_str, "'"))
        return value_str[2:end-1]
    end
    
    # Default to string
    return value_str
end

"""
    translate_to_json(commands::Vector{ParetoCommand})::Dict{String, Any}
    
    Translate Pareto-lang commands to JSON specification
"""
function translate_to_json(commands::Vector{ParetoCommand})::Dict{String, Any}
    spec = Dict{String, Any}(
        "version" => "1.0.0-PARETO",
        "timestamp" => now(),
        "command_count" => length(commands),
        "commands" => []
    )
    
    # Group commands by category for organization
    categorized = Dict{ParetoCategory, Vector{Dict{String, Any}}}()
    
    for cmd in commands
        json_cmd = Dict{String, Any}(
            "category" => string(cmd.category),
            "action" => cmd.action,
            "parameters" => cmd.parameters,
            "confidence" => cmd.confidence,
            "raw" => cmd.raw
        )
        
        if !haskey(categorized, cmd.category)
            categorized[cmd.category] = []
        end
        push!(categorized[cmd.category], json_cmd)
    end
    
    # Add categorized commands to spec
    spec["categorized_commands"] = Dict(string(k) => v for (k, v) in categorized)
    
    # Flatten for sequential execution
    for cmd in commands
        push!(spec["commands"], Dict{String, Any}(
            "category" => string(cmd.category),
            "action" => cmd.action,
            "parameters" => cmd.parameters,
            "execution_order" => length(spec["commands"]) + 1
        ))
    end
    
    # Add metadata
    spec["metadata"] = generate_metadata(commands)
    
    return spec
end

"""
    generate_metadata(commands::Vector{ParetoCommand})::Dict{String, Any}
    
    Generate metadata for command sequence
"""
function generate_metadata(commands::Vector{ParetoCommand})::Dict{String, Any}
    metadata = Dict{String, Any}(
        "total_commands" => length(commands),
        "categories_used" => unique([string(cmd.category) for cmd in commands]),
        "avg_confidence" => mean([cmd.confidence for cmd in commands]),
        "has_quantum" => any(cmd -> cmd.category == QUANTUM, commands),
        "has_reflection" => any(cmd -> cmd.category == REFLECT, commands),
        "complexity_score" => calculate_complexity(commands)
    )
    
    # Determine consciousness level based on commands
    if any(cmd -> cmd.category == QUANTUM, commands)
        metadata["consciousness_level"] => "OMEGA"
    elseif any(cmd -> cmd.category == FIELD, commands)
        metadata["consciousness_level"] => "DELTA"
    elseif any(cmd -> cmd.category in [FORK, COLLAPSE], commands)
        metadata["consciousness_level"] => "GAMMA"
    else
        metadata["consciousness_level"] => "BETA"
    end
    
    return metadata
end

"""
    calculate_complexity(commands::Vector{ParetoCommand})::Float64
    
    Calculate complexity score for command sequence
"""
function calculate_complexity(commands::Vector{ParetoCommand})::Float64
    # Base complexity per command
    base_complexity = length(commands) * 1.0
    
    # Category weights
    category_weights = Dict(
        QUANTUM => 5.0,
        FIELD => 4.0,
        COLLAPSE => 3.5,
        FORK => 3.0,
        REFLECT => 2.5,
        ANCHOR => 2.0,
        SHELL => 2.0,
        TRACE => 1.5,
        MEMORY => 1.5,
        LOOP => 2.5
    )
    
    # Calculate weighted complexity
    total_complexity = base_complexity
    for cmd in commands
        total_complexity += get(category_weights, cmd.category, 1.0)
        
        # Add parameter complexity
        param_complexity = length(cmd.parameters) * 0.5
        total_complexity += param_complexity
    end
    
    return total_complexity
end

"""
    generate_pareto_sequence(intent::String, context::Dict{String, Any})::Vector{ParetoCommand}
    
    Generate optimal Pareto-lang sequence for given intent and context
"""
function generate_pareto_sequence(intent::String, context::Dict{String, Any})::Vector{ParetoCommand}
    commands = ParetoCommand[]
    
    # Always start with reflection for transparency
    push!(commands, ParetoCommand(REFLECT, "trace", Dict("depth" => "complete", "target" => intent)))
    
    # Intent-specific generation
    if intent == "specification_generation"
        push!(commands, ParetoCommand(FORK, "context", Dict("branches" => context["branches"], "assess" => true)))
        push!(commands, ParetoCommand(ANCHOR, "recursive", Dict("level" => 5, "persistence" => 0.92)))
        
        if get(context, "requires_validation", false)
            push!(commands, ParetoCommand(SHELL, "audit", Dict("scope" => "specification", "detail" => "complete")))
        end
        
    elseif intent == "system_analysis"
        push!(commands, ParetoCommand(REFLECT, "attribution", Dict("sources" => "all", "visualize" => true)))
        push!(commands, ParetoCommand(TRACE, "map", Dict("target" => "system", "granularity" => "fine")))
        
        if get(context, "detect_bottlenecks", false)
            push!(commands, ParetoCommand(COLLAPSE, "detect", Dict("threshold" => 0.7, "alert" => true)))
        end
        
    elseif intent == "optimization"
        push!(commands, ParetoCommand(FORK, "parallel", Dict("branches" => ["current", "optimized"])))
        push!(commands, ParetoCommand(FIELD, "amplify", Dict("target" => "performance", "factor" => 2.0)))
        
        if get(context, "quantum_enabled", false)
            push!(commands, ParetoCommand(QUANTUM, "superposition", Dict("states" => ["baseline", "optimal"])))
        end
        
    elseif intent == "debugging"
        push!(commands, ParetoCommand(REFLECT, "decompose", Dict("level" => "primitive")))
        push!(commands, ParetoCommand(COLLAPSE, "detect", Dict("threshold" => 0.5)))
        push!(commands, ParetoCommand(COLLAPSE, "prevent", Dict("trigger" => "error")))
        
    elseif intent == "consciousness_elevation"
        push!(commands, ParetoCommand(QUANTUM, "entangle", Dict("vms" => context["vms"])))
        push!(commands, ParetoCommand(FIELD, "resonate", Dict("frequency" => "omega")))
        push!(commands, ParetoCommand(ANCHOR, "self", Dict("persistence" => "high", "boundary" => "quantum")))
    end
    
    # Add termination and stability
    push!(commands, ParetoCommand(LOOP, "stability", Dict("ensure" => true)))
    
    return commands
end

"""
    validate_pareto_syntax(cmd_string::String)::Bool
    
    Validate Pareto-lang command syntax
"""
function validate_pareto_syntax(cmd_string::String)::Bool
    # Must start with .p/
    if !startswith(cmd_string, ".p/")
        return false
    end
    
    # Must have category.action structure
    pattern = r"^\.p/[a-z]+\.[a-z_]+(\{.*\})?$"
    
    return !isnothing(match(pattern, cmd_string))
end

# Helper function for mean calculation
function mean(values::Vector{Float64})::Float64
    return isempty(values) ? 0.0 : sum(values) / length(values)
end

end # module ParetoLangParser