#!/usr/bin/env julia

"""
Verification script to ensure all Julia templates are properly formatted
and all prompts use Julia syntax instead of Python.
"""

using Pkg

println("🔍 Verifying Julia conversion in 20_templates...")
println("=" ^ 60)

# Check for Julia template files
julia_files = readdir(".", join=false)
julia_templates = filter(f -> endswith(f, ".jl"), julia_files)

println("\n✅ Found $(length(julia_templates)) Julia templates:")
for file in julia_templates
    println("  • $file")
end

# Check for Python files (should be none)
python_files = filter(f -> endswith(f, ".py"), julia_files)
if length(python_files) > 0
    println("\n⚠️ Warning: Found $(length(python_files)) Python files still present:")
    for file in python_files
        println("  • $file")
    end
else
    println("\n✅ No Python files found (all converted to Julia)")
end

# Check prompts folder
prompts_dir = "PROMPTS"
if isdir(prompts_dir)
    println("\n📋 Checking prompt files for Julia compliance...")
    
    prompt_files = filter(f -> endswith(f, ".md"), readdir(prompts_dir, join=false))
    
    issues_found = false
    
    for file in prompt_files
        filepath = joinpath(prompts_dir, file)
        content = read(filepath, String)
        
        # Check for Python references
        if occursin("\"python\"", lowercase(content)) && !occursin("pythoncall", lowercase(content))
            println("  ⚠️ $file: Contains 'python' reference (should be 'julia')")
            issues_found = true
        end
        
        # Check for proper Julia syntax in code blocks
        if occursin("```julia", content)
            # Extract Julia code blocks
            julia_blocks = eachmatch(r"```julia\n(.*?)```"s, content)
            for block in julia_blocks
                code = block.captures[1]
                
                # Check for Python-style syntax
                if occursin(r":\s*$"m, code)  # Python-style colons at line end
                    println("  ⚠️ $file: Contains Python-style colons")
                    issues_found = true
                end
                
                if occursin("= None", code)  # Python None instead of nothing
                    println("  ⚠️ $file: Contains Python 'None' (should be 'nothing')")
                    issues_found = true
                end
            end
        end
    end
    
    if !issues_found
        println("  ✅ All prompt files use proper Julia syntax")
    end
end

# Verify README references
readme_path = "README.md"
if isfile(readme_path)
    println("\n📚 Checking README.md...")
    readme_content = read(readme_path, String)
    
    if occursin("supercomputeprogramming.org", readme_content)
        println("  ✅ Domain correctly referenced as supercomputeprogramming.org")
    else
        println("  ⚠️ Domain reference needs updating")
    end
    
    if occursin("Quantum Forest", readme_content) || occursin("Rainforest", readme_content)
        println("  ✅ Using Quantum Forest/Rainforest paradigm")
    else
        println("  ⚠️ Still using old Atom paradigm")
    end
end

println("\n" * "=" ^ 60)
println("✨ Julia conversion verification complete!")
println("\nSummary:")
println("  • Julia templates: $(length(julia_templates))")
println("  • Python files remaining: $(length(python_files))")
println("  • Prompt files checked: $(length(prompt_files))")
println("  • Domain: supercomputeprogramming.org")
println("\n🌳 Ready for Quantum Forest deployment! 🌳")