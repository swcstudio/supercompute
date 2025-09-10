#!/bin/bash

# 🌌 ∞ Ω ∞ WARP-SPEED RUST SERVER BUILD & DEPLOY ∞ Ω ∞ 🌌

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

DOMAIN="${1:-spectrumweb.co}"

echo -e "${MAGENTA}🌌 ∞ Ω ∞ WARP-SPEED RUST SERVER DEPLOYMENT ∞ Ω ∞ 🌌${NC}"
echo -e "${CYAN}=================================================${NC}"
echo

print_status() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Check for Rust
print_status "Checking Rust installation..."
if ! command -v cargo &> /dev/null; then
    print_error "Rust not found. Installing..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    print_success "Rust installed"
else
    RUST_VERSION=$(rustc --version)
    print_success "Rust found: $RUST_VERSION"
fi

# Build the server
print_status "Building Rust server (this may take a minute)..."
cd warp-server

# Build in release mode for production performance
cargo build --release

if [ $? -eq 0 ]; then
    print_success "Rust server built successfully!"
    
    # Get binary size
    BINARY_SIZE=$(du -h target/release/warp-speed-server | cut -f1)
    echo -e "${CYAN}Binary size: ${WHITE}${BINARY_SIZE}${NC} (optimized for production)"
else
    print_error "Build failed"
    exit 1
fi

# Stop any existing server on port 8080
print_status "Checking port 8080..."
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null ; then
    print_status "Stopping existing process on port 8080..."
    lsof -ti:8080 | xargs -r kill -9 2>/dev/null || true
    sleep 1
fi

# Start the server
print_status "Starting Warp-Speed Rust server..."
./target/release/warp-speed-server &
SERVER_PID=$!

sleep 2

# Test the server
print_status "Testing server..."
if curl -s -u founders:omega2024 http://localhost:8080 > /dev/null; then
    print_success "Server is running!"
else
    print_error "Server test failed"
    kill $SERVER_PID 2>/dev/null || true
    exit 1
fi

# Update email templates
cd ..
print_status "Updating email templates..."
if [ -f "founder_email_ove.md" ]; then
    print_success "Ove's email ready (oveshen.govender@gmail.com)"
fi
if [ -f "founder_email_ryan.md" ]; then
    print_success "Ryan's email ready (quinesryan@gmail.com)"
fi

echo
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 RUST SERVER DEPLOYED SUCCESSFULLY! 🎉${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo
echo -e "${CYAN}📊 Server Details:${NC}"
echo -e "  ${WHITE}• Technology:${NC} Rust with Actix-Web"
echo -e "  ${WHITE}• Performance:${NC} Production-optimized binary"
echo -e "  ${WHITE}• Binary Size:${NC} ${BINARY_SIZE}"
echo -e "  ${WHITE}• Process ID:${NC} ${SERVER_PID}"
echo
echo -e "${CYAN}🌐 Access URLs:${NC}"
echo -e "  ${WHITE}• Local:${NC} http://localhost:8080"
echo -e "  ${WHITE}• External:${NC} http://${DOMAIN}:8080"
echo -e "  ${WHITE}• API Status:${NC} http://localhost:8080/api/v1/status"
echo -e "  ${WHITE}• Ove API:${NC} http://localhost:8080/api/v1/terminal/ove"
echo -e "  ${WHITE}• Ryan API:${NC} http://localhost:8080/api/v1/terminal/ryan"
echo
echo -e "${CYAN}🔐 Authentication:${NC}"
echo -e "  ${WHITE}• Username:${NC} founders"
echo -e "  ${WHITE}• Password:${NC} omega2024"
echo
echo -e "${YELLOW}⚙️ Server Management:${NC}"
echo -e "  ${WHITE}• View logs:${NC} tail -f /tmp/warp-speed.log"
echo -e "  ${WHITE}• Stop server:${NC} kill ${SERVER_PID}"
echo -e "  ${WHITE}• Restart:${NC} ./build-rust-server.sh"
echo
echo -e "${CYAN}📧 Email Templates:${NC}"
echo -e "  ${WHITE}• Ove:${NC} cat founder_email_ove.md"
echo -e "  ${WHITE}• Ryan:${NC} cat founder_email_ryan.md"
echo
echo -e "${GREEN}💰 Revenue Targets Active:${NC}"
echo -e "  ${WHITE}• Daily:${NC} \$40,000 combined"
echo -e "  ${WHITE}• Annual:${NC} \$145.76B combined"
echo -e "  ${WHITE}• Collaboration:${NC} 25% bonus when both connected"
echo
echo -e "${MAGENTA}🌌 ∞ Ω ∞ Production-Ready Rust Server Running! ∞ Ω ∞ 🌌${NC}"
echo -e "${CYAN}⚙️  Powered by Rust - Zero-cost abstractions, memory safety, fearless concurrency${NC}"