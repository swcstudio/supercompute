#!/bin/bash

# Claude Code Integrations Setup Script
# This script helps set up all platform integrations

set -e

echo "🤖 Claude Code Integrations Setup"
echo "================================="
echo

# Check for required tools
check_requirements() {
    echo "📋 Checking requirements..."
    
    if ! command -v node &> /dev/null; then
        echo "❌ Node.js is required. Please install Node.js 18+"
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        echo "❌ npm is required. Please install npm"
        exit 1
    fi
    
    echo "✅ All requirements met"
    echo
}

# Install dependencies
install_dependencies() {
    echo "📦 Installing dependencies..."
    
    npm init -y 2>/dev/null || true
    
    npm install --save \
        express \
        body-parser \
        dotenv \
        @anthropic-ai/sdk \
        @octokit/rest \
        @linear/sdk \
        @slack/bolt \
        telegraf \
        crypto
    
    npm install --save-dev \
        nodemon \
        eslint \
        prettier
    
    echo "✅ Dependencies installed"
    echo
}

# Create environment file
create_env_file() {
    if [ -f .env ]; then
        echo "⚠️  .env file already exists. Skipping..."
        return
    fi
    
    echo "🔐 Creating .env file..."
    
    cat > .env << 'EOF'
# Core Configuration
ANTHROPIC_API_KEY=sk-ant-...
GITHUB_TOKEN=ghp_...
GITHUB_OWNER=your-org
GITHUB_REPO=your-repo
API_TOKEN=your-secret-api-token

# GitHub Configuration
GITHUB_WEBHOOK_SECRET=your-github-webhook-secret

# Linear Configuration (optional)
LINEAR_ENABLED=false
LINEAR_API_KEY=lin_api_...
LINEAR_WEBHOOK_SECRET=your-linear-webhook-secret

# Slack Configuration (optional)
SLACK_ENABLED=false
SLACK_BOT_TOKEN=xoxb-...
SLACK_SIGNING_SECRET=...
SLACK_APP_TOKEN=xapp-...
SLACK_DEFAULT_CHANNEL=#dev

# Telegram Configuration (optional)
TELEGRAM_ENABLED=false
TELEGRAM_BOT_TOKEN=...
TELEGRAM_DEFAULT_CHAT_ID=...

# Server Configuration
PORT=3000
NODE_ENV=production
LOG_LEVEL=info
EOF
    
    echo "✅ .env file created. Please update with your actual values."
    echo
}

# Create server file
create_server() {
    if [ -f server.js ]; then
        echo "⚠️  server.js already exists. Skipping..."
        return
    fi
    
    echo "🚀 Creating server.js..."
    
    cat > server.js << 'EOF'
require('dotenv').config();
const WebhookOrchestrator = require('./.github/integrations/webhook-orchestrator');

const config = {
  anthropic: {
    apiKey: process.env.ANTHROPIC_API_KEY,
  },
  github: {
    token: process.env.GITHUB_TOKEN,
    owner: process.env.GITHUB_OWNER,
    repo: process.env.GITHUB_REPO,
    webhookSecret: process.env.GITHUB_WEBHOOK_SECRET,
  },
  linear: {
    enabled: process.env.LINEAR_ENABLED === 'true',
    apiKey: process.env.LINEAR_API_KEY,
    webhookSecret: process.env.LINEAR_WEBHOOK_SECRET,
  },
  slack: {
    enabled: process.env.SLACK_ENABLED === 'true',
    botToken: process.env.SLACK_BOT_TOKEN,
    signingSecret: process.env.SLACK_SIGNING_SECRET,
    appToken: process.env.SLACK_APP_TOKEN,
    defaultChannel: process.env.SLACK_DEFAULT_CHANNEL || '#dev',
  },
  telegram: {
    enabled: process.env.TELEGRAM_ENABLED === 'true',
    botToken: process.env.TELEGRAM_BOT_TOKEN,
    defaultChatId: process.env.TELEGRAM_DEFAULT_CHAT_ID,
  },
  apiToken: process.env.API_TOKEN,
};

const orchestrator = new WebhookOrchestrator(config);
const port = process.env.PORT || 3000;

orchestrator.start(port);

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\nShutting down gracefully...');
  orchestrator.shutdown();
});

process.on('SIGTERM', () => {
  console.log('\nShutting down gracefully...');
  orchestrator.shutdown();
});
EOF
    
    echo "✅ server.js created"
    echo
}

# Create package.json scripts
update_package_json() {
    echo "📝 Updating package.json scripts..."
    
    # Use node to update package.json
    node -e "
    const fs = require('fs');
    const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
    
    pkg.scripts = {
        ...pkg.scripts,
        'start': 'node server.js',
        'dev': 'nodemon server.js',
        'lint': 'eslint .',
        'format': 'prettier --write \"**/*.js\"'
    };
    
    fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
    "
    
    echo "✅ package.json updated"
    echo
}

# Create Docker files
create_docker_files() {
    echo "🐳 Creating Docker files..."
    
    # Dockerfile
    cat > Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies
RUN npm ci --production

# Copy application files
COPY . .

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (res) => process.exit(res.statusCode === 200 ? 0 : 1))"

# Run as non-root user
USER node

# Start application
CMD ["node", "server.js"]
EOF
    
    # docker-compose.yml
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  claude-code:
    build: .
    ports:
      - "${PORT:-3000}:3000"
    env_file:
      - .env
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    healthcheck:
      test: ["CMD", "node", "-e", "require('http').get('http://localhost:3000/health', (res) => process.exit(res.statusCode === 200 ? 0 : 1))"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 5s
EOF
    
    # .dockerignore
    cat > .dockerignore << 'EOF'
node_modules
npm-debug.log
.env
.git
.gitignore
*.md
.dockerignore
Dockerfile
docker-compose.yml
.github/workflows
coverage
.nyc_output
.vscode
.idea
EOF
    
    echo "✅ Docker files created"
    echo
}

# Create PM2 ecosystem file
create_pm2_config() {
    echo "⚙️  Creating PM2 ecosystem file..."
    
    cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'claude-code-integrations',
    script: './server.js',
    instances: 1,
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/error.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    max_memory_restart: '500M',
    watch: false,
    autorestart: true,
    max_restarts: 10,
    min_uptime: '10s',
    restart_delay: 4000,
    kill_timeout: 5000
  }]
};
EOF
    
    mkdir -p logs
    
    echo "✅ PM2 ecosystem file created"
    echo
}

# Setup instructions
show_instructions() {
    echo "📚 Setup Instructions"
    echo "===================="
    echo
    echo "1. Update the .env file with your actual API keys and tokens"
    echo
    echo "2. Configure webhooks in each platform:"
    echo "   - GitHub: https://your-domain.com/webhooks/github"
    echo "   - Linear: https://your-domain.com/webhooks/linear"
    echo "   - Slack: https://your-domain.com/webhooks/slack/events"
    echo
    echo "3. Start the server:"
    echo "   Development: npm run dev"
    echo "   Production: npm start"
    echo "   Docker: docker-compose up -d"
    echo "   PM2: pm2 start ecosystem.config.js"
    echo
    echo "4. Test the setup:"
    echo "   curl http://localhost:3000/health"
    echo
    echo "5. Set up SSL/TLS with a reverse proxy (nginx/caddy) for production"
    echo
    echo "📖 Full documentation: .claude/018-claude-code-integrations.md"
    echo
}

# Main setup flow
main() {
    check_requirements
    install_dependencies
    create_env_file
    create_server
    update_package_json
    create_docker_files
    create_pm2_config
    show_instructions
    
    echo "✅ Claude Code Integrations setup complete!"
    echo
    echo "🚀 Ready to start with: npm run dev"
}

# Run main
main