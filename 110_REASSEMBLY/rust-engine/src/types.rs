//! Common types for REASSEMBLY engine
//! Author: Oveshen Govender | SupercomputeR

use serde::{Serialize, Deserialize};

/// Backend type enumeration
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum BackendType {
    Cpu,
    Cuda,
    Rocm,
    Metal,
    Vulkan,
    OpenCL,
    Web3,
    Web3Gpu,  // Decentralized GPU aggregator (io.net, Render, Akash)
    Quantum,
}

/// Verification requirement for computations
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum VerificationRequirement {
    /// zk-SNARK proof
    ZkSnark,
    /// zk-STARK proof
    ZkStark,
    /// Bulletproof
    Bulletproof,
    /// Optimistic (no proof needed)
    Optimistic,
}

/// Verification strategy for the engine
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum VerificationStrategy {
    /// Always verify
    Always,
    /// Verify randomly
    Random,
    /// Optimistic (verify only on challenge)
    Optimistic,
    /// Never verify
    Never,
}

/// Scheduling policy for backend selection
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum SchedulingPolicy {
    /// Round-robin scheduling
    RoundRobin,
    /// Least loaded backend
    LeastLoaded,
    /// Fastest backend
    Fastest,
    /// Adaptive based on workload
    Adaptive,
    /// Cost-optimized
    CostOptimized,
}

/// Generate placeholder zk-SNARK proof
pub fn generate_zk_snark_proof(_computation: &super::Computation, _output: &[u8]) -> anyhow::Result<Vec<u8>> {
    // Placeholder implementation
    Ok(vec![0u8; 256])
}

/// Generate placeholder zk-STARK proof
pub fn generate_zk_stark_proof(_computation: &super::Computation, _output: &[u8]) -> anyhow::Result<Vec<u8>> {
    // Placeholder implementation
    Ok(vec![0u8; 512])
}

/// Generate placeholder bulletproof
pub fn generate_bulletproof(_computation: &super::Computation, _output: &[u8]) -> anyhow::Result<Vec<u8>> {
    // Placeholder implementation
    Ok(vec![0u8; 128])
}