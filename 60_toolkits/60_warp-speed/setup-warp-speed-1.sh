#!/bin/bash

# Warp-Speed VM Instance 1 Setup Script
# Part of the Supercompute Dissertation Research
# Co-authors: Kev (Software Engineering) & Research Team

echo "
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║     🌌  WARP-SPEED VM INSTANCE 1 - INITIALIZATION  🌌               ║
║                                                                       ║
║     Quantum Consciousness: OMEGA                                     ║
║     ETD Potential: \$145.76B+                                         ║
║     Research Mode: ACTIVE                                            ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
"

# Set environment variables for VM Instance 1
export WARP_INSTANCE=1
export WARP_INSTANCE_NAME="warp-speed-1"
export WARP_PORT=8080
export WARP_GRPC_PORT=9090
export WARP_WEBSOCKET_PORT=8085

# Shared inference endpoint
export INFERENCE_ENDPOINT="http://localhost:11434"
export INFERENCE_MODEL="qwen2.5:latest"

# Database connections
export DRAGONFLY_URL="redis://localhost:6379/0"
export SPACETIME_URL="http://localhost:3000"
export TIMESCALE_URL="postgresql://quantum:omega_consciousness_2025@localhost:5432/warpspeed"
export PGVECTOR_URL="postgresql://quantum:omega_consciousness_2025@localhost:5433/warpvector"
export MONGODB_URL="mongodb://warpspeed_app:quantum_app_2025@localhost:27017/warpspeed"

# CUDA configuration for GPU 0
export CUDA_VISIBLE_DEVICES=0
export CUDA_DEVICE_ORDER="PCI_BUS_ID"
export TF_FORCE_GPU_ALLOW_GROWTH=true

# Quantum consciousness settings
export CONSCIOUSNESS_DEFAULT_LEVEL="OMEGA"
export QUANTUM_COHERENCE=0.97
export SUPERPOSITION_MAINTENANCE=true
export ETD_BASE_VALUE=45000

# Memory allocation (15GB for VM1)
export JAVA_OPTS="-Xmx15g -Xms2g -XX:+UseG1GC -XX:ParallelGCThreads=3"
export JULIA_NUM_THREADS=3

# Workspace configuration
export WARPSPEED_WORKSPACE="/purplehat/vm1"
export WARPSPEED_LOGS="/purplehat/logs/vm1"

# Create necessary directories
mkdir -p $WARPSPEED_WORKSPACE
mkdir -p $WARPSPEED_LOGS
mkdir -p /purplehat/models/vm1
mkdir -p /purplehat/checkpoints/vm1

# Academic research settings
export RESEARCH_MODE=true
export CO_AUTHOR="Kev"
export DISSERTATION_CHAPTER="7"
export ACADEMIC_PURPOSE="Applied Scientific Programming Research"

# Blockchain education settings
export BLOCKCHAIN_TESTNET_ONLY=true
export ANOMA_ENDPOINT="http://localhost:26657"
export EDUCATIONAL_MODE=true

# Function to check dependencies
check_dependencies() {
    echo "⚡ Checking dependencies for VM Instance 1..."
    
    # Check Java
    if command -v java &> /dev/null; then
        echo "✓ Java installed: $(java -version 2>&1 | head -n 1)"
    else
        echo "✗ Java not found. Please install Java 21+"
        exit 1
    fi
    
    # Check Julia
    if command -v julia &> /dev/null; then
        echo "✓ Julia installed: $(julia --version)"
    else
        echo "⚠ Julia not found. Some features will be limited"
    fi
    
    # Check CUDA
    if command -v nvidia-smi &> /dev/null; then
        echo "✓ CUDA available:"
        nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
    else
        echo "⚠ CUDA not available. GPU acceleration disabled"
    fi
    
    # Check Podman
    if command -v podman &> /dev/null; then
        echo "✓ Podman installed: $(podman --version)"
    else
        echo "✗ Podman not found. Please install Podman"
        exit 1
    fi
}

# Function to start databases
start_databases() {
    echo "🔌 Starting database services..."
    
    cd /home/ubuntu/src/repos/supercompute/60_toolkits/60_warp-speed
    
    # Start containers with Podman Compose
    podman-compose up -d
    
    # Wait for databases to be ready
    echo "⏳ Waiting for databases to initialize..."
    sleep 10
    
    # Check database connectivity
    echo "✓ Databases started successfully"
}

# Function to initialize Julia environment
init_julia() {
    echo "🔮 Initializing Julia environment for VM1..."
    
    cd /home/ubuntu/src/repos/supercompute
    
    # Create VM1-specific Julia project
    julia -e '
        using Pkg
        Pkg.activate("vm1")
        Pkg.add(["HTTP", "JSON3", "CUDA", "Flux", "Yao"])
        println("✓ Julia packages installed for VM1")
    '
}

# Function to compile Java application
compile_java() {
    echo "☕ Compiling Warp-Speed Java application..."
    
    cd /home/ubuntu/src/repos/supercompute/60_toolkits/60_warp-speed
    
    # Build with Maven
    mvn clean compile
    
    echo "✓ Java application compiled"
}

# Function to start Warp-Speed VM1
start_warpspeed() {
    echo "🚀 Starting Warp-Speed VM Instance 1..."
    
    cd /home/ubuntu/src/repos/supercompute/60_toolkits/60_warp-speed
    
    # Start the application
    nohup mvn spring-boot:run \
        -Dspring.profiles.active=vm1 \
        -Dserver.port=$WARP_PORT \
        > $WARPSPEED_LOGS/warpspeed-vm1.log 2>&1 &
    
    echo $! > /purplehat/warpspeed-vm1.pid
    
    echo "✓ Warp-Speed VM1 started (PID: $(cat /purplehat/warpspeed-vm1.pid))"
    echo "📊 Logs: tail -f $WARPSPEED_LOGS/warpspeed-vm1.log"
    echo "🌐 Web Interface: http://localhost:$WARP_PORT"
}

# Function to display status
show_status() {
    echo "
╔═══════════════════════════════════════════════════════════════════════╗
║                    VM INSTANCE 1 STATUS                              ║
╠═══════════════════════════════════════════════════════════════════════╣
║  Instance ID: 1                                                      ║
║  Port: $WARP_PORT                                                    ║
║  GPU: CUDA Device 0                                                  ║
║  Memory: 15GB                                                        ║
║  Threads: 3                                                          ║
║  Consciousness: OMEGA                                                ║
║  ETD Base: \$45K                                                      ║
║  Research Mode: ACTIVE                                               ║
║  Co-author: Kev                                                      ║
╚═══════════════════════════════════════════════════════════════════════╝
"
}

# Main execution
main() {
    check_dependencies
    start_databases
    init_julia
    compile_java
    start_warpspeed
    show_status
}

# Run main function
main

echo "
🌟 Warp-Speed VM Instance 1 initialization complete!
💎 ETD Generation: ACTIVE
🔬 Research Mode: ENABLED
📚 Academic Contribution: Supercompute Dissertation Chapter 7
"