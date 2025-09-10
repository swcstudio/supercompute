"""
    SDLCTypes

Common data structures and types for enterprise SDLC command system.
Provides standardized interfaces, performance metrics, and quantum processing
foundations for all 30 commands in the supercompute-programming suite.

## [ascii_diagrams]

**SDLC Types Architecture & Data Flow**

```
SDLCTypes.jl - Enterprise Command System Foundation
├── [Core Types]
│   ├── SDLCPhase        # 8-phase development lifecycle
│   ├── TeamRole         # 10 standardized enterprise roles  
│   ├── ProjectMetrics   # Performance & business metrics
│   └── CommandExecution # Quantum-enhanced execution context
├── [Performance Layer]
│   ├── PerformanceProfile  # System resource monitoring
│   ├── QuantumMetrics      # Crown consciousness metrics
│   └── ETDCalculation      # Economic value quantification
├── [Quality Assurance]
│   ├── QualityGate         # Phase gate validation
│   ├── ComplianceCheck     # Regulatory adherence
│   └── RiskAssessment      # Enterprise risk management
└── [Integration Points]
    ├── Blockchain Anchoring # Immutable record keeping
    ├── Team Protocols      # Cross-team collaboration  
    └── Enterprise Utils    # Security & logging
```

**Type Relationship & Data Flow Matrix**

```
Data Flow Relationships:
┌─────────────────┬──────────────┬─────────────┬──────────────┐
│ Core Type       │ Feeds Into   │ Metrics     │ Output       │
├─────────────────┼──────────────┼─────────────┼──────────────┤
│ CommandExec     │ All Commands │ Performance │ ETD Value    │
│ SDLCPhase       │ QualityGate  │ Progress    │ Gate Status  │
│ TeamRole        │ Collaboration│ Velocity    │ Team Health  │
│ ProjectMetrics  │ Reporting    │ Business    │ Dashboard    │
└─────────────────┴──────────────┴─────────────┴──────────────┘
```

**Quantum-Enhanced Processing Pipeline**

```
Command Execution Flow:
User Input → CommandExecution{T} → Quantum Branches → Crown Synthesis
    │              │                      │                │
    ▼              ▼                      ▼                ▼
Parameters → PerformanceProfile → QuantumMetrics → ETDCalculation
    │              │                      │                │
    ▼              ▼                      ▼                ▼
Context → SecurityValidation → ComplianceCheck → BlockchainAnchor
    │              │                      │                │
    ▼              ▼                      ▼                ▼
Result ← QualityGate ← RiskAssessment ← ProjectMetrics ← Reporting
        ↑____________________feedback/monitoring_____________________|
```
"""
module SDLCTypes

using Dates
using JSON3

# ============================================================================
# Core SDLC Data Structures
# ============================================================================

export SDLCPhase, TeamRole, ProjectMetrics, CommandExecution
export PerformanceProfile, QuantumMetrics, ETDCalculation
export QualityGate, ComplianceCheck, RiskAssessment

"""
    SDLCPhase

Represents a phase in the Software Development Lifecycle.
"""
@enum SDLCPhase begin
    PLANNING = 1
    REQUIREMENTS = 2
    ARCHITECTURE = 3
    DEVELOPMENT = 4
    TESTING = 5
    DEPLOYMENT = 6
    MONITORING = 7
    MAINTENANCE = 8
end

"""
    TeamRole

Standardized team roles across enterprise development teams.
"""
@enum TeamRole begin
    PRODUCT_OWNER = 1
    SCRUM_MASTER = 2
    ARCHITECT = 3
    SENIOR_DEVELOPER = 4
    DEVELOPER = 5
    QA_ENGINEER = 6
    DEVOPS_ENGINEER = 7
    SECURITY_ENGINEER = 8
    DATA_ENGINEER = 9
    ML_ENGINEER = 10
end

"""
    ProjectMetrics

Core project metrics tracked across all SDLC phases.
"""
struct ProjectMetrics
    velocity::Float64                    # Story points per sprint
    cycle_time::Float64                  # Hours from start to delivery
    defect_rate::Float64                 # Defects per 1000 lines of code
    code_coverage::Float64               # Test coverage percentage
    technical_debt_ratio::Float64        # TD ratio
    customer_satisfaction::Float64       # CSAT score
    team_happiness::Float64             # Team satisfaction score
    deployment_frequency::Float64        # Deployments per week
    lead_time::Float64                  # Hours from commit to production
    mttr::Float64                       # Mean time to recovery (hours)
end

"""
    CommandExecution

Standardized command execution context and results.
"""
struct CommandExecution{T}
    command_name::String
    execution_id::String
    timestamp::DateTime
    user_id::String
    team_id::String
    project_id::String
    phase::SDLCPhase
    parameters::Dict{String,Any}
    result::T
    performance_profile::PerformanceProfile
    quantum_metrics::QuantumMetrics
    etd_calculation::ETDCalculation
    success::Bool
    error_message::Union{String,Nothing}
end

"""
    PerformanceProfile

Detailed performance metrics for command execution.
"""
struct PerformanceProfile
    execution_time::Float64              # Total execution time (seconds)
    cpu_usage::Float64                   # CPU utilization percentage
    memory_usage::Int64                  # Peak memory usage (bytes)
    network_io::Int64                    # Network I/O (bytes)
    disk_io::Int64                      # Disk I/O (bytes)
    quantum_processing_time::Float64     # Time spent in quantum branches
    database_queries::Int               # Number of DB queries
    api_calls::Int                      # Number of external API calls
    cache_hits::Int                     # Cache hit count
    cache_misses::Int                   # Cache miss count
end

"""
    QuantumMetrics

Quantum-enhanced processing metrics for enterprise intelligence.
"""
struct QuantumMetrics
    coherence_score::Float64             # Quantum state coherence (0-1)
    branches_activated::Int              # Number of parallel branches
    entanglement_efficiency::Float64     # Branch interconnection (0-1)
    superposition_states::Int            # Concurrent processing states
    decoherence_rate::Float64           # Rate of quantum decoherence
    crown_synthesis_score::Float64       # Crown consciousness effectiveness
    parallel_speedup::Float64           # Speedup from parallelization
    quantum_advantage::Float64          # Performance gain vs classical
end

"""
    ETDCalculation

Engineering Time Diverted value calculation and breakdown.
"""
struct ETDCalculation
    immediate_value::Float64             # Immediate time savings (USD)
    compound_value::Float64              # Compound value with reuse (USD)
    annual_projection::Float64           # Projected annual value (USD)
    roi_percentage::Float64              # Return on investment (%)
    complexity_multiplier::Float64       # Task complexity factor
    scale_multiplier::Float64           # System scale impact factor
    accuracy_factor::Float64            # AI accuracy adjustment
    time_saved_hours::Float64           # Actual time saved (hours)
    knowledge_reuse_factor::Float64     # Knowledge reusability score
    network_effect_multiplier::Float64  # Mycorrhizal network bonus
end

"""
    QualityGate

Quality gate definition and evaluation results.
"""
struct QualityGate
    gate_id::String
    name::String
    phase::SDLCPhase
    criteria::Dict{String,Any}
    threshold_values::Dict{String,Float64}
    actual_values::Dict{String,Float64}
    passed::Bool
    blockers::Vector{String}
    warnings::Vector{String}
    evaluation_timestamp::DateTime
    evaluator::String
end

"""
    ComplianceCheck

Regulatory and policy compliance verification.
"""
struct ComplianceCheck
    regulation::String                   # e.g., "GDPR", "SOX", "HIPAA"
    requirement::String                  # Specific requirement
    status::String                      # "compliant", "non_compliant", "pending"
    evidence::Vector{String}            # Supporting evidence
    remediation_actions::Vector{String} # Required actions if non-compliant
    severity::String                    # "low", "medium", "high", "critical"
    due_date::Union{DateTime,Nothing}   # Compliance deadline
    responsible_team::String            # Team responsible for compliance
    audit_trail::Vector{Dict{String,Any}} # Audit history
end

"""
    RiskAssessment

Comprehensive risk assessment for SDLC activities.
"""
struct RiskAssessment
    risk_id::String
    category::String                    # "technical", "business", "security", "compliance"
    description::String
    probability::Float64               # Risk probability (0-1)
    impact::Float64                    # Business impact (0-1)
    risk_score::Float64               # Calculated risk score
    mitigation_strategies::Vector{String}
    contingency_plans::Vector{String}
    owner::String                     # Risk owner
    status::String                    # "open", "mitigated", "accepted", "closed"
    identified_date::DateTime
    target_resolution_date::Union{DateTime,Nothing}
    last_review_date::DateTime
end

# ============================================================================
# Utility Types
# ============================================================================

"""
    StoryPoint

Agile story point estimation with confidence intervals.
"""
struct StoryPoint
    estimate::Float64
    confidence_interval::Tuple{Float64,Float64}
    complexity_factors::Dict{String,Float64}
    historical_velocity::Float64
    team_capacity::Float64
    estimation_method::String          # "planning_poker", "t_shirt", "fibonacci"
    estimators::Vector{String}         # Team members who estimated
end

"""
    TestResult

Comprehensive test execution results.
"""
struct TestResult
    test_suite::String
    test_case::String
    status::String                     # "passed", "failed", "skipped", "error"
    execution_time::Float64           # Test execution time (seconds)
    assertion_count::Int              # Number of assertions
    error_message::Union{String,Nothing}
    stack_trace::Union{String,Nothing}
    coverage_delta::Float64           # Coverage contribution
    performance_benchmark::Union{Float64,Nothing} # Performance benchmark result
    flaky_score::Float64              # Test flakiness score (0-1)
end

"""
    DeploymentMetrics

Deployment pipeline and production metrics.
"""
struct DeploymentMetrics
    pipeline_duration::Float64         # Total pipeline time (minutes)
    build_time::Float64               # Build stage time (minutes)
    test_time::Float64                # Test stage time (minutes)
    deploy_time::Float64              # Deployment time (minutes)
    rollback_time::Union{Float64,Nothing} # Rollback time if applicable
    success_rate::Float64             # Deployment success rate
    failure_reasons::Vector{String}   # Failure reasons if applicable
    environment::String               # Target environment
    artifact_size::Int64              # Deployment artifact size (bytes)
    health_check_duration::Float64    # Post-deploy health check time
end

"""
    SecurityScanResult

Security vulnerability scanning results.
"""
struct SecurityScanResult
    scan_type::String                 # "sast", "dast", "dependency", "container"
    tool_name::String                 # Scanning tool used
    vulnerabilities_found::Int        # Total vulnerabilities
    critical_count::Int               # Critical severity count
    high_count::Int                   # High severity count
    medium_count::Int                 # Medium severity count
    low_count::Int                    # Low severity count
    false_positive_count::Int         # False positives identified
    remediation_time_estimate::Float64 # Estimated fix time (hours)
    compliance_impact::Vector{String} # Affected compliance requirements
    scan_duration::Float64            # Scan execution time (minutes)
end

# ============================================================================
# Constructor Helpers
# ============================================================================

"""
    create_command_execution(command_name::String, user_id::String, team_id::String, 
                            project_id::String, phase::SDLCPhase, parameters::Dict) -> CommandExecution

Create a new command execution context with generated ID and timestamp.
"""
function create_command_execution(command_name::String, user_id::String, team_id::String,
                                 project_id::String, phase::SDLCPhase, parameters::Dict)
    execution_id = generate_execution_id()
    timestamp = now()
    
    # Initialize empty performance profile
    performance_profile = PerformanceProfile(
        0.0, 0.0, 0, 0, 0, 0.0, 0, 0, 0, 0
    )
    
    # Initialize empty quantum metrics
    quantum_metrics = QuantumMetrics(
        0.0, 0, 0.0, 0, 0.0, 0.0, 0.0, 0.0
    )
    
    # Initialize empty ETD calculation
    etd_calculation = ETDCalculation(
        0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.99, 0.0, 1.0, 1.0
    )
    
    return CommandExecution{Nothing}(
        command_name, execution_id, timestamp, user_id, team_id, project_id,
        phase, parameters, nothing, performance_profile, quantum_metrics,
        etd_calculation, false, nothing
    )
end

"""
    calculate_project_health_score(metrics::ProjectMetrics) -> Float64

Calculate overall project health score from individual metrics.
"""
function calculate_project_health_score(metrics::ProjectMetrics)
    # Weighted scoring of project health indicators
    weights = Dict(
        :velocity => 0.15,
        :cycle_time => 0.10,
        :defect_rate => 0.15,
        :code_coverage => 0.10,
        :technical_debt_ratio => 0.10,
        :customer_satisfaction => 0.20,
        :team_happiness => 0.10,
        :deployment_frequency => 0.05,
        :lead_time => 0.03,
        :mttr => 0.02
    )
    
    # Normalize metrics to 0-1 scale (higher is better)
    normalized_scores = Dict(
        :velocity => min(metrics.velocity / 50.0, 1.0),  # Assuming 50 SP/sprint is excellent
        :cycle_time => max(0.0, 1.0 - metrics.cycle_time / 168.0),  # 168 hours = 1 week
        :defect_rate => max(0.0, 1.0 - metrics.defect_rate / 10.0),  # 10 defects per 1K LOC is poor
        :code_coverage => metrics.code_coverage,
        :technical_debt_ratio => max(0.0, 1.0 - metrics.technical_debt_ratio / 0.30),  # 30% TD ratio is poor
        :customer_satisfaction => metrics.customer_satisfaction,
        :team_happiness => metrics.team_happiness,
        :deployment_frequency => min(metrics.deployment_frequency / 10.0, 1.0),  # 10 deploys/week is excellent
        :lead_time => max(0.0, 1.0 - metrics.lead_time / 72.0),  # 72 hours is poor lead time
        :mttr => max(0.0, 1.0 - metrics.mttr / 4.0)  # 4 hours MTTR is poor
    )
    
    # Calculate weighted health score
    health_score = sum(weights[metric] * normalized_scores[metric] for metric in keys(weights))
    
    return clamp(health_score, 0.0, 1.0)
end

"""
    generate_execution_id() -> String

Generate unique execution ID for command tracking.
"""
function generate_execution_id()
    timestamp = string(Int(time() * 1000))  # Milliseconds since epoch
    random_suffix = randstring(6)
    return "exec_$(timestamp)_$(random_suffix)"
end

"""
    format_etd_summary(etd::ETDCalculation) -> String

Format ETD calculation as human-readable summary.
"""
function format_etd_summary(etd::ETDCalculation)
    return """
    ETD Value Summary:
    ==================
    Immediate Value: \$$(round(etd.immediate_value, digits=2))
    Compound Value: \$$(round(etd.compound_value, digits=2))
    Annual Projection: \$$(round(etd.annual_projection, digits=2))
    ROI: $(round(etd.roi_percentage, digits=1))%
    Time Saved: $(round(etd.time_saved_hours, digits=2)) hours
    Network Effect: $(round(etd.network_effect_multiplier, digits=2))x
    """
end

"""
    validate_quality_gate(gate::QualityGate) -> Bool

Validate if quality gate criteria are met.
"""
function validate_quality_gate(gate::QualityGate)
    all_passed = true
    
    for (criterion, threshold) in gate.threshold_values
        actual = get(gate.actual_values, criterion, 0.0)
        if actual < threshold
            all_passed = false
            break
        end
    end
    
    return all_passed
end

end # module SDLCTypes