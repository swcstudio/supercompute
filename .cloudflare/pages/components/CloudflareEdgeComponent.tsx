/**
 * Cloudflare Edge Component
 * 
 * React component that runs on Cloudflare's edge network
 * with server-side rendering and edge caching
 */

import React, { Suspense, useEffect, useState } from 'react';

// Edge-optimized data fetching hook
export function useEdgeData<T>(
  endpoint: string,
  options?: RequestInit
): { data: T | null; loading: boolean; error: Error | null } {
  const [state, setState] = useState<{
    data: T | null;
    loading: boolean;
    error: Error | null;
  }>({
    data: null,
    loading: true,
    error: null
  });

  useEffect(() => {
    const controller = new AbortController();

    fetch(endpoint, {
      ...options,
      signal: controller.signal,
      headers: {
        'CF-Edge-Cache': 'max-age=60',
        ...options?.headers
      }
    })
      .then(res => res.json())
      .then(data => setState({ data, loading: false, error: null }))
      .catch(error => {
        if (error.name !== 'AbortError') {
          setState({ data: null, loading: false, error });
        }
      });

    return () => controller.abort();
  }, [endpoint]);

  return state;
}

// Edge-aware component wrapper
export function EdgeComponent({
  children,
  fallback,
  cacheKey,
  revalidate = 60
}: {
  children: React.ReactNode;
  fallback?: React.ReactNode;
  cacheKey?: string;
  revalidate?: number;
}) {
  const [isClient, setIsClient] = useState(false);

  useEffect(() => {
    setIsClient(true);
  }, []);

  // Add edge caching headers
  useEffect(() => {
    if (typeof window !== 'undefined' && cacheKey) {
      const meta = document.createElement('meta');
      meta.name = 'cf-edge-cache';
      meta.content = `key=${cacheKey}, max-age=${revalidate}`;
      document.head.appendChild(meta);
      
      return () => {
        document.head.removeChild(meta);
      };
    }
  }, [cacheKey, revalidate]);

  if (!isClient) {
    return <>{fallback || children}</>;
  }

  return <Suspense fallback={fallback}>{children}</Suspense>;
}

// AI-powered edge component
export function AIEdgeComponent({
  prompt,
  children,
  enhance = true
}: {
  prompt: string;
  children: React.ReactNode;
  enhance?: boolean;
}) {
  const { data, loading, error } = useEdgeData<{ enhanced: string }>(
    '/api/enhance',
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ prompt, content: children })
    }
  );

  if (!enhance) return <>{children}</>;
  if (loading) return <div className="ai-loading">Enhancing with AI...</div>;
  if (error) return <>{children}</>;
  
  return <div dangerouslySetInnerHTML={{ __html: data?.enhanced || '' }} />;
}

// Streaming AI response component
export function StreamingAIComponent({
  endpoint,
  prompt,
  onChunk
}: {
  endpoint: string;
  prompt: string;
  onChunk?: (chunk: string) => void;
}) {
  const [response, setResponse] = useState('');
  const [isStreaming, setIsStreaming] = useState(false);

  const startStream = async () => {
    setIsStreaming(true);
    setResponse('');

    try {
      const res = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: prompt })
      });

      const reader = res.body?.getReader();
      const decoder = new TextDecoder();

      while (reader) {
        const { done, value } = await reader.read();
        if (done) break;

        const chunk = decoder.decode(value);
        const lines = chunk.split('\n');

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            const data = line.slice(6);
            if (data === '[DONE]') {
              setIsStreaming(false);
              return;
            }
            
            try {
              const parsed = JSON.parse(data);
              if (parsed.text) {
                setResponse(prev => prev + parsed.text);
                onChunk?.(parsed.text);
              }
            } catch {}
          }
        }
      }
    } catch (error) {
      console.error('Streaming error:', error);
      setIsStreaming(false);
    }
  };

  return (
    <div className="streaming-ai">
      <button onClick={startStream} disabled={isStreaming}>
        {isStreaming ? 'Streaming...' : 'Start AI Stream'}
      </button>
      <div className="ai-response">{response}</div>
    </div>
  );
}

// Edge-optimized image component
export function EdgeImage({
  src,
  alt,
  width,
  height,
  quality = 85,
  format = 'auto'
}: {
  src: string;
  alt: string;
  width?: number;
  height?: number;
  quality?: number;
  format?: 'auto' | 'webp' | 'avif';
}) {
  const transformedSrc = `/cdn-cgi/image/width=${width},height=${height},quality=${quality},format=${format}/${src}`;
  
  return (
    <img
      src={transformedSrc}
      alt={alt}
      width={width}
      height={height}
      loading="lazy"
    />
  );
}

// Geolocation-aware component
export function GeoComponent({
  children,
  regions
}: {
  children: React.ReactNode;
  regions?: Record<string, React.ReactNode>;
}) {
  const [region, setRegion] = useState<string>('default');

  useEffect(() => {
    // Get region from Cloudflare headers
    const cfRegion = document.querySelector('meta[name="cf-region"]')?.getAttribute('content');
    if (cfRegion) {
      setRegion(cfRegion);
    }
  }, []);

  return <>{regions?.[region] || children}</>;
}

// A/B testing component
export function ABTestComponent({
  variants,
  defaultVariant = 'A'
}: {
  variants: Record<string, React.ReactNode>;
  defaultVariant?: string;
}) {
  const [variant, setVariant] = useState(defaultVariant);

  useEffect(() => {
    // Get variant from edge worker
    fetch('/api/ab-variant')
      .then(res => res.json())
      .then(data => setVariant(data.variant))
      .catch(() => {});
  }, []);

  return <>{variants[variant] || variants[defaultVariant]}</>;
}

// Rate-limited component
export function RateLimitedComponent({
  children,
  limit = 100,
  window = 60
}: {
  children: React.ReactNode;
  limit?: number;
  window?: number;
}) {
  const [allowed, setAllowed] = useState(true);

  useEffect(() => {
    fetch('/api/rate-limit-check', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ limit, window })
    })
      .then(res => res.json())
      .then(data => setAllowed(data.allowed))
      .catch(() => setAllowed(false));
  }, [limit, window]);

  if (!allowed) {
    return <div className="rate-limited">Rate limit exceeded. Please try again later.</div>;
  }

  return <>{children}</>;
}

// Edge cache component
export function EdgeCache({
  cacheKey,
  ttl = 3600,
  staleWhileRevalidate = 86400,
  children
}: {
  cacheKey: string;
  ttl?: number;
  staleWhileRevalidate?: number;
  children: React.ReactNode;
}) {
  useEffect(() => {
    // Set cache headers
    const headers = {
      'Cache-Control': `public, max-age=${ttl}, stale-while-revalidate=${staleWhileRevalidate}`,
      'CF-Cache-Tag': cacheKey
    };

    // Send headers to edge worker
    fetch('/api/set-cache-headers', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ headers })
    });
  }, [cacheKey, ttl, staleWhileRevalidate]);

  return <>{children}</>;
}

// WebSocket component for real-time edge updates
export function EdgeWebSocket({
  url,
  onMessage,
  onConnect,
  onDisconnect
}: {
  url: string;
  onMessage: (data: any) => void;
  onConnect?: () => void;
  onDisconnect?: () => void;
}) {
  useEffect(() => {
    const ws = new WebSocket(url);

    ws.onopen = () => onConnect?.();
    ws.onclose = () => onDisconnect?.();
    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        onMessage(data);
      } catch {
        onMessage(event.data);
      }
    };

    return () => ws.close();
  }, [url]);

  return null;
}

// Export all components
export default {
  EdgeComponent,
  AIEdgeComponent,
  StreamingAIComponent,
  EdgeImage,
  GeoComponent,
  ABTestComponent,
  RateLimitedComponent,
  EdgeCache,
  EdgeWebSocket,
  useEdgeData
};