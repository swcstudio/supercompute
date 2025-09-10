#!/bin/bash

# 🌌 ∞ Ω ∞ HTTPS CONFIGURATION FOR WARP-SPEED ∞ Ω ∞ 🌌

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

DOMAIN="kled.io"
EMAIL="oveshen.govender@gmail.com"
SERVER_IP="51.161.218.49"

echo -e "${MAGENTA}🌌 ∞ Ω ∞ WARP-SPEED HTTPS CONFIGURATION ∞ Ω ∞ 🌌${NC}"
echo -e "${CYAN}=================================================${NC}"
echo

print_status() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Step 1: Install Certbot
print_status "Installing Certbot for Let's Encrypt..."

if ! certbot --version &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y certbot python3-certbot-nginx
    print_success "Certbot installed"
else
    print_success "Certbot already installed"
fi

# Step 2: Install Nginx if not present
print_status "Checking Nginx installation..."

if ! nginx -v &> /dev/null; then
    sudo apt-get install -y nginx
    print_success "Nginx installed"
else
    print_success "Nginx already installed"
fi

# Step 3: Create Nginx configuration
print_status "Creating Nginx configuration for $DOMAIN..."

sudo tee /etc/nginx/sites-available/warp-speed << EOF
# HTTP server - redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    # Redirect all other traffic to HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    # SSL certificates (will be created by certbot)
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Proxy to Warp-Speed dashboard
    location / {
        proxy_pass http://localhost:8888;
        proxy_http_version 1.1;
        
        # WebSocket support
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Headers
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Timeouts for long-running connections
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffering
        proxy_buffering off;
        proxy_request_buffering off;
    }
    
    # API endpoints
    location /api/ {
        proxy_pass http://localhost:8888/api/;
        proxy_http_version 1.1;
        
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # CORS headers
        add_header Access-Control-Allow-Origin "$DOMAIN" always;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type" always;
    }
    
    # WebSocket endpoint
    location /ws {
        proxy_pass http://localhost:8888/ws;
        proxy_http_version 1.1;
        
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        
        # WebSocket timeouts
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://localhost:8888/health;
        access_log off;
    }
}
EOF

print_success "Nginx configuration created"

# Step 4: Enable the site
print_status "Enabling Nginx site..."

sudo ln -sf /etc/nginx/sites-available/warp-speed /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
if sudo nginx -t; then
    print_success "Nginx configuration valid"
else
    print_error "Nginx configuration invalid"
    exit 1
fi

# Step 5: Create certificate directory
sudo mkdir -p /var/www/certbot

# Step 6: Restart Nginx to apply HTTP configuration
print_status "Restarting Nginx..."
sudo systemctl restart nginx
print_success "Nginx restarted"

# Step 7: Obtain SSL certificate
print_status "Obtaining SSL certificate from Let's Encrypt..."

sudo certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d $DOMAIN \
    -d www.$DOMAIN

if [ $? -eq 0 ]; then
    print_success "SSL certificate obtained successfully"
else
    print_error "Failed to obtain SSL certificate"
    print_status "Trying standalone method..."
    
    # Stop Nginx temporarily
    sudo systemctl stop nginx
    
    # Try standalone method
    sudo certbot certonly \
        --standalone \
        --email $EMAIL \
        --agree-tos \
        --no-eff-email \
        --force-renewal \
        -d $DOMAIN \
        -d www.$DOMAIN
    
    # Restart Nginx
    sudo systemctl start nginx
fi

# Step 8: Reload Nginx with SSL
print_status "Reloading Nginx with SSL configuration..."
sudo systemctl reload nginx
print_success "Nginx reloaded with SSL"

# Step 9: Set up auto-renewal
print_status "Setting up automatic certificate renewal..."

# Create renewal script
sudo tee /etc/cron.daily/certbot-renew << 'EOF'
#!/bin/bash
certbot renew --quiet --post-hook "systemctl reload nginx"
EOF

sudo chmod +x /etc/cron.daily/certbot-renew
print_success "Auto-renewal configured"

# Step 10: Test HTTPS
print_status "Testing HTTPS configuration..."

sleep 2

if curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN/health | grep -q "200\|401"; then
    print_success "HTTPS is working!"
else
    print_error "HTTPS test failed - check configuration"
fi

# Step 11: Update firewall
print_status "Configuring firewall..."

if command -v ufw &> /dev/null; then
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 8888/tcp
    print_success "Firewall configured"
else
    print_status "UFW not installed, skipping firewall configuration"
fi

echo
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 HTTPS CONFIGURATION COMPLETE! 🎉${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo
echo -e "${CYAN}🔒 SSL Status:${NC}"
echo -e "  ${WHITE}• Domain:${NC} https://$DOMAIN"
echo -e "  ${WHITE}• Certificate:${NC} Let's Encrypt"
echo -e "  ${WHITE}• Auto-renewal:${NC} Enabled"
echo -e "  ${WHITE}• Nginx:${NC} Configured and running"
echo
echo -e "${CYAN}🌐 Access Points:${NC}"
echo -e "  ${WHITE}• Dashboard:${NC} https://$DOMAIN"
echo -e "  ${WHITE}• Ove Terminal:${NC} https://$DOMAIN/?terminal=ove"
echo -e "  ${WHITE}• Ryan Terminal:${NC} https://$DOMAIN/?terminal=ryan"
echo -e "  ${WHITE}• API:${NC} https://$DOMAIN/api/v1/status"
echo -e "  ${WHITE}• WebSocket:${NC} wss://$DOMAIN/ws"
echo
echo -e "${CYAN}📱 Mobile App Configuration:${NC}"
echo -e "  Update apps to use: ${WHITE}https://$DOMAIN${NC}"
echo
echo -e "${YELLOW}⚠️  Next Steps:${NC}"
echo -e "  1. Deploy backend: cd ~/src/repos/manifolded && ./deploy-warp-speed.sh"
echo -e "  2. Verify: https://$DOMAIN"
echo -e "  3. Distribute apps to founders"
echo
echo -e "${MAGENTA}🌌 ∞ Ω ∞ HTTPS Secured with OMEGA Consciousness! ∞ Ω ∞ 🌌${NC}"