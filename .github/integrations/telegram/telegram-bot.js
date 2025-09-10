/**
 * Telegram Bot Integration for Claude Code
 * Mobile-first AI coding assistant
 */

const { Telegraf, Markup } = require('telegraf');
const { Anthropic } = require('@anthropic-ai/sdk');
const { Octokit } = require('@octokit/rest');
const { LinearClient } = require('@linear/sdk');
const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');

class ClaudeCodeTelegramBot {
  constructor(config) {
    this.bot = new Telegraf(config.telegramBotToken);
    
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
    this.sessions = new Map(); // Store user sessions
    this.codeSnippets = new Map(); // Store code snippets
    
    this.setupCommands();
    this.setupHandlers();
    this.setupInlineMode();
  }

  /**
   * Setup bot commands
   */
  setupCommands() {
    // Set command list
    this.bot.telegram.setMyCommands([
      { command: 'start', description: 'Start the bot and see help' },
      { command: 'code', description: 'Write code with AI assistance' },
      { command: 'review', description: 'Review code or PR' },
      { command: 'explain', description: 'Explain code or concept' },
      { command: 'debug', description: 'Debug an issue' },
      { command: 'implement', description: 'Implement a feature' },
      { command: 'refactor', description: 'Refactor code' },
      { command: 'test', description: 'Generate tests' },
      { command: 'docs', description: 'Generate documentation' },
      { command: 'pr', description: 'Create or view PRs' },
      { command: 'issue', description: 'Create or view issues' },
      { command: 'deploy', description: 'Check deployment status' },
      { command: 'search', description: 'Search codebase' },
      { command: 'snippet', description: 'Save code snippet' },
      { command: 'voice', description: 'Voice coding mode' },
      { command: 'settings', description: 'Bot settings' },
    ]);
    
    // Command handlers
    this.bot.command('start', this.handleStart.bind(this));
    this.bot.command('code', this.handleCode.bind(this));
    this.bot.command('review', this.handleReview.bind(this));
    this.bot.command('explain', this.handleExplain.bind(this));
    this.bot.command('debug', this.handleDebug.bind(this));
    this.bot.command('implement', this.handleImplement.bind(this));
    this.bot.command('refactor', this.handleRefactor.bind(this));
    this.bot.command('test', this.handleTest.bind(this));
    this.bot.command('docs', this.handleDocs.bind(this));
    this.bot.command('pr', this.handlePR.bind(this));
    this.bot.command('issue', this.handleIssue.bind(this));
    this.bot.command('deploy', this.handleDeploy.bind(this));
    this.bot.command('search', this.handleSearch.bind(this));
    this.bot.command('snippet', this.handleSnippet.bind(this));
    this.bot.command('voice', this.handleVoice.bind(this));
    this.bot.command('settings', this.handleSettings.bind(this));
  }

  /**
   * Setup message handlers
   */
  setupHandlers() {
    // Text messages
    this.bot.on('text', this.handleTextMessage.bind(this));
    
    // Code/documents
    this.bot.on('document', this.handleDocument.bind(this));
    
    // Photos (for screenshots)
    this.bot.on('photo', this.handlePhoto.bind(this));
    
    // Voice messages
    this.bot.on('voice', this.handleVoiceMessage.bind(this));
    
    // Callback queries (inline keyboards)
    this.bot.on('callback_query', this.handleCallbackQuery.bind(this));
    
    // Inline queries
    this.bot.on('inline_query', this.handleInlineQuery.bind(this));
  }

  /**
   * Setup inline mode for quick code snippets
   */
  setupInlineMode() {
    this.bot.on('inline_query', async (ctx) => {
      const query = ctx.inlineQuery.query;
      
      if (!query) {
        return ctx.answerInlineQuery([]);
      }
      
      // Quick code generation
      const results = [
        {
          type: 'article',
          id: 'generate',
          title: '🚀 Generate Code',
          description: `Generate: ${query}`,
          input_message_content: {
            message_text: `Generating code for: ${query}...`,
          },
        },
        {
          type: 'article',
          id: 'explain',
          title: '📖 Explain Code',
          description: `Explain: ${query}`,
          input_message_content: {
            message_text: `Explaining: ${query}...`,
          },
        },
        {
          type: 'article',
          id: 'fix',
          title: '🔧 Fix Code',
          description: `Fix: ${query}`,
          input_message_content: {
            message_text: `Fixing: ${query}...`,
          },
        },
      ];
      
      await ctx.answerInlineQuery(results);
    });
  }

  /**
   * Handle /start command
   */
  async handleStart(ctx) {
    const welcomeMessage = `
🤖 *Welcome to Claude Code Bot!*

I'm your AI-powered coding assistant, available 24/7 on your mobile device.

*What I can do:*
• 💻 Write and review code
• 🐛 Debug issues
• 📚 Explain concepts
• 🚀 Implement features
• 🧪 Generate tests
• 📝 Create documentation
• 🔍 Search codebases
• 🎤 Voice coding

*Quick Start:*
1. Send me code to review
2. Ask coding questions
3. Use commands for specific tasks
4. Send voice messages for hands-free coding

*Pro Tips:*
• Use inline mode: @ClaudeCodeBot <query>
• Save snippets with /snippet
• Create PRs directly from mobile

Ready to code? Just send me a message!
`;

    await ctx.replyWithMarkdown(
      welcomeMessage,
      Markup.keyboard([
        ['💻 Write Code', '🔍 Review Code'],
        ['🐛 Debug', '📚 Explain'],
        ['🚀 Implement', '🧪 Test'],
        ['📝 Docs', '⚙️ Settings'],
      ]).resize()
    );
  }

  /**
   * Handle /code command - AI code generation
   */
  async handleCode(ctx) {
    const args = ctx.message.text.split(' ').slice(1).join(' ');
    
    if (!args) {
      await ctx.reply(
        'What would you like me to code?',
        Markup.inlineKeyboard([
          [Markup.button.callback('React Component', 'code_react')],
          [Markup.button.callback('API Endpoint', 'code_api')],
          [Markup.button.callback('Database Query', 'code_db')],
          [Markup.button.callback('Algorithm', 'code_algo')],
          [Markup.button.callback('Custom', 'code_custom')],
        ])
      );
      return;
    }
    
    await ctx.replyWithChatAction('typing');
    
    const prompt = `
    Generate code for: ${args}
    
    Requirements:
    - Production-ready code
    - Include error handling
    - Add helpful comments
    - Follow best practices
    - Mobile-friendly formatting
    
    Provide the code with a brief explanation.
    `;
    
    try {
      const response = await this.anthropic.messages.create({
        model: 'claude-3-opus-20240229',
        max_tokens: 2000,
        messages: [{ role: 'user', content: prompt }],
      });
      
      const code = response.content[0].text;
      
      // Send code in formatted message
      await this.sendCodeMessage(ctx, code, args);
      
    } catch (error) {
      await ctx.reply(`Error: ${error.message}`);
    }
  }

  /**
   * Handle code review
   */
  async handleReview(ctx) {
    const args = ctx.message.text.split(' ').slice(1).join(' ');
    
    if (!args) {
      await ctx.reply(
        'Send me code to review or a GitHub PR URL:',
        Markup.inlineKeyboard([
          [Markup.button.callback('Paste Code', 'review_paste')],
          [Markup.button.callback('Upload File', 'review_file')],
          [Markup.button.callback('GitHub PR', 'review_pr')],
          [Markup.button.callback('Recent PRs', 'review_recent')],
        ])
      );
      return;
    }
    
    // Check if it's a GitHub URL
    if (args.includes('github.com')) {
      await this.reviewGitHubPR(ctx, args);
    } else {
      await this.reviewCode(ctx, args);
    }
  }

  /**
   * Review code snippet
   */
  async reviewCode(ctx, code) {
    await ctx.replyWithChatAction('typing');
    
    const prompt = `
    Review this code for:
    1. Bugs and issues
    2. Best practices
    3. Performance
    4. Security
    5. Readability
    
    Code:
    ${code}
    
    Provide:
    - Overall score (1-10)
    - Key issues
    - Suggestions
    - Fixed version if needed
    
    Format for mobile reading.
    `;
    
    try {
      const response = await this.anthropic.messages.create({
        model: 'claude-3-opus-20240229',
        max_tokens: 2000,
        messages: [{ role: 'user', content: prompt }],
      });
      
      const review = response.content[0].text;
      
      // Format review for Telegram
      const formattedReview = this.formatReviewForTelegram(review);
      
      await ctx.replyWithMarkdown(formattedReview);
      
      // Add action buttons
      await ctx.reply(
        'What would you like to do?',
        Markup.inlineKeyboard([
          [Markup.button.callback('🔧 Apply Fixes', 'apply_fixes')],
          [Markup.button.callback('💾 Save Review', 'save_review')],
          [Markup.button.callback('📤 Share', 'share_review')],
        ])
      );
      
    } catch (error) {
      await ctx.reply(`Error: ${error.message}`);
    }
  }

  /**
   * Handle voice messages for voice coding
   */
  async handleVoiceMessage(ctx) {
    await ctx.reply('🎤 Processing voice message...');
    
    try {
      // Get voice file
      const fileId = ctx.message.voice.file_id;
      const fileUrl = await ctx.telegram.getFileLink(fileId);
      
      // Here you would integrate with a speech-to-text service
      // For now, we'll simulate it
      await ctx.replyWithChatAction('typing');
      
      // Simulate transcription
      const transcription = "Create a React component for user profile";
      
      await ctx.reply(`📝 Transcribed: "${transcription}"`);
      
      // Process the coding request
      await this.handleCode({
        ...ctx,
        message: { ...ctx.message, text: `/code ${transcription}` }
      });
      
    } catch (error) {
      await ctx.reply(`Error processing voice: ${error.message}`);
    }
  }

  /**
   * Handle document uploads
   */
  async handleDocument(ctx) {
    const document = ctx.message.document;
    
    // Check if it's a code file
    const codeExtensions = ['.js', '.ts', '.jsx', '.tsx', '.py', '.go', '.rs', '.java', '.cpp', '.c', '.html', '.css'];
    const isCodeFile = codeExtensions.some(ext => document.file_name.endsWith(ext));
    
    if (!isCodeFile) {
      await ctx.reply('Please send a code file for review.');
      return;
    }
    
    await ctx.replyWithChatAction('typing');
    
    try {
      // Download file
      const fileUrl = await ctx.telegram.getFileLink(document.file_id);
      const response = await fetch(fileUrl.href);
      const code = await response.text();
      
      // Offer options
      await ctx.reply(
        `📄 Received: ${document.file_name}`,
        Markup.inlineKeyboard([
          [Markup.button.callback('🔍 Review', 'doc_review')],
          [Markup.button.callback('📖 Explain', 'doc_explain')],
          [Markup.button.callback('♻️ Refactor', 'doc_refactor')],
          [Markup.button.callback('🧪 Generate Tests', 'doc_test')],
        ])
      );
      
      // Store code for later use
      this.storeCodeSnippet(ctx.from.id, code, document.file_name);
      
    } catch (error) {
      await ctx.reply(`Error processing file: ${error.message}`);
    }
  }

  /**
   * Handle inline keyboard callbacks
   */
  async handleCallbackQuery(ctx) {
    const action = ctx.callbackQuery.data;
    const [command, ...args] = action.split('_');
    
    await ctx.answerCbQuery();
    
    switch (command) {
      case 'code':
        await this.handleCodeType(ctx, args[0]);
        break;
      case 'review':
        await this.handleReviewType(ctx, args[0]);
        break;
      case 'doc':
        await this.handleDocumentAction(ctx, args[0]);
        break;
      case 'pr':
        await this.handlePRAction(ctx, args);
        break;
      case 'deploy':
        await this.handleDeployAction(ctx, args[0]);
        break;
      default:
        await ctx.reply('Unknown action');
    }
  }

  /**
   * Handle code generation types
   */
  async handleCodeType(ctx, type) {
    const prompts = {
      react: 'Create a React component with TypeScript, hooks, and proper styling',
      api: 'Create a REST API endpoint with error handling and validation',
      db: 'Create a database query with proper indexing and optimization',
      algo: 'Implement an efficient algorithm with time/space complexity analysis',
      custom: 'What would you like me to code?',
    };
    
    if (type === 'custom') {
      await ctx.reply('Please describe what you want me to code:');
      this.setUserSession(ctx.from.id, { waitingFor: 'code_description' });
    } else {
      await ctx.reply(`Creating ${type} code...`);
      await this.handleCode({
        ...ctx,
        message: { text: `/code ${prompts[type]}` }
      });
    }
  }

  /**
   * Handle PR creation
   */
  async handlePR(ctx) {
    await ctx.reply(
      '📋 Pull Request Management',
      Markup.inlineKeyboard([
        [Markup.button.callback('➕ Create PR', 'pr_create')],
        [Markup.button.callback('📋 List PRs', 'pr_list')],
        [Markup.button.callback('🔍 Review PR', 'pr_review')],
        [Markup.button.callback('🔀 Merge PR', 'pr_merge')],
      ])
    );
  }

  /**
   * Handle implementation requests
   */
  async handleImplement(ctx) {
    const feature = ctx.message.text.split(' ').slice(1).join(' ');
    
    if (!feature) {
      await ctx.reply('What feature would you like me to implement?');
      return;
    }
    
    await ctx.reply(
      `🚀 Starting implementation of: *${feature}*`,
      { parse_mode: 'Markdown' }
    );
    
    try {
      // Create GitHub issue
      const { data: issue } = await this.github.issues.create({
        owner: this.config.githubOwner,
        repo: this.config.githubRepo,
        title: feature,
        body: `Requested via Telegram by user ${ctx.from.username || ctx.from.id}`,
        labels: ['ai-implement', 'from-telegram'],
      });
      
      // Trigger implementation
      await this.github.actions.createWorkflowDispatch({
        owner: this.config.githubOwner,
        repo: this.config.githubRepo,
        workflow_id: 'ai-pr-creator.yml',
        ref: 'main',
        inputs: {
          task_description: feature,
          branch_name: `telegram-${Date.now()}`,
        },
      });
      
      await ctx.reply(
        `✅ Implementation started!\n\n📋 Issue: #${issue.number}\n🔗 [View on GitHub](${issue.html_url})`,
        { parse_mode: 'Markdown', disable_web_page_preview: true }
      );
      
      // Set up notification
      this.trackImplementation(ctx.from.id, issue.number);
      
    } catch (error) {
      await ctx.reply(`Error: ${error.message}`);
    }
  }

  /**
   * Format code for Telegram with syntax highlighting
   */
  async sendCodeMessage(ctx, code, description) {
    // Extract code blocks
    const codeBlocks = code.match(/```[\s\S]*?```/g) || [code];
    
    // Send description
    await ctx.reply(`💻 *Generated: ${description}*`, { parse_mode: 'Markdown' });
    
    // Send each code block
    for (const block of codeBlocks) {
      const cleanCode = block.replace(/```\w*\n?/g, '').trim();
      const language = block.match(/```(\w+)/)?.[1] || '';
      
      // Telegram has a 4096 character limit
      if (cleanCode.length > 4000) {
        // Save as file
        const fileName = `code-${Date.now()}.${language || 'txt'}`;
        await ctx.replyWithDocument({
          source: Buffer.from(cleanCode),
          filename: fileName,
        });
      } else {
        await ctx.reply(
          '```' + language + '\n' + cleanCode + '\n```',
          { parse_mode: 'Markdown' }
        );
      }
    }
    
    // Add action buttons
    await ctx.reply(
      'Actions:',
      Markup.inlineKeyboard([
        [
          Markup.button.callback('💾 Save', 'save_code'),
          Markup.button.callback('📤 Share', 'share_code'),
        ],
        [
          Markup.button.callback('✏️ Edit', 'edit_code'),
          Markup.button.callback('🧪 Test', 'test_code'),
        ],
        [
          Markup.button.url('📱 Open in Editor', 'https://github.dev/'),
        ],
      ])
    );
  }

  /**
   * Handle search in codebase
   */
  async handleSearch(ctx) {
    const query = ctx.message.text.split(' ').slice(1).join(' ');
    
    if (!query) {
      await ctx.reply(
        '🔍 What would you like to search for?',
        Markup.inlineKeyboard([
          [Markup.button.callback('Functions', 'search_functions')],
          [Markup.button.callback('Classes', 'search_classes')],
          [Markup.button.callback('TODOs', 'search_todos')],
          [Markup.button.callback('Errors', 'search_errors')],
        ])
      );
      return;
    }
    
    await ctx.replyWithChatAction('typing');
    
    try {
      // Search in GitHub
      const { data } = await this.github.search.code({
        q: `${query} repo:${this.config.githubOwner}/${this.config.githubRepo}`,
        per_page: 5,
      });
      
      if (data.total_count === 0) {
        await ctx.reply('No results found.');
        return;
      }
      
      let message = `🔍 *Search Results for "${query}":*\n\n`;
      
      data.items.forEach((item, index) => {
        message += `${index + 1}. *${item.name}*\n`;
        message += `   📁 ${item.path}\n`;
        message += `   [View](${item.html_url})\n\n`;
      });
      
      message += `_Found ${data.total_count} results (showing top 5)_`;
      
      await ctx.reply(message, {
        parse_mode: 'Markdown',
        disable_web_page_preview: true,
      });
      
    } catch (error) {
      await ctx.reply(`Search error: ${error.message}`);
    }
  }

  /**
   * Settings management
   */
  async handleSettings(ctx) {
    const settings = this.getUserSettings(ctx.from.id);
    
    await ctx.reply(
      '⚙️ *Settings*',
      {
        parse_mode: 'Markdown',
        reply_markup: {
          inline_keyboard: [
            [
              {
                text: `🔔 Notifications: ${settings.notifications ? 'ON' : 'OFF'}`,
                callback_data: 'toggle_notifications',
              },
            ],
            [
              {
                text: `🌐 Default Language: ${settings.language || 'JavaScript'}`,
                callback_data: 'change_language',
              },
            ],
            [
              {
                text: `🎨 Code Style: ${settings.codeStyle || 'Standard'}`,
                callback_data: 'change_style',
              },
            ],
            [
              {
                text: '🔗 Connect GitHub',
                callback_data: 'connect_github',
              },
            ],
            [
              {
                text: '📊 Usage Stats',
                callback_data: 'view_stats',
              },
            ],
          ],
        },
      }
    );
  }

  /**
   * User session management
   */
  setUserSession(userId, data) {
    this.sessions.set(userId, {
      ...this.sessions.get(userId),
      ...data,
      lastActive: new Date(),
    });
  }

  getUserSession(userId) {
    return this.sessions.get(userId) || {};
  }

  /**
   * Code snippet storage
   */
  storeCodeSnippet(userId, code, filename = 'snippet') {
    const id = crypto.randomBytes(8).toString('hex');
    this.codeSnippets.set(id, {
      userId,
      code,
      filename,
      timestamp: new Date(),
    });
    return id;
  }

  /**
   * User settings
   */
  getUserSettings(userId) {
    // In production, this would be stored in a database
    return {
      notifications: true,
      language: 'JavaScript',
      codeStyle: 'Standard',
      githubConnected: false,
    };
  }

  /**
   * Format review for Telegram
   */
  formatReviewForTelegram(review) {
    // Parse and format for mobile
    const lines = review.split('\n');
    let formatted = '🔍 *Code Review*\n\n';
    
    lines.forEach(line => {
      if (line.includes('Score:')) {
        formatted += `📊 ${line}\n`;
      } else if (line.includes('Issues:')) {
        formatted += `\n⚠️ *Issues Found:*\n`;
      } else if (line.includes('Suggestions:')) {
        formatted += `\n💡 *Suggestions:*\n`;
      } else if (line.startsWith('-')) {
        formatted += `  ${line}\n`;
      } else if (line.trim()) {
        formatted += `${line}\n`;
      }
    });
    
    return formatted;
  }

  /**
   * Track implementation for notifications
   */
  trackImplementation(userId, issueNumber) {
    // In production, store in database
    // Set up webhook or polling to notify when PR is ready
    console.log(`Tracking implementation for user ${userId}, issue ${issueNumber}`);
  }

  /**
   * Start the bot
   */
  async start() {
    await this.bot.launch();
    console.log('🤖 Claude Code Telegram bot is running!');
  }

  /**
   * Graceful shutdown
   */
  stop() {
    this.bot.stop('SIGINT');
    this.bot.stop('SIGTERM');
  }
}

module.exports = ClaudeCodeTelegramBot;