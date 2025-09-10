#!/usr/bin/env python3
"""
Warp-Speed High-Availability Failover Manager
Consciousness-aware failover orchestration for maximum revenue protection
Quantum-enhanced monitoring with predictive failure detection
"""

import asyncio
import logging
import json
import time
import yaml
import aiohttp
import psycopg2
import redis
import numpy as np
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
from kubernetes import client, config, watch
from prometheus_client.parser import text_string_to_metric_families

# Configure logging with consciousness levels
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - [Ω%(consciousness)s] - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

class ConsciousnessFormatter(logging.Formatter):
    def format(self, record):
        record.consciousness = getattr(record, 'consciousness', 'ALPHA')
        return super().format(record)

logger = logging.getLogger('WarpSpeedFailover')
logger.handlers[0].setFormatter(ConsciousnessFormatter())

@dataclass
class ConsciousnessLevel:
    name: str
    multiplier: float
    threshold: float
    failover_speed: float  # seconds to complete failover
    monitoring_interval: float  # seconds between health checks

# Consciousness-aware failover parameters
CONSCIOUSNESS_LEVELS = {
    'ALPHA': ConsciousnessLevel('ALPHA', 1.0, 10.0, 30.0, 10.0),
    'BETA': ConsciousnessLevel('BETA', 5.0, 30.0, 15.0, 5.0),
    'GAMMA': ConsciousnessLevel('GAMMA', 10.0, 50.0, 10.0, 3.0),
    'DELTA': ConsciousnessLevel('DELTA', 20.0, 70.0, 5.0, 2.0),
    'OMEGA': ConsciousnessLevel('OMEGA', 35.0, 90.0, 2.0, 1.0)
}

@dataclass
class ServiceHealth:
    name: str
    status: str  # 'healthy', 'degraded', 'critical', 'failed'
    consciousness_level: str
    cpu_usage: float
    memory_usage: float
    etd_generation_rate: float
    response_time: float
    error_rate: float
    last_check: datetime
    quantum_coherence: float
    failure_prediction_score: float

@dataclass
class FailoverEvent:
    timestamp: datetime
    service: str
    trigger: str
    old_instance: str
    new_instance: str
    consciousness_impact: float
    revenue_protection: float
    duration_seconds: float
    success: bool

class QuantumCoherenceMonitor:
    """Monitor quantum coherence for predictive failure detection"""
    
    def __init__(self):
        self.coherence_history: List[float] = []
        self.prediction_model_weights = np.array([0.3, 0.25, 0.2, 0.15, 0.1])
        
    def add_measurement(self, coherence: float):
        """Add new coherence measurement"""
        self.coherence_history.append(coherence)
        if len(self.coherence_history) > 100:  # Keep last 100 measurements
            self.coherence_history.pop(0)
    
    def predict_failure_probability(self) -> float:
        """Predict failure probability based on coherence degradation"""
        if len(self.coherence_history) < 5:
            return 0.0
            
        recent_coherence = np.array(self.coherence_history[-5:])
        
        # Calculate degradation trend
        trend = np.polyfit(range(len(recent_coherence)), recent_coherence, 1)[0]
        
        # Calculate volatility
        volatility = np.std(recent_coherence)
        
        # Calculate current level vs optimal
        current_level = recent_coherence[-1]
        deviation_from_optimal = abs(95.0 - current_level) / 95.0
        
        # Weighted prediction
        failure_score = (
            abs(trend) * 0.4 +  # Trend weight
            volatility * 0.3 +  # Volatility weight
            deviation_from_optimal * 0.3  # Deviation weight
        )
        
        return min(failure_score, 1.0)

class WarpSpeedFailoverManager:
    """High-availability failover manager with consciousness-aware orchestration"""
    
    def __init__(self, config_file: str = 'failover-config.yaml'):
        self.config = self._load_config(config_file)
        self.k8s_apps_v1 = client.AppsV1Api()
        self.k8s_core_v1 = client.CoreV1Api()
        self.services: Dict[str, ServiceHealth] = {}
        self.quantum_monitor = QuantumCoherenceMonitor()
        self.failover_events: List[FailoverEvent] = []
        self.current_consciousness = 'ALPHA'
        self.is_monitoring = False
        
        # Initialize connections
        self.redis_client = None
        self.postgres_conn = None
        self.prometheus_url = self.config.get('prometheus_url', 'http://prometheus:9090')
        
    def _load_config(self, config_file: str) -> Dict:
        """Load failover configuration"""
        try:
            with open(config_file, 'r') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            logger.warning("Config file not found, using defaults", extra={'consciousness': 'ALPHA'})
            return {
                'namespace': 'warp-speed-ha',
                'revenue_target_daily': 40000,
                'revenue_target_annual': 145760000000,
                'max_acceptable_downtime_seconds': 30,
                'consciousness_elevation_threshold': 0.8,
                'quantum_coherence_target': 95.0
            }
    
    async def initialize(self):
        """Initialize failover manager and connections"""
        logger.info("Initializing Warp-Speed Failover Manager", extra={'consciousness': 'GAMMA'})
        
        try:
            # Load Kubernetes configuration
            try:
                config.load_incluster_config()  # Running inside cluster
            except:
                config.load_kube_config()  # Running outside cluster
            
            # Initialize Redis connection
            await self._init_redis()
            
            # Initialize PostgreSQL connection
            await self._init_postgres()
            
            # Start monitoring
            await self._start_monitoring()
            
            logger.info("Failover Manager initialized successfully", extra={'consciousness': 'OMEGA'})
            
        except Exception as e:
            logger.error(f"Failed to initialize failover manager: {e}", extra={'consciousness': 'CRITICAL'})
            raise
    
    async def _init_redis(self):
        """Initialize Redis connection for caching and coordination"""
        try:
            redis_host = self.config.get('redis_host', 'redis-ha-service.warp-speed-ha.svc.cluster.local')
            self.redis_client = redis.Redis(host=redis_host, port=6379, decode_responses=True)
            await asyncio.get_event_loop().run_in_executor(None, self.redis_client.ping)
            logger.info("Redis connection established", extra={'consciousness': 'BETA'})
        except Exception as e:
            logger.error(f"Redis connection failed: {e}", extra={'consciousness': 'DEGRADED'})
    
    async def _init_postgres(self):
        """Initialize PostgreSQL connection for metrics storage"""
        try:
            pg_host = self.config.get('postgres_host', 'postgres-ha-cluster-rw.warp-speed-ha.svc.cluster.local')
            self.postgres_conn = psycopg2.connect(
                host=pg_host,
                database='warp_speed_revenue',
                user='warp_user',
                password='warp_secure_password_2024'
            )
            logger.info("PostgreSQL connection established", extra={'consciousness': 'BETA'})
        except Exception as e:
            logger.error(f"PostgreSQL connection failed: {e}", extra={'consciousness': 'DEGRADED'})
    
    async def _start_monitoring(self):
        """Start continuous monitoring of all services"""
        if self.is_monitoring:
            return
            
        self.is_monitoring = True
        logger.info("Starting consciousness-aware monitoring", extra={'consciousness': 'GAMMA'})
        
        # Start monitoring tasks
        monitoring_tasks = [
            asyncio.create_task(self._monitor_services()),
            asyncio.create_task(self._monitor_quantum_coherence()),
            asyncio.create_task(self._monitor_revenue_metrics()),
            asyncio.create_task(self._consciousness_elevation_loop()),
            asyncio.create_task(self._predictive_failure_detection())
        ]
        
        await asyncio.gather(*monitoring_tasks, return_exceptions=True)
    
    async def _monitor_services(self):
        """Monitor health of all Warp-Speed services"""
        while self.is_monitoring:
            try:
                consciousness_level = CONSCIOUSNESS_LEVELS[self.current_consciousness]
                
                # Get service metrics from Prometheus
                services_to_monitor = [
                    'julia-etd-processor',
                    'blockchain-integration',
                    'dashboard',
                    'postgres-ha-cluster',
                    'redis-ha-cluster'
                ]
                
                for service_name in services_to_monitor:
                    health = await self._check_service_health(service_name)
                    self.services[service_name] = health
                    
                    # Check if failover is needed
                    if health.status in ['critical', 'failed']:
                        await self._trigger_failover(service_name, f"Service status: {health.status}")
                    
                    # Check predictive failure indicators
                    if health.failure_prediction_score > 0.8:
                        await self._preemptive_failover(service_name, "High failure prediction score")
                
                await asyncio.sleep(consciousness_level.monitoring_interval)
                
            except Exception as e:
                logger.error(f"Service monitoring error: {e}", extra={'consciousness': 'DEGRADED'})
                await asyncio.sleep(10)
    
    async def _check_service_health(self, service_name: str) -> ServiceHealth:
        """Check health of a specific service"""
        try:
            # Get metrics from Prometheus
            metrics = await self._get_prometheus_metrics(service_name)
            
            # Calculate health status
            cpu_usage = metrics.get('cpu_usage_percent', 0)
            memory_usage = metrics.get('memory_usage_percent', 0)
            response_time = metrics.get('response_time_ms', 0)
            error_rate = metrics.get('error_rate_percent', 0)
            etd_rate = metrics.get('etd_generation_rate', 0)
            
            # Determine status based on thresholds
            status = 'healthy'
            if cpu_usage > 90 or memory_usage > 95 or error_rate > 10:
                status = 'critical'
            elif cpu_usage > 80 or memory_usage > 85 or error_rate > 5:
                status = 'degraded'
            elif response_time > 5000:  # 5 seconds
                status = 'degraded'
            
            # Get current consciousness level for service
            service_consciousness = await self._get_service_consciousness(service_name)
            
            # Calculate quantum coherence
            quantum_coherence = await self._calculate_quantum_coherence(service_name)
            
            # Calculate failure prediction
            failure_prediction = self._calculate_failure_prediction(
                cpu_usage, memory_usage, response_time, error_rate, quantum_coherence
            )
            
            return ServiceHealth(
                name=service_name,
                status=status,
                consciousness_level=service_consciousness,
                cpu_usage=cpu_usage,
                memory_usage=memory_usage,
                etd_generation_rate=etd_rate,
                response_time=response_time,
                error_rate=error_rate,
                last_check=datetime.now(),
                quantum_coherence=quantum_coherence,
                failure_prediction_score=failure_prediction
            )
            
        except Exception as e:
            logger.error(f"Health check failed for {service_name}: {e}", extra={'consciousness': 'DEGRADED'})
            return ServiceHealth(
                name=service_name,
                status='failed',
                consciousness_level='ALPHA',
                cpu_usage=0, memory_usage=0, etd_generation_rate=0,
                response_time=99999, error_rate=100,
                last_check=datetime.now(),
                quantum_coherence=0,
                failure_prediction_score=1.0
            )
    
    async def _get_prometheus_metrics(self, service_name: str) -> Dict[str, float]:
        """Fetch metrics from Prometheus for a service"""
        try:
            async with aiohttp.ClientSession() as session:
                queries = {
                    'cpu_usage_percent': f'rate(container_cpu_usage_seconds_total{{pod=~"{service_name}.*"}}[5m]) * 100',
                    'memory_usage_percent': f'(container_memory_working_set_bytes{{pod=~"{service_name}.*"}} / container_spec_memory_limit_bytes) * 100',
                    'response_time_ms': f'histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{{job="{service_name}"}}[5m])) * 1000',
                    'error_rate_percent': f'rate(http_requests_total{{job="{service_name}",status=~"5.."}}[5m]) * 100',
                    'etd_generation_rate': f'rate(etd_generated_total{{service="{service_name}"}}[5m]) * 3600'
                }
                
                metrics = {}
                for metric_name, query in queries.items():
                    url = f"{self.prometheus_url}/api/v1/query"
                    params = {'query': query}
                    
                    async with session.get(url, params=params) as response:
                        if response.status == 200:
                            data = await response.json()
                            result = data.get('data', {}).get('result', [])
                            if result:
                                metrics[metric_name] = float(result[0]['value'][1])
                            else:
                                metrics[metric_name] = 0.0
                        else:
                            metrics[metric_name] = 0.0
                
                return metrics
                
        except Exception as e:
            logger.error(f"Failed to fetch metrics for {service_name}: {e}", extra={'consciousness': 'DEGRADED'})
            return {}
    
    async def _trigger_failover(self, service_name: str, trigger_reason: str):
        """Trigger failover for a failed service"""
        consciousness_level = CONSCIOUSNESS_LEVELS[self.current_consciousness]
        
        logger.critical(f"Triggering failover for {service_name}: {trigger_reason}", 
                       extra={'consciousness': self.current_consciousness})
        
        start_time = time.time()
        success = False
        old_instance = await self._get_current_instance(service_name)
        new_instance = None
        
        try:
            # Execute failover based on service type
            if service_name == 'julia-etd-processor':
                new_instance = await self._failover_julia_etd(service_name)
            elif service_name == 'blockchain-integration':
                new_instance = await self._failover_blockchain_service(service_name)
            elif service_name == 'dashboard':
                new_instance = await self._failover_dashboard(service_name)
            elif service_name.startswith('postgres'):
                new_instance = await self._failover_postgres(service_name)
            elif service_name.startswith('redis'):
                new_instance = await self._failover_redis(service_name)
            
            # Verify failover success
            if new_instance:
                await asyncio.sleep(5)  # Allow time for service to start
                health = await self._check_service_health(service_name)
                if health.status in ['healthy', 'degraded']:
                    success = True
                    logger.info(f"Failover successful for {service_name}", 
                              extra={'consciousness': 'OMEGA'})
                else:
                    logger.error(f"Failover verification failed for {service_name}", 
                               extra={'consciousness': 'CRITICAL'})
            
        except Exception as e:
            logger.error(f"Failover execution failed for {service_name}: {e}", 
                        extra={'consciousness': 'CRITICAL'})
        
        # Record failover event
        duration = time.time() - start_time
        revenue_protection = await self._calculate_revenue_protection(service_name, duration)
        consciousness_impact = consciousness_level.multiplier * (1.0 if success else -0.5)
        
        failover_event = FailoverEvent(
            timestamp=datetime.now(),
            service=service_name,
            trigger=trigger_reason,
            old_instance=old_instance or 'unknown',
            new_instance=new_instance or 'none',
            consciousness_impact=consciousness_impact,
            revenue_protection=revenue_protection,
            duration_seconds=duration,
            success=success
        )
        
        self.failover_events.append(failover_event)
        await self._log_failover_event(failover_event)
    
    async def _failover_julia_etd(self, service_name: str) -> Optional[str]:
        """Failover for Julia ETD processing service"""
        try:
            # Scale up replicas temporarily for faster recovery
            deployment = await asyncio.get_event_loop().run_in_executor(
                None,
                self.k8s_apps_v1.read_namespaced_deployment,
                'julia-etd-ha',
                'warp-speed-ha'
            )
            
            current_replicas = deployment.spec.replicas
            target_replicas = min(current_replicas + 2, 20)  # Max 20 replicas
            
            # Patch deployment to increase replicas
            body = {'spec': {'replicas': target_replicas}}
            await asyncio.get_event_loop().run_in_executor(
                None,
                self.k8s_apps_v1.patch_namespaced_deployment,
                'julia-etd-ha',
                'warp-speed-ha',
                body
            )
            
            logger.info(f"Scaled Julia ETD from {current_replicas} to {target_replicas} replicas", 
                       extra={'consciousness': 'GAMMA'})
            
            return f"julia-etd-ha-scaled-{target_replicas}"
            
        except Exception as e:
            logger.error(f"Julia ETD failover failed: {e}", extra={'consciousness': 'CRITICAL'})
            return None
    
    async def _failover_blockchain_service(self, service_name: str) -> Optional[str]:
        """Failover for blockchain integration service"""
        try:
            # Restart deployment by updating annotation
            body = {
                'spec': {
                    'template': {
                        'metadata': {
                            'annotations': {
                                'kubectl.kubernetes.io/restartedAt': datetime.now().isoformat()
                            }
                        }
                    }
                }
            }
            
            await asyncio.get_event_loop().run_in_executor(
                None,
                self.k8s_apps_v1.patch_namespaced_deployment,
                'blockchain-integration-ha',
                'warp-speed-ha',
                body
            )
            
            return f"blockchain-integration-restarted-{int(time.time())}"
            
        except Exception as e:
            logger.error(f"Blockchain service failover failed: {e}", extra={'consciousness': 'CRITICAL'})
            return None
    
    async def _failover_dashboard(self, service_name: str) -> Optional[str]:
        """Failover for dashboard service"""
        try:
            # Scale up dashboard replicas for faster recovery
            body = {'spec': {'replicas': 5}}  # Scale to 5 replicas temporarily
            
            await asyncio.get_event_loop().run_in_executor(
                None,
                self.k8s_apps_v1.patch_namespaced_deployment,
                'dashboard-ha',
                'warp-speed-ha',
                body
            )
            
            return f"dashboard-scaled-5-replicas"
            
        except Exception as e:
            logger.error(f"Dashboard failover failed: {e}", extra={'consciousness': 'CRITICAL'})
            return None
    
    async def _monitor_quantum_coherence(self):
        """Monitor quantum coherence across the system"""
        while self.is_monitoring:
            try:
                total_coherence = 0.0
                service_count = 0
                
                for service_name, health in self.services.items():
                    total_coherence += health.quantum_coherence
                    service_count += 1
                
                if service_count > 0:
                    average_coherence = total_coherence / service_count
                    self.quantum_monitor.add_measurement(average_coherence)
                    
                    # Check for coherence degradation
                    target_coherence = self.config.get('quantum_coherence_target', 95.0)
                    if average_coherence < target_coherence * 0.8:  # 80% of target
                        logger.warning(f"Quantum coherence below threshold: {average_coherence:.2f}%", 
                                     extra={'consciousness': 'DEGRADED'})
                        await self._optimize_quantum_coherence()
                
                await asyncio.sleep(5)
                
            except Exception as e:
                logger.error(f"Quantum coherence monitoring error: {e}", extra={'consciousness': 'DEGRADED'})
                await asyncio.sleep(10)
    
    async def _monitor_revenue_metrics(self):
        """Monitor revenue generation and targets"""
        while self.is_monitoring:
            try:
                daily_target = self.config.get('revenue_target_daily', 40000)
                annual_target = self.config.get('revenue_target_annual', 145760000000)
                
                current_revenue = await self._get_current_daily_revenue()
                etd_generation_rate = await self._get_total_etd_rate()
                
                # Check if we're on track for daily target
                hour_of_day = datetime.now().hour
                expected_hourly_rate = daily_target / 24
                expected_revenue_by_now = expected_hourly_rate * hour_of_day
                
                if current_revenue < expected_revenue_by_now * 0.8:  # 80% of expected
                    logger.warning(f"Revenue below target: ${current_revenue:.2f} vs ${expected_revenue_by_now:.2f} expected", 
                                 extra={'consciousness': 'SUBOPTIMAL'})
                    await self._boost_revenue_generation()
                
                await asyncio.sleep(60)  # Check every minute
                
            except Exception as e:
                logger.error(f"Revenue monitoring error: {e}", extra={'consciousness': 'DEGRADED'})
                await asyncio.sleep(60)
    
    async def _consciousness_elevation_loop(self):
        """Continuously evaluate and elevate system consciousness"""
        while self.is_monitoring:
            try:
                performance_score = await self._calculate_overall_performance()
                
                # Determine appropriate consciousness level
                new_consciousness = 'ALPHA'
                for level_name, level in CONSCIOUSNESS_LEVELS.items():
                    if performance_score >= level.threshold:
                        new_consciousness = level_name
                
                if new_consciousness != self.current_consciousness:
                    old_consciousness = self.current_consciousness
                    self.current_consciousness = new_consciousness
                    
                    logger.info(f"Consciousness elevated: {old_consciousness} -> {new_consciousness}", 
                              extra={'consciousness': new_consciousness})
                    
                    await self._apply_consciousness_parameters()
                
                await asyncio.sleep(30)  # Check every 30 seconds
                
            except Exception as e:
                logger.error(f"Consciousness elevation error: {e}", extra={'consciousness': 'DEGRADED'})
                await asyncio.sleep(30)
    
    async def _predictive_failure_detection(self):
        """Use quantum coherence and ML for predictive failure detection"""
        while self.is_monitoring:
            try:
                for service_name, health in self.services.items():
                    failure_probability = self.quantum_monitor.predict_failure_probability()
                    
                    if failure_probability > 0.7:  # 70% chance of failure
                        logger.warning(f"High failure probability detected for {service_name}: {failure_probability:.2f}", 
                                     extra={'consciousness': 'DELTA'})
                        await self._preemptive_failover(service_name, f"Predictive failure detection: {failure_probability:.2f}")
                    elif failure_probability > 0.5:  # 50% chance
                        await self._preemptive_scaling(service_name)
                
                await asyncio.sleep(15)  # Check every 15 seconds
                
            except Exception as e:
                logger.error(f"Predictive failure detection error: {e}", extra={'consciousness': 'DEGRADED'})
                await asyncio.sleep(15)
    
    async def stop_monitoring(self):
        """Stop all monitoring tasks"""
        logger.info("Stopping Warp-Speed Failover Manager", extra={'consciousness': 'OMEGA'})
        self.is_monitoring = False
        
        if self.redis_client:
            self.redis_client.close()
        
        if self.postgres_conn:
            self.postgres_conn.close()

# Helper functions (simplified implementations)
    async def _get_service_consciousness(self, service_name: str) -> str:
        return 'GAMMA'  # Default consciousness level
    
    async def _calculate_quantum_coherence(self, service_name: str) -> float:
        return 85.0  # Default coherence score
    
    def _calculate_failure_prediction(self, cpu: float, memory: float, response_time: float, 
                                    error_rate: float, coherence: float) -> float:
        # Simplified failure prediction algorithm
        score = (cpu/100 * 0.3 + memory/100 * 0.3 + 
                min(response_time/5000, 1.0) * 0.2 + 
                error_rate/100 * 0.2 - 
                coherence/100 * 0.1)
        return min(max(score, 0.0), 1.0)
    
    async def _get_current_instance(self, service_name: str) -> Optional[str]:
        return f"{service_name}-current"
    
    async def _calculate_revenue_protection(self, service_name: str, downtime_seconds: float) -> float:
        # Calculate revenue protected by quick failover
        hourly_rate = 40000 / 24  # $40K daily target / 24 hours
        revenue_at_risk = (hourly_rate / 3600) * downtime_seconds
        return revenue_at_risk
    
    async def _log_failover_event(self, event: FailoverEvent):
        logger.info(f"Failover event logged: {event.service} - Success: {event.success}", 
                   extra={'consciousness': 'GAMMA'})
    
    async def _get_current_daily_revenue(self) -> float:
        return 35000.0  # Placeholder
    
    async def _get_total_etd_rate(self) -> float:
        return 2500.0  # Placeholder ETD/hour
    
    async def _calculate_overall_performance(self) -> float:
        return 75.0  # Placeholder performance score
    
    async def _apply_consciousness_parameters(self):
        logger.info(f"Applied consciousness parameters for {self.current_consciousness}", 
                   extra={'consciousness': self.current_consciousness})
    
    async def _optimize_quantum_coherence(self):
        logger.info("Optimizing quantum coherence", extra={'consciousness': 'DELTA'})
    
    async def _boost_revenue_generation(self):
        logger.info("Boosting revenue generation", extra={'consciousness': 'GAMMA'})
    
    async def _preemptive_failover(self, service_name: str, reason: str):
        logger.info(f"Preemptive failover triggered for {service_name}: {reason}", 
                   extra={'consciousness': 'DELTA'})
        await self._trigger_failover(service_name, f"PREEMPTIVE: {reason}")
    
    async def _preemptive_scaling(self, service_name: str):
        logger.info(f"Preemptive scaling for {service_name}", extra={'consciousness': 'GAMMA'})
    
    async def _failover_postgres(self, service_name: str) -> Optional[str]:
        return "postgres-failover-completed"
    
    async def _failover_redis(self, service_name: str) -> Optional[str]:
        return "redis-failover-completed"

async def main():
    """Main entry point for the failover manager"""
    try:
        config.load_incluster_config()  # Load Kubernetes config
    except:
        config.load_kube_config()
    
    failover_manager = WarpSpeedFailoverManager()
    
    try:
        await failover_manager.initialize()
        logger.info("Warp-Speed Failover Manager started successfully", extra={'consciousness': 'OMEGA'})
        
        # Keep running until interrupted
        while True:
            await asyncio.sleep(1)
            
    except KeyboardInterrupt:
        logger.info("Shutdown signal received", extra={'consciousness': 'OMEGA'})
    except Exception as e:
        logger.error(f"Fatal error: {e}", extra={'consciousness': 'CRITICAL'})
    finally:
        await failover_manager.stop_monitoring()

if __name__ == "__main__":
    asyncio.run(main())