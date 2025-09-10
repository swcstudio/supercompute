module SupercomputerProgramming

# Core Julia imports
using DataFrames
using Statistics
using LinearAlgebra
using Random
using Distributed

# Python interoperability
using PythonCall

# Web3 and blockchain
using HTTP
using JSON3
using SHA

# Graph and network analysis
using Graphs
using MetaGraphs

# Export main modules
export RainforestCore, QuantumDynamics, BlockchainIntegration, DemonstrationLearning

# Include submodules
include("core/rainforest_core.jl")
include("quantum/quantum_dynamics.jl")
include("blockchain/blockchain_integration.jl")
include("learning/demonstration_learning.jl")
include("utils/python_bridge.jl")

# Module initialization
function __init__()
    # Initialize Python environment if needed
    PythonBridge.initialize_python_env()
    
    # Set up blockchain connections
    BlockchainIntegration.initialize_networks()
    
    # Warm up quantum simulators
    QuantumDynamics.initialize_quantum_backend()
    
    @info "SupercomputerProgramming initialized - The Rainforest Awakens 🌳"
end

end # module