# Claude Code Integrations

This directory contains all platform integrations for Claude Code, providing AI-powered development assistance across multiple platforms.

## 🚀 Available Integrations

### 1. Linear (Task Management)
- **File**: `linear/linear-webhook.js`
- **Features**:
  - AI task decomposition
  - Automatic GitHub issue creation
  - Story point estimation
  - Technical spec generation
  - Similar issue analysis

### 2. Slack (Team Collaboration)
- **File**: `slack/slack-bot.js`
- **Features**:
  - Code review in Slack
  - Feature implementation
  - Debug assistance
  - Real-time notifications
  - Slash commands

### 3. Telegram (Mobile Coding)
- **File**: `telegram/telegram-bot.js`
- **Features**:
  - Mobile code reviews
  - Voice coding
  - Inline code generation
  - GitHub integration
  - Snippet management

### 4. Webhook Orchestrator
- **File**: `webhook-orchestrator.js`
- **Features**:
  - Unified webhook management
  - Cross-platform notifications
  - Event routing
  - Search API
  - Metrics tracking

## 📦 Installation

```bash
npm install express body-parser @slack/bolt telegraf @linear/sdk @octokit/rest @anthropic-ai/sdk
```

## 🔧 Configuration

Create a `.env` file:

```bash
# Core
ANTHROPIC_API_KEY=sk-ant-...
GITHUB_TOKEN=ghp_...
GITHUB_OWNER=your-org
GITHUB_REPO=your-repo
API_TOKEN=your-secret-token

# GitHub
GITHUB_WEBHOOK_SECRET=...

# Linear
LINEAR_API_KEY=lin_api_...
LINEAR_WEBHOOK_SECRET=...

# Slack
SLACK_BOT_TOKEN=xoxb-...
SLACK_SIGNING_SECRET=...
SLACK_APP_TOKEN=xapp-...

# Telegram
TELEGRAM_BOT_TOKEN=...
```

## 🚀 Quick Start

```javascript
// server.js
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
    enabled: true,
    apiKey: process.env.LINEAR_API_KEY,
    webhookSecret: process.env.LINEAR_WEBHOOK_SECRET,
  },
  slack: {
    enabled: true,
    botToken: process.env.SLACK_BOT_TOKEN,
    signingSecret: process.env.SLACK_SIGNING_SECRET,
    appToken: process.env.SLACK_APP_TOKEN,
    defaultChannel: '#dev',
  },
  telegram: {
    enabled: true,
    botToken: process.env.TELEGRAM_BOT_TOKEN,
  },
  apiToken: process.env.API_TOKEN,
};

const orchestrator = new WebhookOrchestrator(config);
orchestrator.start(3000);

// Graceful shutdown
process.on('SIGINT', () => orchestrator.shutdown());
process.on('SIGTERM', () => orchestrator.shutdown());
```

## 🌐 Webhook URLs

Configure these webhook URLs in each platform:

- **GitHub**: `https://your-domain.com/webhooks/github`
- **Linear**: `https://your-domain.com/webhooks/linear`
- **Slack**: `https://your-domain.com/webhooks/slack/events`
- **Telegram**: Set via API or use polling

## 📚 Usage Examples

### Linear → GitHub → Slack Flow

1. Create Linear issue with `ai-implement` label
2. Linear webhook triggers
3. GitHub issue created automatically
4. AI implementation starts
5. PR created
6. Slack notified

### Slack Commands

```
/code-review https://github.com/org/repo/pull/123
/implement Add user authentication with OAuth
/debug TypeError in production
```

### Telegram Bot

```
/code React component for user profile
/review https://github.com/org/repo/pull/456
/implement Payment processing system
```

## 🔒 Security

- All webhooks use signature verification
- API endpoints require authentication
- Secrets stored in environment variables
- Rate limiting implemented
- HTTPS required

## 📊 Monitoring

Access metrics at: `GET /health`

```json
{
  "status": "healthy",
  "uptime": 3600,
  "metrics": {
    "webhooksReceived": 150,
    "webhooksProcessed": 148,
    "errors": 2
  },
  "platforms": ["linear", "slack", "telegram"]
}
```

## 🐛 Debugging

Enable debug mode:

```javascript
const orchestrator = new WebhookOrchestrator({
  ...config,
  debug: true,
  logLevel: 'verbose'
});
```

## 🚀 Deployment

### Using Docker

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
```

### Using PM2

```bash
pm2 start server.js --name claude-code
pm2 save
pm2 startup
```

## 📝 License

MIT

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

---

*Part of the Claude Code AI ecosystem*