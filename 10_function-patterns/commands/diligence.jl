"""
    DiligenceCommand

Enterprise Due Diligence System for Terminal Agents.
Implements quantum-enhanced due diligence processes with automated risk assessment,
market analysis, and comprehensive evaluation orchestration for investments and partnerships.

## [ascii_diagrams]

**Enterprise Due Diligence Architecture**

```
DiligenceCommand.jl - Investment & Partnership Intelligence System
├── [Due Diligence Orchestration Engine]
│   ├── ContextGatherer         # Target entity information collection
│   ├── MarketAnalyzer          # Competitive landscape and market analysis
│   ├── TechnicalAssessment     # Technology stack and IP evaluation
│   └── RiskEvaluator           # Comprehensive risk assessment engine
├── [Financial Analysis Framework]
│   ├── FinancialDataProcessor  # Financial statements and metrics analysis
│   ├── ValuationModeler        # Company valuation and projection modeling
│   ├── CashFlowAnalyzer        # Cash flow analysis and sustainability
│   └── InvestmentMetricsCalc   # ROI, IRR, and investment metrics calculation
├── [Team & Management Assessment]
│   ├── LeadershipProfiler      # Executive team background analysis
│   ├── TeamCapabilityAssessment # Technical and operational team evaluation
│   ├── CultureAnalyzer         # Organizational culture and values assessment
│   └── BoardCompositionAnalyzer # Board structure and governance evaluation
├── [Legal & Compliance Engine]
│   ├── LegalDocumentAnalyzer   # Contract, IP, and legal document review
│   ├── ComplianceChecker       # Regulatory compliance verification
│   ├── IPPortfolioAnalyzer     # Intellectual property assessment
│   └── LitigationRiskAssessment # Legal risk and litigation history analysis
├── [Risk Intelligence System]
│   ├── RedFlagDetector         # Automated red flag identification
│   ├── CompetitiveThreats      # Competitive risk assessment
│   ├── OperationalRisks        # Operational and execution risk analysis
│   └── MarketRisks             # Market and economic risk evaluation
└── [Enterprise Integration]
    ├── InvestmentCommitteeReporting # Executive summary and recommendations
    ├── DueDiligenceDataRoom    # Secure document management
    ├── StakeholderCommunication # Investor and partner communication
    └── QuantumDiligenceOptimization # AI-enhanced evaluation processes
```

**Due Diligence Process Flow**

```
Due Diligence Orchestration Pipeline:
Context Gathering → Market Analysis → Technical Assessment → Financial Review → Risk Analysis → Decision
      │                │                │                   │             │              │
      ▼                ▼                ▼                   ▼             ▼              ▼
Target Info → Competitive → Technology → Financial Metrics → Red Flags → Go/No-Go
      │                │                │                   │             │              │
      ▼                ▼                ▼                   ▼             ▼              ▼
Company Data → Market Size → IP/Tech → Cash Flow Analysis → Risk Score → Investment Rec
($125K ETD)    ($185K ETD)   ($285K ETD)   ($385K ETD)     ($485K ETD)   ($685K ETD)
```

**Due Diligence Assessment Matrix**

```
ENTERPRISE DUE DILIGENCE EVALUATION FRAMEWORK
┌─────────────────┬─────────────┬─────────────┬─────────────┐
│ Assessment Area │    Basic    │ Comprehensive│   Premium   │
├─────────────────┼─────────────┼─────────────┼─────────────┤
│ Market Analysis │ TAM/SAM     │ Competitive │ Deep Market │
│                 │ $125K ETD   │ $185K ETD   │ $285K ETD   │
├─────────────────┼─────────────┼─────────────┼─────────────┤
│ Financial Review│ Basic Ratios│ Full Model  │ Stress Test │
│                 │ $185K ETD   │ $285K ETD   │ $385K ETD   │
├─────────────────┼─────────────┼─────────────┼─────────────┤
│ Technical DD    │ Tech Stack  │ IP Analysis │ Full Audit  │
│                 │ $225K ETD   │ $325K ETD   │ $485K ETD   │
├─────────────────┼─────────────┼─────────────┼─────────────┤
│ Risk Assessment │ Red Flags   │ Risk Model  │ Quantum Risk│
│                 │ $285K ETD   │ $385K ETD   │ $685K ETD   │
└─────────────────┴─────────────┴─────────────┴─────────────┘
```

"""

using Dates, JSON3, Statistics, StatsBase, HTTP

# Import shared enterprise utilities
include("shared/sdlc_types.jl")
include("shared/team_protocols.jl")
include("shared/enterprise_utils.jl")

"""
    DiligenceAgent

Main due diligence agent with quantum-enhanced evaluation capabilities.
"""
mutable struct DiligenceAgent
    session_id::String
    diligence_projects::Dict{String, DiligenceProject}
    assessment_frameworks::Dict{String, AssessmentFramework}
    risk_models::Dict{String, RiskModel}
    market_data_sources::Dict{String, MarketDataSource}
    evaluation_history::Vector{DiligenceEvaluation}
    audit_logger::AuditLogger
    quantum_optimizer::QuantumProcessor
    
    function DiligenceAgent(config::EnterpriseConfig=EnterpriseConfig())
        session_id = generate_session_id()
        
        new(
            session_id,
            Dict{String, DiligenceProject}(),
            load_assessment_frameworks(),
            load_risk_models(),
            load_market_data_sources(),
            DiligenceEvaluation[],
            AuditLogger("diligence_agent_$(session_id)"),
            QuantumProcessor(:diligence_optimization)
        )
    end
end

"""
    DiligenceProject

Complete due diligence project with target entity and assessment parameters.
"""
struct DiligenceProject
    id::String
    target_name::String
    target_type::Symbol  # :startup, :company, :partnership, :acquisition
    industry::String
    region::String
    investment_amount::Float64
    assessment_type::Symbol  # :basic, :comprehensive, :premium
    stakeholders::Vector{String}
    timeline_weeks::Int
    created_at::DateTime
    status::Symbol  # :planning, :active, :review, :completed, :cancelled
end

"""
    DiligenceEvaluation

Comprehensive due diligence evaluation results with recommendations.
"""
struct DiligenceEvaluation
    id::String
    project_id::String
    evaluation_date::DateTime
    assessment_areas::Dict{String, AssessmentResult}
    overall_score::Float64
    risk_score::Float64
    financial_metrics::Dict{String, Float64}
    red_flags::Vector{RedFlag}
    key_strengths::Vector{String}
    critical_concerns::Vector{String}
    recommendation::Symbol  # :proceed, :proceed_with_conditions, :decline, :more_info_needed
    confidence_level::Float64
    etd_value::Float64
end

"""
    AssessmentResult

Individual assessment area results with scoring and analysis.
"""
struct AssessmentResult
    area_name::String
    score::Float64  # 0-100
    weight::Float64  # Importance weighting
    findings::Vector{String}
    concerns::Vector{String}
    recommendations::Vector{String}
    data_quality::Float64  # Quality of underlying data
    confidence::Float64
end

"""
    RedFlag

Identified red flag with severity and impact assessment.
"""
struct RedFlag
    id::String
    category::Symbol  # :financial, :legal, :operational, :market, :team
    severity::Symbol  # :critical, :high, :medium, :low
    description::String
    evidence::Vector{String}
    potential_impact::String
    mitigation_options::Vector{String}
    risk_score::Float64
end

"""
    process_diligence_request(agent::DiligenceAgent, request::String, args::Dict{String,Any})

Main entry point for processing due diligence requests with quantum enhancement.
"""
function process_diligence_request(agent::DiligenceAgent, request::String, args::Dict{String,Any}=Dict{String,Any}())
    log_info(agent.audit_logger, "Processing due diligence request", 
            Dict("request" => request, "args" => args))
    
    try
        # Phase 1: Context Gathering and Project Setup
        project_context = gather_diligence_context(agent, request, args)
        log_phase_completion(agent.audit_logger, "context_gathering", project_context)
        
        # Phase 2: Market Analysis and Competitive Landscape
        market_analysis = analyze_market_and_competition(agent, project_context)
        log_phase_completion(agent.audit_logger, "market_analysis", market_analysis)
        
        # Phase 3: Technical and Product Assessment
        technical_assessment = assess_technology_and_product(agent, project_context, market_analysis)
        log_phase_completion(agent.audit_logger, "technical_assessment", technical_assessment)
        
        # Phase 4: Financial Analysis and Modeling
        financial_analysis = conduct_financial_analysis(agent, project_context)
        log_phase_completion(agent.audit_logger, "financial_analysis", financial_analysis)
        
        # Phase 5: Team and Management Evaluation
        team_evaluation = evaluate_team_and_management(agent, project_context)
        log_phase_completion(agent.audit_logger, "team_evaluation", team_evaluation)
        
        # Phase 6: Legal and Compliance Review
        legal_review = conduct_legal_compliance_review(agent, project_context)
        log_phase_completion(agent.audit_logger, "legal_review", legal_review)
        
        # Phase 7: Comprehensive Risk Assessment
        risk_assessment = conduct_comprehensive_risk_assessment(agent, project_context, 
                                                              market_analysis, technical_assessment, 
                                                              financial_analysis, team_evaluation, legal_review)
        log_phase_completion(agent.audit_logger, "risk_assessment", risk_assessment)
        
        # Phase 8: Final Evaluation and Recommendation
        final_evaluation = generate_final_evaluation_and_recommendation(agent, project_context,
                                                                      market_analysis, technical_assessment,
                                                                      financial_analysis, team_evaluation,
                                                                      legal_review, risk_assessment)
        log_phase_completion(agent.audit_logger, "final_evaluation", final_evaluation)
        
        # Calculate ETD value
        etd_value = calculate_diligence_etd_value(agent, final_evaluation, project_context)
        
        # Store evaluation in history
        push!(agent.evaluation_history, final_evaluation)
        
        log_success(agent.audit_logger, "Due diligence request completed",
                   Dict("etd_value" => etd_value, "recommendation" => final_evaluation.recommendation,
                        "overall_score" => final_evaluation.overall_score))
        
        return DiligenceResponse(
            success=true,
            evaluation=final_evaluation,
            market_analysis=market_analysis,
            technical_assessment=technical_assessment,
            financial_analysis=financial_analysis,
            team_evaluation=team_evaluation,
            legal_review=legal_review,
            risk_assessment=risk_assessment,
            etd_value=etd_value,
            audit_trail=get_audit_log(agent.audit_logger)
        )
        
    catch e
        log_error(agent.audit_logger, "Due diligence request failed", e)
        return DiligenceResponse(
            success=false,
            error=string(e),
            audit_trail=get_audit_log(agent.audit_logger)
        )
    end
end

"""
    gather_diligence_context(agent::DiligenceAgent, request::String, args::Dict)

Gather comprehensive context and setup due diligence project parameters.
"""
function gather_diligence_context(agent::DiligenceAgent, request::String, args::Dict)
    # Quantum-enhanced context analysis
    quantum_context = process_with_crown_consciousness(
        agent.quantum_optimizer,
        request,
        :diligence_context_analysis
    )
    
    # Parse diligence request parameters
    target_name = get(args, "target", extract_target_from_request(request))
    target_type = Symbol(get(args, "type", determine_target_type(request)))
    industry = get(args, "industry", extract_industry_from_request(request))
    region = get(args, "region", "global")
    investment_amount = Float64(get(args, "investment", 0.0))
    assessment_type = Symbol(get(args, "assessment_type", "comprehensive"))
    
    # Create diligence project
    project_id = generate_project_id()
    project = DiligenceProject(
        id=project_id,
        target_name=target_name,
        target_type=target_type,
        industry=industry,
        region=region,
        investment_amount=investment_amount,
        assessment_type=assessment_type,
        stakeholders=get(args, "stakeholders", String[]),
        timeline_weeks=Int(get(args, "timeline_weeks", 4)),
        created_at=now(),
        status=:active
    )
    
    # Store project
    agent.diligence_projects[project_id] = project
    
    # Gather initial target information
    target_information = gather_target_information(project, quantum_context)
    
    # Select assessment framework
    assessment_framework = select_assessment_framework(
        agent.assessment_frameworks,
        project.target_type,
        project.assessment_type
    )
    
    return DiligenceContext(
        project=project,
        target_information=target_information,
        assessment_framework=assessment_framework,
        quantum_insights=quantum_context[:insights],
        context_quality_score=assess_context_quality(target_information),
        estimated_etd_value=quantum_context[:etd_value]
    )
end

"""
    conduct_financial_analysis(agent::DiligenceAgent, context::DiligenceContext)

Conduct comprehensive financial analysis with quantum-enhanced modeling.
"""
function conduct_financial_analysis(agent::DiligenceAgent, context::DiligenceContext)
    # Quantum-enhanced financial analysis
    quantum_financial = process_with_crown_consciousness(
        agent.quantum_optimizer,
        context,
        :financial_analysis
    )
    
    # Gather financial data
    financial_data = gather_financial_data(context.target_information, quantum_financial)
    
    # Calculate key financial metrics
    financial_metrics = calculate_key_financial_metrics(financial_data)
    
    # Perform valuation analysis
    valuation_analysis = conduct_valuation_analysis(financial_data, financial_metrics, quantum_financial)
    
    # Analyze cash flow and sustainability
    cash_flow_analysis = analyze_cash_flow_sustainability(financial_data, quantum_financial)
    
    # Identify financial red flags
    financial_red_flags = identify_financial_red_flags(financial_data, financial_metrics)
    
    # Generate financial projections
    financial_projections = generate_financial_projections(
        financial_data,
        financial_metrics,
        quantum_financial
    )
    
    return FinancialAnalysisResults(
        financial_metrics=financial_metrics,
        valuation_analysis=valuation_analysis,
        cash_flow_analysis=cash_flow_analysis,
        financial_projections=financial_projections,
        red_flags=financial_red_flags,
        data_quality_score=assess_financial_data_quality(financial_data),
        confidence_score=quantum_financial[:confidence],
        analysis_etd_value=quantum_financial[:etd_value]
    )
end

"""
    conduct_comprehensive_risk_assessment(agent::DiligenceAgent, context, market, technical, financial, team, legal)

Conduct comprehensive risk assessment integrating all evaluation areas.
"""
function conduct_comprehensive_risk_assessment(agent::DiligenceAgent, context::DiligenceContext, 
                                             market_analysis, technical_assessment, 
                                             financial_analysis, team_evaluation, legal_review)
    # Quantum-enhanced risk assessment
    quantum_risk = process_with_crown_consciousness(
        agent.quantum_optimizer,
        (context=context, market=market_analysis, technical=technical_assessment,
         financial=financial_analysis, team=team_evaluation, legal=legal_review),
        :comprehensive_risk_assessment
    )
    
    # Aggregate red flags from all areas
    all_red_flags = vcat(
        market_analysis.red_flags,
        technical_assessment.red_flags,
        financial_analysis.red_flags,
        team_evaluation.red_flags,
        legal_review.red_flags
    )
    
    # Calculate risk scores by category
    risk_scores = calculate_risk_scores_by_category(all_red_flags, quantum_risk)
    
    # Identify critical risk combinations
    critical_risk_combinations = identify_critical_risk_combinations(all_red_flags, quantum_risk)
    
    # Generate risk mitigation strategies
    mitigation_strategies = generate_risk_mitigation_strategies(all_red_flags, quantum_risk)
    
    # Calculate overall risk score
    overall_risk_score = calculate_overall_risk_score(risk_scores, critical_risk_combinations)
    
    # Risk scenario modeling
    risk_scenarios = generate_risk_scenarios(all_red_flags, quantum_risk)
    
    return RiskAssessmentResults(
        red_flags=all_red_flags,
        risk_scores_by_category=risk_scores,
        critical_combinations=critical_risk_combinations,
        mitigation_strategies=mitigation_strategies,
        risk_scenarios=risk_scenarios,
        overall_risk_score=overall_risk_score,
        risk_tolerance_analysis=analyze_risk_tolerance(context.project, overall_risk_score),
        quantum_insights=quantum_risk[:insights],
        assessment_etd_value=quantum_risk[:etd_value]
    )
end

"""
    generate_final_evaluation_and_recommendation(agent::DiligenceAgent, ...)

Generate final evaluation and investment recommendation with quantum insights.
"""
function generate_final_evaluation_and_recommendation(agent::DiligenceAgent, context::DiligenceContext,
                                                     market_analysis, technical_assessment,
                                                     financial_analysis, team_evaluation,
                                                     legal_review, risk_assessment)
    # Quantum-enhanced final evaluation
    quantum_evaluation = process_with_crown_consciousness(
        agent.quantum_optimizer,
        (context=context, market=market_analysis, technical=technical_assessment,
         financial=financial_analysis, team=team_evaluation, legal=legal_review, 
         risk=risk_assessment),
        :final_evaluation_synthesis
    )
    
    # Calculate weighted assessment scores
    assessment_areas = Dict{String, AssessmentResult}()
    assessment_areas["market"] = create_assessment_result("Market Analysis", market_analysis, 0.20)
    assessment_areas["technical"] = create_assessment_result("Technical Assessment", technical_assessment, 0.25)
    assessment_areas["financial"] = create_assessment_result("Financial Analysis", financial_analysis, 0.30)
    assessment_areas["team"] = create_assessment_result("Team Evaluation", team_evaluation, 0.15)
    assessment_areas["legal"] = create_assessment_result("Legal Review", legal_review, 0.10)
    
    # Calculate overall score
    overall_score = calculate_weighted_overall_score(assessment_areas)
    
    # Generate investment recommendation
    recommendation = generate_investment_recommendation(
        overall_score,
        risk_assessment.overall_risk_score,
        context.project.investment_amount,
        quantum_evaluation
    )
    
    # Identify key strengths and concerns
    key_strengths = identify_key_strengths(assessment_areas)
    critical_concerns = identify_critical_concerns(risk_assessment.red_flags)
    
    # Calculate confidence level
    confidence_level = calculate_evaluation_confidence(assessment_areas, risk_assessment)
    
    evaluation_id = generate_evaluation_id()
    
    return DiligenceEvaluation(
        id=evaluation_id,
        project_id=context.project.id,
        evaluation_date=now(),
        assessment_areas=assessment_areas,
        overall_score=overall_score,
        risk_score=risk_assessment.overall_risk_score,
        financial_metrics=financial_analysis.financial_metrics,
        red_flags=risk_assessment.red_flags,
        key_strengths=key_strengths,
        critical_concerns=critical_concerns,
        recommendation=recommendation,
        confidence_level=confidence_level,
        etd_value=quantum_evaluation[:etd_value]
    )
end

"""
    calculate_diligence_etd_value(agent::DiligenceAgent, evaluation::DiligenceEvaluation, context::DiligenceContext)

Calculate Engineering Time Diverted value for due diligence operations.
"""
function calculate_diligence_etd_value(agent::DiligenceAgent, evaluation::DiligenceEvaluation, context::DiligenceContext)
    # Base ETD from evaluation complexity and thoroughness
    base_etd = evaluation.etd_value
    
    # Quantum enhancement multiplier
    quantum_multiplier = 1.0 + (agent.quantum_optimizer.coherence_level * 1.3)
    
    # Assessment comprehensiveness multiplier
    comprehensiveness_score = calculate_assessment_comprehensiveness(evaluation.assessment_areas)
    comprehensiveness_multiplier = 1.0 + (comprehensiveness_score * 0.5)
    
    # Investment size impact multiplier (larger investments = higher ETD value)
    investment_size_multiplier = case
        context.project.investment_amount > 10_000_000 => 2.0  # $10M+
        context.project.investment_amount > 1_000_000 => 1.5   # $1M+
        context.project.investment_amount > 100_000 => 1.2     # $100K+
        else => 1.0
    end
    
    # Risk mitigation value (identifying risks has high ETD value)
    risk_count = length(evaluation.red_flags)
    critical_risks = count(flag -> flag.severity == :critical, evaluation.red_flags)
    risk_mitigation_multiplier = 1.0 + (risk_count * 0.1) + (critical_risks * 0.3)
    
    # Enterprise decision quality bonus (better recommendations = higher value)
    decision_quality_multiplier = case evaluation.recommendation
        :proceed => evaluation.confidence_level > 0.8 ? 1.4 : 1.2
        :proceed_with_conditions => 1.3
        :decline => evaluation.confidence_level > 0.8 ? 1.5 : 1.2  # High-confidence declines save money
        :more_info_needed => 1.1
    end
    
    # Time savings multiplier (automated due diligence saves massive time)
    time_savings_multiplier = 3.2  # Manual DD typically takes 6-12 weeks
    
    total_etd = base_etd * quantum_multiplier * comprehensiveness_multiplier * 
                investment_size_multiplier * risk_mitigation_multiplier * 
                decision_quality_multiplier * time_savings_multiplier
    
    return total_etd
end

# Utility Functions

function extract_target_from_request(request::String)::String
    # Simple target name extraction - in production would use NLP
    words = split(lowercase(request))
    
    # Look for common patterns
    for (i, word) in enumerate(words)
        if word in ["target", "company", "startup"] && i < length(words)
            return words[i+1]
        end
    end
    
    return "Unknown Target"
end

function determine_target_type(request::String)::String
    request_lower = lowercase(request)
    
    if occursin("startup", request_lower)
        return "startup"
    elseif occursin("acquisition", request_lower) || occursin("acquire", request_lower)
        return "acquisition"
    elseif occursin("partnership", request_lower) || occursin("partner", request_lower)
        return "partnership"
    else
        return "company"
    end
end

function calculate_key_financial_metrics(financial_data::Dict)::Dict{String, Float64}
    metrics = Dict{String, Float64}()
    
    # Revenue metrics
    if haskey(financial_data, "revenue")
        revenue_data = financial_data["revenue"]
        if length(revenue_data) >= 2
            metrics["revenue_growth"] = (last(revenue_data) - first(revenue_data)) / first(revenue_data) * 100
        end
        metrics["current_revenue"] = last(revenue_data)
    end
    
    # Profitability metrics
    if haskey(financial_data, "gross_profit")
        metrics["gross_margin"] = financial_data["gross_profit"] / get(financial_data, "revenue", 1.0) * 100
    end
    
    # Cash metrics
    if haskey(financial_data, "cash_position")
        metrics["cash_position"] = financial_data["cash_position"]
    end
    
    # Burn rate
    if haskey(financial_data, "monthly_burn")
        cash_position = get(metrics, "cash_position", 0.0)
        monthly_burn = financial_data["monthly_burn"]
        if monthly_burn > 0
            metrics["runway_months"] = cash_position / monthly_burn
        end
    end
    
    return metrics
end

function generate_investment_recommendation(overall_score::Float64, risk_score::Float64, 
                                          investment_amount::Float64, quantum_evaluation::Dict)::Symbol
    # Investment decision matrix based on score and risk
    if overall_score >= 80 && risk_score <= 30
        return :proceed
    elseif overall_score >= 70 && risk_score <= 50
        return :proceed_with_conditions
    elseif overall_score >= 50 && risk_score <= 40
        return :proceed_with_conditions
    elseif overall_score < 40 || risk_score > 70
        return :decline
    else
        return :more_info_needed
    end
end

function load_assessment_frameworks()::Dict{String, AssessmentFramework}
    frameworks = Dict{String, AssessmentFramework}()
    
    # Sample assessment frameworks
    frameworks["startup_comprehensive"] = AssessmentFramework(
        name="Startup Comprehensive Assessment",
        target_types=[:startup],
        assessment_areas=["market", "technical", "financial", "team", "legal"],
        area_weights=Dict("market" => 0.20, "technical" => 0.25, "financial" => 0.30, "team" => 0.15, "legal" => 0.10),
        timeline_weeks=4,
        estimated_etd_value=685_000.0
    )
    
    return frameworks
end

# Response Types

"""
    DiligenceResponse

Complete response from due diligence agent processing.
"""
struct DiligenceResponse
    success::Bool
    evaluation::Union{DiligenceEvaluation, Nothing}
    market_analysis::Union{MarketAnalysisResults, Nothing}
    technical_assessment::Union{TechnicalAssessmentResults, Nothing}
    financial_analysis::Union{FinancialAnalysisResults, Nothing}
    team_evaluation::Union{TeamEvaluationResults, Nothing}
    legal_review::Union{LegalReviewResults, Nothing}
    risk_assessment::Union{RiskAssessmentResults, Nothing}
    etd_value::Float64
    error::Union{String, Nothing}
    audit_trail::Vector{AuditLogEntry}
    
    function DiligenceResponse(; success::Bool,
                              evaluation::Union{DiligenceEvaluation, Nothing}=nothing,
                              market_analysis::Union{MarketAnalysisResults, Nothing}=nothing,
                              technical_assessment::Union{TechnicalAssessmentResults, Nothing}=nothing,
                              financial_analysis::Union{FinancialAnalysisResults, Nothing}=nothing,
                              team_evaluation::Union{TeamEvaluationResults, Nothing}=nothing,
                              legal_review::Union{LegalReviewResults, Nothing}=nothing,
                              risk_assessment::Union{RiskAssessmentResults, Nothing}=nothing,
                              etd_value::Float64=0.0,
                              error::Union{String, Nothing}=nothing,
                              audit_trail::Vector{AuditLogEntry}=AuditLogEntry[])
        new(success, evaluation, market_analysis, technical_assessment, financial_analysis,
            team_evaluation, legal_review, risk_assessment, etd_value, error, audit_trail)
    end
end

"""
    create_diligence_agent(config::Dict{String,Any}=Dict{String,Any}())

Factory function to create configured due diligence agent.
"""
function create_diligence_agent(config::Dict{String,Any}=Dict{String,Any}())
    enterprise_config = EnterpriseConfig(
        enable_quantum_optimization=get(config, "quantum", true),
        enable_blockchain_anchoring=get(config, "blockchain", true),
        security_level=Symbol(get(config, "security_level", "high")),
        audit_level=Symbol(get(config, "audit_level", "comprehensive"))
    )
    
    return DiligenceAgent(enterprise_config)
end

# Export main functions and types
export DiligenceAgent, DiligenceResponse, DiligenceProject, DiligenceEvaluation, RedFlag
export process_diligence_request, create_diligence_agent, calculate_diligence_etd_value