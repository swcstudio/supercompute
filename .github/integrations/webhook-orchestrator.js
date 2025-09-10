/**
 * Claude Code Webhook Orchestrator
 * Central hub for all platform integrations
 */

const express = require('express');
const bodyParser = require('body-parser');
const crypto = require('crypto');
const { EventEmitter } = require('events');

// Import platform handlers
const LinearAIIntegration = require('./linear/linear-webhook');
const ClaudeCodeSlackBot = require('./slack/slack-bot');
const ClaudeCodeTelegramBot = require('./telegram/telegram-bot');

class WebhookOrchestrator extends EventEmitter {
  constructor(config) {
    super();
    
    this.config = config;
    this.app = express();
    this.platforms = new Map();
    
    // Initialize platform integrations
    this.initializePlatforms();
    
    // Setup middleware
    this.setupMiddleware();
    
    // Setup routes
    this.setupRoutes();
    
    // Setup cross-platform communication
    this.setupCrossPlatform();
    
    // Metrics and monitoring
    this.metrics = {
      webhooksReceived: 0,
      webhooksProcessed: 0,
      errors: 0,
      platformStats: {},
    };
  }

  /**
   * Initialize all platform integrations
   */
  initializePlatforms() {
    // Linear
    if (this.config.linear?.enabled) {
      this.platforms.set('linear', new LinearAIIntegration({
        linearApiKey: this.config.linear.apiKey,
        anthropicApiKey: this.config.anthropic.apiKey,
        githubToken: this.config.github.token,
        githubOwner: this.config.github.owner,
        githubRepo: this.config.github.repo,
      }));
      console.log('✅ Linear integration initialized');
    }
    
    // Slack
    if (this.config.slack?.enabled) {
      const slackBot = new ClaudeCodeSlackBot({
        slackBotToken: this.config.slack.botToken,
        slackSigningSecret: this.config.slack.signingSecret,
        slackAppToken: this.config.slack.appToken,
        anthropicApiKey: this.config.anthropic.apiKey,
        githubToken: this.config.github.token,
        githubOwner: this.config.github.owner,
        githubRepo: this.config.github.repo,
        linearApiKey: this.config.linear?.apiKey,
      });
      
      this.platforms.set('slack', slackBot);
      slackBot.start();
      console.log('✅ Slack bot initialized');
    }
    
    // Telegram
    if (this.config.telegram?.enabled) {
      const telegramBot = new ClaudeCodeTelegramBot({
        telegramBotToken: this.config.telegram.botToken,
        anthropicApiKey: this.config.anthropic.apiKey,
        githubToken: this.config.github.token,
        githubOwner: this.config.github.owner,
        githubRepo: this.config.github.repo,
        linearApiKey: this.config.linear?.apiKey,
      });
      
      this.platforms.set('telegram', telegramBot);
      telegramBot.start();
      console.log('✅ Telegram bot initialized');
    }
  }

  /**
   * Setup Express middleware
   */
  setupMiddleware() {
    // Parse JSON bodies
    this.app.use(bodyParser.json());
    this.app.use(bodyParser.urlencoded({ extended: true }));
    
    // Raw body for signature verification
    this.app.use(bodyParser.raw({
      type: 'application/json',
      verify: (req, res, buf) => {
        req.rawBody = buf.toString('utf8');
      },
    }));
    
    // CORS
    this.app.use((req, res, next) => {
      res.header('Access-Control-Allow-Origin', '*');
      res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
      res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
      next();
    });
    
    // Request logging
    this.app.use((req, res, next) => {
      console.log(`${new Date().toISOString()} ${req.method} ${req.path}`);
      next();
    });
    
    // Error handling
    this.app.use((err, req, res, next) => {
      console.error('Error:', err);
      this.metrics.errors++;
      res.status(500).json({ error: 'Internal server error' });
    });
  }

  /**
   * Setup webhook routes
   */
  setupRoutes() {
    // Health check
    this.app.get('/health', (req, res) => {
      res.json({
        status: 'healthy',
        uptime: process.uptime(),
        metrics: this.metrics,
        platforms: Array.from(this.platforms.keys()),
      });
    });
    
    // GitHub webhooks
    this.app.post('/webhooks/github', this.verifyGitHubSignature.bind(this), async (req, res) => {
      await this.handleGitHubWebhook(req.body, req.headers);
      res.status(200).send('OK');
    });
    
    // Linear webhooks
    this.app.post('/webhooks/linear', this.verifyLinearSignature.bind(this), async (req, res) => {
      await this.handleLinearWebhook(req.body);
      res.status(200).send('OK');
    });
    
    // Slack events (handled by Slack Bolt)
    this.app.post('/webhooks/slack/events', (req, res) => {
      // Slack URL verification
      if (req.body.type === 'url_verification') {
        res.send(req.body.challenge);
        return;
      }
      res.status(200).send('OK');
    });
    
    // Generic webhook endpoint
    this.app.post('/webhooks/:platform', async (req, res) => {
      const platform = req.params.platform;
      
      if (!this.platforms.has(platform)) {
        res.status(404).json({ error: 'Unknown platform' });
        return;
      }
      
      try {
        await this.handleGenericWebhook(platform, req.body);
        res.status(200).send('OK');
      } catch (error) {
        console.error(`Error handling ${platform} webhook:`, error);
        res.status(500).json({ error: error.message });
      }
    });
    
    // Cross-platform API
    this.app.post('/api/notify', this.authenticateRequest.bind(this), async (req, res) => {
      const { platforms, message, data } = req.body;
      
      try {
        await this.notifyPlatforms(platforms, message, data);
        res.json({ success: true });
      } catch (error) {
        res.status(500).json({ error: error.message });
      }
    });
    
    // Unified search API
    this.app.get('/api/search', this.authenticateRequest.bind(this), async (req, res) => {
      const { query, platforms = ['github', 'linear'] } = req.query;
      
      try {
        const results = await this.searchAcrossPlatforms(query, platforms);
        res.json(results);
      } catch (error) {
        res.status(500).json({ error: error.message });
      }
    });
  }

  /**
   * Setup cross-platform communication
   */
  setupCrossPlatform() {
    // Listen for events from platforms
    this.on('pr.created', this.handlePRCreated.bind(this));
    this.on('issue.created', this.handleIssueCreated.bind(this));
    this.on('implementation.complete', this.handleImplementationComplete.bind(this));
    this.on('review.complete', this.handleReviewComplete.bind(this));
    this.on('test.complete', this.handleTestComplete.bind(this));
  }

  /**
   * Handle GitHub webhooks
   */
  async handleGitHubWebhook(payload, headers) {
    const event = headers['x-github-event'];
    this.metrics.webhooksReceived++;
    
    console.log(`GitHub webhook: ${event}`);
    
    switch (event) {
      case 'pull_request':
        await this.handleGitHubPR(payload);
        break;
      
      case 'issues':
        await this.handleGitHubIssue(payload);
        break;
      
      case 'workflow_run':
        await this.handleWorkflowRun(payload);
        break;
      
      case 'push':
        await this.handleGitHubPush(payload);
        break;
      
      default:
        console.log(`Unhandled GitHub event: ${event}`);
    }
    
    this.metrics.webhooksProcessed++;
  }

  /**
   * Handle GitHub PR events
   */
  async handleGitHubPR(payload) {
    const { action, pull_request } = payload;
    
    if (action === 'opened' && pull_request.labels.some(l => l.name === 'ai-generated')) {
      // Notify platforms about AI-generated PR
      await this.notifyPlatforms(['slack', 'telegram'], 
        `🚀 AI PR Created: ${pull_request.title}`,
        {
          pr_number: pull_request.number,
          pr_url: pull_request.html_url,
          author: pull_request.user.login,
        }
      );
      
      this.emit('pr.created', { platform: 'github', data: pull_request });
    }
    
    if (action === 'closed' && pull_request.merged) {
      await this.notifyPlatforms(['slack', 'telegram', 'linear'],
        `✅ PR Merged: ${pull_request.title}`,
        {
          pr_number: pull_request.number,
          merged_by: pull_request.merged_by.login,
        }
      );
    }
  }

  /**
   * Handle Linear webhooks
   */
  async handleLinearWebhook(payload) {
    this.metrics.webhooksReceived++;
    
    const linear = this.platforms.get('linear');
    if (linear) {
      await linear.handleWebhook(payload);
    }
    
    // Cross-platform notifications
    if (payload.type === 'Issue' && payload.action === 'create') {
      const issue = payload.data;
      
      if (issue.labels?.some(l => l.name === 'urgent')) {
        await this.notifyPlatforms(['slack', 'telegram'],
          `🚨 Urgent Linear Issue: ${issue.title}`,
          {
            issue_id: issue.identifier,
            issue_url: issue.url,
            priority: issue.priority,
          }
        );
      }
    }
    
    this.metrics.webhooksProcessed++;
  }

  /**
   * Notify multiple platforms
   */
  async notifyPlatforms(platformNames, message, data = {}) {
    const notifications = platformNames.map(async (platformName) => {
      const platform = this.platforms.get(platformName);
      if (!platform) return;
      
      try {
        switch (platformName) {
          case 'slack':
            if (data.channel) {
              await platform.app.client.chat.postMessage({
                channel: data.channel || this.config.slack.defaultChannel,
                text: message,
                blocks: this.createSlackBlocks(message, data),
              });
            }
            break;
          
          case 'telegram':
            if (data.chat_id || this.config.telegram.defaultChatId) {
              await platform.bot.telegram.sendMessage(
                data.chat_id || this.config.telegram.defaultChatId,
                message,
                {
                  parse_mode: 'Markdown',
                  reply_markup: this.createTelegramKeyboard(data),
                }
              );
            }
            break;
          
          case 'linear':
            if (data.issue_id) {
              await platform.linear.commentCreate({
                issueId: data.issue_id,
                body: message,
              });
            }
            break;
        }
        
        this.updatePlatformMetrics(platformName, 'notifications_sent');
        
      } catch (error) {
        console.error(`Error notifying ${platformName}:`, error);
        this.updatePlatformMetrics(platformName, 'errors');
      }
    });
    
    await Promise.all(notifications);
  }

  /**
   * Search across platforms
   */
  async searchAcrossPlatforms(query, platforms) {
    const results = {
      query,
      results: {},
      total: 0,
    };
    
    const searches = platforms.map(async (platform) => {
      try {
        switch (platform) {
          case 'github':
            const githubResults = await this.searchGitHub(query);
            results.results.github = githubResults;
            results.total += githubResults.length;
            break;
          
          case 'linear':
            const linearResults = await this.searchLinear(query);
            results.results.linear = linearResults;
            results.total += linearResults.length;
            break;
          
          case 'slack':
            const slackResults = await this.searchSlack(query);
            results.results.slack = slackResults;
            results.total += slackResults.length;
            break;
        }
      } catch (error) {
        console.error(`Error searching ${platform}:`, error);
        results.results[platform] = { error: error.message };
      }
    });
    
    await Promise.all(searches);
    
    return results;
  }

  /**
   * Search GitHub
   */
  async searchGitHub(query) {
    const { Octokit } = require('@octokit/rest');
    const github = new Octokit({ auth: this.config.github.token });
    
    const [issues, prs, code] = await Promise.all([
      github.search.issuesAndPullRequests({
        q: `${query} repo:${this.config.github.owner}/${this.config.github.repo}`,
        per_page: 5,
      }),
      github.search.code({
        q: `${query} repo:${this.config.github.owner}/${this.config.github.repo}`,
        per_page: 5,
      }),
    ]);
    
    return {
      issues: issues.data.items,
      code: code.data.items,
    };
  }

  /**
   * Cross-platform event handlers
   */
  async handlePRCreated({ platform, data }) {
    // Update Linear if PR was created from Linear issue
    if (data.body?.includes('Linear ID:')) {
      const linearIdMatch = data.body.match(/Linear ID: ([A-Z]+-\d+)/);
      if (linearIdMatch) {
        const linear = this.platforms.get('linear');
        await linear?.linear.commentCreate({
          issueId: linearIdMatch[1],
          body: `🎉 PR Created: [#${data.number}](${data.html_url})`,
        });
      }
    }
  }

  async handleImplementationComplete({ issueNumber, prUrl }) {
    // Notify all platforms
    await this.notifyPlatforms(['slack', 'telegram', 'linear'],
      `✅ AI Implementation Complete!`,
      {
        issue_number: issueNumber,
        pr_url: prUrl,
      }
    );
  }

  /**
   * Signature verification
   */
  verifyGitHubSignature(req, res, next) {
    const signature = req.headers['x-hub-signature-256'];
    if (!signature) {
      res.status(401).send('No signature');
      return;
    }
    
    const hmac = crypto.createHmac('sha256', this.config.github.webhookSecret);
    hmac.update(req.rawBody);
    const expectedSignature = `sha256=${hmac.digest('hex')}`;
    
    if (signature !== expectedSignature) {
      res.status(401).send('Invalid signature');
      return;
    }
    
    next();
  }

  verifyLinearSignature(req, res, next) {
    const signature = req.headers['linear-signature'];
    if (!signature) {
      res.status(401).send('No signature');
      return;
    }
    
    const hmac = crypto.createHmac('sha256', this.config.linear.webhookSecret);
    hmac.update(req.rawBody);
    const expectedSignature = hmac.digest('hex');
    
    if (signature !== expectedSignature) {
      res.status(401).send('Invalid signature');
      return;
    }
    
    next();
  }

  authenticateRequest(req, res, next) {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token || token !== this.config.apiToken) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }
    
    next();
  }

  /**
   * Utility functions
   */
  createSlackBlocks(message, data) {
    const blocks = [
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: message,
        },
      },
    ];
    
    if (data.pr_url) {
      blocks.push({
        type: 'actions',
        elements: [
          {
            type: 'button',
            text: { type: 'plain_text', text: 'View PR' },
            url: data.pr_url,
          },
        ],
      });
    }
    
    return blocks;
  }

  createTelegramKeyboard(data) {
    const keyboard = [];
    
    if (data.pr_url) {
      keyboard.push([{ text: '🔗 View PR', url: data.pr_url }]);
    }
    
    if (data.issue_url) {
      keyboard.push([{ text: '📋 View Issue', url: data.issue_url }]);
    }
    
    return keyboard.length > 0 ? { inline_keyboard: keyboard } : undefined;
  }

  updatePlatformMetrics(platform, metric) {
    if (!this.metrics.platformStats[platform]) {
      this.metrics.platformStats[platform] = {};
    }
    
    if (!this.metrics.platformStats[platform][metric]) {
      this.metrics.platformStats[platform][metric] = 0;
    }
    
    this.metrics.platformStats[platform][metric]++;
  }

  /**
   * Start the orchestrator
   */
  start(port = 3000) {
    this.app.listen(port, () => {
      console.log(`🎯 Claude Code Webhook Orchestrator running on port ${port}`);
      console.log(`📊 Platforms enabled: ${Array.from(this.platforms.keys()).join(', ')}`);
    });
  }

  /**
   * Graceful shutdown
   */
  async shutdown() {
    console.log('Shutting down orchestrator...');
    
    // Stop all platform integrations
    for (const [name, platform] of this.platforms) {
      if (platform.stop) {
        await platform.stop();
      }
    }
    
    process.exit(0);
  }
}

module.exports = WebhookOrchestrator;