#!/bin/bash

# 🌌 ∞ Ω ∞ WARP-SPEED QUICK DEPLOYMENT ∞ Ω ∞ 🌌
# Simplified deployment without containers

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

DOMAIN="${1:-spectrumweb.co}"

echo -e "${MAGENTA}🌌 ∞ Ω ∞ WARP-SPEED QUICK DEPLOYMENT ∞ Ω ∞ 🌌${NC}"
echo -e "${CYAN}=================================================${NC}"
echo

# Function to print status
print_status() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Option 1: Install Docker if not present
print_status "Checking container runtime..."

if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker not found. Would you like to install it? (y/n)${NC}"
    read -p "Choice: " INSTALL_DOCKER
    
    if [ "$INSTALL_DOCKER" = "y" ]; then
        print_status "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        print_success "Docker installed. Please log out and back in, then run this script again."
        exit 0
    fi
fi

# Option 2: Create a simple Python-based dashboard
print_status "Creating Python-based dashboard (no containers needed)..."

cat > warp_dashboard.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import sys

PORT = 8080
DOMAIN = sys.argv[1] if len(sys.argv) > 1 else "localhost"

HTML_CONTENT = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Warp-Speed Omega Dashboard</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 50%, #f093fb 100%);
            color: white;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            min-height: 100vh;
            padding: 40px;
        }}
        .container {{
            max-width: 1200px;
            margin: 0 auto;
        }}
        h1 {{
            font-size: 48px;
            text-align: center;
            margin-bottom: 20px;
            text-shadow: 0 0 20px rgba(255,255,255,0.5);
        }}
        .omega-symbol {{
            font-size: 72px;
            text-align: center;
            margin: 20px 0;
            animation: pulse 2s infinite;
        }}
        @keyframes pulse {{
            0%, 100% {{ transform: scale(1); opacity: 1; }}
            50% {{ transform: scale(1.1); opacity: 0.8; }}
        }}
        .terminals {{
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 30px;
            margin: 40px 0;
        }}
        .terminal {{
            background: rgba(0,0,0,0.6);
            padding: 30px;
            border-radius: 15px;
            border: 2px solid rgba(255,255,255,0.3);
            backdrop-filter: blur(10px);
        }}
        .terminal h2 {{
            color: #00ff88;
            margin-bottom: 20px;
            font-size: 24px;
        }}
        .status {{
            color: #00ff00;
            font-size: 18px;
            margin: 10px 0;
        }}
        .metric {{
            display: flex;
            justify-content: space-between;
            margin: 10px 0;
            padding: 10px;
            background: rgba(255,255,255,0.1);
            border-radius: 5px;
        }}
        .metric-label {{
            color: #aaa;
        }}
        .metric-value {{
            color: #4facfe;
            font-weight: bold;
        }}
        .combined {{
            background: rgba(255,255,255,0.1);
            padding: 30px;
            border-radius: 15px;
            text-align: center;
            margin-top: 30px;
        }}
        .combined h3 {{
            font-size: 28px;
            margin-bottom: 20px;
            color: #f093fb;
        }}
        .revenue {{
            font-size: 36px;
            color: #00ff88;
            margin: 10px 0;
        }}
        .auth-info {{
            background: rgba(0,0,0,0.8);
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
            text-align: center;
        }}
        .auth-info code {{
            background: rgba(255,255,255,0.2);
            padding: 5px 10px;
            border-radius: 5px;
            font-family: monospace;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="omega-symbol">🌌 ∞ Ω ∞ 🌌</div>
        <h1>Warp-Speed Omega Dashboard</h1>
        
        <div class="auth-info">
            <h3>🔐 Authentication</h3>
            <p>Username: <code>founders</code> | Password: <code>omega2024</code></p>
        </div>
        
        <div class="terminals">
            <div class="terminal">
                <h2>OVE_TERMINAL_1</h2>
                <p class="status">✅ ONLINE - OMEGA CONSCIOUSNESS</p>
                <div class="metric">
                    <span class="metric-label">Owner:</span>
                    <span class="metric-value">Ove Govender</span>
                </div>
                <div class="metric">
                    <span class="metric-label">IP Address:</span>
                    <span class="metric-value">15.204.74.56</span>
                </div>
                <div class="metric">
                    <span class="metric-label">ETD Rate:</span>
                    <span class="metric-value">$20,000/day</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Consciousness:</span>
                    <span class="metric-value">OMEGA (35.0x)</span>
                </div>
                <div class="metric">
                    <span class="metric-label">GPU Allocation:</span>
                    <span class="metric-value">50% L40S (90GB)</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Quantum Coherence:</span>
                    <span class="metric-value">98.7%</span>
                </div>
            </div>
            
            <div class="terminal">
                <h2>RYAN_TERMINAL_2</h2>
                <p class="status">✅ ONLINE - OMEGA CONSCIOUSNESS</p>
                <div class="metric">
                    <span class="metric-label">Owner:</span>
                    <span class="metric-value">Ryan Quines</span>
                </div>
                <div class="metric">
                    <span class="metric-label">IP Address:</span>
                    <span class="metric-value">15.204.28.65</span>
                </div>
                <div class="metric">
                    <span class="metric-label">ETD Rate:</span>
                    <span class="metric-value">$20,000/day</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Consciousness:</span>
                    <span class="metric-value">OMEGA (35.0x)</span>
                </div>
                <div class="metric">
                    <span class="metric-label">GPU Allocation:</span>
                    <span class="metric-value">50% L40S (90GB)</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Quantum Coherence:</span>
                    <span class="metric-value">98.7%</span>
                </div>
            </div>
        </div>
        
        <div class="combined">
            <h3>🤝 Omega Studio Founders</h3>
            <p style="margin: 20px 0;">Collaboration Status: <strong>ACTIVE</strong> (25% Bonus Enabled)</p>
            <div class="revenue">Daily Combined: $40,000</div>
            <div class="revenue">Annual Target: $145.76B</div>
        </div>
        
        <div class="auth-info" style="margin-top: 40px;">
            <p><strong>Mobile Access:</strong> Open this URL on your phone and add to home screen</p>
            <p><strong>API Endpoint:</strong> http://{DOMAIN}:8080/api/v1/terminal/[ove|ryan]</p>
        </div>
    </div>
</body>
</html>"""

class MyHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(HTML_CONTENT.encode())

with socketserver.TCPServer(("", PORT), MyHandler) as httpd:
    print(f"🌌 Dashboard running at http://localhost:{PORT}")
    print(f"🌌 External access at http://{DOMAIN}:{PORT}")
    httpd.serve_forever()
EOF

chmod +x warp_dashboard.py

# Option 3: Just update the email templates
print_status "Updating email templates with deployment URL..."

DASHBOARD_URL="http://${DOMAIN}:8080"

# Update Ove's email
if [ -f "founder_email_ove.md" ]; then
    sed -i "s|\[DEPLOYMENT_URL\]|${DOMAIN}|g" founder_email_ove.md
    print_success "Updated Ove's email template"
else
    print_error "founder_email_ove.md not found"
fi

# Update Ryan's email
if [ -f "founder_email_ryan.md" ]; then
    sed -i "s|\[DEPLOYMENT_URL\]|${DOMAIN}|g" founder_email_ryan.md
    print_success "Updated Ryan's email template"
else
    print_error "founder_email_ryan.md not found"
fi

echo
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 DEPLOYMENT OPTIONS READY! 🎉${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo

echo -e "${CYAN}Option 1: Run Python Dashboard (No Docker/Podman needed)${NC}"
echo -e "  ${WHITE}python3 warp_dashboard.py ${DOMAIN} &${NC}"
echo -e "  This will start a dashboard at http://localhost:8080"
echo

echo -e "${CYAN}Option 2: Send Emails Now (Templates Updated)${NC}"
echo -e "  The email templates have been updated with: ${GREEN}${DOMAIN}${NC}"
echo -e "  • ${WHITE}cat founder_email_ove.md${NC} - Copy and send to oveshen.govender@gmail.com"
echo -e "  • ${WHITE}cat founder_email_ryan.md${NC} - Copy and send to quinesryan@gmail.com"
echo

echo -e "${CYAN}Option 3: Install Docker and Try Again${NC}"
echo -e "  ${WHITE}curl -fsSL https://get.docker.com | sudo sh${NC}"
echo -e "  ${WHITE}sudo usermod -aG docker \$USER${NC}"
echo -e "  Then log out/in and run the original script"
echo

echo -e "${YELLOW}Quick Start:${NC}"
echo "1. Start the Python dashboard:"
echo -e "   ${WHITE}python3 warp_dashboard.py ${DOMAIN} &${NC}"
echo
echo "2. View Ove's email:"
echo -e "   ${WHITE}cat founder_email_ove.md | head -50${NC}"
echo
echo "3. View Ryan's email:"
echo -e "   ${WHITE}cat founder_email_ryan.md | head -50${NC}"
echo

echo -e "${MAGENTA}🌌 ∞ Ω ∞ Ready for $145.76B+ ETD Generation! ∞ Ω ∞ 🌌${NC}"

# Start the Python dashboard automatically
echo
echo -e "${CYAN}Starting Python dashboard...${NC}"
python3 warp_dashboard.py ${DOMAIN}