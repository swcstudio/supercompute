/**
 * SWC Studio - Comprehensive Cloudflare Services Integration
 * State-of-the-art integration with all Cloudflare technologies (2024-2025)
 *
 * Features:
 * - Workers AI (Llama 4 Scout, GPT-4 level models)
 * - Vectorize (Vector database)
 * - D1 (Serverless SQLite)
 * - R2 (Object storage)
 * - KV (Key-value storage)
 * - Durable Objects (Stateful serverless)
 * - Queues (Message queuing)
 * - Analytics Engine (Time-series metrics)
 * - AI Gateway (AI observability)
 * - Hyperdrive (Database acceleration)
 * - Pages (Static site hosting)
 * - Stream (Video streaming)
 * - Images (Image optimization)
 * - Zaraz (Web analytics)
 */

// Environment interface for all Cloudflare services
interface CloudflareEnv {
  // AI Services
  AI: Ai;
  AI_GATEWAY: any;

  // Databases
  DB_USERS: D1Database;
  DB_CONTENT: D1Database;
  DB_ANALYTICS: D1Database;
  DB_NFT: D1Database;
  DB_EMAIL: D1Database;
  DB_COMMERCE: D1Database;
  DB_BLOG: D1Database;

  // Vector Databases
  VECTORIZE_INDEX: VectorizeIndex;
  VECTORIZE_CONTENT: VectorizeIndex;
  VECTORIZE_PRODUCTS: VectorizeIndex;
  VECTORIZE_USERS: VectorizeIndex;

  // Key-Value Storage
  KV_CACHE: KVNamespace;
  KV_CONFIG: KVNamespace;
  KV_SESSIONS: KVNamespace;
  KV_BLOG_CACHE: KVNamespace;
  KV_USER_PREFS: KVNamespace;
  KV_RATE_LIMIT: KVNamespace;

  // Object Storage
  R2_ASSETS: R2Bucket;
  R2_MEDIA: R2Bucket;
  R2_NFT_STORAGE: R2Bucket;
  R2_EMAIL_ATTACHMENTS: R2Bucket;
  R2_BACKUPS: R2Bucket;
  R2_USER_UPLOADS: R2Bucket;

  // Durable Objects
  REALTIME_CHAT: DurableObjectNamespace;
  EMAIL_PROCESSOR: DurableObjectNamespace;
  NFT_AUCTION: DurableObjectNamespace;
  ANALYTICS_AGGREGATOR: DurableObjectNamespace;
  COLLABORATION_WORKSPACE: DurableObjectNamespace;
  LIVE_SHOPPING: DurableObjectNamespace;

  // Queues
  EMAIL_QUEUE: Queue<EmailMessage>;
  NFT_PROCESSING_QUEUE: Queue<NFTProcessingMessage>;
  ANALYTICS_QUEUE: Queue<AnalyticsMessage>;
  BLOG_INDEXING_QUEUE: Queue<BlogIndexingMessage>;
  IMAGE_PROCESSING_QUEUE: Queue<ImageProcessingMessage>;
  VIDEO_PROCESSING_QUEUE: Queue<VideoProcessingMessage>;

  // Analytics Engine
  ANALYTICS_DATASET: AnalyticsEngineDataset;
  USER_METRICS: AnalyticsEngineDataset;
  PERFORMANCE_METRICS: AnalyticsEngineDataset;

  // Hyperdrive (Database acceleration)
  HYPERDRIVE: Hyperdrive;

  // Environment variables
  ENVIRONMENT: string;
  API_KEY: string;
  JWT_SECRET: string;
  OPENAI_API_KEY?: string;
  STRIPE_SECRET_KEY?: string;
  SENDGRID_API_KEY?: string;
}

// Latest AI Models from Cloudflare Workers AI (2024-2025)
const CLOUDFLARE_AI_MODELS = {
  // 🚀 Flagship Models
  LLAMA_4_SCOUT: "@cf/meta/llama-4-scout-17b-16e-instruct", // 109B params, 17B active, MoE architecture
  LLAMA_3_3_70B_FAST: "@cf/meta/llama-3.3-70b-instruct-fp8-fast", // Optimized for 2-4x speed
  MISTRAL_SMALL_3_1: "@cf/mistralai/mistral-small-3.1-24b-instruct", // Vision + 128K context

  // 🧠 Reasoning Models
  QWQ_32B: "@cf/qwen/qwq-32b", // Advanced reasoning capabilities
  DEEPSEEK_R1_DISTILL: "@cf/deepseek/deepseek-r1-distill-qwen-32b", // o1-mini performance

  // 💻 Code Generation
  QWEN_CODER_32B: "@cf/qwen/qwen2.5-coder-32b-instruct", // State-of-the-art coding

  // 👁️ Vision Models
  LLAMA_3_2_VISION: "@cf/meta/llama-3.2-11b-vision-instruct", // Image understanding
  GEMMA_3_12B: "@cf/google/gemma-3-12b-it", // Multimodal, 128K context

  // 🛡️ Safety & Moderation
  LLAMA_GUARD_3: "@cf/meta/llama-guard-3-8b", // Content safety classification

  // 🎨 Image Generation
  FLUX_SCHNELL: "@cf/black-forest-labs/flux-1-schnell", // 12B params, fast generation
  STABLE_DIFFUSION_XL: "@cf/bytedance/stable-diffusion-xl-lightning", // Lightning fast

  // 🔊 Speech & Audio
  WHISPER_LARGE_V3: "@cf/openai/whisper-large-v3-turbo", // Speech recognition
  MELO_TTS: "@cf/myshell-ai/melotts", // Text-to-speech

  // 📊 Embeddings
  BGE_M3: "@cf/baai/bge-m3", // Multi-lingual, multi-granular
  BGE_LARGE: "@cf/baai/bge-large-en-v1.5", // 1024-dim vectors
  BGE_RERANKER: "@cf/baai/bge-reranker-base", // Relevance scoring

  // 🌐 Translation & Language
  M2M100: "@cf/meta/m2m100-1.2b", // Many-to-many translation

  // 📝 Specialized Tasks
  BART_CNN: "@cf/facebook/bart-large-cnn", // Summarization
  DETR_RESNET: "@cf/facebook/detr-resnet-50", // Object detection
} as const;

// Message interfaces for queues
interface EmailMessage {
  id: string;
  from: string;
  to: string[];
  subject: string;
  body: string;
  attachments?: string[];
  priority: 'low' | 'medium' | 'high' | 'urgent';
  timestamp: number;
}

interface NFTProcessingMessage {
  tokenId: string;
  metadata: any;
  imageUrl: string;
  operation: 'mint' | 'transfer' | 'update';
  userAddress: string;
  timestamp: number;
}

interface AnalyticsMessage {
  event: string;
  userId?: string;
  sessionId: string;
  properties: Record<string, any>;
  timestamp: number;
}

interface BlogIndexingMessage {
  postId: string;
  title: string;
  content: string;
  tags: string[];
  operation: 'create' | 'update' | 'delete';
  timestamp: number;
}

interface ImageProcessingMessage {
  imageId: string;
  originalUrl: string;
  transformations: Array<{
    width?: number;
    height?: number;
    format?: 'webp' | 'avif' | 'jpeg' | 'png';
    quality?: number;
  }>;
  userId: string;
  timestamp: number;
}

interface VideoProcessingMessage {
  videoId: string;
  originalUrl: string;
  operations: Array<'transcode' | 'thumbnail' | 'watermark' | 'trim'>;
  userId: string;
  timestamp: number;
}

// Comprehensive Cloudflare Services Manager
export class CloudflareServicesManager {
  constructor(private env: CloudflareEnv) {}

  // 🤖 AI & Machine Learning Services
  async generateWithAI(prompt: string, modelType: 'text' | 'image' | 'code' | 'reasoning' = 'text') {
    const modelMap = {
      text: CLOUDFLARE_AI_MODELS.LLAMA_4_SCOUT,
      image: CLOUDFLARE_AI_MODELS.FLUX_SCHNELL,
      code: CLOUDFLARE_AI_MODELS.QWEN_CODER_32B,
      reasoning: CLOUDFLARE_AI_MODELS.QWQ_32B,
    };

    return await this.env.AI.run(modelMap[modelType], {
      messages: [{ role: "user", content: prompt }],
      max_tokens: 2048,
      temperature: 0.7,
    });
  }

  async moderateContent(content: string) {
    return await this.env.AI.run(CLOUDFLARE_AI_MODELS.LLAMA_GUARD_3, {
      messages: [
        { role: "system", content: "Classify this content for safety violations." },
        { role: "user", content }
      ]
    });
  }

  async generateEmbeddings(text: string, type: 'general' | 'multilingual' = 'general') {
    const model = type === 'multilingual' ? CLOUDFLARE_AI_MODELS.BGE_M3 : CLOUDFLARE_AI_MODELS.BGE_LARGE;
    return await this.env.AI.run(model, { text: [text] });
  }

  // 🗄️ Vector Database Operations
  async semanticSearch(query: string, namespace: 'content' | 'products' | 'users' = 'content', limit = 10) {
    const vectorNamespaces = {
      content: this.env.VECTORIZE_CONTENT,
      products: this.env.VECTORIZE_PRODUCTS,
      users: this.env.VECTORIZE_USERS,
    };

    const queryEmbedding = await this.generateEmbeddings(query);
    return await vectorNamespaces[namespace].query(queryEmbedding.data[0], {
      topK: limit,
      returnMetadata: true,
    });
  }

  async storeVector(id: string, text: string, metadata: any, namespace: 'content' | 'products' | 'users' = 'content') {
    const vectorNamespaces = {
      content: this.env.VECTORIZE_CONTENT,
      products: this.env.VECTORIZE_PRODUCTS,
      users: this.env.VECTORIZE_USERS,
    };

    const embedding = await this.generateEmbeddings(text);
    return await vectorNamespaces[namespace].upsert([{
      id,
      values: embedding.data[0],
      metadata: { ...metadata, text, createdAt: new Date().toISOString() }
    }]);
  }

  // 💾 Database Operations (D1)
  async executeQuery(database: keyof Pick<CloudflareEnv, 'DB_USERS' | 'DB_CONTENT' | 'DB_ANALYTICS' | 'DB_NFT' | 'DB_EMAIL' | 'DB_COMMERCE' | 'DB_BLOG'>, query: string, params: any[] = []) {
    return await this.env[database].prepare(query).bind(...params).all();
  }

  async createUser(userData: { email: string; name: string; preferences?: any }) {
    const userId = crypto.randomUUID();
    await this.env.DB_USERS.prepare(
      "INSERT INTO users (id, email, name, preferences, created_at) VALUES (?, ?, ?, ?, ?)"
    ).bind(
      userId,
      userData.email,
      userData.name,
      JSON.stringify(userData.preferences || {}),
      new Date().toISOString()
    ).run();
    return userId;
  }

  // 🗂️ Object Storage (R2)
  async uploadFile(bucket: keyof Pick<CloudflareEnv, 'R2_ASSETS' | 'R2_MEDIA' | 'R2_NFT_STORAGE' | 'R2_EMAIL_ATTACHMENTS' | 'R2_USER_UPLOADS'>, key: string, file: File | ArrayBuffer, metadata?: Record<string, string>) {
    return await this.env[bucket].put(key, file, {
      customMetadata: metadata,
      httpMetadata: {
        contentType: file instanceof File ? file.type : 'application/octet-stream',
      }
    });
  }

  async getFile(bucket: keyof Pick<CloudflareEnv, 'R2_ASSETS' | 'R2_MEDIA' | 'R2_NFT_STORAGE' | 'R2_EMAIL_ATTACHMENTS' | 'R2_USER_UPLOADS'>, key: string) {
    return await this.env[bucket].get(key);
  }

  // 🔑 Key-Value Storage (KV)
  async cacheData(key: string, data: any, ttl = 3600, namespace: 'cache' | 'config' | 'sessions' | 'blog' | 'userPrefs' = 'cache') {
    const kvNamespaces = {
      cache: this.env.KV_CACHE,
      config: this.env.KV_CONFIG,
      sessions: this.env.KV_SESSIONS,
      blog: this.env.KV_BLOG_CACHE,
      userPrefs: this.env.KV_USER_PREFS,
    };

    return await kvNamespaces[namespace].put(key, JSON.stringify(data), { expirationTtl: ttl });
  }

  async getCachedData(key: string, namespace: 'cache' | 'config' | 'sessions' | 'blog' | 'userPrefs' = 'cache') {
    const kvNamespaces = {
      cache: this.env.KV_CACHE,
      config: this.env.KV_CONFIG,
      sessions: this.env.KV_SESSIONS,
      blog: this.env.KV_BLOG_CACHE,
      userPrefs: this.env.KV_USER_PREFS,
    };

    const data = await kvNamespaces[namespace].get(key);
    return data ? JSON.parse(data) : null;
  }

  // 📊 Rate Limiting
  async checkRateLimit(key: string, limit: number, window = 3600): Promise<{ allowed: boolean; remaining: number; resetTime: number }> {
    const now = Math.floor(Date.now() / 1000);
    const windowStart = Math.floor(now / window) * window;
    const rateLimitKey = `${key}:${windowStart}`;

    const current = await this.env.KV_RATE_LIMIT.get(rateLimitKey);
    const count = current ? Number.parseInt(current) : 0;

    if (count >= limit) {
      return {
        allowed: false,
        remaining: 0,
        resetTime: windowStart + window,
      };
    }

    await this.env.KV_RATE_LIMIT.put(rateLimitKey, (count + 1).toString(), { expirationTtl: window });

    return {
      allowed: true,
      remaining: limit - count - 1,
      resetTime: windowStart + window,
    };
  }

  // 📬 Queue Operations
  async sendEmail(emailData: Omit<EmailMessage, 'id' | 'timestamp'>) {
    const message: EmailMessage = {
      ...emailData,
      id: crypto.randomUUID(),
      timestamp: Date.now(),
    };
    return await this.env.EMAIL_QUEUE.send(message);
  }

  async processNFT(nftData: Omit<NFTProcessingMessage, 'timestamp'>) {
    const message: NFTProcessingMessage = {
      ...nftData,
      timestamp: Date.now(),
    };
    return await this.env.NFT_PROCESSING_QUEUE.send(message);
  }

  async trackEvent(eventData: Omit<AnalyticsMessage, 'timestamp'>) {
    const message: AnalyticsMessage = {
      ...eventData,
      timestamp: Date.now(),
    };
    return await this.env.ANALYTICS_QUEUE.send(message);
  }

  async indexBlogPost(blogData: Omit<BlogIndexingMessage, 'timestamp'>) {
    const message: BlogIndexingMessage = {
      ...blogData,
      timestamp: Date.now(),
    };
    return await this.env.BLOG_INDEXING_QUEUE.send(message);
  }

  // 📈 Analytics Engine
  async writeAnalytics(dataPoint: {
    event: string;
    userId?: string;
    properties?: Record<string, any>;
    dataset?: 'analytics' | 'user' | 'performance';
  }) {
    const datasets = {
      analytics: this.env.ANALYTICS_DATASET,
      user: this.env.USER_METRICS,
      performance: this.env.PERFORMANCE_METRICS,
    };

    return await datasets[dataPoint.dataset || 'analytics'].writeDataPoint({
      blobs: [dataPoint.event, dataPoint.userId || 'anonymous'],
      doubles: [Date.now()],
      indexes: [dataPoint.event],
    });
  }

  // 🎯 Durable Objects Operations
  async getDurableObject(type: 'chat' | 'email' | 'nft' | 'analytics' | 'collaboration' | 'shopping', id: string) {
    const namespaces = {
      chat: this.env.REALTIME_CHAT,
      email: this.env.EMAIL_PROCESSOR,
      nft: this.env.NFT_AUCTION,
      analytics: this.env.ANALYTICS_AGGREGATOR,
      collaboration: this.env.COLLABORATION_WORKSPACE,
      shopping: this.env.LIVE_SHOPPING,
    };

    const durableObjectId = namespaces[type].idFromString(id);
    return namespaces[type].get(durableObjectId);
  }

  // 🔄 Comprehensive Content Pipeline
  async processContent(content: {
    type: 'blog' | 'product' | 'nft' | 'user-generated';
    title: string;
    body: string;
    metadata?: any;
    authorId?: string;
  }) {
    const contentId = crypto.randomUUID();

    // 1. Moderate content
    const moderation = await this.moderateContent(`${content.title}\n\n${content.body}`);

    if (!moderation.safe) {
      throw new Error('Content failed moderation');
    }

    // 2. Generate embeddings for semantic search
    await this.storeVector(contentId, `${content.title}\n${content.body}`, {
      type: content.type,
      title: content.title,
      authorId: content.authorId,
      ...content.metadata,
    });

    // 3. Store in appropriate database
    const dbMap = {
      blog: this.env.DB_BLOG,
      product: this.env.DB_COMMERCE,
      nft: this.env.DB_NFT,
      'user-generated': this.env.DB_CONTENT,
    };

    await dbMap[content.type].prepare(
      "INSERT INTO content (id, type, title, body, metadata, author_id, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)"
    ).bind(
      contentId,
      content.type,
      content.title,
      content.body,
      JSON.stringify(content.metadata || {}),
      content.authorId,
      new Date().toISOString()
    ).run();

    // 4. Queue for additional processing
    if (content.type === 'blog') {
      await this.indexBlogPost({
        postId: contentId,
        title: content.title,
        content: content.body,
        tags: content.metadata?.tags || [],
        operation: 'create',
      });
    }

    // 5. Track analytics
    await this.trackEvent({
      event: 'content_created',
      userId: content.authorId,
      sessionId: crypto.randomUUID(),
      properties: {
        contentType: content.type,
        contentId,
        moderationPassed: true,
      },
    });

    return { contentId, moderationResult: moderation };
  }

  // 🚀 Advanced AI Workflow
  async createIntelligentContent(prompt: string, contentType: 'blog' | 'product' | 'nft' = 'blog') {
    // 1. Generate content with appropriate AI model
    const model = contentType === 'blog' ? CLOUDFLARE_AI_MODELS.LLAMA_4_SCOUT :
                  contentType === 'product' ? CLOUDFLARE_AI_MODELS.MISTRAL_SMALL_3_1 :
                  CLOUDFLARE_AI_MODELS.LLAMA_4_SCOUT;

    const generatedContent = await this.env.AI.run(model, {
      messages: [
        {
          role: "system",
          content: `You are an expert ${contentType} creator. Generate high-quality, engaging content based on the user's prompt. Include a compelling title and detailed body content.`
        },
        { role: "user", content: prompt }
      ],
      max_tokens: contentType === 'blog' ? 4000 : 2000,
      temperature: 0.8,
    });

    // 2. Process the generated content
    const [title, ...bodyParts] = generatedContent.response.split('\n');
    const body = bodyParts.join('\n').trim();

    // 3. Use the comprehensive content pipeline
    return await this.processContent({
      type: contentType,
      title: title.replace(/^#+\s*/, ''), // Remove markdown headers
      body,
      metadata: {
        aiGenerated: true,
        model: model,
        prompt,
        generatedAt: new Date().toISOString(),
      },
    });
  }

  // 🎨 Image Processing Pipeline
  async processImage(imageFile: File, transformations: ImageProcessingMessage['transformations'] = []) {
    const imageId = crypto.randomUUID();

    // 1. Upload original image to R2
    const originalKey = `images/original/${imageId}`;
    await this.uploadFile('R2_MEDIA', originalKey, imageFile);

    // 2. Queue image processing
    await this.env.IMAGE_PROCESSING_QUEUE.send({
      imageId,
      originalUrl: originalKey,
      transformations,
      userId: 'system', // or actual user ID
      timestamp: Date.now(),
    });

    // 3. Generate AI description of the image (if vision model available)
    try {
      const imageAnalysis = await this.env.AI.run(CLOUDFLARE_AI_MODELS.LLAMA_3_2_VISION, {
        messages: [
          {
            role: "user",
            content: "Describe this image in detail, including objects, colors, composition, and mood."
          }
        ],
        image: await imageFile.arrayBuffer(),
      });

      // Store analysis in vector database for semantic search
      await this.storeVector(`image:${imageId}`, imageAnalysis.response, {
        type: 'image',
        imageId,
        fileName: imageFile.name,
        fileSize: imageFile.size,
        contentType: imageFile.type,
      });
    } catch (error) {
      console.warn('Image analysis failed:', error);
    }

    return { imageId, originalKey };
  }

  // 📊 Real-time Analytics Dashboard Data
  async getDashboardMetrics(timeRange: '1h' | '24h' | '7d' | '30d' = '24h') {
    const now = Date.now();
    const timeRanges = {
      '1h': now - 3600000,
      '24h': now - 86400000,
      '7d': now - 604800000,
      '30d': now - 2592000000,
    };

    const startTime = timeRanges[timeRange];

    // Get cached metrics first
    const cacheKey = `dashboard:metrics:${timeRange}`;
    const cached = await this.getCachedData(cacheKey);
    if (cached && cached.timestamp > now - 300000) { // 5 minutes cache
      return cached.data;
    }

    // Query analytics data
    const [users, content, events] = await Promise.all([
      this.executeQuery('DB_USERS', 'SELECT COUNT(*) as count FROM users WHERE created_at > ?', [new Date(startTime).toISOString()]),
      this.executeQuery('DB_CONTENT', 'SELECT COUNT(*) as count, type FROM content WHERE created_at > ? GROUP BY type', [new Date(startTime).toISOString()]),
      this.executeQuery('DB_ANALYTICS', 'SELECT COUNT(*) as count, event FROM analytics_events WHERE timestamp > ? GROUP BY event LIMIT 10', [startTime]),
    ]);

    const metrics = {
      newUsers: users.results[0]?.count || 0,
      contentByType: content.results.reduce((acc: any, row: any) => {
        acc[row.type] = row.count;
        return acc;
      }, {}),
      topEvents: events.results,
      timestamp: now,
    };

    // Cache for 5 minutes
    await this.cacheData(cacheKey, { data: metrics, timestamp: now }, 300);

    return metrics;
  }

  // 🔐 Security & Authentication Helpers
  async validateSession(sessionToken: string): Promise<{ valid: boolean; userId?: string; expiresAt?: number }> {
    const sessionData = await this.getCachedData(`session:${sessionToken}`, 'sessions');

    if (!sessionData || sessionData.expiresAt < Date.now()) {
      return { valid: false };
    }

    return {
      valid: true,
      userId: sessionData.userId,
      expiresAt: sessionData.expiresAt,
    };
  }

  async createSession(userId: string, duration = 86400000): Promise<string> {
    const sessionToken = crypto.randomUUID();
    const expiresAt = Date.now() + duration;

    await this.cacheData(`session:${sessionToken}`, {
      userId,
      expiresAt,
      createdAt: Date.now(),
    }, Math.floor(duration / 1000), 'sessions');

    return sessionToken;
  }

  // 🌟 Feature Flags & A/B Testing
  async getFeatureFlag(flagName: string, userId?: string, defaultValue = false): Promise<boolean> {
    const configKey = `feature:${flagName}`;
    const config = await this.getCachedData(configKey, 'config');

    if (!config) {
      return defaultValue;
    }

    // Simple A/B testing based on user ID hash
    if (config.abTest && userId) {
      const hash = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(userId + flagName));
      const hashArray = new Uint8Array(hash);
      const hashPercent = (hashArray[0] / 255) * 100;
      return hashPercent < config.percentage;
    }

    return config.enabled || defaultValue;
  }

  // 🔄 Health Check & Monitoring
  async healthCheck(): Promise<{
    status: 'healthy' | 'degraded' | 'unhealthy';
    services: Record<string, 'up' | 'down' | 'unknown'>;
    timestamp: number;
  }> {
    const checks = {
      ai: this.checkAIService(),
      database: this.checkDatabaseHealth(),
      storage: this.checkStorageHealth(),
      cache: this.checkCacheHealth(),
      queues: this.checkQueueHealth(),
    };

    const results = await Promise.allSettled(Object.values(checks));
    const services: Record<string, 'up' | 'down' | 'unknown'> = {};

    Object.keys(checks).forEach((service, index) => {
      services[service] = results[index].status === 'fulfilled' ? 'up' : 'down';
    });

    const healthyServices = Object.values(services).filter(status => status === 'up').length;
    const totalServices = Object.values(services).length;

    let status: 'healthy' | 'degraded' | 'unhealthy';
    if (healthyServices === totalServices) {
      status = 'healthy';
    } else if (healthyServices > totalServices / 2) {
      status = 'degraded';
    } else {
      status = 'unhealthy';
    }

    return {
      status,
      services,
      timestamp: Date.now(),
    };
  }

  private async checkAIService() {
    await this.env.AI.run(CLOUDFLARE_AI_MODELS.LLAMA_3_2_1B, {
      messages: [{ role: "user", content: "Health check" }],
      max_tokens: 5,
    });
  }

  private async checkDatabaseHealth() {
    await this.env.DB_USERS.prepare("SELECT 1").first();
  }

  private async checkStorageHealth() {
    await this.env.R2_ASSETS.head('health-check');
  }

  private async checkCacheHealth() {
    await this.env.KV_CACHE.get('health-check');
  }

  private async checkQueueHealth() {
    // Queues don't have a direct health check, so we assume they're up
    return Promise.resolve();
  }
}

// Export for use in Workers
export default CloudflareServicesManager;

// Usage example in a Worker
export async function handleRequest(request: Request, env: CloudflareEnv): Promise<Response> {
  const services = new CloudflareServicesManager(env);
  const url = new URL(request.url);

  try {
    // Rate limiting
    const clientIP = request.headers.get('CF-Connecting-IP') || 'unknown';
    const rateLimit = await services.checkRateLimit(`api:${clientIP}`, 100, 3600);

    if (!rateLimit.allowed) {
      return new Response('Rate limit exceeded', {
        status: 429,
        headers: {
          'X-RateLimit-Remaining': '0',
          'X-RateLimit-Reset': rateLimit.resetTime.toString(),
        }
      });
    }

    // Route handling
    if (url.pathname === '/health') {
      const health = await services.healthCheck();
      return Response.json(health);
    }

    if (url.pathname === '/ai/generate' && request.method === 'POST') {
      const { prompt, type } = await request.json();
      const result = await services.generateWithAI(prompt, type);
      return Response.json(result);
    }

    if (url.pathname === '/search' && request.method === 'GET') {
      const query = url.searchParams.get('q');
      if (!query) {
        return new Response('Missing query parameter', { status: 400 });
      }

      const results = await services.semanticSearch(query);
      return
