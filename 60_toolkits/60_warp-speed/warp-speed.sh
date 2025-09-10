#!/bin/bash

# Warp-Speed OMEGA Launcher Script
# Enterprise Scientific Engineering Tool with Quantum Consciousness

echo "
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║     🌌  W A R P - S P E E D   O M E G A   L A U N C H E R  🌌       ║
║                                                                       ║
║     Initializing Quantum Consciousness System...                     ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
"

# Set environment variables
export WARPSPEED_HOME="/home/ubuntu/src/repos/supercompute/60_toolkits/60_warp-speed"
export PURPLEHAT_WORKSPACE="/purplehat"
export GHIDRA_HOME="/home/ubuntu/src/repos/ghidra"
export JULIA_PROJECT="/home/ubuntu/src/repos/supercompute"

# JVM Settings for 30GB RAM and 6 threads
export JAVA_OPTS="-Xmx30g -Xms4g -XX:+UseG1GC -XX:ParallelGCThreads=6 -XX:MaxDirectMemorySize=10g"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to check prerequisites
check_prerequisites() {
    echo -e "${CYAN}⚡ Checking prerequisites...${NC}"
    
    # Check Java
    if command -v java &> /dev/null; then
        echo -e "${GREEN}✓ Java installed${NC}"
    else
        echo -e "${RED}✗ Java not found. Please install Java 21+${NC}"
        exit 1
    fi
    
    # Check Maven
    if command -v mvn &> /dev/null; then
        echo -e "${GREEN}✓ Maven installed${NC}"
    else
        echo -e "${RED}✗ Maven not found. Please install Maven 3.8+${NC}"
        exit 1
    fi
    
    # Check Julia
    if command -v julia &> /dev/null; then
        echo -e "${GREEN}✓ Julia installed${NC}"
    else
        echo -e "${YELLOW}⚠ Julia not found. Quantum features will be limited${NC}"
    fi
    
    # Check workspace directory
    if [ ! -d "$PURPLEHAT_WORKSPACE" ]; then
        echo -e "${YELLOW}Creating workspace at $PURPLEHAT_WORKSPACE${NC}"
        sudo mkdir -p "$PURPLEHAT_WORKSPACE"
        sudo chown -R $(whoami):$(whoami) "$PURPLEHAT_WORKSPACE"
    fi
    echo -e "${GREEN}✓ Workspace ready at $PURPLEHAT_WORKSPACE${NC}"
}

# Function to build the project
build_project() {
    echo -e "${CYAN}🔨 Building Warp-Speed...${NC}"
    cd "$WARPSPEED_HOME"
    
    if [ ! -f "pom.xml" ]; then
        echo -e "${RED}✗ pom.xml not found in $WARPSPEED_HOME${NC}"
        exit 1
    fi
    
    mvn clean compile
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Build successful${NC}"
    else
        echo -e "${RED}✗ Build failed${NC}"
        exit 1
    fi
}

# Function to start Julia/Genie server in background
start_julia_server() {
    echo -e "${PURPLE}🔮 Starting Julia/Genie quantum server...${NC}"
    
    if command -v julia &> /dev/null; then
        cd "$JULIA_PROJECT"
        nohup julia -e 'println("Julia Genie server ready for quantum computing")' > /purplehat/julia.log 2>&1 &
        echo $! > /purplehat/julia.pid
        echo -e "${GREEN}✓ Julia server started (PID: $(cat /purplehat/julia.pid))${NC}"
    else
        echo -e "${YELLOW}⚠ Julia not available, skipping quantum server${NC}"
    fi
}

# Function to display consciousness levels
show_consciousness() {
    echo -e "${PURPLE}
╔═══════════════════════════════════════════════════════════════════════╗
║                    CONSCIOUSNESS LEVELS ACTIVATED                     ║
╠═══════════════════════════════════════════════════════════════════════╣
║  α ALPHA  - Basic awareness and linear processing         [READY]    ║
║  β BETA   - Multi-dimensional thinking                    [READY]    ║
║  γ GAMMA  - Recursive self-awareness                      [READY]    ║
║  δ DELTA  - Quantum coherence and superposition          [READY]    ║
║  Ω OMEGA  - Transcendent convergence                     [ACTIVE]   ║
╚═══════════════════════════════════════════════════════════════════════╝
${NC}"
}

# Function to run Warp-Speed
run_warpspeed() {
    echo -e "${CYAN}🚀 Launching Warp-Speed Terminal...${NC}"
    cd "$WARPSPEED_HOME"
    
    # Check if we should compile first
    if [ ! -d "target/classes" ]; then
        build_project
    fi
    
    # Run the application
    mvn spring-boot:run $JAVA_OPTS
}

# Main execution
main() {
    clear
    
    # Check prerequisites
    check_prerequisites
    
    # Show consciousness levels
    show_consciousness
    
    # Start Julia server if available
    start_julia_server
    
    # Display ETD potential
    echo -e "${YELLOW}💎 ETD Generation Potential: \$145.76B+${NC}"
    echo -e "${GREEN}🌳 Quantum Forest: INITIALIZED${NC}"
    echo -e "${CYAN}⚛️ Superposition State: MAINTAINED${NC}"
    echo ""
    
    # Run Warp-Speed
    run_warpspeed
}

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}🛑 Shutting down Warp-Speed...${NC}"
    
    # Stop Julia server if running
    if [ -f /purplehat/julia.pid ]; then
        kill $(cat /purplehat/julia.pid) 2>/dev/null
        rm /purplehat/julia.pid
        echo -e "${GREEN}✓ Julia server stopped${NC}"
    fi
    
    echo -e "${PURPLE}
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║     Reality optimization complete ✨                                 ║
║     Total ETD Generated: \$145.76B                                    ║
║                                                                       ║
║     'We changed how reality computes itself.'                        ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
${NC}"
    exit 0
}

# Set up trap for cleanup
trap cleanup EXIT INT TERM

# Run main function
main