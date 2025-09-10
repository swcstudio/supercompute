/**
 * Cloudflare R2 Storage Integration
 * 
 * Object storage with S3-compatible API and React hooks
 */

import { useCallback, useEffect, useState } from 'react';

// R2 Object types
export interface R2Object {
  key: string;
  version: string;
  size: number;
  etag: string;
  httpEtag: string;
  checksums: R2Checksums;
  uploaded: Date;
  httpMetadata?: R2HTTPMetadata;
  customMetadata?: Record<string, string>;
  range?: R2Range;
}

export interface R2Checksums {
  md5?: ArrayBuffer;
  sha1?: ArrayBuffer;
  sha256?: ArrayBuffer;
  sha384?: ArrayBuffer;
  sha512?: ArrayBuffer;
}

export interface R2HTTPMetadata {
  contentType?: string;
  contentLanguage?: string;
  contentDisposition?: string;
  contentEncoding?: string;
  cacheControl?: string;
  cacheExpiry?: Date;
}

export interface R2Range {
  offset: number;
  length?: number;
}

export interface R2ListOptions {
  limit?: number;
  prefix?: string;
  cursor?: string;
  delimiter?: string;
  startAfter?: string;
}

export interface R2Objects {
  objects: R2Object[];
  truncated: boolean;
  cursor?: string;
  delimitedPrefixes: string[];
}

export interface R2PutOptions {
  httpMetadata?: R2HTTPMetadata;
  customMetadata?: Record<string, string>;
  md5?: string;
  sha1?: string;
  sha256?: string;
  sha384?: string;
  sha512?: string;
}

export interface R2GetOptions {
  range?: R2Range;
  onlyIf?: R2Conditional;
}

export interface R2Conditional {
  etagMatches?: string;
  etagDoesNotMatch?: string;
  uploadedBefore?: Date;
  uploadedAfter?: Date;
}

// R2 Client for browser
export class R2Client {
  private bucket: string;
  private baseUrl: string;

  constructor(bucket: string, baseUrl: string = '/api/r2') {
    this.bucket = bucket;
    this.baseUrl = baseUrl;
  }

  async put(
    key: string,
    value: string | ArrayBuffer | Blob | File,
    options?: R2PutOptions
  ): Promise<R2Object> {
    const formData = new FormData();
    
    if (value instanceof File) {
      formData.append('file', value);
    } else if (value instanceof Blob) {
      formData.append('file', value, key);
    } else if (value instanceof ArrayBuffer) {
      formData.append('file', new Blob([value]), key);
    } else {
      formData.append('file', new Blob([value]), key);
    }

    if (options?.httpMetadata) {
      formData.append('httpMetadata', JSON.stringify(options.httpMetadata));
    }

    if (options?.customMetadata) {
      formData.append('customMetadata', JSON.stringify(options.customMetadata));
    }

    const response = await fetch(`${this.baseUrl}/${this.bucket}/${key}`, {
      method: 'PUT',
      body: formData
    });

    if (!response.ok) {
      throw new Error(`R2 put failed: ${response.statusText}`);
    }

    return await response.json();
  }

  async get(key: string, options?: R2GetOptions): Promise<Response> {
    const headers: HeadersInit = {};

    if (options?.range) {
      const start = options.range.offset;
      const end = options.range.length 
        ? start + options.range.length - 1 
        : '';
      headers['Range'] = `bytes=${start}-${end}`;
    }

    if (options?.onlyIf) {
      if (options.onlyIf.etagMatches) {
        headers['If-Match'] = options.onlyIf.etagMatches;
      }
      if (options.onlyIf.etagDoesNotMatch) {
        headers['If-None-Match'] = options.onlyIf.etagDoesNotMatch;
      }
    }

    const response = await fetch(`${this.baseUrl}/${this.bucket}/${key}`, {
      headers
    });

    if (!response.ok && response.status !== 304) {
      throw new Error(`R2 get failed: ${response.statusText}`);
    }

    return response;
  }

  async delete(key: string): Promise<void> {
    const response = await fetch(`${this.baseUrl}/${this.bucket}/${key}`, {
      method: 'DELETE'
    });

    if (!response.ok && response.status !== 404) {
      throw new Error(`R2 delete failed: ${response.statusText}`);
    }
  }

  async list(options?: R2ListOptions): Promise<R2Objects> {
    const params = new URLSearchParams();

    if (options?.limit) params.append('limit', String(options.limit));
    if (options?.prefix) params.append('prefix', options.prefix);
    if (options?.cursor) params.append('cursor', options.cursor);
    if (options?.delimiter) params.append('delimiter', options.delimiter);
    if (options?.startAfter) params.append('startAfter', options.startAfter);

    const response = await fetch(
      `${this.baseUrl}/${this.bucket}?${params.toString()}`
    );

    if (!response.ok) {
      throw new Error(`R2 list failed: ${response.statusText}`);
    }

    return await response.json();
  }

  async head(key: string): Promise<R2Object | null> {
    const response = await fetch(`${this.baseUrl}/${this.bucket}/${key}`, {
      method: 'HEAD'
    });

    if (response.status === 404) {
      return null;
    }

    if (!response.ok) {
      throw new Error(`R2 head failed: ${response.statusText}`);
    }

    // Parse headers to construct R2Object
    return {
      key,
      version: response.headers.get('x-amz-version-id') || '',
      size: parseInt(response.headers.get('content-length') || '0'),
      etag: response.headers.get('etag') || '',
      httpEtag: response.headers.get('etag') || '',
      checksums: {},
      uploaded: new Date(response.headers.get('last-modified') || ''),
      httpMetadata: {
        contentType: response.headers.get('content-type') || undefined,
        cacheControl: response.headers.get('cache-control') || undefined
      }
    };
  }

  getPublicUrl(key: string): string {
    return `${window.location.origin}${this.baseUrl}/${this.bucket}/${key}`;
  }
}

// React hook for R2 object
export function useR2Object(
  bucket: string,
  key: string,
  options?: R2GetOptions
): {
  data: Blob | null;
  loading: boolean;
  error: Error | null;
  metadata: R2Object | null;
  refetch: () => Promise<void>;
} {
  const [data, setData] = useState<Blob | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [metadata, setMetadata] = useState<R2Object | null>(null);

  const r2 = new R2Client(bucket);

  const fetch = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      // Get metadata first
      const meta = await r2.head(key);
      setMetadata(meta);

      if (meta) {
        // Get actual object
        const response = await r2.get(key, options);
        const blob = await response.blob();
        setData(blob);
      } else {
        setData(null);
      }
    } catch (err) {
      setError(err as Error);
    } finally {
      setLoading(false);
    }
  }, [bucket, key, options]);

  useEffect(() => {
    fetch();
  }, [fetch]);

  return { data, loading, error, metadata, refetch: fetch };
}

// React hook for R2 upload
export function useR2Upload(bucket: string): {
  upload: (key: string, file: File | Blob, options?: R2PutOptions) => Promise<R2Object>;
  uploading: boolean;
  error: Error | null;
  progress: number;
} {
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const [progress, setProgress] = useState(0);

  const r2 = new R2Client(bucket);

  const upload = useCallback(async (
    key: string,
    file: File | Blob,
    options?: R2PutOptions
  ): Promise<R2Object> => {
    setUploading(true);
    setError(null);
    setProgress(0);

    try {
      // For large files, we could implement chunked upload with progress
      const result = await r2.put(key, file, options);
      setProgress(100);
      return result;
    } catch (err) {
      setError(err as Error);
      throw err;
    } finally {
      setUploading(false);
    }
  }, [bucket]);

  return { upload, uploading, error, progress };
}

// React hook for R2 list
export function useR2List(
  bucket: string,
  options?: R2ListOptions
): {
  objects: R2Object[];
  loading: boolean;
  error: Error | null;
  hasMore: boolean;
  loadMore: () => Promise<void>;
  refresh: () => Promise<void>;
} {
  const [objects, setObjects] = useState<R2Object[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [cursor, setCursor] = useState<string | undefined>(options?.cursor);
  const [hasMore, setHasMore] = useState(true);

  const r2 = new R2Client(bucket);

  const loadObjects = useCallback(async (reset = false) => {
    setLoading(true);
    setError(null);

    try {
      const result = await r2.list({
        ...options,
        cursor: reset ? undefined : cursor
      });

      if (reset) {
        setObjects(result.objects);
      } else {
        setObjects(prev => [...prev, ...result.objects]);
      }

      setCursor(result.cursor);
      setHasMore(result.truncated);
    } catch (err) {
      setError(err as Error);
    } finally {
      setLoading(false);
    }
  }, [bucket, options, cursor]);

  const refresh = useCallback(() => loadObjects(true), [loadObjects]);
  const loadMore = useCallback(() => loadObjects(false), [loadObjects]);

  useEffect(() => {
    refresh();
  }, [bucket, options?.prefix]);

  return {
    objects,
    loading,
    error,
    hasMore,
    loadMore,
    refresh
  };
}

// Multipart upload for large files
export class R2MultipartUpload {
  private client: R2Client;
  private key: string;
  private uploadId: string | null = null;
  private parts: Array<{ partNumber: number; etag: string }> = [];

  constructor(bucket: string, key: string) {
    this.client = new R2Client(bucket);
    this.key = key;
  }

  async initiate(options?: R2PutOptions): Promise<void> {
    const response = await fetch(
      `${this.client['baseUrl']}/${this.client['bucket']}/${this.key}?uploads`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(options || {})
      }
    );

    if (!response.ok) {
      throw new Error('Failed to initiate multipart upload');
    }

    const data = await response.json();
    this.uploadId = data.uploadId;
  }

  async uploadPart(
    partNumber: number,
    data: ArrayBuffer | Blob
  ): Promise<void> {
    if (!this.uploadId) {
      throw new Error('Upload not initiated');
    }

    const response = await fetch(
      `${this.client['baseUrl']}/${this.client['bucket']}/${this.key}?partNumber=${partNumber}&uploadId=${this.uploadId}`,
      {
        method: 'PUT',
        body: data
      }
    );

    if (!response.ok) {
      throw new Error(`Failed to upload part ${partNumber}`);
    }

    const etag = response.headers.get('etag') || '';
    this.parts.push({ partNumber, etag });
  }

  async complete(): Promise<R2Object> {
    if (!this.uploadId) {
      throw new Error('Upload not initiated');
    }

    const response = await fetch(
      `${this.client['baseUrl']}/${this.client['bucket']}/${this.key}?uploadId=${this.uploadId}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          parts: this.parts.sort((a, b) => a.partNumber - b.partNumber)
        })
      }
    );

    if (!response.ok) {
      throw new Error('Failed to complete multipart upload');
    }

    return await response.json();
  }

  async abort(): Promise<void> {
    if (!this.uploadId) return;

    await fetch(
      `${this.client['baseUrl']}/${this.client['bucket']}/${this.key}?uploadId=${this.uploadId}`,
      {
        method: 'DELETE'
      }
    );
  }
}

// Presigned URL generator
export class R2PresignedUrl {
  static async create(
    bucket: string,
    key: string,
    options: {
      expiresIn: number; // seconds
      method?: 'GET' | 'PUT';
      contentType?: string;
    }
  ): Promise<string> {
    const response = await fetch('/api/r2/presign', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        bucket,
        key,
        ...options
      })
    });

    if (!response.ok) {
      throw new Error('Failed to create presigned URL');
    }

    const data = await response.json();
    return data.url;
  }
}

// Image transformation with R2
export function useR2Image(
  bucket: string,
  key: string,
  options?: {
    width?: number;
    height?: number;
    quality?: number;
    format?: 'auto' | 'webp' | 'avif';
  }
): {
  src: string;
  loading: boolean;
  error: Error | null;
} {
  const [src, setSrc] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const transformOptions = [];
    if (options?.width) transformOptions.push(`width=${options.width}`);
    if (options?.height) transformOptions.push(`height=${options.height}`);
    if (options?.quality) transformOptions.push(`quality=${options.quality}`);
    if (options?.format) transformOptions.push(`format=${options.format}`);

    const transformUrl = transformOptions.length
      ? `/cdn-cgi/image/${transformOptions.join(',')}/${bucket}/${key}`
      : `/api/r2/${bucket}/${key}`;

    setSrc(transformUrl);
    setLoading(false);
  }, [bucket, key, options]);

  return { src, loading, error };
}

// Export utilities
export const createR2Client = (bucket: string) => new R2Client(bucket);
export const createR2MultipartUpload = (bucket: string, key: string) => 
  new R2MultipartUpload(bucket, key);