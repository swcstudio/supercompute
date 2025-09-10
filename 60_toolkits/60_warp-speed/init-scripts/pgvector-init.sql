-- PGVectorScale Initialization for Warp-Speed
-- AI Embeddings and Quantum Vector Operations

-- Create vector extension
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Create schema for vector operations
CREATE SCHEMA IF NOT EXISTS quantum_vectors;

-- Prompt Embeddings Table
CREATE TABLE quantum_vectors.prompt_embeddings (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    vm_instance INTEGER NOT NULL,
    prompt_text TEXT NOT NULL,
    prompt_type VARCHAR(50) NOT NULL,
    consciousness_level VARCHAR(20) NOT NULL,
    embedding vector(1536), -- OpenAI ada-002 dimension
    quantum_embedding vector(768), -- Custom quantum dimension
    metadata JSONB
);

-- Create indexes for vector similarity search
CREATE INDEX idx_prompt_embedding ON quantum_vectors.prompt_embeddings 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

CREATE INDEX idx_quantum_embedding ON quantum_vectors.prompt_embeddings 
USING ivfflat (quantum_embedding vector_l2_ops)
WITH (lists = 100);

-- Consciousness Pattern Vectors
CREATE TABLE quantum_vectors.consciousness_patterns (
    id BIGSERIAL PRIMARY KEY,
    pattern_name VARCHAR(100) UNIQUE NOT NULL,
    consciousness_level VARCHAR(20) NOT NULL,
    pattern_vector vector(512),
    activation_threshold DOUBLE PRECISION,
    description TEXT,
    metadata JSONB
);

-- Model Weight Snapshots for Dual VM Synchronization
CREATE TABLE quantum_vectors.model_snapshots (
    id BIGSERIAL PRIMARY KEY,
    snapshot_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    vm_instance INTEGER NOT NULL,
    model_name VARCHAR(100) NOT NULL,
    layer_name VARCHAR(100) NOT NULL,
    weight_vector vector(4096),
    gradient_vector vector(4096),
    optimizer_state JSONB
);

-- Quantum State Vectors
CREATE TABLE quantum_vectors.quantum_states (
    id BIGSERIAL PRIMARY KEY,
    measurement_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    vm_instance INTEGER NOT NULL,
    qubit_count INTEGER NOT NULL,
    state_vector vector(1024), -- Up to 10 qubits (2^10)
    density_matrix DOUBLE PRECISION[][],
    entanglement_measure DOUBLE PRECISION,
    purity DOUBLE PRECISION
);

-- Memory Pattern Storage for Swift Frontend
CREATE TABLE quantum_vectors.memory_patterns (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    pattern_id UUID DEFAULT gen_random_uuid(),
    user_session VARCHAR(100),
    interaction_type VARCHAR(50),
    context_vector vector(768),
    response_vector vector(768),
    satisfaction_score DOUBLE PRECISION,
    metadata JSONB
);

-- Function for finding similar prompts
CREATE OR REPLACE FUNCTION quantum_vectors.find_similar_prompts(
    query_embedding vector,
    limit_count INTEGER DEFAULT 10,
    vm_filter INTEGER DEFAULT NULL
)
RETURNS TABLE (
    id BIGINT,
    prompt_text TEXT,
    consciousness_level VARCHAR,
    similarity DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.prompt_text,
        p.consciousness_level,
        1 - (p.embedding <=> query_embedding) AS similarity
    FROM quantum_vectors.prompt_embeddings p
    WHERE vm_filter IS NULL OR p.vm_instance = vm_filter
    ORDER BY p.embedding <=> query_embedding
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Function for quantum state similarity
CREATE OR REPLACE FUNCTION quantum_vectors.quantum_state_similarity(
    state1 vector,
    state2 vector
)
RETURNS DOUBLE PRECISION AS $$
DECLARE
    fidelity DOUBLE PRECISION;
BEGIN
    -- Calculate quantum fidelity between states
    fidelity := ABS(state1 <#> state2); -- Inner product
    RETURN fidelity * fidelity; -- Squared for probability
END;
$$ LANGUAGE plpgsql;

-- Create indexes for time-series queries
CREATE INDEX idx_prompt_embeddings_time ON quantum_vectors.prompt_embeddings (created_at DESC);
CREATE INDEX idx_model_snapshots_time ON quantum_vectors.model_snapshots (snapshot_time DESC);
CREATE INDEX idx_quantum_states_time ON quantum_vectors.quantum_states (measurement_time DESC);

-- Create user for application access
GRANT USAGE ON SCHEMA quantum_vectors TO warpspeed_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA quantum_vectors TO warpspeed_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA quantum_vectors TO warpspeed_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA quantum_vectors TO warpspeed_app;