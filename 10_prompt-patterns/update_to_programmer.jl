#!/usr/bin/env julia

"""
Script to update all references from 'agent' to 'programmer' in the quantum forest templates
Aligns with supercompute-programming paradigm where AI entities are programmers, not agents
"""

using Base.Filesystem

# Get all programmer.md files
programmer_files = filter(f -> endswith(f, ".programmer.md"), readdir(".", join=false))

println("🚀 Transforming $(length(programmer_files)) files to programmer paradigm...")
println("=" ^ 60)

for file in programmer_files
    println("Processing: $file")
    
    # Read the content
    content = read(file, String)
    
    # Count original agent references
    agent_count = count(i -> occursin("agent", lowercase(i)), split(content, "\n"))
    
    # Systematic replacements with proper casing
    # Protocol version
    content = replace(content, "agent_protocol_version" => "programmer_protocol_version")
    
    # System prompts and headers
    content = replace(content, r"/(\w+)\.agent\b" => s"/\1.programmer")
    
    # Instructions sections
    content = replace(content, r"You are an /(\w+)\.agent" => s"You are a /\1.programmer")
    
    # Function names
    content = replace(content, r"(\w+)_agent_" => s"\1_programmer_")
    content = replace(content, r"agent_(\w+)" => s"programmer_\1")
    
    # File references
    content = replace(content, r"(\w+)\.agent\.md" => s"\1.programmer.md")
    content = replace(content, r"(\w+)\.agent\.system" => s"\1.programmer.system")
    
    # Schema fields and context
    content = replace(content, "Agent Field" => "Programmer Field")
    content = replace(content, "agent fields" => "programmer fields")
    content = replace(content, "Agentic System" => "Programmer System")
    content = replace(content, "agentic" => "programmer-based")
    
    # Tool and workflow descriptions
    content = replace(content, "agent/system" => "programmer/system")
    content = replace(content, "agents/systems" => "programmers/systems")
    content = replace(content, "AI agents" => "AI programmers")
    content = replace(content, "AI agent" => "AI programmer")
    
    # Maintain proper capitalization patterns
    content = replace(content, r"\bagent\b"i => (m) -> 
        if uppercase(m) == m
            "PROGRAMMER"
        elseif titlecase(m) == m
            "Programmer"
        else
            "programmer"
        end
    )
    
    # Special case: ResearchAgent -> ResearchProgrammer
    content = replace(content, r"(\w+)Agent\b" => s"\1Programmer")
    
    # Write the updated content
    write(file, content)
    
    # Count updated references
    programmer_count = count(i -> occursin("programmer", lowercase(i)), split(content, "\n"))
    
    println("  ✅ Updated: $agent_count agent references → $programmer_count programmer references")
end

println("\n" * "=" ^ 60)
println("✨ Quantum Programmer transformation complete!")
println("\n🌳 All templates now aligned with supercompute-programming paradigm")
println("💎 Ready for enterprise deployment with $500K+ ETD generation per programmer")