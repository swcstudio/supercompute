/**
 * Cloudflare D1 Database Integration
 * 
 * Type-safe SQL database with React hooks and migrations
 */

import { useCallback, useEffect, useState } from 'react';

// D1 Database types
export interface D1Database {
  prepare(query: string): D1PreparedStatement;
  batch<T = unknown>(statements: D1PreparedStatement[]): Promise<D1Result<T>[]>;
  exec(query: string): Promise<D1ExecResult>;
}

export interface D1PreparedStatement {
  bind(...values: any[]): D1PreparedStatement;
  first<T = unknown>(colName?: string): Promise<T | null>;
  run<T = unknown>(): Promise<D1Result<T>>;
  all<T = unknown>(): Promise<D1Result<T>>;
  raw<T = unknown>(): Promise<T[]>;
}

export interface D1Result<T = unknown> {
  results?: T[];
  success: boolean;
  error?: string;
  meta: {
    duration: number;
    rows_read: number;
    rows_written: number;
  };
}

export interface D1ExecResult {
  count: number;
  duration: number;
}

// D1 Client for browser
export class D1Client {
  private baseUrl: string;
  private database: string;

  constructor(database: string, baseUrl: string = '/api/d1') {
    this.database = database;
    this.baseUrl = baseUrl;
  }

  prepare(query: string): D1Statement {
    return new D1Statement(this.baseUrl, this.database, query);
  }

  async batch<T = unknown>(statements: D1Statement[]): Promise<D1Result<T>[]> {
    const queries = statements.map(stmt => stmt.toJSON());
    
    const response = await fetch(`${this.baseUrl}/${this.database}/batch`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ queries })
    });

    if (!response.ok) {
      throw new Error(`D1 batch failed: ${response.statusText}`);
    }

    return await response.json();
  }

  async exec(query: string): Promise<D1ExecResult> {
    const response = await fetch(`${this.baseUrl}/${this.database}/exec`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ query })
    });

    if (!response.ok) {
      throw new Error(`D1 exec failed: ${response.statusText}`);
    }

    return await response.json();
  }
}

// D1 Prepared Statement for browser
export class D1Statement {
  private baseUrl: string;
  private database: string;
  private query: string;
  private params: any[] = [];

  constructor(baseUrl: string, database: string, query: string) {
    this.baseUrl = baseUrl;
    this.database = database;
    this.query = query;
  }

  bind(...values: any[]): D1Statement {
    this.params = values;
    return this;
  }

  async first<T = unknown>(colName?: string): Promise<T | null> {
    const result = await this.run<T>();
    
    if (!result.results || result.results.length === 0) {
      return null;
    }

    const row = result.results[0];
    
    if (colName && typeof row === 'object' && row !== null) {
      return (row as any)[colName] || null;
    }

    return row;
  }

  async run<T = unknown>(): Promise<D1Result<T>> {
    const response = await fetch(`${this.baseUrl}/${this.database}/query`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        query: this.query,
        params: this.params
      })
    });

    if (!response.ok) {
      const error = await response.text();
      return {
        success: false,
        error,
        meta: { duration: 0, rows_read: 0, rows_written: 0 }
      };
    }

    return await response.json();
  }

  async all<T = unknown>(): Promise<D1Result<T>> {
    return this.run<T>();
  }

  async raw<T = unknown>(): Promise<T[]> {
    const result = await this.run<T>();
    return result.results || [];
  }

  toJSON() {
    return {
      query: this.query,
      params: this.params
    };
  }
}

// React hook for D1 queries
export function useD1Query<T = unknown>(
  database: string,
  query: string,
  params: any[] = [],
  options?: {
    enabled?: boolean;
    refetchInterval?: number;
  }
): {
  data: T[] | null;
  loading: boolean;
  error: Error | null;
  refetch: () => Promise<void>;
} {
  const [data, setData] = useState<T[] | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const d1 = new D1Client(database);

  const execute = useCallback(async () => {
    if (options?.enabled === false) return;

    setLoading(true);
    setError(null);

    try {
      const statement = d1.prepare(query);
      if (params.length > 0) {
        statement.bind(...params);
      }

      const result = await statement.all<T>();
      
      if (result.success) {
        setData(result.results || null);
      } else {
        throw new Error(result.error || 'Query failed');
      }
    } catch (err) {
      setError(err as Error);
    } finally {
      setLoading(false);
    }
  }, [database, query, ...params, options?.enabled]);

  useEffect(() => {
    execute();

    if (options?.refetchInterval) {
      const interval = setInterval(execute, options.refetchInterval);
      return () => clearInterval(interval);
    }
  }, [execute, options?.refetchInterval]);

  return { data, loading, error, refetch: execute };
}

// React hook for D1 mutations
export function useD1Mutation<T = unknown>(
  database: string
): {
  execute: (query: string, params?: any[]) => Promise<D1Result<T>>;
  loading: boolean;
  error: Error | null;
  data: D1Result<T> | null;
} {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const [data, setData] = useState<D1Result<T> | null>(null);

  const d1 = new D1Client(database);

  const execute = useCallback(async (
    query: string,
    params: any[] = []
  ): Promise<D1Result<T>> => {
    setLoading(true);
    setError(null);

    try {
      const statement = d1.prepare(query);
      if (params.length > 0) {
        statement.bind(...params);
      }

      const result = await statement.run<T>();
      setData(result);
      
      if (!result.success) {
        throw new Error(result.error || 'Mutation failed');
      }

      return result;
    } catch (err) {
      setError(err as Error);
      throw err;
    } finally {
      setLoading(false);
    }
  }, [database]);

  return { execute, loading, error, data };
}

// D1 Migration system
export interface Migration {
  version: number;
  name: string;
  up: string;
  down?: string;
}

export class D1Migrator {
  private d1: D1Client;
  private migrations: Migration[];

  constructor(database: string, migrations: Migration[]) {
    this.d1 = new D1Client(database);
    this.migrations = migrations.sort((a, b) => a.version - b.version);
  }

  async initialize(): Promise<void> {
    await this.d1.exec(`
      CREATE TABLE IF NOT EXISTS _migrations (
        version INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        applied_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);
  }

  async getCurrentVersion(): Promise<number> {
    const result = await this.d1.prepare(
      'SELECT MAX(version) as version FROM _migrations'
    ).first<{ version: number }>();

    return result?.version || 0;
  }

  async up(targetVersion?: number): Promise<void> {
    await this.initialize();

    const currentVersion = await this.getCurrentVersion();
    const target = targetVersion || Math.max(...this.migrations.map(m => m.version));

    const migrationsToRun = this.migrations.filter(
      m => m.version > currentVersion && m.version <= target
    );

    for (const migration of migrationsToRun) {
      console.log(`Running migration ${migration.version}: ${migration.name}`);
      
      await this.d1.exec(migration.up);
      
      await this.d1.prepare(
        'INSERT INTO _migrations (version, name) VALUES (?, ?)'
      ).bind(migration.version, migration.name).run();
    }
  }

  async down(targetVersion: number = 0): Promise<void> {
    await this.initialize();

    const currentVersion = await this.getCurrentVersion();

    const migrationsToRun = this.migrations
      .filter(m => m.version > targetVersion && m.version <= currentVersion)
      .reverse();

    for (const migration of migrationsToRun) {
      if (!migration.down) {
        throw new Error(`No down migration for version ${migration.version}`);
      }

      console.log(`Rolling back migration ${migration.version}: ${migration.name}`);
      
      await this.d1.exec(migration.down);
      
      await this.d1.prepare(
        'DELETE FROM _migrations WHERE version = ?'
      ).bind(migration.version).run();
    }
  }
}

// Query builder for D1
export class D1QueryBuilder {
  private parts: string[] = [];
  private values: any[] = [];

  select(...columns: string[]): this {
    this.parts.push(`SELECT ${columns.length ? columns.join(', ') : '*'}`);
    return this;
  }

  from(table: string): this {
    this.parts.push(`FROM ${table}`);
    return this;
  }

  where(condition: string, ...values: any[]): this {
    this.parts.push(`WHERE ${condition}`);
    this.values.push(...values);
    return this;
  }

  join(table: string, on: string): this {
    this.parts.push(`JOIN ${table} ON ${on}`);
    return this;
  }

  leftJoin(table: string, on: string): this {
    this.parts.push(`LEFT JOIN ${table} ON ${on}`);
    return this;
  }

  orderBy(column: string, direction: 'ASC' | 'DESC' = 'ASC'): this {
    this.parts.push(`ORDER BY ${column} ${direction}`);
    return this;
  }

  limit(count: number): this {
    this.parts.push(`LIMIT ${count}`);
    return this;
  }

  offset(count: number): this {
    this.parts.push(`OFFSET ${count}`);
    return this;
  }

  groupBy(...columns: string[]): this {
    this.parts.push(`GROUP BY ${columns.join(', ')}`);
    return this;
  }

  having(condition: string, ...values: any[]): this {
    this.parts.push(`HAVING ${condition}`);
    this.values.push(...values);
    return this;
  }

  build(): { query: string; params: any[] } {
    return {
      query: this.parts.join(' '),
      params: this.values
    };
  }
}

// Transaction support
export class D1Transaction {
  private statements: D1Statement[] = [];
  private d1: D1Client;

  constructor(database: string) {
    this.d1 = new D1Client(database);
    this.statements.push(
      this.d1.prepare('BEGIN TRANSACTION') as any
    );
  }

  prepare(query: string): D1Statement {
    const stmt = this.d1.prepare(query);
    this.statements.push(stmt as any);
    return stmt;
  }

  async commit(): Promise<D1Result<unknown>[]> {
    this.statements.push(
      this.d1.prepare('COMMIT') as any
    );
    return await this.d1.batch(this.statements);
  }

  async rollback(): Promise<void> {
    await this.d1.exec('ROLLBACK');
  }
}

// Export utilities
export const createD1Client = (database: string) => new D1Client(database);
export const createD1Migrator = (database: string, migrations: Migration[]) => 
  new D1Migrator(database, migrations);
export const createD1QueryBuilder = () => new D1QueryBuilder();
export const createD1Transaction = (database: string) => new D1Transaction(database);