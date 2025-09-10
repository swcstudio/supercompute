/**
 * Katalyst Framework - Cloudflare Workers AI Service
 *
 * Comprehensive AI integration using Cloudflare Workers AI with Llama models
 * Supports content generation, analysis, email processing, and NFT features
 */

export interface Env {
  // AI Binding
  AI: any;

  // Database bindings
  DB_USERS: D1Database;
  DB_CONTENT: D1Database;
  DB_ANALYTICS: D1Database;
  DB_NFT: D1Database;
  DB_EMAIL: D1Database;

  // KV Storage
  KV_CACHE: KVNamespace;
  KV_CONFIG: KVNamespace;
  KV_SESSIONS: KVNamespace;

  // R2 Storage
  R2_ASSETS: R2Bucket;
  R2_MEDIA: R2Bucket;

  // Vectorize for embeddings
  VECTORIZE_INDEX: VectorizeIndex;
  VECTORIZE_CONTENT: VectorizeIndex;

  // Environment variables
  ENVIRONMENT: string;
  API_VERSION: string;
  LOG_LEVEL: string;
}

// AI Model configurations - Latest Cloudflare Workers AI models
const AI_MODELS = {
  // Text Generation - Latest flagship models
  LLAMA_4_SCOUT: '@cf/meta/llama-4-scout-17b-16e-instruct', // Latest multimodal MoE model
  LLAMA_3_3_70B_FAST: '@cf/meta/llama-3.3-70b-instruct-fp8-fast', // Optimized for speed
  LLAMA_3_1_8B_FAST: '@cf/meta/llama-3.1-8b-instruct-fast', // Fast version
  LLAMA_3_1_8B: '@cf/meta/llama-3.1-8b-instruct', // Standard version
  LLAMA_3_8B: '@cf/meta/llama-3-8b-instruct',
  LLAMA_2_7B: '@cf/meta/llama-2-7b-chat-int8',

  // Specialized models
  GEMMA_3_12B: '@cf/google/gemma-3-12b-it', // Multimodal, 128K context
  MISTRAL_SMALL_3_1: '@cf/mistralai/mistral-small-3.1-24b-instruct', // Vision + 128K context
  QWQ_32B: '@cf/qwen/qwq-32b', // Reasoning model
  QWEN_CODER_32B: '@cf/qwen/qwen2.5-coder-32b-instruct', // Code generation
  DEEPSEEK_R1_DISTILL: '@cf/deepseek/deepseek-r1-distill-qwen-32b', // Reasoning distilled

  // Content moderation
  LLAMA_GUARD_3: '@cf/meta/llama-guard-3-8b', // Safety classification

  // Small/efficient models
  LLAMA_3_2_1B: '@cf/meta/llama-3.2-1b-instruct',
  LLAMA_3_2_3B: '@cf/meta/llama-3.2-3b-instruct',
  PHI_2: '@cf/microsoft/phi-2',
  TINY_LLAMA: '@cf/tinyllama/tinyllama-1.1b-chat-v1.0',

  // Vision models
  LLAMA_3_2_VISION: '@cf/meta/llama-3.2-11b-vision-instruct', // Image understanding

  // Embeddings
  EMBEDDING_LARGE: '@cf/baai/bge-large-en-v1.5', // 1024-dim
  EMBEDDING_BASE: '@cf/baai/bge-base-en-v1.5', // 768-dim
  EMBEDDING_SMALL: '@cf/baai/bge-small-en-v1.5', // 384-dim
  EMBEDDING_M3: '@cf/baai/bge-m3', // Multi-lingual, multi-granular

  // Text-to-Image
  FLUX_SCHNELL: '@cf/black-forest-labs/flux-1-schnell', // 12B params image gen
  STABLE_DIFFUSION_XL: '@cf/bytedance/stable-diffusion-xl-lightning',
  DREAMSHAPER: '@cf/lykon/dreamshaper-8-lcm',

  // Text-to-Speech
  MELO_TTS: '@cf/myshell-ai/melotts',

  // Speech Recognition
  WHISPER_LARGE_V3: '@cf/openai/whisper-large-v3-turbo',
  WHISPER: '@cf/openai/whisper',

  // Translation
  M2M100: '@cf/meta/m2m100-1.2b',

  // Classification/Reranking
  BGE_RERANKER: '@cf/baai/bge-reranker-base',
  DISTILBERT_SENTIMENT: '@cf/huggingface/distilbert-sst-2-int8',

  // Object Detection
  DETR_RESNET: '@cf/facebook/detr-resnet-50',

  // Summarization
  BART_CNN: '@cf/facebook/bart-large-cnn',
} as const;

// AI Service class with comprehensive functionality
export class AIService {
  constructor(private env: Env) {}

  /**
   * Generate content using Llama models with function calling support
   */
  async generateContent(request: AIContentRequest): Promise<AIResponse> {
    try {
      const { type, prompt, context, options = {} } = request;
      const model = this.selectOptimalModel(type);

      // Check cache first
      const cacheKey = `ai:content:${this.hashPrompt(prompt)}`;
      const cached = await this.env.KV_CACHE.get(cacheKey);
      if (cached && !options.bypassCache) {
        return JSON.parse(cached);
      }

      // Prepare messages with context
      const messages = this.buildMessages(prompt, context, type);

      // Generate content with streaming support
      const response = await this.env.AI.run(model, {
        messages,
        stream: options.stream || false,
        max_tokens: options.maxTokens || 2048,
        temperature: options.temperature || 0.7,
        top_p: options.topP || 0.9,
        functions: this.getFunctionsForType(type),
      });

      const result: AIResponse = {
        content: response.response || response.choices?.[0]?.message?.content,
        model,
        usage: response.usage,
        metadata: {
          type,
          timestamp: new Date().toISOString(),
          cached: false,
        },
      };

      // Cache successful responses
      if (result.content && !options.stream) {
        await this.env.KV_CACHE.put(cacheKey, JSON.stringify(result), {
          expirationTtl: 3600, // Cache for 1 hour
        });
      }

      // Log analytics
      await this.logAIUsage(type, model, response.usage);

      return result;
    } catch (error) {
      console.error('AI generation failed:', error);
      throw new AIError('Content generation failed', error);
    }
  }

  /**
   * Generate blog posts with SEO optimization
   */
  async generateBlogPost(request: BlogGenerationRequest): Promise<BlogPostResponse> {
    const prompt = `Create a comprehensive blog post about "${
      request.topic
    }" with the following requirements:
    - Target audience: ${request.audience || 'general tech audience'}
    - Tone: ${request.tone || 'professional yet accessible'}
    - Length: ${request.wordCount || 1500} words
    - Include SEO-optimized title and meta description
    - Add relevant headings (H2, H3)
    - Include a compelling introduction and conclusion
    - Add call-to-action at the end
    ${request.keywords ? `- Target keywords: ${request.keywords.join(', ')}` : ''}
    ${request.context ? `- Additional context: ${request.context}` : ''}

    Format the response as JSON with: title, metaDescription, content, headings, tags, estimatedReadTime`;

    const response = await this.generateContent({
      type: 'blog-generation',
      prompt,
      options: {
        maxTokens: 4000,
        temperature: 0.8,
      },
    });

    try {
      const blogData = JSON.parse(response.content);

      // Generate embeddings for content search
      const embeddings = await this.generateEmbeddings(blogData.content);

      // Store in vectorize for semantic search
      await this.env.VECTORIZE_CONTENT.upsert([
        {
          id: `blog-${Date.now()}`,
          values: embeddings,
          metadata: {
            title: blogData.title,
            topic: request.topic,
            tags: blogData.tags,
            createdAt: new Date().toISOString(),
          },
        },
      ]);

      return {
        ...blogData,
        embeddings,
        seoScore: await this.calculateSEOScore(blogData),
      };
    } catch (error) {
      throw new AIError('Failed to parse blog post response', error);
    }
  }

  /**
   * Process and analyze emails with AI
   */
  async processEmail(emailData: EmailProcessRequest): Promise<EmailAnalysisResponse> {
    const functions = [
      {
        name: 'classify_email',
        description: 'Classify email type and priority',
        parameters: {
          type: 'object',
          properties: {
            category: {
              type: 'string',
              enum: ['support', 'sales', 'marketing', 'spam', 'personal'],
            },
            priority: {
              type: 'string',
              enum: ['low', 'medium', 'high', 'urgent'],
            },
            sentiment: {
              type: 'string',
              enum: ['positive', 'neutral', 'negative'],
            },
            requires_response: { type: 'boolean' },
            suggested_response_time: { type: 'string' },
          },
        },
      },
      {
        name: 'extract_entities',
        description: 'Extract important entities from email',
        parameters: {
          type: 'object',
          properties: {
            people: { type: 'array', items: { type: 'string' } },
            companies: { type: 'array', items: { type: 'string' } },
            dates: { type: 'array', items: { type: 'string' } },
            amounts: { type: 'array', items: { type: 'string' } },
            tasks: { type: 'array', items: { type: 'string' } },
          },
        },
      },
    ];

    const prompt = `Analyze this email and provide classification and entity extraction:

    From: ${emailData.from}
    Subject: ${emailData.subject}
    Content: ${emailData.content}

    Please classify the email and extract relevant entities.`;

    const response = await this.env.AI.run(AI_MODELS.LLAMA_3_1_8B, {
      messages: [{ role: 'user', content: prompt }],
      functions,
      function_call: 'auto',
    });

    // Store analysis results
    await this.env.DB_EMAIL.prepare(
      'INSERT INTO email_analysis (email_id, classification, entities, processed_at) VALUES (?, ?, ?, ?)'
    )
      .bind(
        emailData.id,
        JSON.stringify(response.function_call),
        JSON.stringify(response.entities),
        new Date().toISOString()
      )
      .run();

    return {
      classification: response.function_call,
      entities: response.entities,
      summary: response.response,
      processingTime: Date.now() - emailData.timestamp,
    };
  }

  /**
   * Generate NFT descriptions and metadata
   */
  async generateNFTMetadata(request: NFTGenerationRequest): Promise<NFTMetadataResponse> {
    const prompt = `Create compelling NFT metadata for "${request.name}" with these characteristics:
    - Art style: ${request.artStyle || 'digital art'}
    - Theme: ${request.theme || 'abstract'}
    - Rarity: ${request.rarity || 'common'}
    - Collection: ${request.collection || 'Genesis Collection'}

    Generate:
    1. Detailed description (100-200 words)
    2. Attribute list with rarity scores
    3. Artist statement
    4. Collection narrative
    5. Marketing copy for listings

    Format as JSON with: description, attributes, artistStatement, collectionNarrative, marketingCopy, tags`;

    const response = await this.generateContent({
      type: 'nft-generation',
      prompt,
      options: {
        maxTokens: 2000,
        temperature: 0.9,
      },
    });

    const metadata = JSON.parse(response.content);

    // Store NFT metadata in database
    await this.env.DB_NFT.prepare(
      'INSERT INTO nft_metadata (token_id, name, description, attributes, created_at) VALUES (?, ?, ?, ?, ?)'
    )
      .bind(
        request.tokenId,
        request.name,
        metadata.description,
        JSON.stringify(metadata.attributes),
        new Date().toISOString()
      )
      .run();

    return metadata;
  }

  /**
   * Generate embeddings for semantic search
   */
  async generateEmbeddings(
    text: string,
    type: 'large' | 'base' | 'small' | 'm3' = 'large'
  ): Promise<number[]> {
    const embeddingModels = {
      large: AI_MODELS.EMBEDDING_LARGE, // 1024-dim, best quality
      base: AI_MODELS.EMBEDDING_BASE, // 768-dim, balanced
      small: AI_MODELS.EMBEDDING_SMALL, // 384-dim, fastest
      m3: AI_MODELS.EMBEDDING_M3, // Multi-lingual
    };

    const response = await this.env.AI.run(embeddingModels[type], {
      text: [text],
    });

    return response.data[0];
  }

  /**
   * Semantic search using vectorize
   */
  async semanticSearch(query: string, limit = 10): Promise<SearchResult[]> {
    const queryEmbedding = await this.generateEmbeddings(query);

    const results = await this.env.VECTORIZE_INDEX.query(queryEmbedding, {
      topK: limit,
      returnMetadata: true,
    });

    return results.matches.map((match) => ({
      id: match.id,
      score: match.score,
      metadata: match.metadata,
      content: match.metadata?.content || '',
    }));
  }

  /**
   * Content moderation and safety check
   */
  async moderateContent(content: string): Promise<ModerationResult> {
    const prompt = `Analyze this content for safety and appropriateness:
    "${content}"

    Check for:
    - Inappropriate language
    - Hate speech
    - Violence
    - Adult content
    - Spam characteristics
    - Misinformation indicators

    Respond with JSON: { safe: boolean, issues: string[], confidence: number, recommendations: string[] }`;

    const response = await this.generateContent({
      type: 'moderation',
      prompt,
      options: {
        maxTokens: 500,
        temperature: 0.1,
      },
    });

    return JSON.parse(response.content);
  }

  /**
   * Generate AI-powered analytics insights
   */
  async generateAnalyticsInsights(data: AnalyticsData): Promise<InsightsResponse> {
    const prompt = `Analyze this analytics data and provide actionable insights:

    Page Views: ${data.pageViews}
    Unique Visitors: ${data.uniqueVisitors}
    Bounce Rate: ${data.bounceRate}%
    Conversion Rate: ${data.conversionRate}%
    Top Pages: ${data.topPages.join(', ')}
    Traffic Sources: ${JSON.stringify(data.trafficSources)}
    Time Period: ${data.timePeriod}

    Provide:
    1. Key performance highlights
    2. Areas for improvement
    3. Specific recommendations
    4. Predicted trends
    5. Action items

    Format as structured JSON.`;

    const response = await this.generateContent({
      type: 'analytics',
      prompt,
      options: {
        maxTokens: 1500,
        temperature: 0.6,
      },
    });

    return JSON.parse(response.content);
  }

  // Private helper methods

  private selectOptimalModel(type: string): string {
    const modelMap: Record<string, string> = {
      // High-performance tasks use flagship models
      'blog-generation': AI_MODELS.LLAMA_4_SCOUT, // Multimodal for rich content
      'email-processing': AI_MODELS.LLAMA_3_3_70B_FAST, // Large context for emails
      'nft-generation': AI_MODELS.LLAMA_4_SCOUT, // Creative multimodal content
      'code-generation': AI_MODELS.QWEN_CODER_32B, // Specialized code model
      reasoning: AI_MODELS.QWQ_32B, // Advanced reasoning
      vision: AI_MODELS.LLAMA_3_2_VISION, // Image understanding

      // Specialized tasks
      moderation: AI_MODELS.LLAMA_GUARD_3, // Safety classification
      'content-safety': AI_MODELS.LLAMA_GUARD_3,
      analytics: AI_MODELS.LLAMA_3_1_8B_FAST, // Fast analytics
      summarization: AI_MODELS.BART_CNN, // Specialized summarization
      translation: AI_MODELS.M2M100, // Multilingual translation

      // Efficient tasks use smaller models
      'quick-chat': AI_MODELS.LLAMA_3_2_3B,
      'simple-qa': AI_MODELS.LLAMA_3_2_1B,

      // Default to latest flagship
      general: AI_MODELS.LLAMA_4_SCOUT,
    };

    return modelMap[type] || AI_MODELS.LLAMA_4_SCOUT;
  }

  private buildMessages(prompt: string, context?: string, type?: string): any[] {
    const systemPrompts: Record<string, string> = {
      'blog-generation':
        'You are an expert content writer and SEO specialist. Create engaging, well-structured blog posts that rank well in search engines.',
      'email-processing':
        'You are an intelligent email assistant that helps categorize, prioritize, and analyze email communications.',
      'nft-generation':
        'You are a creative NFT metadata specialist who creates compelling descriptions and attributes for digital collectibles.',
      moderation:
        'You are a content moderation specialist focused on identifying potentially harmful or inappropriate content.',
      analytics:
        'You are a data analyst expert at interpreting web analytics and providing actionable business insights.',
    };

    const messages = [];

    if (systemPrompts[type || 'general']) {
      messages.push({
        role: 'system',
        content: systemPrompts[type || 'general'],
      });
    }

    if (context) {
      messages.push({
        role: 'system',
        content: `Additional context: ${context}`,
      });
    }

    messages.push({
      role: 'user',
      content: prompt,
    });

    return messages;
  }

  private getFunctionsForType(type: string): any[] {
    // Return relevant function definitions based on content type
    if (type === 'email-processing') {
      return [
        {
          name: 'classify_email',
          description: 'Classify email properties',
          parameters: {
            type: 'object',
            properties: {
              category: { type: 'string' },
              priority: { type: 'string' },
              sentiment: { type: 'string' },
            },
          },
        },
      ];
    }
    return [];
  }

  private hashPrompt(prompt: string): string {
    // Simple hash function for cache keys
    let hash = 0;
    for (let i = 0; i < prompt.length; i++) {
      const char = prompt.charCodeAt(i);
      hash = (hash << 5) - hash + char;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash.toString(36);
  }

  private async logAIUsage(type: string, model: string, usage: any): Promise<void> {
    try {
      await this.env.DB_ANALYTICS.prepare(
        'INSERT INTO ai_usage_logs (type, model, tokens_used, timestamp) VALUES (?, ?, ?, ?)'
      )
        .bind(type, model, usage?.total_tokens || 0, new Date().toISOString())
        .run();
    } catch (error) {
      console.error('Failed to log AI usage:', error);
    }
  }

  private async calculateSEOScore(blogData: any): Promise<number> {
    // Basic SEO scoring algorithm
    let score = 0;

    // Title length (optimal: 50-60 characters)
    if (blogData.title.length >= 50 && blogData.title.length <= 60) score += 20;

    // Meta description length (optimal: 150-160 characters)
    if (blogData.metaDescription.length >= 150 && blogData.metaDescription.length <= 160)
      score += 20;

    // Content length (optimal: 1500+ words)
    const wordCount = blogData.content.split(' ').length;
    if (wordCount >= 1500) score += 20;

    // Heading structure
    if (blogData.headings && blogData.headings.length >= 3) score += 20;

    // Tag presence
    if (blogData.tags && blogData.tags.length >= 3) score += 20;

    return score;
  }
}

// Type definitions

interface AIContentRequest {
  type: string;
  prompt: string;
  context?: string;
  options?: {
    maxTokens?: number;
    temperature?: number;
    topP?: number;
    stream?: boolean;
    bypassCache?: boolean;
  };
}

interface AIResponse {
  content: string;
  model: string;
  usage?: any;
  metadata: {
    type: string;
    timestamp: string;
    cached: boolean;
  };
}

interface BlogGenerationRequest {
  topic: string;
  audience?: string;
  tone?: string;
  wordCount?: number;
  keywords?: string[];
  context?: string;
}

interface BlogPostResponse {
  title: string;
  metaDescription: string;
  content: string;
  headings: string[];
  tags: string[];
  estimatedReadTime: number;
  embeddings: number[];
  seoScore: number;
}

interface EmailProcessRequest {
  id: string;
  from: string;
  subject: string;
  content: string;
  timestamp: number;
}

interface EmailAnalysisResponse {
  classification: any;
  entities: any;
  summary: string;
  processingTime: number;
}

interface NFTGenerationRequest {
  tokenId: string;
  name: string;
  artStyle?: string;
  theme?: string;
  rarity?: string;
  collection?: string;
}

interface NFTMetadataResponse {
  description: string;
  attributes: any[];
  artistStatement: string;
  collectionNarrative: string;
  marketingCopy: string;
  tags: string[];
}

interface SearchResult {
  id: string;
  score: number;
  metadata: any;
  content: string;
}

interface ModerationResult {
  safe: boolean;
  issues: string[];
  confidence: number;
  recommendations: string[];
}

interface AnalyticsData {
  pageViews: number;
  uniqueVisitors: number;
  bounceRate: number;
  conversionRate: number;
  topPages: string[];
  trafficSources: Record<string, number>;
  timePeriod: string;
}

interface InsightsResponse {
  highlights: string[];
  improvements: string[];
  recommendations: string[];
  trends: string[];
  actionItems: string[];
}

class AIError extends Error {
  constructor(
    message: string,
    public cause?: any
  ) {
    super(message);
    this.name = 'AIError';
  }
}

// Main worker export
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const aiService = new AIService(env);

    try {
      // Route AI requests
      if (url.pathname.startsWith('/ai/')) {
        const endpoint = url.pathname.split('/')[2];

        switch (endpoint) {
          case 'generate':
            const generateRequest = await request.json();
            const result = await aiService.generateContent(generateRequest);
            return new Response(JSON.stringify(result), {
              headers: { 'Content-Type': 'application/json' },
            });

          case 'blog':
            const blogRequest = await request.json();
            const blogResult = await aiService.generateBlogPost(blogRequest);
            return new Response(JSON.stringify(blogResult), {
              headers: { 'Content-Type': 'application/json' },
            });

          case 'email':
            const emailRequest = await request.json();
            const emailResult = await aiService.processEmail(emailRequest);
            return new Response(JSON.stringify(emailResult), {
              headers: { 'Content-Type': 'application/json' },
            });

          case 'nft':
            const nftRequest = await request.json();
            const nftResult = await aiService.generateNFTMetadata(nftRequest);
            return new Response(JSON.stringify(nftResult), {
              headers: { 'Content-Type': 'application/json' },
            });

          case 'search':
            const query = url.searchParams.get('q');
            const limit = Number.parseInt(url.searchParams.get('limit') || '10');
            const searchResults = await aiService.semanticSearch(query!, limit);
            return new Response(JSON.stringify(searchResults), {
              headers: { 'Content-Type': 'application/json' },
            });

          case 'moderate':
            const moderateRequest = await request.json();
            const moderationResult = await aiService.moderateContent(moderateRequest.content);
            return new Response(JSON.stringify(moderationResult), {
              headers: { 'Content-Type': 'application/json' },
            });

          case 'insights':
            const analyticsRequest = await request.json();
            const insights = await aiService.generateAnalyticsInsights(analyticsRequest);
            return new Response(JSON.stringify(insights), {
              headers: { 'Content-Type': 'application/json' },
            });

          default:
            return new Response('AI endpoint not found', { status: 404 });
        }
      }

      return new Response('Katalyst AI Service - Ready', {
        headers: { 'Content-Type': 'text/plain' },
      });
    } catch (error) {
      console.error('AI Service Error:', error);
      return new Response(
        JSON.stringify({
          error: 'AI service error',
          message: error.message,
        }),
        {
          status: 500,
          headers: { 'Content-Type': 'application/json' },
        }
      );
    }
  },
};
