#!/bin/bash

# Cloudflare Setup Script
# Automated setup for Claude Code Cloudflare Integration

set -e

echo "🤖 Claude Code Cloudflare Setup"
echo "================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if wrangler is installed
check_wrangler() {
    if ! command -v wrangler &> /dev/null; then
        echo -e "${RED}❌ Wrangler CLI not found${NC}"
        echo "Please install wrangler: npm install -g wrangler"
        exit 1
    fi
    echo -e "${GREEN}✅ Wrangler CLI found${NC}"
}

# Check if user is logged in
check_auth() {
    if ! wrangler whoami &> /dev/null; then
        echo -e "${YELLOW}⚠️  Not logged in to Cloudflare${NC}"
        echo "Please login: wrangler login"
        read -p "Press enter after logging in..."
    fi
    echo -e "${GREEN}✅ Authenticated with Cloudflare${NC}"
}

# Get account info
get_account_info() {
    echo -e "${BLUE}📋 Getting account information...${NC}"
    ACCOUNT_ID=$(wrangler whoami | grep "Account ID" | cut -d':' -f2 | xargs)
    
    if [ -z "$ACCOUNT_ID" ]; then
        echo -e "${RED}❌ Could not get account ID${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Account ID: $ACCOUNT_ID${NC}"
}

# Create KV namespaces
create_kv_namespaces() {
    echo -e "${BLUE}🗄️ Creating KV namespaces...${NC}"
    
    # Create production namespaces
    echo "Creating CACHE namespace..."
    KV_CACHE_OUTPUT=$(wrangler kv:namespace create "CACHE" 2>&1)
    KV_CACHE_ID=$(echo "$KV_CACHE_OUTPUT" | grep -o 'id = "[^"]*' | cut -d'"' -f2)
    
    echo "Creating CACHE preview namespace..."
    KV_CACHE_PREVIEW_OUTPUT=$(wrangler kv:namespace create "CACHE" --preview 2>&1)
    KV_CACHE_PREVIEW_ID=$(echo "$KV_CACHE_PREVIEW_OUTPUT" | grep -o 'id = "[^"]*' | cut -d'"' -f2)
    
    echo "Creating METRICS namespace..."
    KV_METRICS_OUTPUT=$(wrangler kv:namespace create "METRICS" 2>&1)
    KV_METRICS_ID=$(echo "$KV_METRICS_OUTPUT" | grep -o 'id = "[^"]*' | cut -d'"' -f2)
    
    echo "Creating METRICS preview namespace..."
    KV_METRICS_PREVIEW_OUTPUT=$(wrangler kv:namespace create "METRICS" --preview 2>&1)
    KV_METRICS_PREVIEW_ID=$(echo "$KV_METRICS_PREVIEW_OUTPUT" | grep -o 'id = "[^"]*' | cut -d'"' -f2)
    
    echo -e "${GREEN}✅ KV namespaces created${NC}"
    echo "  CACHE: $KV_CACHE_ID (preview: $KV_CACHE_PREVIEW_ID)"
    echo "  METRICS: $KV_METRICS_ID (preview: $KV_METRICS_PREVIEW_ID)"
}

# Create D1 database
create_d1_database() {
    echo -e "${BLUE}💾 Creating D1 database...${NC}"
    
    D1_OUTPUT=$(wrangler d1 create claude-code-db 2>&1)
    D1_DATABASE_ID=$(echo "$D1_OUTPUT" | grep -o 'database_id = "[^"]*' | cut -d'"' -f2)
    
    if [ -z "$D1_DATABASE_ID" ]; then
        echo -e "${YELLOW}⚠️  Database might already exist, checking...${NC}"
        D1_DATABASE_ID=$(wrangler d1 list | grep "claude-code-db" | awk '{print $2}' | head -1)
    fi
    
    echo -e "${GREEN}✅ D1 database ready: $D1_DATABASE_ID${NC}"
}

# Create R2 bucket
create_r2_bucket() {
    echo -e "${BLUE}📦 Creating R2 bucket...${NC}"
    
    if wrangler r2 bucket create claude-code-storage 2>&1 | grep -q "already exists"; then
        echo -e "${YELLOW}⚠️  R2 bucket already exists${NC}"
    else
        echo -e "${GREEN}✅ R2 bucket created: claude-code-storage${NC}"
    fi
}

# Create Durable Object
setup_durable_objects() {
    echo -e "${BLUE}🔄 Setting up Durable Objects...${NC}"
    
    # Durable Objects are defined in the worker script
    echo -e "${GREEN}✅ Durable Objects will be deployed with worker${NC}"
}

# Update wrangler.toml with resource IDs
update_wrangler_config() {
    echo -e "${BLUE}⚙️ Updating wrangler.toml configuration...${NC}"
    
    WRANGLER_FILE="workers/wrangler.toml"
    
    if [ ! -f "$WRANGLER_FILE" ]; then
        echo -e "${RED}❌ wrangler.toml not found${NC}"
        return 1
    fi
    
    # Create backup
    cp "$WRANGLER_FILE" "$WRANGLER_FILE.backup"
    
    # Update IDs
    if [ ! -z "$KV_CACHE_ID" ]; then
        sed -i.tmp "s/YOUR_KV_CACHE_ID/$KV_CACHE_ID/g" "$WRANGLER_FILE"
    fi
    if [ ! -z "$KV_CACHE_PREVIEW_ID" ]; then
        sed -i.tmp "s/YOUR_KV_CACHE_PREVIEW_ID/$KV_CACHE_PREVIEW_ID/g" "$WRANGLER_FILE"
    fi
    if [ ! -z "$KV_METRICS_ID" ]; then
        sed -i.tmp "s/YOUR_KV_METRICS_ID/$KV_METRICS_ID/g" "$WRANGLER_FILE"
    fi
    if [ ! -z "$KV_METRICS_PREVIEW_ID" ]; then
        sed -i.tmp "s/YOUR_KV_METRICS_PREVIEW_ID/$KV_METRICS_PREVIEW_ID/g" "$WRANGLER_FILE"
    fi
    if [ ! -z "$D1_DATABASE_ID" ]; then
        sed -i.tmp "s/YOUR_D1_DATABASE_ID/$D1_DATABASE_ID/g" "$WRANGLER_FILE"
    fi
    
    # Clean up temp files
    rm -f "$WRANGLER_FILE.tmp"
    
    echo -e "${GREEN}✅ wrangler.toml updated${NC}"
}

# Setup secrets
setup_secrets() {
    echo -e "${BLUE}🔐 Setting up secrets...${NC}"
    echo
    echo "You need to set the following secrets:"
    echo "1. ANTHROPIC_API_KEY (required)"
    echo "2. GITHUB_TOKEN (optional, for GitHub integration)"
    echo "3. GITHUB_WEBHOOK_SECRET (optional, for GitHub webhooks)"
    echo "4. LINEAR_API_KEY (optional, for Linear integration)"
    echo "5. SLACK_BOT_TOKEN (optional, for Slack integration)"
    echo "6. TELEGRAM_BOT_TOKEN (optional, for Telegram integration)"
    echo
    
    read -p "Do you want to set up secrets now? (y/n): " SETUP_SECRETS
    
    if [ "$SETUP_SECRETS" = "y" ] || [ "$SETUP_SECRETS" = "Y" ]; then
        echo
        echo "Setting ANTHROPIC_API_KEY..."
        wrangler secret put ANTHROPIC_API_KEY
        
        read -p "Set GITHUB_TOKEN? (y/n): " SET_GITHUB
        if [ "$SET_GITHUB" = "y" ] || [ "$SET_GITHUB" = "Y" ]; then
            wrangler secret put GITHUB_TOKEN
        fi
        
        read -p "Set GITHUB_WEBHOOK_SECRET? (y/n): " SET_WEBHOOK
        if [ "$SET_WEBHOOK" = "y" ] || [ "$SET_WEBHOOK" = "Y" ]; then
            wrangler secret put GITHUB_WEBHOOK_SECRET
        fi
        
        read -p "Set LINEAR_API_KEY? (y/n): " SET_LINEAR
        if [ "$SET_LINEAR" = "y" ] || [ "$SET_LINEAR" = "Y" ]; then
            wrangler secret put LINEAR_API_KEY
        fi
        
        read -p "Set SLACK_BOT_TOKEN? (y/n): " SET_SLACK
        if [ "$SET_SLACK" = "y" ] || [ "$SET_SLACK" = "Y" ]; then
            wrangler secret put SLACK_BOT_TOKEN
        fi
        
        read -p "Set TELEGRAM_BOT_TOKEN? (y/n): " SET_TELEGRAM
        if [ "$SET_TELEGRAM" = "y" ] || [ "$SET_TELEGRAM" = "Y" ]; then
            wrangler secret put TELEGRAM_BOT_TOKEN
        fi
    else
        echo "You can set secrets later using: wrangler secret put SECRET_NAME"
    fi
    
    echo -e "${GREEN}✅ Secrets setup complete${NC}"
}

# Initialize database with migrations
init_database() {
    echo -e "${BLUE}🗃️ Initializing database...${NC}"
    
    # Create migrations directory if it doesn't exist
    mkdir -p migrations
    
    # Create initial migration if it doesn't exist
    if [ ! -f "migrations/0001_initial.sql" ]; then
        cat > migrations/0001_initial.sql << 'EOF'
-- Initial schema for Claude Code
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    github_id INTEGER UNIQUE,
    username TEXT NOT NULL,
    email TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS code_snippets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    code TEXT NOT NULL,
    language TEXT NOT NULL,
    tags TEXT, -- JSON array
    is_public BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE TABLE IF NOT EXISTS ai_requests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    endpoint TEXT NOT NULL,
    prompt TEXT,
    response_tokens INTEGER,
    processing_time REAL,
    region TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE TABLE IF NOT EXISTS webhooks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    platform TEXT NOT NULL, -- github, linear, slack, telegram
    event_type TEXT NOT NULL,
    payload TEXT NOT NULL, -- JSON
    processed BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_snippets_user_id ON code_snippets(user_id);
CREATE INDEX IF NOT EXISTS idx_snippets_language ON code_snippets(language);
CREATE INDEX IF NOT EXISTS idx_snippets_public ON code_snippets(is_public);
CREATE INDEX IF NOT EXISTS idx_ai_requests_user_id ON ai_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_requests_created_at ON ai_requests(created_at);
CREATE INDEX IF NOT EXISTS idx_webhooks_platform ON webhooks(platform);
CREATE INDEX IF NOT EXISTS idx_webhooks_processed ON webhooks(processed);
EOF
        echo "Created initial migration"
    fi
    
    # Apply migrations
    wrangler d1 migrations apply claude-code-db --local
    wrangler d1 migrations apply claude-code-db
    
    echo -e "${GREEN}✅ Database initialized${NC}"
}

# Deploy worker
deploy_worker() {
    echo -e "${BLUE}🚀 Deploying worker...${NC}"
    
    cd workers
    wrangler publish
    cd ..
    
    echo -e "${GREEN}✅ Worker deployed${NC}"
}

# Create DNS record
setup_dns() {
    echo -e "${BLUE}🌐 Setting up DNS...${NC}"
    
    read -p "Enter your domain (or press enter to skip): " DOMAIN
    
    if [ ! -z "$DOMAIN" ]; then
        read -p "Enter subdomain for the API (default: claude-api): " SUBDOMAIN
        SUBDOMAIN=${SUBDOMAIN:-claude-api}
        
        # Create DNS record
        wrangler dns create "$DOMAIN" "$SUBDOMAIN" --type CNAME --content claude-code-worker.YOUR_SUBDOMAIN.workers.dev
        
        echo -e "${GREEN}✅ DNS record created: $SUBDOMAIN.$DOMAIN${NC}"
    else
        echo "DNS setup skipped"
    fi
}

# Generate summary
generate_summary() {
    echo
    echo -e "${GREEN}🎉 Setup Complete!${NC}"
    echo "========================="
    echo
    echo "📋 Resources Created:"
    echo "  • KV Namespace (CACHE): $KV_CACHE_ID"
    echo "  • KV Namespace (METRICS): $KV_METRICS_ID"
    echo "  • D1 Database: $D1_DATABASE_ID"
    echo "  • R2 Bucket: claude-code-storage"
    echo
    echo "🔗 URLs:"
    echo "  • Worker: https://claude-code-worker.YOUR_SUBDOMAIN.workers.dev"
    echo "  • Health Check: https://claude-code-worker.YOUR_SUBDOMAIN.workers.dev/health"
    echo
    echo "📚 Next Steps:"
    echo "  1. Test the worker: curl https://claude-code-worker.YOUR_SUBDOMAIN.workers.dev/health"
    echo "  2. Deploy your Pages application: wrangler pages publish dist"
    echo "  3. Set up webhooks in GitHub/Linear/Slack"
    echo "  4. Configure your frontend to use the new endpoints"
    echo
    echo "🔧 Useful Commands:"
    echo "  • View logs: wrangler tail"
    echo "  • Update worker: wrangler publish"
    echo "  • Run migrations: wrangler d1 migrations apply claude-code-db"
    echo "  • Manage secrets: wrangler secret put SECRET_NAME"
    echo
    echo "📖 Documentation: .claude/019-cloudflare-integration.md"
}

# Main execution
main() {
    echo -e "${BLUE}Starting Cloudflare setup...${NC}"
    
    check_wrangler
    check_auth
    get_account_info
    create_kv_namespaces
    create_d1_database
    create_r2_bucket
    setup_durable_objects
    update_wrangler_config
    setup_secrets
    init_database
    deploy_worker
    setup_dns
    generate_summary
}

# Run main function
main "$@"