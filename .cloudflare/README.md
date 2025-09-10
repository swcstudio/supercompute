# 🌐 Cloudflare Claude Code Integration

Complete edge AI development platform powered by Cloudflare Workers, Pages, KV, D1, and R2 with Claude Code AI.

## 🚀 Quick Start

### 1. One-Command Setup

```bash
# Run the automated setup script
./scripts/setup.sh
```

This will:
- Create all Cloudflare resources (KV, D1, R2)
- Configure wrangler.toml with correct IDs
- Set up database migrations
- Deploy the Claude Code Worker
- Guide you through secret configuration

### 2. Manual Setup

If you prefer manual setup:

```bash
# Install dependencies
npm install

# Login to Cloudflare
wrangler login

# Create resources
wrangler kv:namespace create "CACHE"
wrangler kv:namespace create "METRICS"
wrangler d1 create claude-code-db
wrangler r2 bucket create claude-code-storage

# Set secrets
wrangler secret put ANTHROPIC_API_KEY
wrangler secret put GITHUB_TOKEN
# ... other secrets

# Deploy
wrangler publish
```

## 📁 Project Structure

```
.cloudflare/
├── workers/                 # Cloudflare Workers
│   ├── claude-code-worker.js   # Main AI worker
│   └── wrangler.toml          # Worker configuration
├── pages/                   # Cloudflare Pages
│   ├── components/            # React edge components
│   └── functions/             # Pages Functions
├── storage/                 # Storage integrations
│   ├── kv-store.ts           # KV storage with React hooks
│   ├── d1-database.ts        # D1 database with migrations
│   └── r2-storage.ts         # R2 object storage
├── scripts/                 # Setup and utility scripts
│   └── setup.sh             # Automated setup
├── migrations/              # D1 database migrations
└── package.json            # Dependencies and scripts
```

## 🔧 Configuration

### Environment Variables

```bash
# Core (Required)
ANTHROPIC_API_KEY=sk-ant-...
GITHUB_TOKEN=ghp_...

# Platform Integrations (Optional)
LINEAR_API_KEY=lin_api_...
SLACK_BOT_TOKEN=xoxb-...
TELEGRAM_BOT_TOKEN=...

# Webhooks (Optional)
GITHUB_WEBHOOK_SECRET=...
LINEAR_WEBHOOK_SECRET=...
```

### Resource IDs

After running setup, your `wrangler.toml` will be automatically updated with:

```toml
[[kv_namespaces]]
binding = "KV_CACHE"
id = "your-actual-kv-cache-id"

[[d1_databases]]
binding = "DB"
database_id = "your-actual-d1-database-id"

[[r2_buckets]]
binding = "STORAGE"
bucket_name = "claude-code-storage"
```

## 🤖 API Endpoints

### Code Generation

```javascript
// Generate code from natural language
const response = await fetch('/api/code', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    prompt: 'Create a React component for user authentication',
    language: 'typescript',
    framework: 'react'
  })
});

const { code } = await response.json();
```

### Code Review

```javascript
// AI-powered code review
const review = await fetch('/api/review', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    code: '// your code here',
    language: 'javascript',
    focus: 'security' // comprehensive, security, performance, readability, bugs
  })
});

const { review: analysis } = await review.json();
```

### Debug Assistance

```javascript
// Debug code issues
const debug = await fetch('/api/debug', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    code: '// problematic code',
    error: 'TypeError: Cannot read property...',
    context: 'React component mounting'
  })
});

const { analysis } = await debug.json();
```

### Streaming Chat

```javascript
// Real-time AI assistance
const response = await fetch('/api/chat', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    message: 'How do I optimize React performance?',
    context: [] // Previous conversation
  })
});

// Process streaming response
const reader = response.body.getReader();
const decoder = new TextDecoder();

while (true) {
  const { done, value } = await reader.read();
  if (done) break;
  
  const chunk = decoder.decode(value);
  const lines = chunk.split('\n');
  
  for (const line of lines) {
    if (line.startsWith('data: ')) {
      const data = line.slice(6);
      if (data === '[DONE]') return;
      
      try {
        const parsed = JSON.parse(data);
        console.log('AI:', parsed.text);
      } catch {}
    }
  }
}
```

## 🎨 React Components

### Edge-Optimized Components

```tsx
import {
  EdgeComponent,
  AIEdgeComponent,
  StreamingAIComponent,
  useEdgeData
} from './.cloudflare/pages/components/CloudflareEdgeComponent';

// Edge-cached component
function App() {
  return (
    <EdgeComponent 
      cacheKey="app-shell" 
      revalidate={3600}
      fallback={<div>Loading...</div>}
    >
      <MainContent />
    </EdgeComponent>
  );
}

// AI-enhanced content
function SmartContent() {
  return (
    <AIEdgeComponent 
      prompt="Make this content more engaging and accessible"
      enhance={true}
    >
      <div>Your original content here</div>
    </AIEdgeComponent>
  );
}

// Real-time AI chat
function ChatWidget() {
  return (
    <StreamingAIComponent
      endpoint="/api/chat"
      prompt="Help me debug this React component"
      onChunk={(chunk) => console.log('Received:', chunk)}
    />
  );
}
```

### Storage Hooks

```tsx
import { useKVStore, useD1Query, useR2Upload } from '../storage';

function UserProfile({ userId }) {
  // KV for user preferences
  const { value: preferences, setValue } = useKVStore(
    'user-prefs', 
    userId,
    { theme: 'dark', notifications: true }
  );

  // D1 for user data
  const { data: userData, loading } = useD1Query(
    'claude-code-db',
    'SELECT * FROM users WHERE id = ?',
    [userId]
  );

  // R2 for avatar upload
  const { upload, uploading, progress } = useR2Upload('avatars');

  const handleAvatarUpload = async (file) => {
    await upload(`avatars/${userId}/${file.name}`, file);
  };

  return (
    <div>
      <h2>{userData?.name}</h2>
      <AvatarUpload onUpload={handleAvatarUpload} uploading={uploading} />
      <UserPreferences 
        preferences={preferences} 
        onChange={setValue} 
      />
    </div>
  );
}
```

## 🔄 Database Migrations

### Creating Migrations

```typescript
// migrations/0002_add_profiles.sql
CREATE TABLE profiles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  social_links TEXT, -- JSON
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE INDEX idx_profiles_user_id ON profiles(user_id);
```

### Running Migrations

```bash
# Local development
wrangler d1 migrations apply claude-code-db --local

# Production
wrangler d1 migrations apply claude-code-db
```

### Programmatic Migrations

```typescript
import { createD1Migrator } from './storage/d1-database';

const migrations = [
  {
    version: 1,
    name: 'initial_schema',
    up: '/* SQL here */',
    down: '/* Rollback SQL */'
  }
];

const migrator = createD1Migrator('claude-code-db', migrations);
await migrator.up(); // Run all pending migrations
```

## 📊 Monitoring & Analytics

### Health Checks

```bash
# Check worker health
curl https://your-worker.workers.dev/health

# Response
{
  "status": "healthy",
  "worker": "claude-code",
  "region": "LAX",
  "timestamp": "2024-01-15T10:30:00Z",
  "metrics": {
    "requests_today": 1250,
    "cache_hits": 892,
    "api_calls": 358
  }
}
```

### Usage Analytics

```typescript
// Track API usage
await fetch('/api/analytics', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    event: 'ai_request',
    data: {
      endpoint: '/api/code',
      tokens: 150,
      processing_time: 1.2,
      region: 'LAX'
    }
  })
});
```

### Performance Metrics

```bash
# View real-time logs
wrangler tail

# Export analytics
wrangler d1 execute claude-code-db --command "
  SELECT 
    DATE(created_at) as date,
    endpoint,
    COUNT(*) as requests,
    AVG(processing_time) as avg_time,
    SUM(response_tokens) as total_tokens
  FROM ai_requests 
  WHERE created_at >= date('now', '-7 days')
  GROUP BY DATE(created_at), endpoint
  ORDER BY date DESC
"
```

## 🔒 Security

### Authentication

```typescript
// Middleware for protected routes
async function authenticate(request: Request): Promise<User | null> {
  const token = request.headers.get('Authorization')?.replace('Bearer ', '');
  if (!token) return null;

  // Check KV cache first
  const cachedUser = await KV_CACHE.get(`auth:${token}`);
  if (cachedUser) return JSON.parse(cachedUser);

  // Validate with external service
  const user = await validateToken(token);
  if (user) {
    await KV_CACHE.put(`auth:${token}`, JSON.stringify(user), {
      expirationTtl: 300 // 5 minutes
    });
  }

  return user;
}
```

### Rate Limiting

```typescript
// Per-IP rate limiting
const clientIP = request.headers.get('CF-Connecting-IP');
const key = `rate:${clientIP}`;
const count = parseInt(await KV_CACHE.get(key) || '0');

if (count >= 100) { // 100 requests per minute
  return new Response('Rate limited', { status: 429 });
}

await KV_CACHE.put(key, String(count + 1), { expirationTtl: 60 });
```

### Webhook Verification

```typescript
// Verify GitHub webhook signatures
async function verifyGitHubSignature(body: string, signature: string): Promise<boolean> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(GITHUB_WEBHOOK_SECRET),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['verify']
  );

  const expectedSignature = await crypto.subtle.sign('HMAC', key, encoder.encode(body));
  const expected = 'sha256=' + Array.from(new Uint8Array(expectedSignature))
    .map(b => b.toString(16).padStart(2, '0')).join('');

  return signature === expected;
}
```

## 🚀 Deployment

### Development

```bash
# Start local development
wrangler dev

# Test with local D1
wrangler d1 execute claude-code-db --local --command "SELECT 1"

# Preview deployment
wrangler preview
```

### Production

```bash
# Deploy worker
wrangler publish

# Deploy pages
wrangler pages publish dist

# Check deployment
curl https://your-worker.workers.dev/health
```

### CI/CD Integration

```yaml
# .github/workflows/deploy-cloudflare.yml
name: Deploy to Cloudflare
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Run tests
        run: npm test
        
      - name: Deploy to Cloudflare
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
        run: |
          cd .cloudflare
          npm install -g wrangler
          wrangler publish
```

## 🎯 Use Cases

### 1. AI Code Review Service

```typescript
// Automatic code review on PR creation
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.url.includes('/webhook/github')) {
      const payload = await request.json();
      
      if (payload.action === 'opened' && payload.pull_request) {
        // Review PR with Claude
        const review = await reviewPullRequest(payload.pull_request, env);
        
        // Cache and post review
        await env.KV_CACHE.put(`review:${payload.pull_request.id}`, JSON.stringify(review));
        await postGitHubReview(payload.pull_request, review, env.GITHUB_TOKEN);
      }
    }
    
    return new Response('OK');
  }
};
```

### 2. Global Code Snippet Manager

```typescript
// Sync code snippets across edge locations
function useGlobalSnippets(userId: string) {
  const { data: snippets, setValue } = useKVStore<CodeSnippet[]>(
    'snippets',
    `user:${userId}`,
    []
  );

  const saveSnippet = async (snippet: CodeSnippet) => {
    const updated = [...(snippets || []), snippet];
    await setValue(updated, { expirationTtl: 31536000 });
    
    // Also persist to D1
    await d1.prepare(
      'INSERT INTO code_snippets (user_id, title, code, language) VALUES (?, ?, ?, ?)'
    ).bind(userId, snippet.title, snippet.code, snippet.language).run();
  };

  return { snippets, saveSnippet };
}
```

### 3. Real-time Collaborative IDE

```typescript
// WebSocket-powered collaborative coding
export class CollaborativeSession extends DurableObject {
  private sessions = new Map<string, WebSocket>();
  private document = '';

  async fetch(request: Request): Promise<Response> {
    if (request.headers.get('Upgrade') === 'websocket') {
      const [client, server] = Object.values(new WebSocketPair());
      await this.handleSession(server);
      return new Response(null, { status: 101, webSocket: client });
    }
    
    return new Response('Not found', { status: 404 });
  }

  async handleSession(websocket: WebSocket) {
    const sessionId = crypto.randomUUID();
    this.sessions.set(sessionId, websocket);

    websocket.addEventListener('message', async (event) => {
      const data = JSON.parse(event.data);
      
      if (data.type === 'code_change') {
        this.document = data.content;
        
        // Broadcast to all sessions
        for (const [id, ws] of this.sessions) {
          if (id !== sessionId) {
            ws.send(JSON.stringify({
              type: 'document_update',
              content: this.document,
              author: data.author
            }));
          }
        }
      }
    });
  }
}
```

## 🔗 Integration Examples

### GitHub Integration

```typescript
// Webhook handler for GitHub events
async function handleGitHubWebhook(request: Request, env: Env) {
  const signature = request.headers.get('X-Hub-Signature-256');
  const body = await request.text();
  
  if (!await verifyGitHubSignature(body, signature, env.GITHUB_WEBHOOK_SECRET)) {
    return new Response('Unauthorized', { status: 401 });
  }
  
  const payload = JSON.parse(body);
  const event = request.headers.get('X-GitHub-Event');
  
  switch (event) {
    case 'issues':
      if (payload.action === 'labeled' && payload.label.name === 'ai-implement') {
        await processIssueForImplementation(payload.issue, env);
      }
      break;
      
    case 'pull_request':
      if (payload.action === 'opened') {
        await queueCodeReview(payload.pull_request, env);
      }
      break;
  }
  
  return new Response('OK');
}
```

### Linear Integration

```typescript
// Sync Linear issues with GitHub
async function handleLinearWebhook(request: Request, env: Env) {
  const payload = await request.json();
  
  if (payload.type === 'Issue' && payload.action === 'create') {
    const issue = payload.data;
    
    // Create corresponding GitHub issue
    const githubIssue = await createGitHubIssue({
      title: issue.title,
      body: `${issue.description}\n\n_Synced from Linear: ${issue.url}_`,
      labels: issue.labels?.map(l => l.name) || []
    }, env.GITHUB_TOKEN);
    
    // Store mapping in D1
    await env.DB.prepare(
      'INSERT INTO linear_github_mapping (linear_id, github_id) VALUES (?, ?)'
    ).bind(issue.id, githubIssue.id).run();
  }
  
  return new Response('OK');
}
```

## 📚 Documentation

- **[Complete Guide](.claude/019-cloudflare-integration.md)** - Comprehensive documentation
- **[API Reference](./docs/api.md)** - All endpoints and parameters
- **[React Components](./docs/components.md)** - Component library documentation
- **[Database Schema](./docs/schema.md)** - D1 database structure
- **[Deployment Guide](./docs/deployment.md)** - Production deployment steps

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Credits

Built with ❤️ using:
- [Cloudflare Workers](https://workers.cloudflare.com/)
- [Claude 3 Opus](https://www.anthropic.com/claude)
- [React](https://react.dev/)
- [TypeScript](https://www.typescriptlang.org/)

---

**Ready to build AI at the edge? Get started with `./scripts/setup.sh`! 🚀**