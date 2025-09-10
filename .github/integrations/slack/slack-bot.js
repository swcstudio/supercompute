/**
 * Slack Bot Integration for Claude Code
 * AI-powered development assistant in Slack
 */

const { App } = require('@slack/bolt');
const { Anthropic } = require('@anthropic-ai/sdk');
const { Octokit } = require('@octokit/rest');
const { LinearClient } = require('@linear/sdk');
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

class ClaudeCodeSlackBot {
  constructor(config) {
    this.app = new App({
      token: config.slackBotToken,
      signingSecret: config.slackSigningSecret,
      socketMode: true,
      appToken: config.slackAppToken,
    });
    
    this.anthropic = new Anthropic({
      apiKey: config.anthropicApiKey,
    });
    
    this.github = new Octokit({
      auth: config.githubToken,
    });
    
    this.linear = config.linearApiKey ? new LinearClient({
      apiKey: config.linearApiKey,
    }) : null;
    
    this.config = config;
    this.setupEventHandlers();
    this.setupCommands();
    this.setupShortcuts();
  }

  /**
   * Setup Slack event handlers
   */
  setupEventHandlers() {
    // Direct messages to bot
    this.app.message(async ({ message, say, client }) => {
      if (message.channel_type === 'im') {
        await this.handleDirectMessage(message, say, client);
      }
    });
    
    // App mentions
    this.app.event('app_mention', async ({ event, say, client }) => {
      await this.handleMention(event, say, client);
    });
    
    // File shared
    this.app.event('file_shared', async ({ event, client }) => {
      await this.handleFileShared(event, client);
    });
  }

  /**
   * Setup slash commands
   */
  setupCommands() {
    // /claude-code command
    this.app.command('/claude-code', async ({ command, ack, respond }) => {
      await ack();
      await this.handleSlashCommand(command, respond);
    });
    
    // /code-review command
    this.app.command('/code-review', async ({ command, ack, respond }) => {
      await ack();
      await this.handleCodeReview(command, respond);
    });
    
    // /implement command
    this.app.command('/implement', async ({ command, ack, respond }) => {
      await ack();
      await this.handleImplement(command, respond);
    });
    
    // /debug command
    this.app.command('/debug', async ({ command, ack, respond }) => {
      await ack();
      await this.handleDebug(command, respond);
    });
  }

  /**
   * Setup shortcuts and interactive components
   */
  setupShortcuts() {
    // Global shortcut for quick code help
    this.app.shortcut('code_help', async ({ shortcut, ack, client }) => {
      await ack();
      await this.openCodeHelpModal(shortcut, client);
    });
    
    // Message shortcut for explaining code
    this.app.shortcut('explain_code', async ({ shortcut, ack, client }) => {
      await ack();
      await this.explainCode(shortcut, client);
    });
    
    // Interactive buttons
    this.app.action('create_pr', async ({ body, ack, client }) => {
      await ack();
      await this.createPullRequest(body, client);
    });
  }

  /**
   * Handle direct messages
   */
  async handleDirectMessage(message, say, client) {
    const { text, user } = message;
    
    // Show typing indicator
    await this.sendTypingIndicator(message.channel);
    
    try {
      // Check if it's a code block
      if (text.includes('```')) {
        await this.analyzeCode(text, say, user);
      } else if (text.toLowerCase().includes('help')) {
        await this.sendHelpMessage(say);
      } else {
        // General AI assistance
        await this.provideGeneralAssistance(text, say, user);
      }
    } catch (error) {
      await say(`Sorry, I encountered an error: ${error.message}`);
    }
  }

  /**
   * Handle mentions
   */
  async handleMention(event, say, client) {
    const { text, user, channel } = event;
    const cleanText = text.replace(/<@[A-Z0-9]+>/g, '').trim();
    
    // Command patterns
    const commands = {
      'review pr': this.reviewPRFromSlack.bind(this),
      'explain': this.explainConcept.bind(this),
      'implement': this.implementFeature.bind(this),
      'refactor': this.refactorCode.bind(this),
      'test': this.generateTests.bind(this),
      'debug': this.debugIssue.bind(this),
      'deploy': this.checkDeployment.bind(this),
      'status': this.projectStatus.bind(this),
    };
    
    for (const [command, handler] of Object.entries(commands)) {
      if (cleanText.toLowerCase().startsWith(command)) {
        await handler(cleanText, say, user, channel);
        return;
      }
    }
    
    // Default response
    await say(`Hi <@${user}>! I can help with:\n• Code reviews\n• Implementation\n• Debugging\n• Testing\n• Refactoring\n\nJust mention me with your request!`);
  }

  /**
   * Review PR from Slack
   */
  async reviewPRFromSlack(text, say, user, channel) {
    const prUrlMatch = text.match(/github\.com\/([^\/]+)\/([^\/]+)\/pull\/(\d+)/);
    
    if (!prUrlMatch) {
      await say('Please provide a valid GitHub PR URL');
      return;
    }
    
    const [, owner, repo, prNumber] = prUrlMatch;
    
    await say({
      text: `Reviewing PR #${prNumber}...`,
      blocks: [
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: `🔍 Reviewing PR #${prNumber} in ${owner}/${repo}...`
          }
        }
      ]
    });
    
    try {
      // Get PR details
      const { data: pr } = await this.github.pulls.get({
        owner,
        repo,
        pull_number: parseInt(prNumber),
      });
      
      // Get PR diff
      const { data: diff } = await this.github.pulls.get({
        owner,
        repo,
        pull_number: parseInt(prNumber),
        mediaType: {
          format: 'diff',
        },
      });
      
      // AI review
      const review = await this.performAIReview(pr, diff);
      
      // Send review to Slack
      await say({
        text: `Review complete for PR #${prNumber}`,
        blocks: this.formatReviewBlocks(pr, review, owner, repo),
      });
      
    } catch (error) {
      await say(`Error reviewing PR: ${error.message}`);
    }
  }

  /**
   * Perform AI code review
   */
  async performAIReview(pr, diff) {
    const prompt = `
    Review this GitHub PR:
    
    Title: ${pr.title}
    Description: ${pr.body || 'No description'}
    Files Changed: ${pr.changed_files}
    Additions: +${pr.additions}
    Deletions: -${pr.deletions}
    
    Diff:
    ${diff.substring(0, 15000)} // Truncated
    
    Provide:
    1. Summary of changes
    2. Code quality assessment (1-10)
    3. Security concerns
    4. Performance implications
    5. Suggestions for improvement
    6. Overall recommendation (Approve/Request Changes/Comment)
    
    Be concise but thorough.
    `;
    
    const response = await this.anthropic.messages.create({
      model: 'claude-3-opus-20240229',
      max_tokens: 2000,
      messages: [{ role: 'user', content: prompt }],
    });
    
    return response.content[0].text;
  }

  /**
   * Format review for Slack blocks
   */
  formatReviewBlocks(pr, review, owner, repo) {
    // Parse review sections
    const sections = review.split('\n\n');
    const summary = sections[0] || 'No summary';
    const qualityMatch = review.match(/quality.*?(\d+)/i);
    const quality = qualityMatch ? qualityMatch[1] : 'N/A';
    const recommendation = review.match(/recommendation.*?(approve|request changes|comment)/i)?.[1] || 'comment';
    
    const blocks = [
      {
        type: 'header',
        text: {
          type: 'plain_text',
          text: `PR Review: ${pr.title}`,
        },
      },
      {
        type: 'section',
        fields: [
          {
            type: 'mrkdwn',
            text: `*PR:* <https://github.com/${owner}/${repo}/pull/${pr.number}|#${pr.number}>`,
          },
          {
            type: 'mrkdwn',
            text: `*Author:* ${pr.user.login}`,
          },
          {
            type: 'mrkdwn',
            text: `*Quality Score:* ${quality}/10`,
          },
          {
            type: 'mrkdwn',
            text: `*Recommendation:* ${recommendation}`,
          },
        ],
      },
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `*Summary:*\n${summary}`,
        },
      },
    ];
    
    // Add security concerns if any
    const securityMatch = review.match(/security.*?:(.*?)(?:\n\n|$)/is);
    if (securityMatch && !securityMatch[1].toLowerCase().includes('no concerns')) {
      blocks.push({
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `🔒 *Security Concerns:*\n${securityMatch[1].trim()}`,
        },
      });
    }
    
    // Add action buttons
    blocks.push({
      type: 'actions',
      elements: [
        {
          type: 'button',
          text: {
            type: 'plain_text',
            text: 'View PR',
          },
          url: pr.html_url,
        },
        {
          type: 'button',
          text: {
            type: 'plain_text',
            text: 'Create Issue',
          },
          action_id: 'create_issue_from_review',
          value: JSON.stringify({ pr: pr.number, owner, repo }),
        },
      ],
    });
    
    return blocks;
  }

  /**
   * Implement feature from Slack
   */
  async implementFeature(text, say, user, channel) {
    const feature = text.replace(/implement\s*/i, '').trim();
    
    if (!feature) {
      await say('Please describe the feature you want implemented');
      return;
    }
    
    await say({
      text: 'Starting implementation...',
      blocks: [
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: `🚀 Starting implementation of: *${feature}*`,
          },
        },
        {
          type: 'context',
          elements: [
            {
              type: 'mrkdwn',
              text: 'This may take a few minutes...',
            },
          ],
        },
      ],
    });
    
    try {
      // Create GitHub issue
      const { data: issue } = await this.github.issues.create({
        owner: this.config.githubOwner,
        repo: this.config.githubRepo,
        title: feature,
        body: `Requested by @${user} in Slack\n\n${feature}`,
        labels: ['ai-implement', 'from-slack'],
      });
      
      // Trigger AI implementation
      await this.github.actions.createWorkflowDispatch({
        owner: this.config.githubOwner,
        repo: this.config.githubRepo,
        workflow_id: 'ai-pr-creator.yml',
        ref: 'main',
        inputs: {
          task_description: feature,
          branch_name: `slack-${Date.now()}`,
          priority: 'medium',
        },
      });
      
      await say({
        text: 'Implementation started!',
        blocks: [
          {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: `✅ Implementation started!\n\n*Issue:* <${issue.html_url}|#${issue.number}>\n*Feature:* ${feature}`,
            },
          },
          {
            type: 'context',
            elements: [
              {
                type: 'mrkdwn',
                text: "I'll notify you when the PR is ready for review.",
              },
            ],
          },
        ],
      });
      
      // Store for notification later
      this.storeImplementationRequest(user, channel, issue.number);
      
    } catch (error) {
      await say(`Error starting implementation: ${error.message}`);
    }
  }

  /**
   * Debug issue from Slack
   */
  async debugIssue(text, say, user, channel) {
    const issue = text.replace(/debug\s*/i, '').trim();
    
    await say('🐛 Let me help you debug that issue...');
    
    const prompt = `
    Help debug this issue:
    ${issue}
    
    Provide:
    1. Likely causes (ranked by probability)
    2. Diagnostic steps to isolate the issue
    3. Code snippets to add for debugging
    4. Common solutions
    5. Prevention strategies
    
    Be specific and actionable.
    `;
    
    const response = await this.anthropic.messages.create({
      model: 'claude-3-opus-20240229',
      max_tokens: 2000,
      messages: [{ role: 'user', content: prompt }],
    });
    
    const debugInfo = response.content[0].text;
    
    // Format as Slack blocks
    const blocks = this.formatDebugBlocks(issue, debugInfo);
    
    await say({
      text: 'Debug analysis complete',
      blocks,
    });
  }

  /**
   * Format debug info as Slack blocks
   */
  formatDebugBlocks(issue, debugInfo) {
    const sections = debugInfo.split(/\d+\.\s+/);
    
    return [
      {
        type: 'header',
        text: {
          type: 'plain_text',
          text: '🐛 Debug Analysis',
        },
      },
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `*Issue:* ${issue}`,
        },
      },
      {
        type: 'divider',
      },
      ...sections.slice(1).map((section, index) => ({
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `*${['Likely Causes', 'Diagnostic Steps', 'Debug Code', 'Solutions', 'Prevention'][index]}:*\n${section.trim()}`,
        },
      })),
    ];
  }

  /**
   * Handle code review slash command
   */
  async handleCodeReview(command, respond) {
    const { text, user_id } = command;
    
    if (!text) {
      await respond('Please provide a PR URL or paste code to review');
      return;
    }
    
    // Check if it's a URL or code
    if (text.includes('github.com')) {
      await this.reviewPRFromSlack(text, respond, user_id);
    } else {
      // Review pasted code
      await this.reviewCode(text, respond);
    }
  }

  /**
   * Review code snippet
   */
  async reviewCode(code, respond) {
    const prompt = `
    Review this code for:
    1. Bugs and issues
    2. Best practices
    3. Performance
    4. Security
    5. Readability
    
    Code:
    ${code}
    
    Provide specific suggestions for improvement.
    `;
    
    const response = await this.anthropic.messages.create({
      model: 'claude-3-opus-20240229',
      max_tokens: 2000,
      messages: [{ role: 'user', content: prompt }],
    });
    
    await respond({
      response_type: 'in_channel',
      text: 'Code Review Complete',
      blocks: [
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: '```\n' + code + '\n```',
          },
        },
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: `*Review:*\n${response.content[0].text}`,
          },
        },
      ],
    });
  }

  /**
   * Open code help modal
   */
  async openCodeHelpModal(shortcut, client) {
    await client.views.open({
      trigger_id: shortcut.trigger_id,
      view: {
        type: 'modal',
        callback_id: 'code_help_modal',
        title: {
          type: 'plain_text',
          text: 'Claude Code Assistant',
        },
        blocks: [
          {
            type: 'input',
            block_id: 'language',
            element: {
              type: 'static_select',
              placeholder: {
                type: 'plain_text',
                text: 'Select language',
              },
              options: [
                { text: { type: 'plain_text', text: 'JavaScript' }, value: 'javascript' },
                { text: { type: 'plain_text', text: 'TypeScript' }, value: 'typescript' },
                { text: { type: 'plain_text', text: 'Python' }, value: 'python' },
                { text: { type: 'plain_text', text: 'Go' }, value: 'go' },
                { text: { type: 'plain_text', text: 'Rust' }, value: 'rust' },
              ],
              action_id: 'language_select',
            },
            label: {
              type: 'plain_text',
              text: 'Language',
            },
          },
          {
            type: 'input',
            block_id: 'question',
            element: {
              type: 'plain_text_input',
              multiline: true,
              action_id: 'question_input',
            },
            label: {
              type: 'plain_text',
              text: 'What do you need help with?',
            },
          },
          {
            type: 'input',
            block_id: 'code',
            optional: true,
            element: {
              type: 'plain_text_input',
              multiline: true,
              action_id: 'code_input',
            },
            label: {
              type: 'plain_text',
              text: 'Code (optional)',
            },
          },
        ],
        submit: {
          type: 'plain_text',
          text: 'Get Help',
        },
      },
    });
  }

  /**
   * Send help message
   */
  async sendHelpMessage(say) {
    await say({
      text: 'Claude Code Help',
      blocks: [
        {
          type: 'header',
          text: {
            type: 'plain_text',
            text: '🤖 Claude Code Assistant',
          },
        },
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: "I'm your AI-powered development assistant! Here's what I can do:",
          },
        },
        {
          type: 'section',
          fields: [
            {
              type: 'mrkdwn',
              text: '*💬 Chat Commands*\n• Ask coding questions\n• Explain concepts\n• Debug issues\n• Best practices',
            },
            {
              type: 'mrkdwn',
              text: '*🔧 Slash Commands*\n• `/code-review` - Review code or PR\n• `/implement` - Implement feature\n• `/debug` - Debug issue\n• `/claude-code` - General help',
            },
          ],
        },
        {
          type: 'section',
          fields: [
            {
              type: 'mrkdwn',
              text: '*🏷 Mention Commands*\n• `@claude review pr <url>`\n• `@claude implement <feature>`\n• `@claude explain <concept>`\n• `@claude test <description>`',
            },
            {
              type: 'mrkdwn',
              text: '*📎 File Actions*\n• Share code files for review\n• Get explanations\n• Suggest improvements\n• Generate tests',
            },
          ],
        },
        {
          type: 'context',
          elements: [
            {
              type: 'mrkdwn',
              text: 'Powered by Claude 3 Opus | <https://github.com/yourusername/ai-github-workflows|GitHub>',
            },
          ],
        },
      ],
    });
  }

  /**
   * Send typing indicator
   */
  async sendTypingIndicator(channel) {
    // Slack doesn't have a direct typing API, but we can use a loading message
    return this.app.client.chat.postMessage({
      channel,
      text: '...',
      blocks: [
        {
          type: 'context',
          elements: [
            {
              type: 'mrkdwn',
              text: '_Claude is thinking..._',
            },
          ],
        },
      ],
    });
  }

  /**
   * Start the bot
   */
  async start() {
    await this.app.start();
    console.log('⚡️ Claude Code Slack bot is running!');
  }
}

module.exports = ClaudeCodeSlackBot;