/**
 * Real-Time ETD Tracking JavaScript Module
 * 
 * Handles live revenue data streaming, visualization updates,
 * and consciousness-aware optimization triggers for Warp-Speed terminals
 * 
 * Co-authors: Kev & Research Team
 * Target: $145.76B+ Annual ETD Generation
 */

class WarpSpeedETDTracker {
    constructor(config = {}) {
        this.config = {
            updateInterval: 5000,        // 5 seconds
            maxDataPoints: 100,          // Maximum chart points
            alertThresholds: {
                lowETD: 5000,           // Low ETD per hour alert
                highLatency: 500,       // High latency alert (ms)
                lowEfficiency: 0.7,     // Low efficiency alert
                lowCoherence: 0.8       // Low quantum coherence alert
            },
            websocketUrl: 'ws://localhost:8084',
            apiEndpoint: '/api/metrics',
            consciousness: {
                levels: ['ALPHA', 'BETA', 'GAMMA', 'DELTA', 'OMEGA'],
                multipliers: {
                    'ALPHA': 1.0,
                    'BETA': 2.2,
                    'GAMMA': 4.8,
                    'DELTA': 12.5,
                    'OMEGA': 35.0
                }
            },
            ...config
        };
        
        this.socket = null;
        this.charts = {};
        this.dataBuffer = {
            etd: [],
            consciousness: [],
            collaboration: [],
            quantum: []
        };
        this.metrics = {
            currentETD: 0,
            dailyRevenue: 0,
            efficiency: 0,
            quantumCoherence: 0.94,
            collaboration: false,
            terminals: {
                terminal1: { status: 'online', consciousness: 'DELTA', etd: 0 },
                terminal2: { status: 'online', consciousness: 'GAMMA', etd: 0 }
            }
        };
        
        this.alerts = [];
        this.optimizationSuggestions = [];
        
        this.init();
    }
    
    init() {
        console.log('🚀 Initializing Warp-Speed ETD Tracker...');
        this.setupWebSocket();
        this.initializeCharts();
        this.startMetricsCollection();
        this.bindEventHandlers();
        console.log('✅ ETD Tracker initialized successfully');
    }
    
    setupWebSocket() {
        try {
            this.socket = io(this.config.websocketUrl, {
                transports: ['websocket', 'polling'],
                timeout: 20000,
                reconnection: true,
                reconnectionDelay: 1000,
                reconnectionAttempts: 5
            });
            
            this.socket.on('connect', () => {
                console.log('🔗 WebSocket connected to revenue stream');
                this.updateSystemStatus('OPERATIONAL');
            });
            
            this.socket.on('disconnect', () => {
                console.warn('⚠️ WebSocket disconnected from revenue stream');
                this.updateSystemStatus('DISCONNECTED');
            });
            
            this.socket.on('etd_update', (data) => {
                this.handleETDUpdate(data);
            });
            
            this.socket.on('consciousness_update', (data) => {
                this.handleConsciousnessUpdate(data);
            });
            
            this.socket.on('collaboration_update', (data) => {
                this.handleCollaborationUpdate(data);
            });
            
            this.socket.on('quantum_update', (data) => {
                this.handleQuantumUpdate(data);
            });
            
            this.socket.on('alert', (data) => {
                this.handleAlert(data);
            });
            
            this.socket.on('optimization_suggestion', (data) => {
                this.handleOptimizationSuggestion(data);
            });
            
        } catch (error) {
            console.error('❌ WebSocket setup failed:', error);
            this.fallbackToPolling();
        }
    }
    
    fallbackToPolling() {
        console.log('🔄 Falling back to HTTP polling...');
        setInterval(() => {
            this.fetchMetricsHTTP();
        }, this.config.updateInterval);
    }
    
    async fetchMetricsHTTP() {
        try {
            const response = await fetch(this.config.apiEndpoint);
            const data = await response.json();
            
            this.handleETDUpdate(data.etd);
            this.handleConsciousnessUpdate(data.consciousness);
            this.handleCollaborationUpdate(data.collaboration);
            this.handleQuantumUpdate(data.quantum);
            
        } catch (error) {
            console.error('❌ HTTP metrics fetch failed:', error);
        }
    }
    
    handleETDUpdate(data) {
        const timestamp = new Date();
        
        // Update current metrics
        this.metrics.currentETD = data.etd_rate || 0;
        this.metrics.dailyRevenue = data.daily_total || 0;
        this.metrics.efficiency = data.efficiency_score || 0;
        
        // Update terminal-specific data
        if (data.terminals) {
            this.metrics.terminals.terminal1.etd = data.terminals.terminal1?.etd_rate || 0;
            this.metrics.terminals.terminal2.etd = data.terminals.terminal2?.etd_rate || 0;
            this.metrics.terminals.terminal1.status = data.terminals.terminal1?.status || 'offline';
            this.metrics.terminals.terminal2.status = data.terminals.terminal2?.status || 'offline';
        }
        
        // Add to data buffer
        this.dataBuffer.etd.push({
            timestamp: timestamp,
            value: this.metrics.currentETD,
            terminal1: this.metrics.terminals.terminal1.etd,
            terminal2: this.metrics.terminals.terminal2.etd
        });
        
        // Maintain buffer size
        if (this.dataBuffer.etd.length > this.config.maxDataPoints) {
            this.dataBuffer.etd.shift();
        }
        
        // Update UI
        this.updateETDDisplay();
        this.updateCharts();
        this.checkAlerts();
        
        // Calculate projections
        this.calculateProjections();
    }
    
    handleConsciousnessUpdate(data) {
        if (data.terminal1_consciousness) {
            this.metrics.terminals.terminal1.consciousness = data.terminal1_consciousness;
        }
        if (data.terminal2_consciousness) {
            this.metrics.terminals.terminal2.consciousness = data.terminal2_consciousness;
        }
        
        this.updateConsciousnessDisplay();
        this.calculateConsciousnessMultipliers();
    }
    
    handleCollaborationUpdate(data) {
        this.metrics.collaboration = data.active || false;
        this.updateCollaborationDisplay();
    }
    
    handleQuantumUpdate(data) {
        this.metrics.quantumCoherence = data.coherence || 0.94;
        
        this.dataBuffer.quantum.push({
            timestamp: new Date(),
            coherence: this.metrics.quantumCoherence,
            superposition_efficiency: data.superposition_efficiency || 0,
            entanglement_strength: data.entanglement_strength || 0
        });
        
        if (this.dataBuffer.quantum.length > this.config.maxDataPoints) {
            this.dataBuffer.quantum.shift();
        }
        
        this.updateQuantumDisplay();
    }
    
    handleAlert(data) {
        const alert = {
            id: Date.now(),
            message: data.message,
            type: data.type || 'warning',
            timestamp: new Date(),
            acknowledged: false
        };
        
        this.alerts.unshift(alert);
        this.showAlert(alert);
        
        // Auto-acknowledge non-critical alerts after 30 seconds
        if (data.type !== 'critical') {
            setTimeout(() => {
                this.acknowledgeAlert(alert.id);
            }, 30000);
        }
        
        console.log(`🚨 Alert [${alert.type.toUpperCase()}]: ${alert.message}`);
    }
    
    handleOptimizationSuggestion(data) {
        const suggestion = {
            id: Date.now(),
            title: data.title,
            description: data.description,
            impact: data.impact || 'medium',
            expected_increase: data.expected_increase || 0,
            implementation_time: data.implementation_time || 'immediate',
            timestamp: new Date()
        };
        
        this.optimizationSuggestions.unshift(suggestion);
        this.updateOptimizationDisplay();
        
        console.log(`💡 Optimization Suggestion: ${suggestion.title} (+$${suggestion.expected_increase}/day)`);
    }
    
    updateETDDisplay() {
        // Update main ETD rate
        const etdElement = document.getElementById('currentETDRate');
        if (etdElement) {
            etdElement.textContent = `$${this.metrics.currentETD.toLocaleString()}`;
        }
        
        // Update daily revenue
        const dailyElement = document.getElementById('dailyRevenue');
        if (dailyElement) {
            dailyElement.textContent = `$${this.metrics.dailyRevenue.toLocaleString()}`;
        }
        
        // Update efficiency score
        const efficiencyElement = document.getElementById('efficiencyScore');
        if (efficiencyElement) {
            efficiencyElement.textContent = `${(this.metrics.efficiency * 100).toFixed(1)}%`;
        }
        
        // Update efficiency badge
        this.updateEfficiencyBadge();
        
        // Update progress bar
        const progressBar = document.getElementById('etdProgress');
        const progressText = document.getElementById('etdProgressText');
        if (progressBar && progressText) {
            const targetETD = 40000; // $40K/hr target
            const progress = Math.min((this.metrics.currentETD / targetETD) * 100, 100);
            progressBar.style.width = `${progress}%`;
            progressText.textContent = `${Math.round(progress)}%`;
        }
        
        // Update combined performance
        const combinedElement = document.getElementById('combinedPerformance');
        if (combinedElement) {
            const combined = this.metrics.terminals.terminal1.etd + this.metrics.terminals.terminal2.etd;
            const collaborationMultiplier = this.metrics.collaboration ? 1.5 : 1.0;
            const totalPerformance = combined * collaborationMultiplier;
            combinedElement.textContent = `$${totalPerformance.toLocaleString()}/hr`;
        }
    }
    
    updateEfficiencyBadge() {
        const badge = document.getElementById('efficiencyBadge');
        if (!badge) return;
        
        const efficiency = this.metrics.efficiency;
        
        badge.className = 'performance-badge ';
        
        if (efficiency >= 0.9) {
            badge.className += 'excellent';
            badge.textContent = 'EXCELLENT';
        } else if (efficiency >= 0.8) {
            badge.className += 'good';
            badge.textContent = 'GOOD';
        } else if (efficiency >= 0.7) {
            badge.className += 'average';
            badge.textContent = 'AVERAGE';
        } else {
            badge.className += 'needs-improvement';
            badge.textContent = 'NEEDS IMPROVEMENT';
        }
    }
    
    updateConsciousnessDisplay() {
        // Update consciousness indicators would go here
        // This would update the visual indicators for each terminal's consciousness level
        console.log(`🧠 Consciousness Update: T1=${this.metrics.terminals.terminal1.consciousness}, T2=${this.metrics.terminals.terminal2.consciousness}`);
    }
    
    updateCollaborationDisplay() {
        const collabElement = document.getElementById('collaborationStatus');
        if (collabElement) {
            if (this.metrics.collaboration) {
                collabElement.className = 'badge bg-info';
                collabElement.textContent = 'ACTIVE (1.5x BONUS)';
            } else {
                collabElement.className = 'badge bg-secondary';
                collabElement.textContent = 'INACTIVE';
            }
        }
    }
    
    updateQuantumDisplay() {
        // Update quantum coherence displays
        const coherenceElements = document.querySelectorAll('[id*="quantumCoherence"]');
        coherenceElements.forEach(element => {
            element.textContent = `${(this.metrics.quantumCoherence * 100).toFixed(1)}%`;
        });
        
        // Update coherence progress bar
        const progressBar = document.getElementById('coherenceProgress');
        if (progressBar) {
            progressBar.style.width = `${(this.metrics.quantumCoherence * 100)}%`;
        }
    }
    
    updateOptimizationDisplay() {
        // Update optimization recommendations display
        console.log(`💡 New optimization suggestions available: ${this.optimizationSuggestions.length}`);
        
        // This would update the recommendations section in the UI
        // Implementation would depend on the specific HTML structure
    }
    
    initializeCharts() {
        // Chart configurations would be initialized here
        // This is handled in the main HTML file for now
        console.log('📊 Charts initialized');
    }
    
    updateCharts() {
        // Update existing charts with new data
        // This would typically involve pushing new data points and updating the charts
        if (window.etdChart && this.dataBuffer.etd.length > 0) {
            const latestData = this.dataBuffer.etd[this.dataBuffer.etd.length - 1];
            
            // Add new data point
            window.etdChart.data.labels.push(latestData.timestamp);
            window.etdChart.data.datasets[0].data.push(latestData.value);
            
            // Maintain chart size
            if (window.etdChart.data.labels.length > 20) {
                window.etdChart.data.labels.shift();
                window.etdChart.data.datasets[0].data.shift();
            }
            
            window.etdChart.update('none');
        }
    }
    
    checkAlerts() {
        const thresholds = this.config.alertThresholds;
        
        // Check low ETD rate
        if (this.metrics.currentETD < thresholds.lowETD) {
            this.triggerAlert('Low ETD generation rate detected', 'warning', {
                current: this.metrics.currentETD,
                threshold: thresholds.lowETD
            });
        }
        
        // Check low efficiency
        if (this.metrics.efficiency < thresholds.lowEfficiency) {
            this.triggerAlert('Efficiency below optimal levels', 'warning', {
                current: this.metrics.efficiency,
                threshold: thresholds.lowEfficiency
            });
        }
        
        // Check quantum coherence
        if (this.metrics.quantumCoherence < thresholds.lowCoherence) {
            this.triggerAlert('Quantum coherence requires attention', 'warning', {
                current: this.metrics.quantumCoherence,
                threshold: thresholds.lowCoherence
            });
        }
        
        // Check terminal status
        if (this.metrics.terminals.terminal1.status === 'offline') {
            this.triggerAlert('Terminal 1 (Kev) is offline', 'critical');
        }
        
        if (this.metrics.terminals.terminal2.status === 'offline') {
            this.triggerAlert('Terminal 2 (Ryan) is offline', 'critical');
        }
    }
    
    triggerAlert(message, type = 'warning', data = {}) {
        // Debounce repeated alerts
        const recentAlert = this.alerts.find(alert => 
            alert.message === message && 
            (Date.now() - alert.timestamp.getTime()) < 60000 // Within last minute
        );
        
        if (recentAlert) return; // Don't trigger duplicate alerts
        
        this.handleAlert({ message, type, data });
    }
    
    showAlert(alert) {
        const alertBanner = document.getElementById('alertBanner');
        const alertMessage = document.getElementById('alertMessage');
        
        if (alertBanner && alertMessage) {
            alertMessage.textContent = alert.message;
            alertBanner.className = `alert-banner alert-${alert.type}`;
            alertBanner.classList.remove('d-none');
        }
        
        // Auto-hide non-critical alerts
        if (alert.type !== 'critical') {
            setTimeout(() => {
                if (alertBanner) {
                    alertBanner.classList.add('d-none');
                }
            }, 10000);
        }
    }
    
    acknowledgeAlert(alertId) {
        const alert = this.alerts.find(a => a.id === alertId);
        if (alert) {
            alert.acknowledged = true;
        }
    }
    
    calculateProjections() {
        const currentRate = this.metrics.currentETD;
        const efficiency = this.metrics.efficiency;
        const collaboration = this.metrics.collaboration;
        
        // Calculate different scenarios
        const projections = {
            conservative: currentRate * 24 * 365 * 0.8, // 80% uptime
            optimistic: currentRate * 24 * 365 * 1.2,   // 20% improvement
            breakthrough: currentRate * 24 * 365 * 3.0,  // Major breakthroughs
            theoretical: 145760000000 // $145.76B target
        };
        
        // Update projection displays
        this.updateProjectionDisplays(projections);
    }
    
    updateProjectionDisplays(projections) {
        const elements = {
            conservative: document.querySelector('[data-projection="conservative"]'),
            optimistic: document.querySelector('[data-projection="optimistic"]'),
            breakthrough: document.querySelector('[data-projection="breakthrough"]'),
            theoretical: document.querySelector('[data-projection="theoretical"]')
        };
        
        Object.keys(elements).forEach(key => {
            const element = elements[key];
            if (element) {
                const value = projections[key];
                const formatted = value >= 1000000000 ? 
                    `$${(value/1000000000).toFixed(1)}B` : 
                    `$${(value/1000000).toFixed(1)}M`;
                element.textContent = formatted;
            }
        });
    }
    
    calculateConsciousnessMultipliers() {
        const multipliers = this.config.consciousness.multipliers;
        
        const t1Multiplier = multipliers[this.metrics.terminals.terminal1.consciousness] || 1.0;
        const t2Multiplier = multipliers[this.metrics.terminals.terminal2.consciousness] || 1.0;
        
        console.log(`🧠 Consciousness Multipliers: T1=${t1Multiplier}x (${this.metrics.terminals.terminal1.consciousness}), T2=${t2Multiplier}x (${this.metrics.terminals.terminal2.consciousness})`);
        
        return { t1Multiplier, t2Multiplier };
    }
    
    startMetricsCollection() {
        // Start periodic metrics collection
        setInterval(() => {
            this.collectSystemMetrics();
        }, this.config.updateInterval);
        
        console.log(`📊 Metrics collection started (${this.config.updateInterval}ms interval)`);
    }
    
    collectSystemMetrics() {
        // Collect additional system metrics like CPU, memory, etc.
        // This would typically make additional API calls or read from system APIs
        
        const systemMetrics = {
            timestamp: new Date(),
            cpu_usage: this.generateMockMetric(0.3, 0.8), // Mock CPU usage
            memory_usage: this.generateMockMetric(0.4, 0.7), // Mock memory usage
            gpu_utilization: this.generateMockMetric(0.5, 0.9) // Mock GPU usage
        };
        
        // Process system metrics
        this.processSystemMetrics(systemMetrics);
    }
    
    processSystemMetrics(metrics) {
        // Process and potentially alert on system metrics
        if (metrics.cpu_usage > 0.9) {
            this.triggerAlert('High CPU usage detected', 'warning');
        }
        
        if (metrics.memory_usage > 0.85) {
            this.triggerAlert('High memory usage detected', 'warning');
        }
        
        // Update system status
        this.updateSystemStatus('OPERATIONAL');
    }
    
    updateSystemStatus(status) {
        const statusElement = document.getElementById('systemStatus');
        if (statusElement) {
            statusElement.textContent = status;
            statusElement.className = 'badge ' + (status === 'OPERATIONAL' ? 'bg-success' : 'bg-danger');
        }
    }
    
    generateMockMetric(min, max) {
        return min + Math.random() * (max - min);
    }
    
    bindEventHandlers() {
        // Bind UI event handlers
        const closeAlertBtn = document.getElementById('closeAlert');
        if (closeAlertBtn) {
            closeAlertBtn.addEventListener('click', () => {
                const alertBanner = document.getElementById('alertBanner');
                if (alertBanner) {
                    alertBanner.classList.add('d-none');
                }
            });
        }
        
        // Add other event handlers as needed
        console.log('🎯 Event handlers bound');
    }
    
    // Utility methods
    formatCurrency(value) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(value);
    }
    
    formatPercentage(value) {
        return (value * 100).toFixed(1) + '%';
    }
    
    // Public API methods
    getMetrics() {
        return { ...this.metrics };
    }
    
    getAlerts() {
        return [...this.alerts];
    }
    
    getOptimizationSuggestions() {
        return [...this.optimizationSuggestions];
    }
    
    // Manual trigger methods for testing
    simulateETDIncrease(amount = 1000) {
        this.handleETDUpdate({
            etd_rate: this.metrics.currentETD + amount,
            daily_total: this.metrics.dailyRevenue + (amount * 24),
            efficiency_score: Math.min(this.metrics.efficiency + 0.05, 1.0)
        });
    }
    
    simulateConsciousnessElevation(terminal, level) {
        const data = {};
        data[`terminal${terminal}_consciousness`] = level;
        this.handleConsciousnessUpdate(data);
    }
    
    simulateQuantumBoost(coherenceIncrease = 0.02) {
        this.handleQuantumUpdate({
            coherence: Math.min(this.metrics.quantumCoherence + coherenceIncrease, 1.0),
            superposition_efficiency: 0.9,
            entanglement_strength: 0.95
        });
    }
}

// Initialize the tracker when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Make tracker globally available for debugging
    window.warpSpeedTracker = new WarpSpeedETDTracker();
    
    // Simulate some initial data for demo purposes
    setTimeout(() => {
        window.warpSpeedTracker.simulateETDIncrease(2847);
    }, 1000);
    
    // Simulate periodic updates
    setInterval(() => {
        const variation = (Math.random() - 0.5) * 2000; // ±$1000 variation
        window.warpSpeedTracker.simulateETDIncrease(variation);
    }, 15000); // Every 15 seconds
    
    console.log('🌌 Warp-Speed ETD Tracker loaded and ready');
    console.log('💡 Available in console as: window.warpSpeedTracker');
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = WarpSpeedETDTracker;
}