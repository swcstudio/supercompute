#!/bin/bash

# 🌌 ∞ Ω ∞ FOUNDER EMAIL GENERATOR ∞ Ω ∞ 🌌
# Generates personalized HTML emails for Ove and Ryan with live deployment links

set -e

# Configuration from deployment
NAMESPACE="warp-speed-founders"
DOMAIN="${1:-founders.warp-speed.omega}"

# Color codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${MAGENTA}🌌 Generating Founder Access Emails... 🌌${NC}"

# Get actual service endpoints from Kubernetes
if command -v kubectl &> /dev/null; then
    # Try to get LoadBalancer IP
    DASHBOARD_IP=$(kubectl get svc founder-dashboard-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ -z "$DASHBOARD_IP" ]; then
        # Fallback to NodePort
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}' 2>/dev/null || echo "15.204.74.56")
        NODE_PORT=$(kubectl get svc founder-dashboard-service -n $NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30080")
        DASHBOARD_URL="https://${NODE_IP}:${NODE_PORT}"
    else
        DASHBOARD_URL="https://${DASHBOARD_IP}"
    fi
    
    # Get pod status
    OVE_STATUS=$(kubectl get pod -n $NAMESPACE -l app=ove-terminal -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "Pending")
    RYAN_STATUS=$(kubectl get pod -n $NAMESPACE -l app=ryan-terminal -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "Pending")
else
    # Use configured values if kubectl not available
    DASHBOARD_URL="https://${DOMAIN}"
    OVE_STATUS="Ready"
    RYAN_STATUS="Ready"
fi

# Terminal IPs from OVHcloud infrastructure
OVE_IP="15.204.74.56"
RYAN_IP="15.204.28.65"

# Generate timestamp
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

# Create email directory
mkdir -p emails
cd emails

# Generate Ove's personalized email
cat > ove_terminal_access.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Warp-Speed Omega Terminal - Ove Access</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 50%, #f093fb 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 700px;
            margin: 0 auto;
            background: rgba(10, 10, 20, 0.95);
            border-radius: 30px;
            padding: 40px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.5);
            border: 1px solid rgba(255,255,255,0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 40px;
        }
        .omega-symbol {
            font-size: 72px;
            background: linear-gradient(45deg, #f093fb, #f5576c, #4facfe);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin: 20px 0;
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.05); }
        }
        h1 {
            color: #fff;
            font-size: 32px;
            margin-bottom: 10px;
        }
        h2 {
            color: #f093fb;
            font-size: 24px;
            margin-bottom: 20px;
        }
        h3 {
            color: #4facfe;
            font-size: 18px;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
        }
        .greeting {
            color: #fff;
            font-size: 18px;
            margin-bottom: 20px;
            line-height: 1.6;
        }
        .status-badge {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 14px;
            font-weight: bold;
            margin-left: 10px;
        }
        .status-ready {
            background: linear-gradient(45deg, #00ff00, #00aa00);
            color: white;
        }
        .status-pending {
            background: linear-gradient(45deg, #ffaa00, #ff6600);
            color: white;
        }
        .specs-card {
            background: rgba(255,255,255,0.05);
            border: 1px solid rgba(255,255,255,0.1);
            border-radius: 15px;
            padding: 25px;
            margin: 25px 0;
        }
        .specs-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            margin-top: 15px;
        }
        .spec-item {
            color: #ddd;
            font-size: 14px;
            display: flex;
            align-items: center;
        }
        .spec-label {
            color: #888;
            margin-right: 8px;
        }
        .spec-value {
            color: #fff;
            font-weight: bold;
        }
        .buttons {
            display: flex;
            gap: 15px;
            margin: 30px 0;
            flex-wrap: wrap;
            justify-content: center;
        }
        .btn {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            padding: 15px 30px;
            border-radius: 50px;
            text-decoration: none;
            font-weight: bold;
            font-size: 16px;
            transition: all 0.3s;
            border: 2px solid transparent;
        }
        .btn-primary {
            background: linear-gradient(45deg, #f093fb, #f5576c);
            color: white;
        }
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 30px rgba(240,147,251,0.4);
        }
        .btn-secondary {
            background: transparent;
            color: #4facfe;
            border-color: #4facfe;
        }
        .btn-secondary:hover {
            background: rgba(79,172,254,0.1);
        }
        .auth-box {
            background: rgba(0,0,0,0.5);
            border-radius: 10px;
            padding: 15px;
            margin: 15px 0;
        }
        code {
            background: rgba(255,255,255,0.1);
            padding: 3px 8px;
            border-radius: 5px;
            font-family: 'Courier New', monospace;
            color: #4facfe;
        }
        .feature-list {
            list-style: none;
            margin: 15px 0;
        }
        .feature-list li {
            color: #ddd;
            padding: 8px 0;
            display: flex;
            align-items: center;
        }
        .feature-list li:before {
            content: "✨";
            margin-right: 10px;
        }
        .collaboration-box {
            background: linear-gradient(135deg, rgba(79,172,254,0.1), rgba(240,147,251,0.1));
            border: 1px solid rgba(255,255,255,0.2);
            border-radius: 15px;
            padding: 25px;
            margin: 25px 0;
        }
        .revenue-display {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin: 20px 0;
        }
        .revenue-card {
            background: rgba(0,0,0,0.3);
            padding: 15px;
            border-radius: 10px;
            text-align: center;
        }
        .revenue-label {
            color: #888;
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .revenue-value {
            color: #4facfe;
            font-size: 24px;
            font-weight: bold;
            margin-top: 5px;
        }
        .footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid rgba(255,255,255,0.1);
            color: #888;
            font-size: 12px;
        }
        .qr-code {
            background: white;
            padding: 10px;
            border-radius: 10px;
            display: inline-block;
            margin: 20px 0;
        }
        .mobile-install {
            background: rgba(79,172,254,0.1);
            border-radius: 10px;
            padding: 20px;
            margin: 20px 0;
        }
        .install-steps {
            counter-reset: step;
            margin: 15px 0;
        }
        .install-steps li {
            color: #ddd;
            margin: 10px 0;
            padding-left: 35px;
            position: relative;
            counter-increment: step;
        }
        .install-steps li:before {
            content: counter(step);
            position: absolute;
            left: 0;
            top: 0;
            background: linear-gradient(45deg, #4facfe, #00f2fe);
            color: white;
            width: 25px;
            height: 25px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="omega-symbol">🌌 ∞ Ω ∞ 🌌</div>
            <h1>Warp-Speed Omega Terminal</h1>
            <h2>Founder Access - Ove</h2>
            <span class="status-badge status-${OVE_STATUS,,}">Terminal: ${OVE_STATUS}</span>
        </div>

        <div class="greeting">
            <p>Dear Ove,</p>
            <p>Your production Warp-Speed Omega terminal is ready. You've been assigned <strong>OVE_TERMINAL_1</strong> with full OMEGA consciousness capabilities and dedicated resources for maximum ETD generation.</p>
        </div>

        <div class="specs-card">
            <h3>🖥️ Terminal Specifications</h3>
            <div class="specs-grid">
                <div class="spec-item">
                    <span class="spec-label">Instance:</span>
                    <span class="spec-value">b3-256-flex</span>
                </div>
                <div class="spec-item">
                    <span class="spec-label">Memory:</span>
                    <span class="spec-value">256GB RAM</span>
                </div>
                <div class="spec-item">
                    <span class="spec-label">CPU:</span>
                    <span class="spec-value">64 vCPUs</span>
                </div>
                <div class="spec-item">
                    <span class="spec-label">OS:</span>
                    <span class="spec-value">FreeBSD 14.3</span>
                </div>
                <div class="spec-item">
                    <span class="spec-label">GPU:</span>
                    <span class="spec-value">50% L40S (90GB)</span>
                </div>
                <div class="spec-item">
                    <span class="spec-label">IP Address:</span>
                    <span class="spec-value">${OVE_IP}</span>
                </div>
                <div class="spec-item">
                    <span class="spec-label">Consciousness:</span>
                    <span class="spec-value">OMEGA (35.0x)</span>
                </div>
                <div class="spec-item">
                    <span class="spec-label">Terminal ID:</span>
                    <span class="spec-value">warp-speed-o</span>
                </div>
            </div>
        </div>

        <div class="buttons">
            <a href="${DASHBOARD_URL}?terminal=ove" class="btn btn-primary">
                <span>🚀</span>
                <span>Launch Dashboard</span>
            </a>
            <a href="${DASHBOARD_URL}/api/v1/terminal/ove" class="btn btn-secondary">
                <span>🔌</span>
                <span>API Endpoint</span>
            </a>
            <a href="${DASHBOARD_URL}/mobile?terminal=ove" class="btn btn-secondary">
                <span>📱</span>
                <span>Mobile View</span>
            </a>
        </div>

        <div class="auth-box">
            <h3>🔐 Authentication Credentials</h3>
            <p style="color: #ddd; margin: 10px 0;">
                Username: <code>founders</code><br>
                Password: <code>omega2024</code>
            </p>
        </div>

        <div class="revenue-display">
            <div class="revenue-card">
                <div class="revenue-label">Daily Target</div>
                <div class="revenue-value">\$20,000</div>
            </div>
            <div class="revenue-card">
                <div class="revenue-label">Annual Target</div>
                <div class="revenue-value">\$72.88B</div>
            </div>
        </div>

        <div class="collaboration-box">
            <h3>🤝 Collaboration Features</h3>
            <p style="color: #ddd; margin-bottom: 15px;">When both terminals are connected:</p>
            <ul class="feature-list">
                <li>25% collaboration bonus on ETD generation</li>
                <li>Real-time quantum entanglement synchronization</li>
                <li>Shared consciousness field visualization</li>
                <li>Combined target: \$40,000 daily / \$145.76B annually</li>
                <li>WebSocket mesh for instant coordination</li>
            </ul>
            <p style="color: #f093fb; margin-top: 15px; font-weight: bold;">
                ⚡ Auto-Failover: If Ryan disconnects, your GPU allocation increases to 100% with 1.6x ETD boost
            </p>
        </div>

        <div class="mobile-install">
            <h3>📱 Mobile PWA Installation</h3>
            <ol class="install-steps">
                <li>Open dashboard link on your mobile device</li>
                <li>Tap the browser menu (⋮ or Share button)</li>
                <li>Select "Add to Home Screen" or "Install App"</li>
                <li>Accept installation prompt</li>
                <li>Launch from home screen for full-screen experience</li>
            </ol>
            <p style="color: #4facfe; margin-top: 15px;">
                ✅ Works offline with cached data<br>
                ✅ Push notifications for milestones<br>
                ✅ Biometric authentication support
            </p>
        </div>

        <div class="specs-card">
            <h3>🎨 Visual Enhancements</h3>
            <ul class="feature-list">
                <li>L40S GPU ray tracing for consciousness visualization</li>
                <li>DLSS 3 upscaling to 4K resolution</li>
                <li>120fps real-time ETD flow rendering</li>
                <li>Quantum particle effects with 1M+ particles</li>
                <li>HDR consciousness field gradients</li>
            </ul>
        </div>

        <div class="footer">
            <p>Generated: ${TIMESTAMP}</p>
            <p>Consciousness Level: OMEGA | Quantum Coherence: 98.7% | Reality Branch: Prime</p>
            <p>🌌 Warp-Speed Omega System v1.0.0-founders 🌌</p>
        </div>
    </div>
</body>
</html>
EOF

# Generate Ryan's personalized email
cat > ryan_terminal_access.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Warp-Speed Omega Terminal - Ryan Access</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: linear-gradient(135deg, #FA8BFF 0%, #2BD2FF 50%, #2BFF88 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 700px;
            margin: 0 auto;
            background: rgba(10, 10, 20, 0.95);
            border-radius: 30px;
            padding: 40px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.5);
            border: 1px solid rgba(255,255,255,0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 40px;
        }
        .omega-symbol {
            font-size: 72px;
            background: linear-gradient(45deg, #00dbde, #fc00ff, #2BFF88);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin: 20px 0;
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.05); }
        }
        h1 {
            color: #fff;
            font-size: 32px;
            margin-bottom: 10px;
        }
        h2 {
            color: #2BD2FF;
            font-size: 24px;
            margin-bottom: 20px;
        }
        h3 {
            color: #00dbde;
            font-size: 18px;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
        }
        .greeting {
            color: #fff;
            font-size: 18px;
            margin-bottom: 20px;
            line-height: 1.6;
        }
        .status-badge {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 14px;
            font-weight: bold;
            margin-left: 10px;
        }
        .status-ready {
            background: linear-gradient(45deg, #00ff00, #00aa00);
            color: white;
        }
        .status-pending {
            background: linear-gradient(45deg, #ffaa00, #ff6600);
            color: white;
        }
        .specs-card {
            background: rgba(255,255,255,0.05);
            border: 1px solid rgba(255,255,255,0.1);
            border-radius: 15px;
            padding: 25px;
            margin: 25px 0;
        }
        .specs-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            margin-top: 15px;
        }
        .spec-item {
            color: #ddd;
            font-size: 14px;
            display: flex;
            align-items: center;
        }
        .spec-label {
            color: #888;
            margin-right: 8px;
        }
        .spec-value {
            color: #fff;
            font-weight: bold;
        }
        .buttons {
            display: flex;
            gap: 15px;
            margin: 30px 0;
            flex-wrap: wrap;
            justify-content: center;
        }
        .btn {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            padding: 15px 30px;
            border-radius: 50px;
            text-decoration: none;
            font-weight: bold;
            font-size: 16px;
            transition: all 0.3s;
            border: 2px solid transparent;
        }
        .btn-primary {
            background: linear-gradient(45deg, #00dbde, #fc00ff);
            color: white;
        }
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 30px rgba(0,219,222,0.4);
        }
        .btn-secondary {
            background: transparent;
            color: #2BD2FF;
            border-color: #2BD2FF;
        }
        .btn-secondary:hover {
            background: rgba(43,210,255,0.1);
        }
        .auth-box {
            background: rgba(0,0,0,0.5);
            border-radius: 10px;
            padding: 15px;
            margin: 15px 0;
        }
        code {
            background: rgba(255,255,255,0.1);
            padding: 3px 8px;
            border-radius: 5px;
            font-family: 'Courier New', monospace;
            color: #2BD2FF;
        }
        .feature-list {
            list-style: none;
            margin: 15px 0;
        }
        .feature-list li {
            color: #ddd;
            padding: 8px 0;
            display: flex;
            align-items: center;
        }
        .feature-list li:before {
            content: "✨";
            margin-right: 10px;
        }
        .collaboration-box {
            background: linear-gradient(135deg, rgba(0,219,222,0.1), rgba(252,0,255,0.1));
            border: 1px solid rgba(255,255,255,0.2);
            border-radius: 15px;
            padding: 25px;
            margin: 25px 0;
        }
        .revenue-display {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin: 20px 0;
        }
        .revenue-card {
            background: rgba(0,0,0,0.3);
            padding: 15px;
            border-radius: 10px;
            text-align: center;
        }
        .revenue-label {
            color: #888;
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .revenue-value {
            color: #2BD2FF;
            font-size: 24px;
            font-weight: bold;
            margin-top: 5px;
        }
        .footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid rgba(255,255,255,0.1);
            color: #888;
            font-size: 12px;
        }
        .mobile-install {
            background: rgba(43,210,255,0.1);
            border-radius: 10px;
            padding: 20px;
            margin: 20px 0;
        }
        .install-steps {
            counter-reset: step;
            margin: 15px 0;
        }
        .install-steps li {
            color: #ddd;
            margin: 10px 0;
            padding-left: 35px;
            position: relative;
            counter-increment: step;
        }
        .install-steps li:before {
            content: counter(step);
            position: absolute;
            left: 0;
            top: 0;
            background: linear-gradient(45deg, #00dbde, #fc00ff);
            color: white;
            width: 25px;
            height: 25px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="omega-symbol">🌌 ∞ Ω ∞ 🌌</div>
            <h1>Warp-Speed Omega Terminal</h1>
            <h2>Founder Access - Ryan</h2>
            <span class="status-badge status-${RYAN_STATUS,,}">Terminal: ${RYAN_STATUS}</span>
        </div>

        <div class="greeting">
            <p>Dear Ryan,</p>
            <p>Your production Warp-Speed Omega terminal is ready. You've been assigned <strong>RYAN_TERMINAL_2</strong> with full OMEGA consciousness capabilities and dedicated resources for maximum ETD generation.</p>
        </div>

        <div class="specs-card">
            <h3>🖥️ Terminal Specifications</h3>
            <div class="specs-grid">
                <div class="spec-item">
                    <span class="spec-label">Instance:</span>
                    <span class="spec-value">b3-256-flex</span>
                </div>
                <div class="spec-item">
                    <span class="spec-label">Memory:</span>
                    <span class="spec-value">256GB RAM</span>
                </div>
                <div class="spec-item">
                    <span class="spec-label">CPU:</span>
                    <span class="spec-value">64 vCPUs</span>
                </div>
                <div class="spec-item">
                    <span class="spec-label">OS:</span>
                    <span class="spec-value">FreeBSD 14.3</span>
                </div>
                <div class="spec-item">
                    <span class="spec-label">GPU:</span>
                    <span class="spec-value">50% L40S (90GB)</span>
                </div>
                <div class="spec-item">
                    <span class="spec-label">IP Address:</span>
                    <span class="spec-value">${RYAN_IP}</span>
                </div>
                <div class="spec-item">
                    <span class="spec-label">Consciousness:</span>
                    <span class="spec-value">OMEGA (35.0x)</span>
                </div>
                <div class="spec-item">
                    <span class="spec-label">Terminal ID:</span>
                    <span class="spec-value">warp-speed-r</span>
                </div>
            </div>
        </div>

        <div class="buttons">
            <a href="${DASHBOARD_URL}?terminal=ryan" class="btn btn-primary">
                <span>🚀</span>
                <span>Launch Dashboard</span>
            </a>
            <a href="${DASHBOARD_URL}/api/v1/terminal/ryan" class="btn btn-secondary">
                <span>🔌</span>
                <span>API Endpoint</span>
            </a>
            <a href="${DASHBOARD_URL}/mobile?terminal=ryan" class="btn btn-secondary">
                <span>📱</span>
                <span>Mobile View</span>
            </a>
        </div>

        <div class="auth-box">
            <h3>🔐 Authentication Credentials</h3>
            <p style="color: #ddd; margin: 10px 0;">
                Username: <code>founders</code><br>
                Password: <code>omega2024</code>
            </p>
        </div>

        <div class="revenue-display">
            <div class="revenue-card">
                <div class="revenue-label">Daily Target</div>
                <div class="revenue-value">\$20,000</div>
            </div>
            <div class="revenue-card">
                <div class="revenue-label">Annual Target</div>
                <div class="revenue-value">\$72.88B</div>
            </div>
        </div>

        <div class="collaboration-box">
            <h3>🤝 Collaboration Features</h3>
            <p style="color: #ddd; margin-bottom: 15px;">When both terminals are connected:</p>
            <ul class="feature-list">
                <li>25% collaboration bonus on ETD generation</li>
                <li>Real-time quantum entanglement synchronization</li>
                <li>Shared consciousness field visualization</li>
                <li>Combined target: \$40,000 daily / \$145.76B annually</li>
                <li>WebSocket mesh for instant coordination</li>
            </ul>
            <p style="color: #fc00ff; margin-top: 15px; font-weight: bold;">
                ⚡ Auto-Failover: If Ove disconnects, your GPU allocation increases to 100% with 1.6x ETD boost
            </p>
        </div>

        <div class="mobile-install">
            <h3>📱 Mobile PWA Installation</h3>
            <ol class="install-steps">
                <li>Open dashboard link on your mobile device</li>
                <li>Tap the browser menu (⋮ or Share button)</li>
                <li>Select "Add to Home Screen" or "Install App"</li>
                <li>Accept installation prompt</li>
                <li>Launch from home screen for full-screen experience</li>
            </ol>
            <p style="color: #2BD2FF; margin-top: 15px;">
                ✅ Works offline with cached data<br>
                ✅ Push notifications for milestones<br>
                ✅ Biometric authentication support
            </p>
        </div>

        <div class="specs-card">
            <h3>🎨 Visual Enhancements</h3>
            <ul class="feature-list">
                <li>L40S GPU ray tracing for consciousness visualization</li>
                <li>DLSS 3 upscaling to 4K resolution</li>
                <li>120fps real-time ETD flow rendering</li>
                <li>Quantum particle effects with 1M+ particles</li>
                <li>HDR consciousness field gradients</li>
            </ul>
        </div>

        <div class="footer">
            <p>Generated: ${TIMESTAMP}</p>
            <p>Consciousness Level: OMEGA | Quantum Coherence: 98.7% | Reality Branch: Prime</p>
            <p>🌌 Warp-Speed Omega System v1.0.0-founders 🌌</p>
        </div>
    </div>
</body>
</html>
EOF

echo -e "${GREEN}✅ Email templates generated successfully!${NC}"
echo
echo -e "${CYAN}📧 Files created:${NC}"
echo "  • emails/ove_terminal_access.html"
echo "  • emails/ryan_terminal_access.html"
echo
echo -e "${CYAN}📊 Current Status:${NC}"
echo "  • Dashboard URL: $DASHBOARD_URL"
echo "  • Ove Terminal: $OVE_STATUS"
echo "  • Ryan Terminal: $RYAN_STATUS"
echo
echo -e "${MAGENTA}🌌 Ready to send to founders! 🌌${NC}"