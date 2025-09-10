/**
 * Claude Code Cloudflare Worker
 * 
 * AI-powered edge functions for serverless development
 * Runs Claude AI directly on Cloudflare's global network
 */

import { Anthropic } from '@anthropic-ai/sdk';

// Environment bindings interface
const ALLOWED_ORIGINS = [
  'https://github.com',
  'https://api.github.com',
  'https://linear.app',
  'https://slack.com',
  'https://api.telegram.org'
];

export default {
  async fetch(request, env, ctx) {
    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': getAllowedOrigin(request),
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-API-Key',
      'Access-Control-Max-Age': '86400',
    };

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    const url = new URL(request.url);
    
    try {
      // Route handlers
      switch (url.pathname) {
        case '/':
          return handleHome(request, corsHeaders);
        
        case '/health':
          return handleHealth(env, corsHeaders);
        
        case '/api/code':
          return handleCodeGeneration(request, env, corsHeaders);
        
        case '/api/review':
          return handleCodeReview(request, env, corsHeaders);
        
        case '/api/debug':
          return handleDebug(request, env, corsHeaders);
        
        case '/api/refactor':
          return handleRefactor(request, env, corsHeaders);
        
        case '/api/test':
          return handleTestGeneration(request, env, corsHeaders);
        
        case '/api/docs':
          return handleDocumentation(request, env, corsHeaders);
        
        case '/api/chat':
          return handleChat(request, env, ctx, corsHeaders);
        
        case '/webhooks/github':
          return handleGitHubWebhook(request, env, corsHeaders);
        
        case '/webhooks/linear':
          return handleLinearWebhook(request, env, corsHeaders);
        
        default:
          return new Response('Not Found', { status: 404, headers: corsHeaders });
      }
    } catch (error) {
      console.error('Worker error:', error);
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
  },

  // Scheduled handler for periodic tasks
  async scheduled(controller, env, ctx) {
    console.log('Running scheduled task...');
    
    // Clean up old cache entries
    await cleanupCache(env);
    
    // Update metrics
    await updateMetrics(env);
  },

  // Email handler for incoming emails
  async email(message, env, ctx) {
    console.log('Received email:', message.from);
    
    // Process email and generate AI response
    const response = await processEmail(message, env);
    
    // Forward to appropriate destination
    await forwardEmail(response, env);
  }
};

// Helper function to get allowed origin
function getAllowedOrigin(request) {
  const origin = request.headers.get('Origin');
  if (origin && ALLOWED_ORIGINS.includes(origin)) {
    return origin;
  }
  return ALLOWED_ORIGINS[0];
}

// Home endpoint
async function handleHome(request, corsHeaders) {
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <title>Claude Code Worker</title>
      <style>
        body { font-family: system-ui; max-width: 800px; margin: 0 auto; padding: 2rem; }
        .endpoint { background: #f4f4f4; padding: 1rem; margin: 1rem 0; border-radius: 8px; }
        code { background: #e4e4e4; padding: 0.2rem 0.4rem; border-radius: 4px; }
      </style>
    </head>
    <body>
      <h1>🤖 Claude Code Cloudflare Worker</h1>
      <p>AI-powered development directly on Cloudflare's edge network.</p>
      
      <h2>Available Endpoints</h2>
      <div class="endpoint">
        <h3>POST /api/code</h3>
        <p>Generate code from descriptions</p>
        <code>{"prompt": "Create a React component", "language": "typescript"}</code>
      </div>
      
      <div class="endpoint">
        <h3>POST /api/review</h3>
        <p>AI-powered code review</p>
        <code>{"code": "...", "language": "javascript", "focus": "security"}</code>
      </div>
      
      <div class="endpoint">
        <h3>POST /api/debug</h3>
        <p>Debug code issues</p>
        <code>{"code": "...", "error": "TypeError...", "context": "..."}</code>
      </div>
      
      <div class="endpoint">
        <h3>POST /api/refactor</h3>
        <p>Refactor and improve code</p>
        <code>{"code": "...", "goals": ["performance", "readability"]}</code>
      </div>
      
      <div class="endpoint">
        <h3>POST /api/test</h3>
        <p>Generate tests for code</p>
        <code>{"code": "...", "framework": "jest", "coverage": "comprehensive"}</code>
      </div>
      
      <div class="endpoint">
        <h3>POST /api/docs</h3>
        <p>Generate documentation</p>
        <code>{"code": "...", "style": "jsdoc", "detail": "comprehensive"}</code>
      </div>
      
      <div class="endpoint">
        <h3>POST /api/chat</h3>
        <p>Interactive AI chat (streaming)</p>
        <code>{"message": "How do I...", "context": []}</code>
      </div>
    </body>
    </html>
  `;
  
  return new Response(html, {
    headers: { ...corsHeaders, 'Content-Type': 'text/html' }
  });
}

// Health check endpoint
async function handleHealth(env, corsHeaders) {
  const metrics = await getMetrics(env);
  
  return new Response(JSON.stringify({
    status: 'healthy',
    worker: 'claude-code',
    region: env.CF_REGION || 'unknown',
    timestamp: new Date().toISOString(),
    metrics
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

// Code generation endpoint
async function handleCodeGeneration(request, env, corsHeaders) {
  const { prompt, language = 'javascript', framework = null } = await request.json();
  
  if (!prompt) {
    return new Response(JSON.stringify({ error: 'Prompt required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  // Check cache first
  const cacheKey = `code:${hashString(prompt + language + framework)}`;
  const cached = await env.KV_CACHE.get(cacheKey);
  if (cached) {
    return new Response(cached, {
      headers: { ...corsHeaders, 'Content-Type': 'application/json', 'X-Cache': 'HIT' }
    });
  }
  
  const anthropic = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
  
  const systemPrompt = `You are an expert ${language} developer. Generate clean, efficient, well-documented code.
${framework ? `Use the ${framework} framework.` : ''}
Follow best practices and include error handling.`;
  
  const response = await anthropic.messages.create({
    model: 'claude-3-opus-20240229',
    system: systemPrompt,
    messages: [{ role: 'user', content: prompt }],
    max_tokens: 4000,
    temperature: 0.2
  });
  
  const result = {
    code: response.content[0].text,
    language,
    framework,
    timestamp: new Date().toISOString()
  };
  
  // Cache the result
  await env.KV_CACHE.put(cacheKey, JSON.stringify(result), {
    expirationTtl: 3600 // 1 hour
  });
  
  // Track metrics
  await trackMetric(env, 'code_generation');
  
  return new Response(JSON.stringify(result), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

// Code review endpoint
async function handleCodeReview(request, env, corsHeaders) {
  const { code, language = 'javascript', focus = 'comprehensive' } = await request.json();
  
  if (!code) {
    return new Response(JSON.stringify({ error: 'Code required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  const anthropic = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
  
  const focusPrompts = {
    comprehensive: 'Provide a comprehensive code review covering all aspects.',
    security: 'Focus on security vulnerabilities and best practices.',
    performance: 'Focus on performance optimizations and bottlenecks.',
    readability: 'Focus on code readability and maintainability.',
    bugs: 'Focus on finding potential bugs and edge cases.'
  };
  
  const systemPrompt = `You are an expert code reviewer. ${focusPrompts[focus] || focusPrompts.comprehensive}
Provide actionable feedback with severity levels (critical, major, minor, suggestion).`;
  
  const response = await anthropic.messages.create({
    model: 'claude-3-opus-20240229',
    system: systemPrompt,
    messages: [{
      role: 'user',
      content: `Review this ${language} code:\n\n\`\`\`${language}\n${code}\n\`\`\``
    }],
    max_tokens: 4000,
    temperature: 0.3
  });
  
  // Parse the review into structured format
  const review = parseCodeReview(response.content[0].text);
  
  // Track metrics
  await trackMetric(env, 'code_review');
  
  return new Response(JSON.stringify({
    review,
    focus,
    timestamp: new Date().toISOString()
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

// Debug endpoint
async function handleDebug(request, env, corsHeaders) {
  const { code, error, context = '', stackTrace = '' } = await request.json();
  
  if (!code || !error) {
    return new Response(JSON.stringify({ error: 'Code and error required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  const anthropic = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
  
  const debugPrompt = `Debug this code that's producing an error:

Code:
\`\`\`
${code}
\`\`\`

Error:
${error}

${stackTrace ? `Stack Trace:\n${stackTrace}\n` : ''}
${context ? `Context:\n${context}` : ''}

Provide:
1. Root cause analysis
2. Specific fix with code
3. Explanation of why it happened
4. Prevention tips`;
  
  const response = await anthropic.messages.create({
    model: 'claude-3-opus-20240229',
    system: 'You are an expert debugger. Analyze code issues and provide clear solutions.',
    messages: [{ role: 'user', content: debugPrompt }],
    max_tokens: 4000,
    temperature: 0.2
  });
  
  // Track metrics
  await trackMetric(env, 'debug');
  
  return new Response(JSON.stringify({
    analysis: response.content[0].text,
    timestamp: new Date().toISOString()
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

// Refactor endpoint
async function handleRefactor(request, env, corsHeaders) {
  const { code, goals = ['readability'], language = 'javascript' } = await request.json();
  
  if (!code) {
    return new Response(JSON.stringify({ error: 'Code required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  const anthropic = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
  
  const goalDescriptions = {
    readability: 'Improve code readability and clarity',
    performance: 'Optimize for better performance',
    maintainability: 'Enhance long-term maintainability',
    testability: 'Make the code more testable',
    modularity: 'Improve modularity and separation of concerns',
    modern: 'Update to modern syntax and patterns'
  };
  
  const selectedGoals = goals.map(g => goalDescriptions[g] || g).join(', ');
  
  const response = await anthropic.messages.create({
    model: 'claude-3-opus-20240229',
    system: `You are an expert at code refactoring. Refactor code to: ${selectedGoals}`,
    messages: [{
      role: 'user',
      content: `Refactor this ${language} code:\n\n\`\`\`${language}\n${code}\n\`\`\``
    }],
    max_tokens: 4000,
    temperature: 0.2
  });
  
  // Track metrics
  await trackMetric(env, 'refactor');
  
  return new Response(JSON.stringify({
    original: code,
    refactored: extractCode(response.content[0].text),
    explanation: extractExplanation(response.content[0].text),
    goals,
    timestamp: new Date().toISOString()
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

// Test generation endpoint
async function handleTestGeneration(request, env, corsHeaders) {
  const { code, framework = 'jest', coverage = 'comprehensive' } = await request.json();
  
  if (!code) {
    return new Response(JSON.stringify({ error: 'Code required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  const anthropic = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
  
  const coveragePrompts = {
    basic: 'Create basic tests covering main functionality',
    comprehensive: 'Create comprehensive tests with high coverage',
    edge_cases: 'Focus on edge cases and error scenarios',
    integration: 'Create integration tests',
    unit: 'Create focused unit tests'
  };
  
  const response = await anthropic.messages.create({
    model: 'claude-3-opus-20240229',
    system: `You are an expert at writing tests. Use ${framework} framework. ${coveragePrompts[coverage]}`,
    messages: [{
      role: 'user',
      content: `Generate tests for this code:\n\n\`\`\`javascript\n${code}\n\`\`\``
    }],
    max_tokens: 4000,
    temperature: 0.2
  });
  
  // Track metrics
  await trackMetric(env, 'test_generation');
  
  return new Response(JSON.stringify({
    tests: extractCode(response.content[0].text),
    framework,
    coverage,
    timestamp: new Date().toISOString()
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

// Documentation generation endpoint
async function handleDocumentation(request, env, corsHeaders) {
  const { code, style = 'jsdoc', detail = 'comprehensive' } = await request.json();
  
  if (!code) {
    return new Response(JSON.stringify({ error: 'Code required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  const anthropic = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
  
  const stylePrompts = {
    jsdoc: 'Generate JSDoc style documentation',
    markdown: 'Generate markdown documentation',
    inline: 'Add inline comments throughout the code',
    readme: 'Generate a README.md file'
  };
  
  const response = await anthropic.messages.create({
    model: 'claude-3-opus-20240229',
    system: `You are a technical writer. ${stylePrompts[style]}. Be ${detail}.`,
    messages: [{
      role: 'user',
      content: `Document this code:\n\n\`\`\`javascript\n${code}\n\`\`\``
    }],
    max_tokens: 4000,
    temperature: 0.3
  });
  
  // Track metrics
  await trackMetric(env, 'documentation');
  
  return new Response(JSON.stringify({
    documentation: response.content[0].text,
    style,
    detail,
    timestamp: new Date().toISOString()
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

// Interactive chat endpoint with streaming
async function handleChat(request, env, ctx, corsHeaders) {
  const { message, context = [] } = await request.json();
  
  if (!message) {
    return new Response(JSON.stringify({ error: 'Message required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  // Create a TransformStream for streaming
  const { readable, writable } = new TransformStream();
  const writer = writable.getWriter();
  const encoder = new TextEncoder();
  
  // Start the stream
  ctx.waitUntil((async () => {
    try {
      const anthropic = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
      
      const messages = [
        ...context.map(msg => ({
          role: msg.role,
          content: msg.content
        })),
        { role: 'user', content: message }
      ];
      
      const stream = await anthropic.messages.create({
        model: 'claude-3-opus-20240229',
        system: 'You are Claude Code, an AI development assistant. Help with coding tasks.',
        messages,
        max_tokens: 4000,
        temperature: 0.5,
        stream: true
      });
      
      for await (const chunk of stream) {
        if (chunk.type === 'content_block_delta') {
          const data = `data: ${JSON.stringify({ text: chunk.delta.text })}\n\n`;
          await writer.write(encoder.encode(data));
        }
      }
      
      await writer.write(encoder.encode('data: [DONE]\n\n'));
      await writer.close();
      
      // Track metrics
      await trackMetric(env, 'chat');
    } catch (error) {
      await writer.write(encoder.encode(`data: ${JSON.stringify({ error: error.message })}\n\n`));
      await writer.close();
    }
  })());
  
  return new Response(readable, {
    headers: {
      ...corsHeaders,
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive'
    }
  });
}

// GitHub webhook handler
async function handleGitHubWebhook(request, env, corsHeaders) {
  const signature = request.headers.get('X-Hub-Signature-256');
  const body = await request.text();
  
  // Verify webhook signature
  if (!await verifyGitHubSignature(body, signature, env.GITHUB_WEBHOOK_SECRET)) {
    return new Response('Unauthorized', { status: 401, headers: corsHeaders });
  }
  
  const payload = JSON.parse(body);
  const event = request.headers.get('X-GitHub-Event');
  
  // Process different GitHub events
  switch (event) {
    case 'issues':
      if (payload.action === 'labeled' && payload.label.name === 'ai-implement') {
        await processGitHubIssue(payload, env);
      }
      break;
    
    case 'pull_request':
      if (payload.action === 'opened' || payload.action === 'synchronize') {
        await processGitHubPR(payload, env);
      }
      break;
  }
  
  return new Response('OK', { headers: corsHeaders });
}

// Linear webhook handler
async function handleLinearWebhook(request, env, corsHeaders) {
  const signature = request.headers.get('Linear-Signature');
  const body = await request.text();
  
  // Verify webhook signature
  if (!await verifyLinearSignature(body, signature, env.LINEAR_WEBHOOK_SECRET)) {
    return new Response('Unauthorized', { status: 401, headers: corsHeaders });
  }
  
  const payload = JSON.parse(body);
  
  // Process Linear events
  if (payload.type === 'Issue' && payload.action === 'create') {
    await processLinearIssue(payload, env);
  }
  
  return new Response('OK', { headers: corsHeaders });
}

// Helper functions
function hashString(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  return Math.abs(hash).toString(36);
}

function parseCodeReview(text) {
  const issues = [];
  const lines = text.split('\n');
  let currentIssue = null;
  
  for (const line of lines) {
    if (line.match(/^(CRITICAL|MAJOR|MINOR|SUGGESTION):/)) {
      if (currentIssue) issues.push(currentIssue);
      const [severity, ...rest] = line.split(':');
      currentIssue = {
        severity: severity.toLowerCase(),
        message: rest.join(':').trim(),
        details: []
      };
    } else if (currentIssue && line.trim()) {
      currentIssue.details.push(line.trim());
    }
  }
  
  if (currentIssue) issues.push(currentIssue);
  
  return {
    issues,
    summary: text.split('\n')[0],
    recommendation: issues.some(i => i.severity === 'critical') ? 'needs-work' : 'approve'
  };
}

function extractCode(text) {
  const codeMatch = text.match(/```[\w]*\n([\s\S]*?)```/);
  return codeMatch ? codeMatch[1].trim() : text;
}

function extractExplanation(text) {
  const parts = text.split(/```[\w]*\n[\s\S]*?```/);
  return parts.map(p => p.trim()).filter(p => p).join('\n\n');
}

async function verifyGitHubSignature(body, signature, secret) {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['verify']
  );
  
  const expectedSignature = await crypto.subtle.sign(
    'HMAC',
    key,
    encoder.encode(body)
  );
  
  const expected = 'sha256=' + Array.from(new Uint8Array(expectedSignature))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
  
  return signature === expected;
}

async function verifyLinearSignature(body, signature, secret) {
  // Similar to GitHub signature verification
  return true; // Simplified for example
}

async function processGitHubIssue(payload, env) {
  // Create AI implementation for the issue
  console.log('Processing GitHub issue:', payload.issue.title);
  
  // Store in D1 for tracking
  await env.DB.prepare(
    'INSERT INTO tasks (github_issue_id, title, status) VALUES (?, ?, ?)'
  ).bind(payload.issue.id, payload.issue.title, 'pending').run();
}

async function processGitHubPR(payload, env) {
  // Trigger AI code review
  console.log('Processing GitHub PR:', payload.pull_request.title);
  
  // Queue for processing
  await env.QUEUE.send({
    type: 'pr_review',
    pr: payload.pull_request
  });
}

async function processLinearIssue(payload, env) {
  // Process Linear issue
  console.log('Processing Linear issue:', payload.data.title);
}

async function getMetrics(env) {
  const metrics = await env.KV_METRICS.get('daily_metrics', 'json') || {};
  return {
    requests_today: metrics.requests || 0,
    cache_hits: metrics.cache_hits || 0,
    api_calls: metrics.api_calls || 0
  };
}

async function trackMetric(env, type) {
  const metrics = await env.KV_METRICS.get('daily_metrics', 'json') || {};
  metrics.requests = (metrics.requests || 0) + 1;
  metrics[type] = (metrics[type] || 0) + 1;
  await env.KV_METRICS.put('daily_metrics', JSON.stringify(metrics));
}

async function cleanupCache(env) {
  // Implement cache cleanup logic
  console.log('Cleaning up cache...');
}

async function updateMetrics(env) {
  // Reset daily metrics
  await env.KV_METRICS.put('daily_metrics', JSON.stringify({}));
}

async function processEmail(message, env) {
  // Process incoming email with AI
  const anthropic = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
  
  const response = await anthropic.messages.create({
    model: 'claude-3-opus-20240229',
    system: 'You are an AI assistant responding to emails about coding questions.',
    messages: [{
      role: 'user',
      content: `Email from: ${message.from}\nSubject: ${message.subject}\n\n${message.text}`
    }],
    max_tokens: 2000
  });
  
  return {
    to: message.from,
    subject: `Re: ${message.subject}`,
    text: response.content[0].text
  };
}

async function forwardEmail(response, env) {
  // Forward email response
  console.log('Forwarding email to:', response.to);
}