//! Task scheduling and orchestration for REASSEMBLY
//! Manages compute job distribution and execution
//! Author: Oveshen Govender | SupercomputeR

use std::sync::Arc;
use std::collections::{HashMap, VecDeque};
use anyhow::Result;
use async_trait::async_trait;
use tokio::sync::{RwLock, mpsc, oneshot};
use tokio::time::{Duration, interval};
use serde::{Serialize, Deserialize};
use crate::backends::ComputeBackend;
use crate::types::SchedulingPolicy;

// ═══════════════════════════════════════════════════════════════
//                    TASK DEFINITION
// ═══════════════════════════════════════════════════════════════

/// Unique task identifier
#[derive(Debug, Clone, Copy, Hash, Eq, PartialEq, Serialize, Deserialize)]
pub struct TaskId(pub u64);

/// Task priority levels
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
pub enum Priority {
    Low = 0,
    Normal = 1,
    High = 2,
    Critical = 3,
}

/// Task status
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum TaskStatus {
    Pending,
    Scheduled,
    Running,
    Completed(Vec<u8>),
    Failed(String),
    Cancelled,
}

/// Compute task
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Task {
    pub id: TaskId,
    pub priority: Priority,
    pub payload: Vec<u8>,
    pub backend_hint: Option<String>,
    pub max_retries: u32,
    pub timeout: Option<Duration>,
    pub dependencies: Vec<TaskId>,
    pub created_at: u64,
    pub status: TaskStatus,
}

impl Task {
    pub fn new(payload: Vec<u8>) -> Self {
        static COUNTER: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
        
        Self {
            id: TaskId(COUNTER.fetch_add(1, std::sync::atomic::Ordering::SeqCst)),
            priority: Priority::Normal,
            payload,
            backend_hint: None,
            max_retries: 3,
            timeout: Some(Duration::from_secs(300)),
            dependencies: Vec::new(),
            created_at: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs(),
            status: TaskStatus::Pending,
        }
    }
    
    pub fn with_priority(mut self, priority: Priority) -> Self {
        self.priority = priority;
        self
    }
    
    pub fn with_backend(mut self, backend: String) -> Self {
        self.backend_hint = Some(backend);
        self
    }
    
    pub fn with_dependencies(mut self, deps: Vec<TaskId>) -> Self {
        self.dependencies = deps;
        self
    }
}

// ═══════════════════════════════════════════════════════════════
//                    SCHEDULER
// ═══════════════════════════════════════════════════════════════

/// Task scheduler with intelligent backend selection
pub struct TaskScheduler {
    /// Available compute backends
    backends: HashMap<String, Arc<dyn ComputeBackend>>,
    
    /// Task queues by priority
    queues: Arc<RwLock<PriorityQueues>>,
    
    /// Active tasks
    active: Arc<RwLock<HashMap<TaskId, TaskHandle>>>,
    
    /// Completed tasks
    completed: Arc<RwLock<HashMap<TaskId, TaskStatus>>>,
    
    /// Scheduling strategy
    strategy: SchedulingStrategy,
    
    /// Worker pool size
    num_workers: usize,
    
    /// Shutdown signal
    shutdown: Arc<RwLock<bool>>,
}

struct PriorityQueues {
    critical: VecDeque<Task>,
    high: VecDeque<Task>,
    normal: VecDeque<Task>,
    low: VecDeque<Task>,
}

impl PriorityQueues {
    fn new() -> Self {
        Self {
            critical: VecDeque::new(),
            high: VecDeque::new(),
            normal: VecDeque::new(),
            low: VecDeque::new(),
        }
    }
    
    fn push(&mut self, task: Task) {
        match task.priority {
            Priority::Critical => self.critical.push_back(task),
            Priority::High => self.high.push_back(task),
            Priority::Normal => self.normal.push_back(task),
            Priority::Low => self.low.push_back(task),
        }
    }
    
    fn pop(&mut self) -> Option<Task> {
        self.critical.pop_front()
            .or_else(|| self.high.pop_front())
            .or_else(|| self.normal.pop_front())
            .or_else(|| self.low.pop_front())
    }
    
    fn is_empty(&self) -> bool {
        self.critical.is_empty() && 
        self.high.is_empty() && 
        self.normal.is_empty() && 
        self.low.is_empty()
    }
}

struct TaskHandle {
    task: Task,
    backend: String,
    cancel_tx: Option<oneshot::Sender<()>>,
}

/// Scheduling strategy
#[derive(Debug, Clone)]
pub enum SchedulingStrategy {
    /// Round-robin across backends
    RoundRobin,
    
    /// Least loaded backend
    LeastLoaded,
    
    /// Cost optimized
    CostOptimized,
    
    /// Performance optimized
    PerformanceOptimized,
    
    /// Custom strategy
    Custom(Arc<dyn SchedulingPolicyTrait>),
}

/// Custom scheduling policy trait
#[async_trait]
pub trait SchedulingPolicyTrait: Send + Sync {
    async fn select_backend(
        &self,
        task: &Task,
        backends: &HashMap<String, Arc<dyn ComputeBackend>>,
    ) -> Option<String>;
}

impl TaskScheduler {
    pub fn new(
        backends: HashMap<String, Arc<dyn ComputeBackend>>,
        strategy: SchedulingStrategy,
        num_workers: usize,
    ) -> Self {
        Self {
            backends,
            queues: Arc::new(RwLock::new(PriorityQueues::new())),
            active: Arc::new(RwLock::new(HashMap::new())),
            completed: Arc::new(RwLock::new(HashMap::new())),
            strategy,
            num_workers,
            shutdown: Arc::new(RwLock::new(false)),
        }
    }
    
    /// Submit a task for execution
    pub async fn submit(&self, task: Task) -> Result<TaskId> {
        let id = task.id;
        
        // Check dependencies
        if !self.dependencies_met(&task).await {
            self.queues.write().await.push(task);
            return Ok(id);
        }
        
        // Try to schedule immediately
        if let Some(backend) = self.select_backend(&task).await {
            self.execute_task(task, backend).await?;
        } else {
            // Queue for later
            self.queues.write().await.push(task);
        }
        
        Ok(id)
    }
    
    /// Get task status
    pub async fn status(&self, id: TaskId) -> Option<TaskStatus> {
        // Check active tasks
        if let Some(handle) = self.active.read().await.get(&id) {
            return Some(handle.task.status.clone());
        }
        
        // Check completed tasks
        self.completed.read().await.get(&id).cloned()
    }
    
    /// Cancel a task
    pub async fn cancel(&self, id: TaskId) -> Result<()> {
        if let Some(mut handle) = self.active.write().await.remove(&id) {
            if let Some(cancel) = handle.cancel_tx.take() {
                let _ = cancel.send(());
            }
            self.completed.write().await.insert(id, TaskStatus::Cancelled);
        }
        Ok(())
    }
    
    /// Start the scheduler
    pub async fn start(&self) {
        // Spawn worker tasks
        for i in 0..self.num_workers {
            let scheduler = self.clone();
            tokio::spawn(async move {
                scheduler.worker_loop(i).await;
            });
        }
        
        // Spawn monitoring task
        let scheduler = self.clone();
        tokio::spawn(async move {
            scheduler.monitor_loop().await;
        });
    }
    
    /// Shutdown the scheduler
    pub async fn shutdown(&self) {
        *self.shutdown.write().await = true;
    }
    
    async fn worker_loop(&self, worker_id: usize) {
        let mut ticker = interval(Duration::from_millis(100));
        
        loop {
            ticker.tick().await;
            
            if *self.shutdown.read().await {
                break;
            }
            
            // Get next task from queue
            let task = {
                let mut queues = self.queues.write().await;
                queues.pop()
            };
            
            if let Some(task) = task {
                // Check dependencies
                if !self.dependencies_met(&task).await {
                    // Re-queue task
                    self.queues.write().await.push(task);
                    continue;
                }
                
                // Select backend and execute
                if let Some(backend) = self.select_backend(&task).await {
                    let _ = self.execute_task(task, backend).await;
                } else {
                    // No backend available, re-queue
                    self.queues.write().await.push(task);
                }
            }
        }
    }
    
    async fn monitor_loop(&self) {
        let mut ticker = interval(Duration::from_secs(10));
        
        loop {
            ticker.tick().await;
            
            if *self.shutdown.read().await {
                break;
            }
            
            // Monitor task health
            let active = self.active.read().await;
            for (id, handle) in active.iter() {
                // Check for timeouts
                if let Some(timeout) = handle.task.timeout {
                    let elapsed = std::time::SystemTime::now()
                        .duration_since(std::time::UNIX_EPOCH)
                        .unwrap()
                        .as_secs() - handle.task.created_at;
                    
                    if elapsed > timeout.as_secs() {
                        // Task timed out
                        let _ = self.cancel(*id).await;
                    }
                }
            }
        }
    }
    
    async fn select_backend(&self, task: &Task) -> Option<String> {
        // Use hint if provided
        if let Some(hint) = &task.backend_hint {
            if self.backends.contains_key(hint) {
                return Some(hint.clone());
            }
        }
        
        // Apply scheduling strategy
        match &self.strategy {
            SchedulingStrategy::RoundRobin => {
                // Simple round-robin
                self.backends.keys().next().cloned()
            },
            SchedulingStrategy::LeastLoaded => {
                // Select least loaded backend
                // In production, would track backend load
                self.backends.keys().next().cloned()
            },
            SchedulingStrategy::CostOptimized => {
                // Select cheapest backend
                // In production, would consider cost metrics
                self.backends.keys().next().cloned()
            },
            SchedulingStrategy::PerformanceOptimized => {
                // Select fastest backend
                // In production, would consider performance metrics
                self.backends.keys().next().cloned()
            },
            SchedulingStrategy::Custom(policy) => {
                policy.select_backend(task, &self.backends).await
            },
        }
    }
    
    async fn execute_task(&self, mut task: Task, backend_name: String) -> Result<()> {
        let backend = self.backends.get(&backend_name)
            .ok_or_else(|| anyhow::anyhow!("Backend not found"))?;
        
        task.status = TaskStatus::Running;
        
        let (cancel_tx, cancel_rx) = oneshot::channel();
        
        self.active.write().await.insert(
            task.id,
            TaskHandle {
                task: task.clone(),
                backend: backend_name.clone(),
                cancel_tx: Some(cancel_tx),
            },
        );
        
        // Execute on backend
        let result = tokio::select! {
            res = backend.execute(&task.payload) => res,
            _ = cancel_rx => {
                Ok(vec![])
            }
        };
        
        // Update status
        let status = match result {
            Ok(output) => TaskStatus::Completed(output),
            Err(e) => TaskStatus::Failed(e.to_string()),
        };
        
        self.active.write().await.remove(&task.id);
        self.completed.write().await.insert(task.id, status);
        
        Ok(())
    }
    
    async fn dependencies_met(&self, task: &Task) -> bool {
        for dep_id in &task.dependencies {
            if let Some(status) = self.completed.read().await.get(dep_id) {
                if !matches!(status, TaskStatus::Completed(_)) {
                    return false;
                }
            } else {
                return false;
            }
        }
        true
    }
}

impl Clone for TaskScheduler {
    fn clone(&self) -> Self {
        Self {
            backends: self.backends.clone(),
            queues: self.queues.clone(),
            active: self.active.clone(),
            completed: self.completed.clone(),
            strategy: self.strategy.clone(),
            num_workers: self.num_workers,
            shutdown: self.shutdown.clone(),
        }
    }
}

// ═══════════════════════════════════════════════════════════════
//                    DAG SCHEDULER
// ═══════════════════════════════════════════════════════════════

/// DAG-based task scheduler for complex workflows
pub struct DagScheduler {
    scheduler: Arc<TaskScheduler>,
    dag: Arc<RwLock<TaskDag>>,
}

#[derive(Debug, Clone)]
pub struct TaskDag {
    nodes: HashMap<TaskId, Task>,
    edges: HashMap<TaskId, Vec<TaskId>>,
}

impl DagScheduler {
    pub fn new(scheduler: Arc<TaskScheduler>) -> Self {
        Self {
            scheduler,
            dag: Arc::new(RwLock::new(TaskDag {
                nodes: HashMap::new(),
                edges: HashMap::new(),
            })),
        }
    }
    
    /// Add a workflow to the DAG
    pub async fn add_workflow(&self, tasks: Vec<Task>) -> Result<()> {
        let mut dag = self.dag.write().await;
        
        for task in tasks {
            let deps = task.dependencies.clone();
            dag.nodes.insert(task.id, task);
            
            for dep in deps {
                dag.edges.entry(dep)
                    .or_insert_with(Vec::new)
                    .push(task.id);
            }
        }
        
        // Schedule root tasks
        self.schedule_ready_tasks().await?;
        
        Ok(())
    }
    
    async fn schedule_ready_tasks(&self) -> Result<()> {
        let dag = self.dag.read().await;
        
        for (id, task) in &dag.nodes {
            if task.dependencies.is_empty() {
                self.scheduler.submit(task.clone()).await?;
            }
        }
        
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    async fn test_task_scheduler() {
        // Create mock backend
        let backends = HashMap::new();
        // In production, would add actual backends
        
        let scheduler = TaskScheduler::new(
            backends,
            SchedulingStrategy::RoundRobin,
            4,
        );
        
        // Submit tasks
        let task1 = Task::new(vec![1, 2, 3])
            .with_priority(Priority::High);
        let id1 = scheduler.submit(task1).await.unwrap();
        
        let task2 = Task::new(vec![4, 5, 6])
            .with_priority(Priority::Normal)
            .with_dependencies(vec![id1]);
        let id2 = scheduler.submit(task2).await.unwrap();
        
        // Check status
        assert!(scheduler.status(id1).await.is_some());
        assert!(scheduler.status(id2).await.is_some());
    }
    
    #[test]
    fn test_priority_queues() {
        let mut queues = PriorityQueues::new();
        
        let critical = Task::new(vec![]).with_priority(Priority::Critical);
        let high = Task::new(vec![]).with_priority(Priority::High);
        let normal = Task::new(vec![]).with_priority(Priority::Normal);
        let low = Task::new(vec![]).with_priority(Priority::Low);
        
        queues.push(low);
        queues.push(normal);
        queues.push(critical);
        queues.push(high);
        
        // Should pop in priority order
        assert_eq!(queues.pop().unwrap().priority, Priority::Critical);
        assert_eq!(queues.pop().unwrap().priority, Priority::High);
        assert_eq!(queues.pop().unwrap().priority, Priority::Normal);
        assert_eq!(queues.pop().unwrap().priority, Priority::Low);
        assert!(queues.is_empty());
    }
}

// ═══════════════════════════════════════════════════════════════
//                    ADAPTIVE SCHEDULER
// ═══════════════════════════════════════════════════════════════

/// Adaptive scheduler for backend selection
pub struct AdaptiveScheduler {
    policy: SchedulingPolicy,
}

impl AdaptiveScheduler {
    pub fn new(policy: SchedulingPolicy) -> Self {
        Self { policy }
    }
    
    /// Evaluate backend fitness for a computation
    pub async fn evaluate_backend(
        &self,
        backend: &dyn ComputeBackend,
        computation: &crate::Computation,
    ) -> Result<f64> {
        if !backend.is_available() {
            return Ok(0.0);
        }
        
        // Score based on policy
        let score = match self.policy {
            SchedulingPolicy::RoundRobin => 1.0,
            SchedulingPolicy::LeastLoaded => {
                // In production, would check actual load
                1.0
            }
            SchedulingPolicy::Fastest => {
                // Score based on backend type speed
                match backend.backend_type() {
                    crate::types::BackendType::Cuda => 10.0,
                    crate::types::BackendType::Rocm => 9.0,
                    crate::types::BackendType::Metal => 8.0,
                    crate::types::BackendType::Vulkan => 7.0,
                    crate::types::BackendType::OpenCL => 6.0,
                    crate::types::BackendType::Web3 => 5.0,
                    crate::types::BackendType::Cpu => 3.0,
                    crate::types::BackendType::Quantum => 15.0,
                }
            }
            SchedulingPolicy::Adaptive => {
                // Adaptive scoring based on computation characteristics
                self.adaptive_score(backend, computation)
            }
            SchedulingPolicy::CostOptimized => {
                // Score inversely proportional to cost
                match backend.backend_type() {
                    crate::types::BackendType::Cpu => 10.0,
                    crate::types::BackendType::Web3 => 1.0,
                    _ => 5.0,
                }
            }
        };
        
        Ok(score)
    }
    
    fn adaptive_score(&self, backend: &dyn ComputeBackend, computation: &crate::Computation) -> f64 {
        // Simple heuristic based on input size
        let size_mb = computation.input.len() as f64 / (1024.0 * 1024.0);
        
        if size_mb > 100.0 {
            // Large computations favor GPU
            match backend.backend_type() {
                crate::types::BackendType::Cuda | 
                crate::types::BackendType::Rocm |
                crate::types::BackendType::Metal => 10.0,
                _ => 3.0,
            }
        } else {
            // Small computations might be better on CPU
            match backend.backend_type() {
                crate::types::BackendType::Cpu => 8.0,
                _ => 5.0,
            }
        }
    }
}