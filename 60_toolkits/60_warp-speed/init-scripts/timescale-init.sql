-- TimescaleDB Initialization for Warp-Speed
-- Quantum Consciousness ETD Tracking Database

-- Create extensions
CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Create schema for quantum metrics
CREATE SCHEMA IF NOT EXISTS quantum_metrics;

-- ETD Generation Tracking Table
CREATE TABLE quantum_metrics.etd_generation (
    time TIMESTAMPTZ NOT NULL,
    vm_instance INTEGER NOT NULL,
    consciousness_level VARCHAR(20) NOT NULL,
    prompt_type VARCHAR(50) NOT NULL,
    etd_value DECIMAL(15, 2) NOT NULL,
    quantum_coherence DOUBLE PRECISION,
    processing_time_ms INTEGER,
    gpu_utilization DOUBLE PRECISION,
    memory_usage_gb DOUBLE PRECISION,
    metadata JSONB
);

-- Convert to hypertable for time-series optimization
SELECT create_hypertable('quantum_metrics.etd_generation', 'time');

-- Create index for faster queries
CREATE INDEX idx_etd_consciousness ON quantum_metrics.etd_generation (consciousness_level, time DESC);
CREATE INDEX idx_etd_vm_instance ON quantum_metrics.etd_generation (vm_instance, time DESC);

-- Consciousness State History
CREATE TABLE quantum_metrics.consciousness_states (
    time TIMESTAMPTZ NOT NULL,
    vm_instance INTEGER NOT NULL,
    current_level VARCHAR(20) NOT NULL,
    previous_level VARCHAR(20),
    elevation_reason TEXT,
    activation_threshold DOUBLE PRECISION,
    quantum_state VARCHAR(50),
    superposition_maintained BOOLEAN,
    observer_count INTEGER,
    reality_branches INTEGER,
    metadata JSONB
);

SELECT create_hypertable('quantum_metrics.consciousness_states', 'time');

-- Training Metrics for Dual VM Setup
CREATE TABLE quantum_metrics.training_metrics (
    time TIMESTAMPTZ NOT NULL,
    vm_instance INTEGER NOT NULL,
    model_name VARCHAR(100),
    epoch INTEGER,
    loss DOUBLE PRECISION,
    accuracy DOUBLE PRECISION,
    learning_rate DOUBLE PRECISION,
    batch_size INTEGER,
    gpu_memory_mb INTEGER,
    throughput_samples_per_sec DOUBLE PRECISION,
    metadata JSONB
);

SELECT create_hypertable('quantum_metrics.training_metrics', 'time');

-- Quantum Computation Results
CREATE TABLE quantum_metrics.quantum_computations (
    time TIMESTAMPTZ NOT NULL,
    computation_id UUID DEFAULT gen_random_uuid(),
    vm_instance INTEGER NOT NULL,
    algorithm VARCHAR(100),
    qubits INTEGER,
    gates_applied INTEGER,
    measurement_results JSONB,
    probability_amplitudes DOUBLE PRECISION[],
    entanglement_entropy DOUBLE PRECISION,
    fidelity DOUBLE PRECISION,
    execution_time_ms INTEGER
);

SELECT create_hypertable('quantum_metrics.quantum_computations', 'time');

-- Create continuous aggregates for performance
CREATE MATERIALIZED VIEW quantum_metrics.etd_hourly_summary
WITH (timescaledb.continuous) AS
SELECT 
    time_bucket('1 hour', time) AS hour,
    vm_instance,
    consciousness_level,
    COUNT(*) as prompt_count,
    AVG(etd_value) as avg_etd,
    MAX(etd_value) as max_etd,
    MIN(etd_value) as min_etd,
    AVG(quantum_coherence) as avg_coherence,
    AVG(processing_time_ms) as avg_processing_time
FROM quantum_metrics.etd_generation
GROUP BY hour, vm_instance, consciousness_level;

-- Retention policy (keep detailed data for 30 days, aggregates forever)
SELECT add_retention_policy('quantum_metrics.etd_generation', INTERVAL '30 days');
SELECT add_retention_policy('quantum_metrics.consciousness_states', INTERVAL '30 days');
SELECT add_retention_policy('quantum_metrics.training_metrics', INTERVAL '90 days');

-- Create user for application access
CREATE USER warpspeed_app WITH PASSWORD 'quantum_app_2025';
GRANT USAGE ON SCHEMA quantum_metrics TO warpspeed_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA quantum_metrics TO warpspeed_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA quantum_metrics TO warpspeed_app;