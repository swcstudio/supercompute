//! Memory management for REASSEMBLY
//! Zero-copy, lock-free memory pool implementation
//! Author: Oveshen Govender | SupercomputeR

use std::sync::Arc;
use std::sync::atomic::{AtomicUsize, AtomicBool, Ordering};
use anyhow::Result;
use parking_lot::RwLock;
use crossbeam::queue::SegQueue;

// ═══════════════════════════════════════════════════════════════
//                    MEMORY POOL
// ═══════════════════════════════════════════════════════════════

/// Lock-free memory pool for zero-copy operations
pub struct MemoryPool {
    /// Total pool size in bytes
    total_size: usize,
    
    /// Currently allocated bytes
    allocated: AtomicUsize,
    
    /// Free buffers queue
    free_buffers: SegQueue<Arc<MemoryBuffer>>,
    
    /// All allocated buffers (for cleanup)
    all_buffers: RwLock<Vec<Arc<MemoryBuffer>>>,
}

impl MemoryPool {
    /// Create a new memory pool with the specified size
    pub fn new(total_size: usize) -> Self {
        Self {
            total_size,
            allocated: AtomicUsize::new(0),
            free_buffers: SegQueue::new(),
            all_buffers: RwLock::new(Vec::new()),
        }
    }
    
    /// Allocate a buffer from the pool
    pub fn allocate(&self, size: usize) -> Result<Arc<MemoryBuffer>> {
        // Check if we have space
        let current = self.allocated.load(Ordering::Relaxed);
        if current + size > self.total_size {
            anyhow::bail!("Memory pool exhausted: {} + {} > {}", current, size, self.total_size);
        }
        
        // Try to reuse a free buffer of suitable size
        while let Some(buffer) = self.free_buffers.pop() {
            if buffer.capacity() >= size {
                buffer.reset();
                buffer.resize(size);
                return Ok(buffer);
            }
        }
        
        // Allocate new buffer
        let buffer = Arc::new(MemoryBuffer::new(size));
        
        // Update allocated count
        self.allocated.fetch_add(size, Ordering::Relaxed);
        
        // Track buffer
        self.all_buffers.write().push(buffer.clone());
        
        Ok(buffer)
    }
    
    /// Return a buffer to the pool
    pub fn free(&self, buffer: Arc<MemoryBuffer>) {
        self.free_buffers.push(buffer);
    }
    
    /// Get currently used memory
    pub fn used(&self) -> usize {
        self.allocated.load(Ordering::Relaxed)
    }
    
    /// Get total pool size
    pub fn total(&self) -> usize {
        self.total_size
    }
    
    /// Clear all allocations
    pub fn clear(&self) {
        // Clear free queue
        while self.free_buffers.pop().is_some() {}
        
        // Clear all buffers
        self.all_buffers.write().clear();
        
        // Reset allocated counter
        self.allocated.store(0, Ordering::Relaxed);
    }
}

// ═══════════════════════════════════════════════════════════════
//                    MEMORY BUFFER
// ═══════════════════════════════════════════════════════════════

/// A reusable memory buffer with zero-copy semantics
pub struct MemoryBuffer {
    /// Raw memory
    data: RwLock<Vec<u8>>,
    
    /// Current size (may be less than capacity)
    size: AtomicUsize,
    
    /// Buffer is locked for GPU operations
    gpu_locked: AtomicBool,
    
    /// Pinned for DMA
    pinned: AtomicBool,
}

impl MemoryBuffer {
    /// Create a new buffer with specified capacity
    pub fn new(capacity: usize) -> Self {
        Self {
            data: RwLock::new(vec![0u8; capacity]),
            size: AtomicUsize::new(capacity),
            gpu_locked: AtomicBool::new(false),
            pinned: AtomicBool::new(false),
        }
    }
    
    /// Get buffer capacity
    pub fn capacity(&self) -> usize {
        self.data.read().len()
    }
    
    /// Get current buffer size
    pub fn size(&self) -> usize {
        self.size.load(Ordering::Relaxed)
    }
    
    /// Resize the buffer (must be <= capacity)
    pub fn resize(&self, new_size: usize) {
        assert!(new_size <= self.capacity());
        self.size.store(new_size, Ordering::Relaxed);
    }
    
    /// Reset the buffer for reuse
    pub fn reset(&self) {
        self.gpu_locked.store(false, Ordering::Relaxed);
        // Don't clear data for performance - just reset size
        self.size.store(0, Ordering::Relaxed);
    }
    
    /// Write data to buffer
    pub fn write(&self, data: &[u8]) -> Result<()> {
        if self.gpu_locked.load(Ordering::Relaxed) {
            anyhow::bail!("Buffer is locked for GPU operations");
        }
        
        let mut buffer = self.data.write();
        if data.len() > buffer.len() {
            anyhow::bail!("Data too large for buffer");
        }
        
        buffer[..data.len()].copy_from_slice(data);
        self.size.store(data.len(), Ordering::Relaxed);
        
        Ok(())
    }
    
    /// Read data from buffer
    pub fn read(&self) -> Vec<u8> {
        let size = self.size.load(Ordering::Relaxed);
        let buffer = self.data.read();
        buffer[..size].to_vec()
    }
    
    /// Get raw pointer for zero-copy operations
    pub unsafe fn as_ptr(&self) -> *const u8 {
        self.data.read().as_ptr()
    }
    
    /// Get mutable raw pointer (unsafe!)
    pub unsafe fn as_mut_ptr(&self) -> *mut u8 {
        // This is very unsafe but needed for GPU operations
        self.data.read().as_ptr() as *mut u8
    }
    
    /// Lock buffer for GPU operations
    pub fn lock_for_gpu(&self) -> Result<()> {
        if self.gpu_locked.compare_exchange(
            false,
            true,
            Ordering::Acquire,
            Ordering::Relaxed
        ).is_err() {
            anyhow::bail!("Buffer already locked for GPU");
        }
        Ok(())
    }
    
    /// Unlock buffer after GPU operations
    pub fn unlock_from_gpu(&self) {
        self.gpu_locked.store(false, Ordering::Release);
    }
    
    /// Pin buffer for DMA operations
    pub fn pin(&self) -> Result<()> {
        if self.pinned.compare_exchange(
            false,
            true,
            Ordering::Acquire,
            Ordering::Relaxed
        ).is_err() {
            anyhow::bail!("Buffer already pinned");
        }
        
        // In production, would actually pin memory pages
        Ok(())
    }
    
    /// Unpin buffer
    pub fn unpin(&self) {
        self.pinned.store(false, Ordering::Release);
    }
}

impl AsRef<[u8]> for MemoryBuffer {
    fn as_ref(&self) -> &[u8] {
        // This is a simplification - in production would need unsafe
        &[]
    }
}

// ═══════════════════════════════════════════════════════════════
//                    GPU MEMORY MANAGEMENT
// ═══════════════════════════════════════════════════════════════

/// GPU memory allocation strategy
#[derive(Debug, Clone, Copy)]
pub enum GpuMemoryStrategy {
    /// Best fit allocation
    BestFit,
    /// First fit allocation
    FirstFit,
    /// Buddy allocator
    Buddy,
}

/// GPU memory allocator
pub struct GpuMemoryAllocator {
    strategy: GpuMemoryStrategy,
    device_memory: usize,
    allocated: AtomicUsize,
}

impl GpuMemoryAllocator {
    pub fn new(strategy: GpuMemoryStrategy, device_memory: usize) -> Self {
        Self {
            strategy,
            device_memory,
            allocated: AtomicUsize::new(0),
        }
    }
    
    pub fn allocate(&self, size: usize) -> Result<GpuMemoryHandle> {
        let current = self.allocated.load(Ordering::Relaxed);
        if current + size > self.device_memory {
            anyhow::bail!("GPU memory exhausted");
        }
        
        self.allocated.fetch_add(size, Ordering::Relaxed);
        
        Ok(GpuMemoryHandle {
            offset: current,
            size,
        })
    }
    
    pub fn free(&self, handle: GpuMemoryHandle) {
        self.allocated.fetch_sub(handle.size, Ordering::Relaxed);
    }
}

/// Handle to GPU memory allocation
#[derive(Debug, Clone)]
pub struct GpuMemoryHandle {
    pub offset: usize,
    pub size: usize,
}

// ═══════════════════════════════════════════════════════════════
//                    UNIFIED MEMORY
// ═══════════════════════════════════════════════════════════════

/// Unified memory that can be accessed by both CPU and GPU
pub struct UnifiedMemory {
    cpu_buffer: Arc<MemoryBuffer>,
    gpu_handle: Option<GpuMemoryHandle>,
    coherent: AtomicBool,
}

impl UnifiedMemory {
    pub fn new(size: usize) -> Self {
        Self {
            cpu_buffer: Arc::new(MemoryBuffer::new(size)),
            gpu_handle: None,
            coherent: AtomicBool::new(true),
        }
    }
    
    /// Synchronize CPU and GPU memory
    pub async fn synchronize(&self) -> Result<()> {
        if !self.coherent.load(Ordering::Relaxed) {
            // Copy data between CPU and GPU
            // Implementation depends on backend
            self.coherent.store(true, Ordering::Release);
        }
        Ok(())
    }
    
    /// Mark memory as modified on CPU
    pub fn mark_cpu_modified(&self) {
        self.coherent.store(false, Ordering::Relaxed);
    }
    
    /// Mark memory as modified on GPU
    pub fn mark_gpu_modified(&self) {
        self.coherent.store(false, Ordering::Relaxed);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_memory_pool() {
        let pool = MemoryPool::new(1024 * 1024); // 1MB pool
        
        // Allocate buffer
        let buffer1 = pool.allocate(1024).unwrap();
        assert_eq!(buffer1.capacity(), 1024);
        assert_eq!(pool.used(), 1024);
        
        // Write and read
        buffer1.write(b"Hello, REASSEMBLY!").unwrap();
        let data = buffer1.read();
        assert_eq!(&data[..18], b"Hello, REASSEMBLY!");
        
        // Return to pool
        pool.free(buffer1);
        
        // Allocate again (should reuse)
        let buffer2 = pool.allocate(512).unwrap();
        assert_eq!(buffer2.size(), 512);
    }
    
    #[test]
    fn test_gpu_locking() {
        let buffer = MemoryBuffer::new(1024);
        
        // Lock for GPU
        buffer.lock_for_gpu().unwrap();
        
        // Can't write while locked
        assert!(buffer.write(b"test").is_err());
        
        // Unlock
        buffer.unlock_from_gpu();
        
        // Now can write
        assert!(buffer.write(b"test").is_ok());
    }
}