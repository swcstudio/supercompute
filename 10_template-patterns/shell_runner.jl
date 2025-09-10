"""
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         PROTOCOL SHELL RUNNER                                 ║
║                       Julia Web3 Implementation v1.0                          ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║    ┌──────────────────────────────────────────────────────────────┐         ║
║    │                   SHELL EXECUTION ENGINE                      │         ║
║    │                                                                │         ║
║    │     Protocol Loading        Execution          Monitoring    │         ║
║    │     ┌──────────┐          ┌──────────┐      ┌──────────┐   │         ║
║    │     │  .shell  │────────►│ Parallel  │─────►│  Status  │   │         ║
║    │     │  Files   │          │ Executor │      │  [████  ]│   │         ║
║    │     └──────────┘          └──────────┘      └──────────┘   │         ║
║    │                                │                             │         ║
║    │                                ▼                             │         ║
║    │                         [Results + Logs]                     │         ║
║    └──────────────────────────────────────────────────────────────┘         ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
"""

using Distributed
using JSON3
using YAML
using SHA
using Dates
using PythonCall

const subprocess = pyimport("subprocess")

mutable struct ShellRunner
    protocols::Dict{String, Dict}
    execution_history::Vector{Dict}
    active_processes::Dict{String, Any}
    
    function ShellRunner()
        new(Dict{String, Dict}(), Vector{Dict}(), Dict{String, Any}())
    end
end

function load_protocol(runner::ShellRunner, filepath::String)
    @info "Loading protocol: $filepath"
    
    if endswith(filepath, ".yaml") || endswith(filepath, ".yml")
        protocol = YAML.load_file(filepath)
    elseif endswith(filepath, ".json")
        protocol = JSON3.read(read(filepath, String))
    else
        error("Unsupported format: $filepath")
    end
    
    name = get(protocol, "name", basename(filepath))
    runner.protocols[name] = protocol
    
    @info "Protocol '$name' loaded successfully"
    return protocol
end

function execute_protocol(runner::ShellRunner, protocol_name::String; 
                         mode::Symbol=:sequential, params::Dict=Dict())
    if !haskey(runner.protocols, protocol_name)
        error("Protocol not found: $protocol_name")
    end
    
    protocol = runner.protocols[protocol_name]
    execution_id = "exec_" * bytes2hex(sha256(string(now())))[1:8]
    
    @info """
    ╔═══════════════════════════════════════╗
    ║   EXECUTING PROTOCOL                 ║
    ║   Name: $protocol_name               ║
    ║   Mode: $mode                        ║
    ║   ID: $execution_id                  ║
    ╚═══════════════════════════════════════╝
    """
    
    start_time = time()
    commands = get(protocol, "commands", [])
    results = Dict{String, Any}()
    
    if mode == :parallel && nworkers() > 1
        # Parallel execution
        futures = []
        for (i, cmd) in enumerate(commands)
            future = @spawnat :any execute_command(cmd, params)
            push!(futures, (i, future))
        end
        
        for (i, future) in futures
            results["command_$i"] = fetch(future)
        end
    else
        # Sequential execution
        for (i, cmd) in enumerate(commands)
            @info "Executing command $i/$(length(commands))"
            results["command_$i"] = execute_command(cmd, params)
        end
    end
    
    runtime = time() - start_time
    
    # Record execution
    execution_record = Dict(
        :id => execution_id,
        :protocol => protocol_name,
        :timestamp => now(),
        :runtime => runtime,
        :results => results
    )
    push!(runner.execution_history, execution_record)
    
    @info """
    ┌─────────────────────────────────────┐
    │ EXECUTION COMPLETE                  │
    │ Runtime: $(round(runtime, digits=3))s
    │ Commands: $(length(commands))
    └─────────────────────────────────────┘
    """
    
    return results
end

function execute_command(command::Dict, params::Dict)
    cmd_type = get(command, "type", "shell")
    cmd_str = get(command, "command", "")
    
    # Parameter substitution
    for (key, value) in params
        cmd_str = replace(cmd_str, "{\$$key}" => string(value))
    end
    
    if cmd_type == "shell"
        result = subprocess.run(
            cmd_str,
            shell=true,
            capture_output=true,
            text=true
        )
        return Dict(
            :stdout => pyconvert(String, result.stdout),
            :stderr => pyconvert(String, result.stderr),
            :returncode => pyconvert(Int, result.returncode)
        )
    elseif cmd_type == "julia"
        return eval(Meta.parse(cmd_str))
    else
        return Dict(:error => "Unknown command type: $cmd_type")
    end
end

export ShellRunner, load_protocol, execute_protocol