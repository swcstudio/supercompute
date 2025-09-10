/**
 * Cloudflare KV Storage Integration
 * 
 * Type-safe KV storage with React hooks and edge optimization
 */

import { useCallback, useEffect, useState } from 'react';

// KV Storage interface
export interface KVStorage {
  get<T = string>(key: string): Promise<T | null>;
  put(key: string, value: any, options?: KVPutOptions): Promise<void>;
  delete(key: string): Promise<void>;
  list(options?: KVListOptions): Promise<KVListResult>;
}

export interface KVPutOptions {
  expirationTtl?: number;
  expiration?: number;
  metadata?: Record<string, any>;
}

export interface KVListOptions {
  prefix?: string;
  limit?: number;
  cursor?: string;
}

export interface KVListResult {
  keys: KVKey[];
  list_complete: boolean;
  cursor?: string;
}

export interface KVKey {
  name: string;
  expiration?: number;
  metadata?: Record<string, any>;
}

// KV Store client
export class CloudflareKVStore implements KVStorage {
  private namespace: string;
  private baseUrl: string;

  constructor(namespace: string, baseUrl: string = '/api/kv') {
    this.namespace = namespace;
    this.baseUrl = baseUrl;
  }

  async get<T = string>(key: string): Promise<T | null> {
    try {
      const response = await fetch(`${this.baseUrl}/${this.namespace}/${key}`);
      
      if (!response.ok) {
        if (response.status === 404) return null;
        throw new Error(`KV get failed: ${response.statusText}`);
      }

      const contentType = response.headers.get('content-type');
      
      if (contentType?.includes('application/json')) {
        return await response.json();
      }
      
      return await response.text() as T;
    } catch (error) {
      console.error('KV get error:', error);
      return null;
    }
  }

  async put(key: string, value: any, options?: KVPutOptions): Promise<void> {
    try {
      const body = typeof value === 'object' 
        ? JSON.stringify(value) 
        : String(value);

      const response = await fetch(`${this.baseUrl}/${this.namespace}/${key}`, {
        method: 'PUT',
        headers: {
          'Content-Type': typeof value === 'object' 
            ? 'application/json' 
            : 'text/plain',
          ...(options?.expirationTtl && {
            'X-Expiration-TTL': String(options.expirationTtl)
          }),
          ...(options?.expiration && {
            'X-Expiration': String(options.expiration)
          }),
          ...(options?.metadata && {
            'X-Metadata': JSON.stringify(options.metadata)
          })
        },
        body
      });

      if (!response.ok) {
        throw new Error(`KV put failed: ${response.statusText}`);
      }
    } catch (error) {
      console.error('KV put error:', error);
      throw error;
    }
  }

  async delete(key: string): Promise<void> {
    try {
      const response = await fetch(`${this.baseUrl}/${this.namespace}/${key}`, {
        method: 'DELETE'
      });

      if (!response.ok && response.status !== 404) {
        throw new Error(`KV delete failed: ${response.statusText}`);
      }
    } catch (error) {
      console.error('KV delete error:', error);
      throw error;
    }
  }

  async list(options?: KVListOptions): Promise<KVListResult> {
    try {
      const params = new URLSearchParams();
      
      if (options?.prefix) params.append('prefix', options.prefix);
      if (options?.limit) params.append('limit', String(options.limit));
      if (options?.cursor) params.append('cursor', options.cursor);

      const response = await fetch(
        `${this.baseUrl}/${this.namespace}?${params.toString()}`
      );

      if (!response.ok) {
        throw new Error(`KV list failed: ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      console.error('KV list error:', error);
      return { keys: [], list_complete: true };
    }
  }
}

// React hook for KV storage
export function useKVStore<T = string>(
  namespace: string,
  key: string,
  defaultValue?: T
): {
  value: T | null;
  loading: boolean;
  error: Error | null;
  setValue: (value: T, options?: KVPutOptions) => Promise<void>;
  refresh: () => Promise<void>;
  remove: () => Promise<void>;
} {
  const [value, setValue] = useState<T | null>(defaultValue || null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  
  const kv = new CloudflareKVStore(namespace);

  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    
    try {
      const data = await kv.get<T>(key);
      setValue(data);
    } catch (err) {
      setError(err as Error);
    } finally {
      setLoading(false);
    }
  }, [key, namespace]);

  const updateValue = useCallback(async (newValue: T, options?: KVPutOptions) => {
    setError(null);
    
    try {
      await kv.put(key, newValue, options);
      setValue(newValue);
    } catch (err) {
      setError(err as Error);
      throw err;
    }
  }, [key, namespace]);

  const remove = useCallback(async () => {
    setError(null);
    
    try {
      await kv.delete(key);
      setValue(null);
    } catch (err) {
      setError(err as Error);
      throw err;
    }
  }, [key, namespace]);

  useEffect(() => {
    refresh();
  }, [refresh]);

  return {
    value,
    loading,
    error,
    setValue: updateValue,
    refresh,
    remove
  };
}

// React hook for KV list
export function useKVList(
  namespace: string,
  options?: KVListOptions
): {
  keys: KVKey[];
  loading: boolean;
  error: Error | null;
  hasMore: boolean;
  loadMore: () => Promise<void>;
  refresh: () => Promise<void>;
} {
  const [keys, setKeys] = useState<KVKey[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [cursor, setCursor] = useState<string | undefined>(options?.cursor);
  const [hasMore, setHasMore] = useState(true);
  
  const kv = new CloudflareKVStore(namespace);

  const loadKeys = useCallback(async (reset = false) => {
    setLoading(true);
    setError(null);
    
    try {
      const result = await kv.list({
        ...options,
        cursor: reset ? undefined : cursor
      });
      
      if (reset) {
        setKeys(result.keys);
      } else {
        setKeys(prev => [...prev, ...result.keys]);
      }
      
      setCursor(result.cursor);
      setHasMore(!result.list_complete);
    } catch (err) {
      setError(err as Error);
    } finally {
      setLoading(false);
    }
  }, [namespace, options, cursor]);

  const refresh = useCallback(() => loadKeys(true), [loadKeys]);
  const loadMore = useCallback(() => loadKeys(false), [loadKeys]);

  useEffect(() => {
    refresh();
  }, [namespace, options?.prefix]);

  return {
    keys,
    loading,
    error,
    hasMore,
    loadMore,
    refresh
  };
}

// Cache wrapper for KV
export class KVCache {
  private kv: CloudflareKVStore;
  private cache: Map<string, { value: any; expires: number }>;
  private ttl: number;

  constructor(namespace: string, ttl = 60000) { // 1 minute default
    this.kv = new CloudflareKVStore(namespace);
    this.cache = new Map();
    this.ttl = ttl;
  }

  async get<T = string>(key: string): Promise<T | null> {
    // Check memory cache first
    const cached = this.cache.get(key);
    if (cached && cached.expires > Date.now()) {
      return cached.value;
    }

    // Fetch from KV
    const value = await this.kv.get<T>(key);
    
    if (value !== null) {
      this.cache.set(key, {
        value,
        expires: Date.now() + this.ttl
      });
    }

    return value;
  }

  async put(key: string, value: any, options?: KVPutOptions): Promise<void> {
    await this.kv.put(key, value, options);
    
    // Update cache
    this.cache.set(key, {
      value,
      expires: Date.now() + this.ttl
    });
  }

  invalidate(key: string): void {
    this.cache.delete(key);
  }

  clear(): void {
    this.cache.clear();
  }
}

// Namespaced KV operations
export class NamespacedKV {
  private kv: CloudflareKVStore;
  private namespace: string;

  constructor(baseNamespace: string, subNamespace: string) {
    this.kv = new CloudflareKVStore(baseNamespace);
    this.namespace = subNamespace;
  }

  private prefixKey(key: string): string {
    return `${this.namespace}:${key}`;
  }

  async get<T = string>(key: string): Promise<T | null> {
    return this.kv.get<T>(this.prefixKey(key));
  }

  async put(key: string, value: any, options?: KVPutOptions): Promise<void> {
    return this.kv.put(this.prefixKey(key), value, options);
  }

  async delete(key: string): Promise<void> {
    return this.kv.delete(this.prefixKey(key));
  }

  async list(options?: KVListOptions): Promise<KVListResult> {
    const result = await this.kv.list({
      ...options,
      prefix: this.prefixKey(options?.prefix || '')
    });

    // Remove namespace prefix from keys
    return {
      ...result,
      keys: result.keys.map(key => ({
        ...key,
        name: key.name.replace(`${this.namespace}:`, '')
      }))
    };
  }
}

// Batch operations
export class KVBatch {
  private operations: Array<{
    type: 'put' | 'delete';
    key: string;
    value?: any;
    options?: KVPutOptions;
  }> = [];

  put(key: string, value: any, options?: KVPutOptions): this {
    this.operations.push({ type: 'put', key, value, options });
    return this;
  }

  delete(key: string): this {
    this.operations.push({ type: 'delete', key });
    return this;
  }

  async execute(kv: CloudflareKVStore): Promise<void> {
    await Promise.all(
      this.operations.map(op => {
        if (op.type === 'put') {
          return kv.put(op.key, op.value, op.options);
        } else {
          return kv.delete(op.key);
        }
      })
    );
  }
}

// Export utilities
export const createKVStore = (namespace: string) => new CloudflareKVStore(namespace);
export const createKVCache = (namespace: string, ttl?: number) => new KVCache(namespace, ttl);
export const createNamespacedKV = (base: string, sub: string) => new NamespacedKV(base, sub);
export const createKVBatch = () => new KVBatch();