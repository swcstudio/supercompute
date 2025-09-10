/**
 * Cloudflare Pages Functions API Route
 * 
 * Catch-all API route that handles all edge function requests
 * Integrates with Claude Code Worker for AI functionality
 */

import type { 
  PagesFunction, 
  EventContext,
  Request as CFRequest 
} from '@cloudflare/workers-types';

interface Env {
  CLAUDE_WORKER: Fetcher;
  KV_CACHE: KVNamespace;
  DB: D1Database;
  STORAGE: R2Bucket;
  AI_SESSION: DurableObjectNamespace;
  ANTHROPIC_API_KEY: string;
  GITHUB_TOKEN: string;
}

// Main route handler
export const onRequest: PagesFunction<Env> = async (context) => {
  const { request, env, params } = context;
  const url = new URL(request.url);
  
  // Extract route from catch-all parameter
  const route = params.route?.join('/') || '';
  
  // Route to appropriate handler
  switch (route) {
    case 'enhance':
      return handleEnhance(request, env);
    
    case 'rate-limit-check':
      return handleRateLimitCheck(request, env);
    
    case 'set-cache-headers':
      return handleSetCacheHeaders(request, env);
    
    case 'ab-variant':
      return handleABVariant(request, env);
    
    case 'edge-function':
      return handleEdgeFunction(request, env);
    
    default:
      // Proxy to Claude Worker for AI endpoints
      if (route.startsWith('code') || route.startsWith('review') || 
          route.startsWith('debug') || route.startsWith('chat')) {
        return env.CLAUDE_WORKER.fetch(request);
      }
      
      return new Response('Not Found', { status: 404 });
  }
};

// AI content enhancement
async function handleEnhance(request: CFRequest, env: Env): Promise<Response> {
  try {
    const { prompt, content } = await request.json() as any;
    
    // Check cache first
    const cacheKey = `enhance:${hashContent(prompt + content)}`;
    const cached = await env.KV_CACHE.get(cacheKey);
    
    if (cached) {
      return new Response(cached, {
        headers: {
          'Content-Type': 'application/json',
          'X-Cache': 'HIT'
        }
      });
    }
    
    // Call Claude Worker
    const enhanced = await env.CLAUDE_WORKER.fetch(
      new Request('https://worker.local/api/code', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          prompt: `Enhance this HTML content: ${prompt}\n\nContent: ${content}`,
          language: 'html'
        })
      })
    );
    
    const result = await enhanced.json();
    const response = JSON.stringify({ enhanced: result.code });
    
    // Cache the result
    await env.KV_CACHE.put(cacheKey, response, {
      expirationTtl: 3600 // 1 hour
    });
    
    return new Response(response, {
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: 'Enhancement failed' }), 
      { status: 500 }
    );
  }
}

// Rate limiting check
async function handleRateLimitCheck(request: CFRequest, env: Env): Promise<Response> {
  try {
    const { limit = 100, window = 60 } = await request.json() as any;
    const clientIP = request.headers.get('CF-Connecting-IP') || 'unknown';
    
    const key = `ratelimit:${clientIP}:${window}`;
    const count = parseInt(await env.KV_CACHE.get(key) || '0');
    
    if (count >= limit) {
      return new Response(
        JSON.stringify({ allowed: false, remaining: 0 }),
        { headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Increment counter
    await env.KV_CACHE.put(key, String(count + 1), {
      expirationTtl: window
    });
    
    return new Response(
      JSON.stringify({ allowed: true, remaining: limit - count - 1 }),
      { headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: 'Rate limit check failed' }), 
      { status: 500 }
    );
  }
}

// Set cache headers
async function handleSetCacheHeaders(request: CFRequest, env: Env): Promise<Response> {
  try {
    const { headers } = await request.json() as any;
    
    // Store headers for the current request context
    const requestId = request.headers.get('CF-Request-ID') || 'unknown';
    await env.KV_CACHE.put(
      `headers:${requestId}`,
      JSON.stringify(headers),
      { expirationTtl: 300 } // 5 minutes
    );
    
    return new Response('OK', { status: 200 });
  } catch (error) {
    return new Response('Failed to set headers', { status: 500 });
  }
}

// A/B testing variant assignment
async function handleABVariant(request: CFRequest, env: Env): Promise<Response> {
  try {
    const clientIP = request.headers.get('CF-Connecting-IP') || 'unknown';
    const userAgent = request.headers.get('User-Agent') || '';
    
    // Check if user already has a variant
    const variantKey = `abtest:${clientIP}`;
    let variant = await env.KV_CACHE.get(variantKey);
    
    if (!variant) {
      // Assign variant based on hash of IP + User Agent
      const hash = await hashString(clientIP + userAgent);
      const variantIndex = parseInt(hash.substring(0, 8), 16) % 100;
      variant = variantIndex < 50 ? 'A' : 'B';
      
      // Store variant assignment
      await env.KV_CACHE.put(variantKey, variant, {
        expirationTtl: 86400 * 30 // 30 days
      });
    }
    
    return new Response(
      JSON.stringify({ variant }),
      { headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ variant: 'A' }), // Default to A on error
      { headers: { 'Content-Type': 'application/json' } }
    );
  }
}

// Generic edge function handler
async function handleEdgeFunction(request: CFRequest, env: Env): Promise<Response> {
  try {
    const { action, data } = await request.json() as any;
    
    switch (action) {
      case 'geo-lookup':
        return handleGeoLookup(request);
      
      case 'image-transform':
        return handleImageTransform(data, env);
      
      case 'websocket-auth':
        return handleWebSocketAuth(data, env);
      
      case 'log-analytics':
        return handleAnalytics(data, env);
      
      default:
        return new Response('Unknown action', { status: 400 });
    }
  } catch (error) {
    return new Response('Edge function failed', { status: 500 });
  }
}

// Geo lookup handler
function handleGeoLookup(request: CFRequest): Response {
  const cf = request.cf;
  
  return new Response(JSON.stringify({
    country: cf?.country || 'unknown',
    region: cf?.region || 'unknown',
    city: cf?.city || 'unknown',
    timezone: cf?.timezone || 'unknown',
    latitude: cf?.latitude || 0,
    longitude: cf?.longitude || 0,
    continent: cf?.continent || 'unknown',
    postalCode: cf?.postalCode || 'unknown'
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
}

// Image transformation handler
async function handleImageTransform(data: any, env: Env): Promise<Response> {
  const { url, options } = data;
  
  // Build transformation URL
  const transformOptions = [];
  if (options.width) transformOptions.push(`width=${options.width}`);
  if (options.height) transformOptions.push(`height=${options.height}`);
  if (options.quality) transformOptions.push(`quality=${options.quality}`);
  if (options.format) transformOptions.push(`format=${options.format}`);
  
  const transformUrl = `/cdn-cgi/image/${transformOptions.join(',')}/${url}`;
  
  return new Response(JSON.stringify({ url: transformUrl }), {
    headers: { 'Content-Type': 'application/json' }
  });
}

// WebSocket authentication
async function handleWebSocketAuth(data: any, env: Env): Promise<Response> {
  const { token } = data;
  
  // Validate token
  const isValid = await validateToken(token, env);
  
  if (isValid) {
    // Generate WebSocket ticket
    const ticket = generateTicket();
    await env.KV_CACHE.put(`ws:${ticket}`, 'valid', {
      expirationTtl: 300 // 5 minutes
    });
    
    return new Response(JSON.stringify({ ticket }), {
      headers: { 'Content-Type': 'application/json' }
    });
  }
  
  return new Response('Unauthorized', { status: 401 });
}

// Analytics logging
async function handleAnalytics(data: any, env: Env): Promise<Response> {
  try {
    // Log to D1 database
    await env.DB.prepare(
      'INSERT INTO analytics (event, data, timestamp) VALUES (?, ?, ?)'
    ).bind(data.event, JSON.stringify(data.data), new Date().toISOString()).run();
    
    return new Response('OK', { status: 200 });
  } catch (error) {
    return new Response('Analytics failed', { status: 500 });
  }
}

// Helper functions
function hashContent(content: string): string {
  let hash = 0;
  for (let i = 0; i < content.length; i++) {
    const char = content.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  return Math.abs(hash).toString(36);
}

async function hashString(str: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(str);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

async function validateToken(token: string, env: Env): Promise<boolean> {
  // Implement token validation logic
  return token === env.ANTHROPIC_API_KEY; // Simplified example
}

function generateTicket(): string {
  return crypto.randomUUID();
}

// Export middleware
export const onRequestGet = onRequest;
export const onRequestPost = onRequest;
export const onRequestPut = onRequest;
export const onRequestDelete = onRequest;
export const onRequestOptions = onRequest;