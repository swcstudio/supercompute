//! Compute backend implementations for REASSEMBLY
//! Author: Oveshen Govender | SupercomputeR

use async_trait::async_trait;
use anyhow::Result;
use std::sync::Arc;
use serde::{Serialize, Deserialize};

use crate::memory::MemoryBuffer;
use crate::wasm::WasmModule;

// ═══════════════════════════════════════════════════════════════
//                    BACKEND TRAIT
// ═══════════════════════════════════════════════════════════════

/// Types of compute backends
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum BackendType {
    Cpu,
    Cuda,
    Rocm,
    Metal,
    Vulkan,
    OpenCL,
    Web3,
    Quantum,
}

/// Trait for all compute backends
#[async_trait]
pub trait ComputeBackend: Send + Sync {
    /// Get the backend type
    fn backend_type(&self) -> BackendType;
    
    /// Check if backend is available
    fn is_available(&self) -> bool;
    
    /// Get backend capabilities
    fn capabilities(&self) -> BackendCapabilities;
    
    /// Execute a WebAssembly module
    async fn execute(
        &self,
        module: Arc<WasmModule>,
        input: Arc<MemoryBuffer>,
    ) -> Result<Vec<u8>>;
    
    /// Estimate resource requirements
    async fn estimate_resources(&self, module: &WasmModule) -> ResourceEstimate;
    
    /// Shutdown the backend
    async fn shutdown(&mut self) -> Result<()>;
}

/// Backend capabilities
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BackendCapabilities {
    pub max_memory: usize,
    pub max_threads: usize,
    pub supports_float16: bool,
    pub supports_float32: bool,
    pub supports_float64: bool,
    pub supports_int8: bool,
    pub supports_tensor_ops: bool,
    pub supports_async: bool,
}

/// Resource estimate for computation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResourceEstimate {
    pub memory_bytes: usize,
    pub compute_units: f64,
    pub estimated_time_ms: u64,
}

// ═══════════════════════════════════════════════════════════════
//                    CPU BACKEND
// ═══════════════════════════════════════════════════════════════

pub struct CpuBackend {
    num_threads: usize,
    simd_width: usize,
}

impl CpuBackend {
    pub fn new() -> Result<Self> {
        Ok(Self {
            num_threads: num_cpus::get(),
            simd_width: 256, // AVX2
        })
    }
}

#[async_trait]
impl ComputeBackend for CpuBackend {
    fn backend_type(&self) -> BackendType {
        BackendType::Cpu
    }
    
    fn is_available(&self) -> bool {
        true // CPU is always available
    }
    
    fn capabilities(&self) -> BackendCapabilities {
        BackendCapabilities {
            max_memory: sys_info::mem_info()
                .map(|info| info.total as usize * 1024)
                .unwrap_or(8 * 1024 * 1024 * 1024),
            max_threads: self.num_threads,
            supports_float16: false,
            supports_float32: true,
            supports_float64: true,
            supports_int8: true,
            supports_tensor_ops: false,
            supports_async: true,
        }
    }
    
    async fn execute(
        &self,
        module: Arc<WasmModule>,
        input: Arc<MemoryBuffer>,
    ) -> Result<Vec<u8>> {
        // Execute WASM module on CPU
        module.execute_cpu(input.as_ref()).await
    }
    
    async fn estimate_resources(&self, module: &WasmModule) -> ResourceEstimate {
        ResourceEstimate {
            memory_bytes: module.memory_requirements(),
            compute_units: 1.0,
            estimated_time_ms: 100, // Rough estimate
        }
    }
    
    async fn shutdown(&mut self) -> Result<()> {
        Ok(())
    }
}

// ═══════════════════════════════════════════════════════════════
//                    CUDA BACKEND
// ═══════════════════════════════════════════════════════════════

#[cfg(feature = "cuda")]
pub struct CudaBackend {
    device_id: i32,
    compute_capability: (i32, i32),
    memory_bytes: usize,
}

#[cfg(feature = "cuda")]
impl CudaBackend {
    pub fn new() -> Result<Self> {
        use cuda_sys::*;
        
        unsafe {
            // Initialize CUDA
            let result = cuInit(0);
            if result != CUresult::CUDA_SUCCESS {
                anyhow::bail!("Failed to initialize CUDA");
            }
            
            // Get device properties
            let mut device_count = 0;
            cuDeviceGetCount(&mut device_count);
            
            if device_count == 0 {
                anyhow::bail!("No CUDA devices found");
            }
            
            // Use first device
            let device_id = 0;
            let mut device = 0;
            cuDeviceGet(&mut device, device_id);
            
            // Get compute capability
            let mut major = 0;
            let mut minor = 0;
            cuDeviceComputeCapability(&mut major, &mut minor, device);
            
            // Get memory
            let mut memory = 0;
            cuDeviceTotalMem(&mut memory, device);
            
            Ok(Self {
                device_id,
                compute_capability: (major, minor),
                memory_bytes: memory as usize,
            })
        }
    }
}

#[cfg(feature = "cuda")]
#[async_trait]
impl ComputeBackend for CudaBackend {
    fn backend_type(&self) -> BackendType {
        BackendType::Cuda
    }
    
    fn is_available(&self) -> bool {
        true
    }
    
    fn capabilities(&self) -> BackendCapabilities {
        BackendCapabilities {
            max_memory: self.memory_bytes,
            max_threads: 1024 * 32, // Typical for modern GPUs
            supports_float16: self.compute_capability.0 >= 5,
            supports_float32: true,
            supports_float64: self.compute_capability.0 >= 1 && self.compute_capability.1 >= 3,
            supports_int8: self.compute_capability.0 >= 6,
            supports_tensor_ops: self.compute_capability.0 >= 7,
            supports_async: true,
        }
    }
    
    async fn execute(
        &self,
        module: Arc<WasmModule>,
        input: Arc<MemoryBuffer>,
    ) -> Result<Vec<u8>> {
        // Execute WASM module on CUDA GPU
        module.execute_cuda(self.device_id, input.as_ref()).await
    }
    
    async fn estimate_resources(&self, module: &WasmModule) -> ResourceEstimate {
        ResourceEstimate {
            memory_bytes: module.memory_requirements(),
            compute_units: 100.0, // GPUs are much faster
            estimated_time_ms: 10,
        }
    }
    
    async fn shutdown(&mut self) -> Result<()> {
        // Clean up CUDA resources
        Ok(())
    }
}

// ═══════════════════════════════════════════════════════════════
//                    ROCM BACKEND
// ═══════════════════════════════════════════════════════════════

#[cfg(feature = "rocm")]
pub struct RocmBackend {
    device_id: i32,
    memory_bytes: usize,
}

#[cfg(feature = "rocm")]
impl RocmBackend {
    pub fn new() -> Result<Self> {
        // Initialize ROCm/HIP
        Ok(Self {
            device_id: 0,
            memory_bytes: 16 * 1024 * 1024 * 1024, // 16GB typical
        })
    }
}

#[cfg(feature = "rocm")]
#[async_trait]
impl ComputeBackend for RocmBackend {
    fn backend_type(&self) -> BackendType {
        BackendType::Rocm
    }
    
    fn is_available(&self) -> bool {
        true
    }
    
    fn capabilities(&self) -> BackendCapabilities {
        BackendCapabilities {
            max_memory: self.memory_bytes,
            max_threads: 1024 * 32,
            supports_float16: true,
            supports_float32: true,
            supports_float64: true,
            supports_int8: true,
            supports_tensor_ops: true, // Matrix cores on MI100+
            supports_async: true,
        }
    }
    
    async fn execute(
        &self,
        module: Arc<WasmModule>,
        input: Arc<MemoryBuffer>,
    ) -> Result<Vec<u8>> {
        module.execute_rocm(self.device_id, input.as_ref()).await
    }
    
    async fn estimate_resources(&self, module: &WasmModule) -> ResourceEstimate {
        ResourceEstimate {
            memory_bytes: module.memory_requirements(),
            compute_units: 90.0,
            estimated_time_ms: 12,
        }
    }
    
    async fn shutdown(&mut self) -> Result<()> {
        Ok(())
    }
}

// ═══════════════════════════════════════════════════════════════
//                    METAL BACKEND (Apple Silicon)
// ═══════════════════════════════════════════════════════════════

#[cfg(feature = "metal")]
pub struct MetalBackend {
    device: metal::Device,
    command_queue: metal::CommandQueue,
}

#[cfg(feature = "metal")]
impl MetalBackend {
    pub fn new() -> Result<Self> {
        let device = metal::Device::system_default()
            .ok_or_else(|| anyhow::anyhow!("No Metal device found"))?;
        
        let command_queue = device.new_command_queue();
        
        Ok(Self {
            device,
            command_queue,
        })
    }
}

#[cfg(feature = "metal")]
#[async_trait]
impl ComputeBackend for MetalBackend {
    fn backend_type(&self) -> BackendType {
        BackendType::Metal
    }
    
    fn is_available(&self) -> bool {
        true
    }
    
    fn capabilities(&self) -> BackendCapabilities {
        BackendCapabilities {
            max_memory: self.device.recommended_max_working_set_size() as usize,
            max_threads: 1024 * 8,
            supports_float16: true,
            supports_float32: true,
            supports_float64: false,
            supports_int8: true,
            supports_tensor_ops: true, // Neural Engine
            supports_async: true,
        }
    }
    
    async fn execute(
        &self,
        module: Arc<WasmModule>,
        input: Arc<MemoryBuffer>,
    ) -> Result<Vec<u8>> {
        module.execute_metal(&self.device, &self.command_queue, input.as_ref()).await
    }
    
    async fn estimate_resources(&self, module: &WasmModule) -> ResourceEstimate {
        ResourceEstimate {
            memory_bytes: module.memory_requirements(),
            compute_units: 50.0,
            estimated_time_ms: 15,
        }
    }
    
    async fn shutdown(&mut self) -> Result<()> {
        Ok(())
    }
}

// ═══════════════════════════════════════════════════════════════
//                    VULKAN BACKEND
// ═══════════════════════════════════════════════════════════════

#[cfg(feature = "vulkan")]
pub struct VulkanBackend {
    device: Arc<vulkano::device::Device>,
    queue: Arc<vulkano::device::Queue>,
}

#[cfg(feature = "vulkan")]
impl VulkanBackend {
    pub fn new() -> Result<Self> {
        use vulkano::instance::{Instance, InstanceCreateInfo};
        use vulkano::device::{Device, DeviceCreateInfo, QueueCreateInfo};
        
        let instance = Instance::new(InstanceCreateInfo::default())?;
        
        let physical = instance
            .enumerate_physical_devices()?
            .next()
            .ok_or_else(|| anyhow::anyhow!("No Vulkan device found"))?;
        
        let queue_family_index = physical
            .queue_family_properties()
            .iter()
            .enumerate()
            .position(|(_, q)| q.queue_flags.compute)
            .ok_or_else(|| anyhow::anyhow!("No compute queue found"))? as u32;
        
        let (device, mut queues) = Device::new(
            physical,
            DeviceCreateInfo {
                queue_create_infos: vec![QueueCreateInfo {
                    queue_family_index,
                    ..Default::default()
                }],
                ..Default::default()
            },
        )?;
        
        let queue = queues.next().unwrap();
        
        Ok(Self {
            device,
            queue,
        })
    }
}

#[cfg(feature = "vulkan")]
#[async_trait]
impl ComputeBackend for VulkanBackend {
    fn backend_type(&self) -> BackendType {
        BackendType::Vulkan
    }
    
    fn is_available(&self) -> bool {
        true
    }
    
    fn capabilities(&self) -> BackendCapabilities {
        let props = self.device.physical_device().properties();
        
        BackendCapabilities {
            max_memory: props.max_memory_allocation_count as usize,
            max_threads: props.max_compute_work_group_invocations as usize,
            supports_float16: true,
            supports_float32: true,
            supports_float64: props.max_compute_shared_memory_size > 0,
            supports_int8: true,
            supports_tensor_ops: false,
            supports_async: true,
        }
    }
    
    async fn execute(
        &self,
        module: Arc<WasmModule>,
        input: Arc<MemoryBuffer>,
    ) -> Result<Vec<u8>> {
        module.execute_vulkan(&self.device, &self.queue, input.as_ref()).await
    }
    
    async fn estimate_resources(&self, module: &WasmModule) -> ResourceEstimate {
        ResourceEstimate {
            memory_bytes: module.memory_requirements(),
            compute_units: 40.0,
            estimated_time_ms: 20,
        }
    }
    
    async fn shutdown(&mut self) -> Result<()> {
        Ok(())
    }
}

// ═══════════════════════════════════════════════════════════════
//                    WEB3 BACKEND
// ═══════════════════════════════════════════════════════════════

use crate::web3::Web3Provider;

pub struct Web3Backend {
    provider: Arc<Web3Provider>,
}

impl Web3Backend {
    pub fn new(provider: Arc<Web3Provider>) -> Self {
        Self { provider }
    }
}

#[async_trait]
impl ComputeBackend for Web3Backend {
    fn backend_type(&self) -> BackendType {
        BackendType::Web3
    }
    
    fn is_available(&self) -> bool {
        true
    }
    
    fn capabilities(&self) -> BackendCapabilities {
        BackendCapabilities {
            max_memory: 1024 * 1024 * 1024, // 1GB typical for smart contracts
            max_threads: 1, // Sequential execution
            supports_float16: false,
            supports_float32: false, // Most blockchains don't support floats
            supports_float64: false,
            supports_int8: true,
            supports_tensor_ops: false,
            supports_async: true,
        }
    }
    
    async fn execute(
        &self,
        module: Arc<WasmModule>,
        input: Arc<MemoryBuffer>,
    ) -> Result<Vec<u8>> {
        // This is handled specially in the engine
        anyhow::bail!("Web3 backend execution must go through engine")
    }
    
    async fn estimate_resources(&self, module: &WasmModule) -> ResourceEstimate {
        ResourceEstimate {
            memory_bytes: module.memory_requirements(),
            compute_units: 0.1, // Very slow compared to local compute
            estimated_time_ms: 10000, // Blockchain is slow
        }
    }
    
    async fn shutdown(&mut self) -> Result<()> {
        Ok(())
    }
}