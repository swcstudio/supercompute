#!/usr/bin/env julia
"""
    Simple User Prompt Enhancer Module
    
    Transforms user prompts without circular dependencies
"""
module UserPromptEnhancerSimple

using JSON3
using Dates

export enhance_user_prompt_simple, suggest_slash_command_simple

# Simplified slash command registry
const SLASH_COMMANDS = [
    "alignment", "research", "architect", "optimize", "security",
    "data", "test", "refactor", "document", "deploy",
    "monitor", "migrate", "analyze", "automate", "benchmark", "integrate"
]

"""
    enhance_user_prompt_simple(prompt::String, context::Dict)
    
    Simplified prompt enhancement without circular dependencies
"""
function enhance_user_prompt_simple(prompt::String, context::Dict)
    enhanced = copy(context)
    enhanced["prompt"] = prompt
    enhanced["enhanced"] = true
    enhanced["timestamp"] = now()
    
    # Check for slash command
    if startswith(strip(prompt), "/")
        parts = split(strip(prompt), " ", limit=2)
        command = replace(parts[1], "/" => "")
        
        if command in SLASH_COMMANDS
            enhanced["slash_command_detected"] = command
            enhanced["command_valid"] = true
            
            # Parse arguments if present
            if length(parts) > 1
                enhanced["command_args"] = parts[2]
            end
        else
            enhanced["slash_command_detected"] = command
            enhanced["command_valid"] = false
            enhanced["suggestions"] = suggest_similar_commands(command)
        end
    else
        # Suggest relevant commands based on content
        suggestions = suggest_slash_command_simple(prompt)
        if !isempty(suggestions)
            enhanced["suggested_commands"] = suggestions
        end
    end
    
    # Add v7.0 patterns
    enhanced["context_version"] = "7.0"
    enhanced["patterns"] = [
        "context_engineering_active",
        "field_resonance_enabled",
        "julia_hpc_optimization"
    ]
    
    return enhanced
end

"""
    suggest_slash_command_simple(prompt::String)
    
    Suggest relevant slash commands based on prompt content
"""
function suggest_slash_command_simple(prompt::String)
    prompt_lower = lowercase(prompt)
    suggestions = String[]
    
    # Simple keyword matching
    if occursin("safety", prompt_lower) || occursin("security", prompt_lower)
        push!(suggestions, "alignment")
        push!(suggestions, "security")
    end
    
    if occursin("research", prompt_lower) || occursin("explore", prompt_lower)
        push!(suggestions, "research")
        push!(suggestions, "analyze")
    end
    
    if occursin("build", prompt_lower) || occursin("design", prompt_lower)
        push!(suggestions, "architect")
    end
    
    if occursin("test", prompt_lower)
        push!(suggestions, "test")
        push!(suggestions, "benchmark")
    end
    
    if occursin("optimize", prompt_lower) || occursin("performance", prompt_lower)
        push!(suggestions, "optimize")
        push!(suggestions, "benchmark")
    end
    
    if occursin("refactor", prompt_lower) || occursin("clean", prompt_lower)
        push!(suggestions, "refactor")
    end
    
    if occursin("document", prompt_lower) || occursin("docs", prompt_lower)
        push!(suggestions, "document")
    end
    
    if occursin("deploy", prompt_lower) || occursin("release", prompt_lower)
        push!(suggestions, "deploy")
    end
    
    return unique(suggestions)
end

"""
    suggest_similar_commands(input::String)
    
    Find similar commands using simple character overlap
"""
function suggest_similar_commands(input::String)
    similar = String[]
    input_lower = lowercase(input)
    
    for cmd in SLASH_COMMANDS
        # Check if command starts with same letter
        if !isempty(input_lower) && !isempty(cmd) && 
           lowercase(first(cmd)) == lowercase(first(input_lower))
            push!(similar, cmd)
        end
    end
    
    # If no matches, try substring match
    if isempty(similar)
        for cmd in SLASH_COMMANDS
            if occursin(input_lower, cmd) || occursin(cmd, input_lower)
                push!(similar, cmd)
            end
        end
    end
    
    return similar[1:min(3, length(similar))]
end

end # module