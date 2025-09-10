# Claude Code AI Deployment Guide

This guide covers deploying the complete Claude Code AI ecosystem including GitHub workflows and platform integrations.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   Your Infrastructure                        │
├─────────────────────────────────────────────────────────────┤
│  GitHub Actions    │  Webhook Server   │  Platform Bots     │
│  - AI Workflows    │  - Orchestrator   │  - Slack Bot       │
│  - Automated PRs   │  - Event Router   │  - Telegram Bot    │
│  - Code Reviews    │  - API Gateway    │  - Linear Hooks    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Anthropic API   │
                    │  (Claude 3 Opus) │
                    └──────────────────┘
```

## 📋 Prerequisites

- GitHub repository with Actions enabled
- Anthropic API key (Claude 3 Opus access)
- Server/VPS for webhook orchestrator (or use Vercel/Railway)
- Platform accounts (Linear, Slack, Telegram)
- Domain with SSL/TLS certificate

## 🚀 Step-by-Step Deployment

### Step 1: GitHub Repository Setup

1. **Copy GitHub Workflows**
   ```bash
   # Clone the AI workflows repository
   git clone https://github.com/yourusername/ai-github-workflows.git
   
   # Copy workflows to your project
   cp -r ai-github-workflows/.github/workflows/* your-project/.github/workflows/
   ```

2. **Create Required Secrets**
   ```bash
   # Add to your repository settings → Secrets
   ANTHROPIC_API_KEY=sk-ant-...
   TURBO_TOKEN=...        # Optional for Turborepo
   NX_CLOUD_ACCESS_TOKEN=... # Optional for Nx
   ```

3. **Create Labels**
   ```bash
   # Run the label setup script
   curl -sSL https://raw.githubusercontent.com/yourusername/ai-github-workflows/main/.github/setup-labels.sh | bash
   ```

### Step 2: Deploy Webhook Orchestrator

#### Option A: Using Vercel (Recommended for simplicity)

1. **Create Vercel Project**
   ```bash
   # Install Vercel CLI
   npm i -g vercel
   
   # Create api directory
   mkdir api
   
   # Create serverless function
   cat > api/webhooks.js << 'EOF'
   const WebhookOrchestrator = require('../.github/integrations/webhook-orchestrator');
   
   const orchestrator = new WebhookOrchestrator({
     // Configuration from environment variables
   });
   
   module.exports = orchestrator.app;
   EOF
   
   # Deploy
   vercel --prod
   ```

2. **Set Environment Variables in Vercel**
   ```
   ANTHROPIC_API_KEY
   GITHUB_TOKEN
   LINEAR_API_KEY
   SLACK_BOT_TOKEN
   TELEGRAM_BOT_TOKEN
   ```

#### Option B: Using Docker on VPS

1. **Setup Server**
   ```bash
   # SSH to your server
   ssh user@your-server.com
   
   # Clone repository
   git clone https://github.com/yourusername/your-project.git
   cd your-project/.github/integrations
   
   # Run setup script
   ./setup.sh
   ```

2. **Configure Environment**
   ```bash
   # Edit .env file with your actual values
   nano .env
   ```

3. **Deploy with Docker Compose**
   ```bash
   # Build and start
   docker-compose up -d
   
   # Check logs
   docker-compose logs -f
   ```

4. **Setup Nginx Reverse Proxy**
   ```nginx
   server {
       listen 443 ssl http2;
       server_name webhooks.yourdomain.com;
       
       ssl_certificate /path/to/cert.pem;
       ssl_certificate_key /path/to/key.pem;
       
       location / {
           proxy_pass http://localhost:3000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```

### Step 3: Configure Platform Integrations

#### Linear Setup

1. **Create Webhook**
   - Go to Linear Settings → API → Webhooks
   - URL: `https://webhooks.yourdomain.com/webhooks/linear`
   - Secret: Generate secure secret
   - Events: Select all

2. **Create API Key**
   - Settings → API → Personal API keys
   - Create new key with full access

#### Slack Setup

1. **Create Slack App**
   - Visit api.slack.com/apps
   - Create New App → From scratch
   - Add to workspace

2. **Configure Bot**
   ```yaml
   # OAuth & Permissions
   Bot Token Scopes:
     - chat:write
     - commands
     - im:history
     - app_mentions:read
     - files:read
   
   # Event Subscriptions
   Request URL: https://webhooks.yourdomain.com/webhooks/slack/events
   
   Bot Events:
     - app_mention
     - message.im
     - file_shared
   ```

3. **Add Slash Commands**
   - `/code-review` → Request URL
   - `/implement` → Request URL
   - `/debug` → Request URL

#### Telegram Setup

1. **Create Bot**
   ```bash
   # Talk to @BotFather on Telegram
   /newbot
   # Follow prompts to get token
   ```

2. **Set Webhook**
   ```bash
   curl -X POST https://api.telegram.org/bot<TOKEN>/setWebhook \
     -d "url=https://webhooks.yourdomain.com/webhooks/telegram"
   ```

### Step 4: Configure GitHub Webhooks

1. **Repository Settings → Webhooks**
2. **Add Webhook**
   - URL: `https://webhooks.yourdomain.com/webhooks/github`
   - Content type: `application/json`
   - Secret: Your webhook secret
   - Events:
     - Pull requests
     - Issues
     - Issue comments
     - Workflow runs
     - Pushes

### Step 5: Test the System

1. **Test GitHub Workflows**
   ```bash
   # Create test issue with AI label
   gh issue create --title "Test AI Implementation" \
     --body "Create a hello world function" \
     --label "ai-implement"
   ```

2. **Test Slack Integration**
   ```
   /code-review https://github.com/org/repo/pull/123
   @claude implement user authentication
   ```

3. **Test Telegram Bot**
   ```
   /start
   /code React component for user profile
   ```

4. **Test Webhook Health**
   ```bash
   curl https://webhooks.yourdomain.com/health
   ```

## 🔒 Security Checklist

- [ ] All API keys stored as environment variables
- [ ] Webhook signatures verified
- [ ] HTTPS/TLS enabled on all endpoints
- [ ] Rate limiting configured
- [ ] Error logging without exposing secrets
- [ ] Regular key rotation schedule
- [ ] Audit logs enabled
- [ ] Access controls on GitHub Actions

## 📊 Monitoring Setup

### 1. Application Monitoring

```javascript
// Add to orchestrator
const prometheus = require('prom-client');

// Create metrics
const webhookCounter = new prometheus.Counter({
  name: 'webhooks_total',
  help: 'Total webhooks received',
  labelNames: ['platform', 'event']
});

// Expose metrics endpoint
app.get('/metrics', (req, res) => {
  res.set('Content-Type', prometheus.register.contentType);
  res.end(prometheus.register.metrics());
});
```

### 2. Uptime Monitoring

- Use UptimeRobot or similar:
  - Monitor `/health` endpoint
  - Alert on downtime
  - Check every 5 minutes

### 3. Error Tracking

```javascript
// Sentry integration
const Sentry = require("@sentry/node");

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
});

app.use(Sentry.Handlers.errorHandler());
```

## 🔧 Troubleshooting

### Common Issues

1. **Webhook Signature Verification Failed**
   ```bash
   # Debug webhook signatures
   curl -X POST https://webhooks.yourdomain.com/webhooks/github \
     -H "Content-Type: application/json" \
     -H "X-Hub-Signature-256: sha256=..." \
     -d '{"test": true}'
   ```

2. **Platform Not Receiving Messages**
   - Check API rate limits
   - Verify bot permissions
   - Check webhook delivery logs

3. **AI Workflows Not Triggering**
   - Verify labels exist
   - Check Actions tab for errors
   - Ensure secrets are set

### Debug Mode

```bash
# Enable verbose logging
LOG_LEVEL=debug npm start

# Test specific integration
node -e "
const LinearIntegration = require('./linear/linear-webhook');
const integration = new LinearIntegration(config);
integration.handleWebhook(testPayload);
"
```

## 🚀 Scaling Considerations

### High Volume

1. **Use Message Queue**
   ```javascript
   const Queue = require('bull');
   const webhookQueue = new Queue('webhooks');
   
   app.post('/webhooks/*', async (req, res) => {
     await webhookQueue.add(req.body);
     res.status(200).send('OK');
   });
   ```

2. **Horizontal Scaling**
   ```yaml
   # docker-compose.yml
   services:
     orchestrator:
       image: claude-code
       deploy:
         replicas: 3
   ```

3. **Database for State**
   ```javascript
   // Use Redis for session storage
   const redis = require('redis');
   const client = redis.createClient();
   ```

## 📈 Performance Optimization

1. **Webhook Response Time**
   - Acknowledge immediately
   - Process asynchronously
   - Use queues for heavy tasks

2. **API Rate Limiting**
   ```javascript
   const rateLimit = require('express-rate-limit');
   
   const limiter = rateLimit({
     windowMs: 60 * 1000, // 1 minute
     max: 100 // limit each IP to 100 requests per minute
   });
   
   app.use('/api/', limiter);
   ```

3. **Caching**
   ```javascript
   // Cache GitHub data
   const NodeCache = require('node-cache');
   const cache = new NodeCache({ stdTTL: 600 }); // 10 minutes
   ```

## 🆘 Support & Resources

- **Documentation**: `.claude/` directory
- **Issues**: GitHub Issues
- **Community**: Discord/Slack
- **Updates**: Watch repository for updates

## 🎉 Success Checklist

- [ ] All workflows copied and configured
- [ ] Webhook orchestrator deployed
- [ ] Platform integrations connected
- [ ] Webhooks configured
- [ ] Initial tests passed
- [ ] Monitoring setup
- [ ] Team trained on commands

---

*Congratulations! Your Claude Code AI ecosystem is now deployed!*