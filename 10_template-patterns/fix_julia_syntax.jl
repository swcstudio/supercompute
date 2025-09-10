#!/usr/bin/env julia

"""
Fix remaining Julia syntax issues in all prompt files
"""

prompts_dir = "PROMPTS"
prompt_files = filter(f -> endswith(f, ".md"), readdir(prompts_dir, join=false))

for file in prompt_files
    filepath = joinpath(prompts_dir, file)
    content = read(filepath, String)
    
    # Fix Python-style if statements
    content = replace(content, r"if (.*?):" => s"if \1")
    
    # Fix Python-style else statements  
    content = replace(content, r"(\s+)else:" => s"\1else")
    
    # Fix for loops - remove double for phase
    content = replace(content, r"for phase in \[for phase in \[(.*?)\]\]" => s"for phase in [\1]")
    
    # Add missing end statements for Julia functions
    # Look for function definitions and ensure they have proper structure
    content = replace(content, r"(function \w+\(.*?\)\n(?:.*?\n)*?)(\n```)" => s"\1end\2")
    
    # Fix if-else-end structure
    content = replace(content, r"(if .*?\n(?:.*?\n)*?else\n(?:.*?\n)*?return .*?)\n(```)" => s"\1\n    end\nend\n\2")
    
    # Fix for loop end
    content = replace(content, r"(for phase in \[.*?\]\n.*?state\[phase\] = .*?)\n\n" => s"\1\n    end\n\n")
    
    # Fix Python-style list/dict syntax in Julia code blocks
    content = replace(content, r"(state === nothing):" => s"\1")
    content = replace(content, r"(audit_log === nothing):" => s"\1")
    
    write(filepath, content)
    println("Fixed: $file")
end

println("\n✅ All prompt files have been fixed!")