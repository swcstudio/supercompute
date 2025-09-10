#!/usr/bin/env julia

"""
Verification script to ensure complete transformation from agent to programmer paradigm
"""

println("🔍 Verifying Quantum Programmer Transformation...")
println("=" ^ 60)

# Check for .programmer.md files
programmer_files = filter(f -> endswith(f, ".programmer.md"), readdir(".", join=false))
println("\n✅ Found $(length(programmer_files)) programmer templates")

# Check for any remaining .agent.md files
agent_files = filter(f -> endswith(f, ".agent.md"), readdir(".", join=false))
if length(agent_files) > 0
    println("⚠️  Warning: Found $(length(agent_files)) remaining .agent.md files:")
    for file in agent_files
        println("  • $file")
    end
else
    println("✅ No .agent.md files remaining (all converted)")
end

# Check content of programmer files for proper updates
println("\n📋 Checking programmer files for proper content updates...")
issues = []

for file in programmer_files
    content = read(file, String)
    
    # Check for programmer_protocol_version
    if occursin("programmer_protocol_version", content)
        # Good - properly updated
    elseif occursin("agent_protocol_version", content)
        push!(issues, "$file: Still contains 'agent_protocol_version'")
    end
    
    # Check for system prompt updates
    if occursin(r"/\w+\.programmer\b", content)
        # Good - properly updated
    elseif occursin(r"/\w+\.agent\b", content)
        push!(issues, "$file: Still contains '.agent' system prompts")
    end
end

if length(issues) > 0
    println("⚠️  Found $(length(issues)) issues:")
    for issue in issues
        println("  • $issue")
    end
else
    println("✅ All programmer files properly updated")
end

# Check README.md
println("\n📚 Checking README.md...")
readme_content = read("README.md", String)

readme_checks = [
    ("ETD per programmer", occursin("ETD-\$500K%2B%20per%20programmer", readme_content)),
    ("Programmer Protocol Templates", occursin("Programmer Protocol Templates", readme_content)),
    ("Programmer file references", occursin(".programmer.md", readme_content)),
    ("No .agent.md references", !occursin(".agent.md", readme_content))
]

for (check_name, passed) in readme_checks
    if passed
        println("  ✅ $check_name")
    else
        println("  ⚠️  $check_name - needs attention")
    end
end

# Summary
println("\n" * "=" ^ 60)
println("✨ Verification Summary:")
println("  • Programmer templates: $(length(programmer_files))")
println("  • Agent files remaining: $(length(agent_files))")
println("  • Content issues: $(length(issues))")
println("\n🌳 Quantum Programmer Paradigm Status: $(length(agent_files) == 0 && length(issues) == 0 ? "READY" : "NEEDS ATTENTION")")
println("💎 Enterprise ETD Generation Potential: \$500K-\$2M per programmer annually")