"""
High-Performance Sales & Customer Success Subagents for Schemantics
Lead qualification, proposal generation, and customer success automation
"""

module SalesCustomerSuccessSubagents

using JSON3
using UUIDs
using Dates
using DataFrames
using Distributed

include("../BusinessSubagentFramework.jl")
using .BusinessSubagentFramework

export LeadQualifierSubagent, ProposalGeneratorSubagent, CustomerSuccessSubagent
export qualify_leads, generate_proposals, monitor_customer_health

# Lead Qualifier Subagent - Advanced lead scoring and qualification
struct LeadQualifierSubagent <: AbstractBusinessSubagent
    name::String
    capabilities::Vector{String}
    templates::Dict{String, String}
    performance_metrics::ExecutionMetrics
    
    function LeadQualifierSubagent()
        capabilities = [
            "Lead scoring and qualification", "Prospect research and analysis",
            "Intent signal detection", "Account-based lead prioritization",
            "Lead routing and assignment", "Qualification call preparation",
            "Competitive analysis", "ROI potential assessment"
        ]
        
        templates = Dict{String, String}(
            "lead_qualification_report" => """
            # Lead Qualification Report - {lead_name}
            
            ## Lead Summary:
            - **Company**: {company_name}
            - **Contact**: {contact_name} ({contact_title})
            - **Industry**: {industry}
            - **Company Size**: {company_size}
            - **Lead Source**: {lead_source}
            - **Date Qualified**: {qualification_date}
            
            ## Qualification Score: {qualification_score}/100
            
            ### Scoring Breakdown:
            - **Budget Fit** ({budget_score}/25): {budget_justification}
            - **Authority Level** ({authority_score}/25): {authority_justification}
            - **Need Alignment** ({need_score}/25): {need_justification}
            - **Timeline Readiness** ({timeline_score}/25): {timeline_justification}
            
            ## Technical Stack Analysis:
            - **Primary Languages**: {primary_languages}
            - **Current Tools**: {current_tools}
            - **Pain Points**: {pain_points}
            - **Schemantics Fit Score**: {fit_score}/10
            
            ## Business Context:
            - **Growth Stage**: {growth_stage}
            - **Key Challenges**: {key_challenges}
            - **Decision Making Process**: {decision_process}
            - **Evaluation Timeline**: {evaluation_timeline}
            
            ## Recommended Next Actions:
            {next_actions}
            
            ## Personalization Notes:
            {personalization_notes}
            
            ## Competitive Intelligence:
            {competitive_info}
            
            ## ROI Potential:
            - **Estimated Annual Value**: ${estimated_annual_value}
            - **Implementation Effort**: {implementation_effort}
            - **Success Probability**: {success_probability}%
            
            ## Follow-up Strategy:
            {follow_up_strategy}
            """,
            
            "qualification_scorecard" => """
            # Qualification Scorecard - {company_name}
            
            ## BANT Analysis:
            
            ### Budget (Score: {budget_score}/25)
            - Estimated Budget Range: ${budget_range}
            - Budget Authority: {budget_authority}
            - Budget Timeline: {budget_timeline}
            - Investment Readiness: {investment_readiness}
            
            ### Authority (Score: {authority_score}/25)
            - Decision Maker Level: {decision_maker_level}
            - Stakeholder Influence: {stakeholder_influence}
            - Champion Identification: {champion_status}
            - Approval Process: {approval_process}
            
            ### Need (Score: {need_score}/25)
            - Problem Severity: {problem_severity}
            - Current Solution Gaps: {solution_gaps}
            - Impact of Inaction: {inaction_impact}
            - Schemantics Solution Fit: {solution_fit}
            
            ### Timeline (Score: {timeline_score}/25)
            - Urgency Level: {urgency_level}
            - Decision Timeline: {decision_timeline}
            - Implementation Window: {implementation_window}
            - Competing Priorities: {competing_priorities}
            
            ## Additional Qualifiers:
            - **Technology Alignment**: {tech_alignment}/10
            - **Team Size Fit**: {team_size_fit}/10
            - **Growth Trajectory**: {growth_trajectory}/10
            - **Innovation Appetite**: {innovation_appetite}/10
            
            ## Overall Qualification: {overall_qualification}
            ## Recommended Priority: {priority_level}
            """,
            
            "prospect_research" => """
            # Prospect Research - {company_name}
            
            ## Company Intelligence:
            - **Founded**: {founded_year}
            - **Headquarters**: {headquarters}
            - **Employee Count**: {employee_count}
            - **Annual Revenue**: ${annual_revenue}
            - **Funding Stage**: {funding_stage}
            - **Recent Funding**: ${recent_funding} ({funding_date})
            
            ## Technology Stack:
            - **Programming Languages**: {programming_languages}
            - **Development Tools**: {development_tools}
            - **Infrastructure**: {infrastructure}
            - **Databases**: {databases}
            
            ## Team Structure:
            - **Engineering Team Size**: {engineering_team_size}
            - **Development Methodology**: {development_methodology}
            - **Technical Leadership**: {technical_leadership}
            
            ## Business Insights:
            - **Product Focus**: {product_focus}
            - **Target Market**: {target_market}
            - **Competitive Position**: {competitive_position}
            - **Growth Challenges**: {growth_challenges}
            
            ## Recent Activity:
            - **News/Announcements**: {recent_news}
            - **Job Postings**: {job_postings}
            - **Technology Adoption**: {tech_adoption}
            
            ## Engagement History:
            - **Previous Touchpoints**: {previous_touchpoints}
            - **Content Engagement**: {content_engagement}
            - **Event Participation**: {event_participation}
            
            ## Sales Intelligence:
            - **Best Contact Approach**: {contact_approach}
            - **Key Value Propositions**: {value_propositions}
            - **Potential Objections**: {potential_objections}
            - **Recommended Demo Focus**: {demo_focus}
            """
        )
        
        new("lead-qualifier-agent", capabilities, templates, ExecutionMetrics())
    end
end

# Proposal Generator Subagent - Custom proposal and contract generation
struct ProposalGeneratorSubagent <: AbstractBusinessSubagent
    name::String
    capabilities::Vector{String}
    templates::Dict{String, String}
    performance_metrics::ExecutionMetrics
    
    function ProposalGeneratorSubagent()
        capabilities = [
            "Custom proposal generation", "ROI calculation and modeling",
            "Implementation roadmap creation", "Pricing optimization",
            "Contract template customization", "Risk assessment",
            "Success metrics definition", "Timeline estimation"
        ]
        
        templates = Dict{String, String}(
            "technical_proposal" => """
            # Schemantics Implementation Proposal
            ## {company_name} - {proposal_date}
            
            ### Executive Summary
            
            We're excited to propose a comprehensive Schemantics implementation for {company_name} that will transform your {primary_use_case} development workflow. Based on our analysis of your current {current_stack} environment, we've designed a solution that will deliver {primary_benefit} while seamlessly integrating with your existing {integration_points}.
            
            **Expected Outcomes:**
            - {outcome_1}
            - {outcome_2} 
            - {outcome_3}
            
            **Investment**: ${total_investment}
            **Expected ROI**: {roi_percentage}% in {roi_timeframe}
            **Implementation Timeline**: {implementation_timeline}
            
            ---
            
            ### Technical Solution Overview
            
            #### Current State Analysis
            {current_state_analysis}
            
            #### Proposed Architecture
            {proposed_architecture}
            
            #### Integration Strategy
            Our implementation will integrate seamlessly with your existing stack:
            
            - **{language_1} Projects**: {integration_approach_1}
            - **{language_2} Projects**: {integration_approach_2}
            - **Development Tools**: {dev_tools_integration}
            - **CI/CD Pipeline**: {cicd_integration}
            
            #### Schema-Alignment Benefits for Your Team
            {schema_benefits}
            
            ---
            
            ### Implementation Roadmap
            
            #### Phase 1: Foundation ({phase1_duration})
            {phase1_details}
            
            #### Phase 2: Core Implementation ({phase2_duration})  
            {phase2_details}
            
            #### Phase 3: Optimization & Scale ({phase3_duration})
            {phase3_details}
            
            #### Phase 4: Advanced Features ({phase4_duration})
            {phase4_details}
            
            ---
            
            ### Investment & ROI Analysis
            
            #### Investment Breakdown
            - **Software License**: ${software_cost}
            - **Implementation Services**: ${implementation_cost}
            - **Training & Onboarding**: ${training_cost}
            - **First Year Support**: ${support_cost}
            - **Total Year 1**: ${total_year1_cost}
            
            #### ROI Calculation
            
            **Productivity Gains:**
            - Development Speed Increase: {dev_speed_increase}%
            - Bug Reduction: {bug_reduction}%
            - Code Quality Improvement: {quality_improvement}%
            
            **Cost Savings (Annual):**
            - Reduced Development Time: ${dev_time_savings}
            - Fewer Production Issues: ${production_savings}
            - Improved Developer Efficiency: ${efficiency_savings}
            - **Total Annual Savings**: ${total_savings}
            
            **Net ROI**: ${net_roi} ({roi_percentage}%) by month {roi_month}
            
            ---
            
            ### Success Metrics & KPIs
            
            We'll track the following metrics to ensure successful implementation:
            
            #### Technical Metrics:
            - Schema compliance rate: Target {schema_compliance_target}%
            - Build time improvement: Target {build_time_target}% reduction
            - Code quality score: Target {quality_score_target}/10
            - Developer productivity: Target {productivity_target}% increase
            
            #### Business Metrics:
            - Time to market: Target {time_to_market_target}% improvement
            - Developer satisfaction: Target {satisfaction_target}/10
            - Code maintainability: Target {maintainability_target}% improvement
            
            ---
            
            ### Team & Support
            
            #### Implementation Team
            - **Technical Lead**: {tech_lead_name}
            - **Solutions Architect**: {solutions_architect}
            - **Developer Success Manager**: {success_manager}
            
            #### Support Structure
            - **Onboarding Support**: {onboarding_support_details}
            - **Ongoing Support**: {ongoing_support_details}
            - **Training Program**: {training_program_details}
            
            ---
            
            ### Risk Mitigation
            
            {risk_mitigation_plan}
            
            ---
            
            ### Next Steps
            
            1. **Technical Deep Dive** ({next_step_1_timeline})
               {next_step_1_details}
            
            2. **Pilot Program Setup** ({next_step_2_timeline})
               {next_step_2_details}
            
            3. **Full Implementation Kickoff** ({next_step_3_timeline})
               {next_step_3_details}
            
            ---
            
            ### Questions?
            
            We're here to ensure this solution perfectly fits your needs. Please don't hesitate to reach out with any questions.
            
            **Primary Contact**: {primary_contact}
            **Email**: {contact_email}
            **Direct Line**: {contact_phone}
            
            We're excited about the opportunity to help {company_name} achieve {primary_goal} with Schemantics!
            """,
            
            "pricing_proposal" => """
            # Schemantics Pricing Proposal - {company_name}
            
            ## Recommended Package: {recommended_package}
            
            ### Package Overview
            {package_overview}
            
            ### Pricing Structure
            
            #### Year 1 Investment:
            - **Base Platform License** ({license_tier}): ${base_license_cost}/month
            - **Implementation Services**: ${implementation_services_cost}
            - **Training & Onboarding**: ${training_cost}
            - **Premium Support**: ${support_cost}
            - **Professional Services**: ${professional_services_cost}
            
            **Total Year 1**: ${total_year1}
            **Monthly Year 1**: ${monthly_year1}
            
            #### Year 2+ Ongoing:
            - **Platform License**: ${ongoing_license_cost}/month
            - **Standard Support**: ${ongoing_support_cost}/month
            - **Total Monthly**: ${ongoing_monthly_total}
            
            ### Package Includes:
            {package_includes}
            
            ### Custom Add-ons Available:
            {custom_addons}
            
            ### Volume Discounts:
            {volume_discounts}
            
            ### Payment Terms:
            {payment_terms}
            
            ### Contract Terms:
            - **Initial Term**: {contract_term}
            - **Renewal Terms**: {renewal_terms}
            - **Cancellation Policy**: {cancellation_policy}
            
            ### Investment Justification:
            
            **Cost per Developer per Month**: ${cost_per_dev}
            **Productivity Gain per Developer**: {productivity_gain}%
            **Payback Period**: {payback_period} months
            **3-Year ROI**: {three_year_roi}%
            
            This represents an investment of ${investment_per_productivity_point} per productivity percentage point gained.
            """,
            
            "implementation_plan" => """
            # Implementation Plan - {company_name}
            
            ## Project Overview
            - **Client**: {company_name}
            - **Project Start**: {start_date}
            - **Go-Live Date**: {go_live_date}
            - **Total Duration**: {total_duration}
            - **Team Size**: {team_size} developers
            
            ## Implementation Phases
            
            ### Phase 1: Discovery & Planning ({phase1_start} - {phase1_end})
            
            **Objectives:**
            {phase1_objectives}
            
            **Key Activities:**
            {phase1_activities}
            
            **Deliverables:**
            {phase1_deliverables}
            
            **Success Criteria:**
            {phase1_success_criteria}
            
            ### Phase 2: Core Setup ({phase2_start} - {phase2_end})
            
            **Objectives:**
            {phase2_objectives}
            
            **Key Activities:**
            {phase2_activities}
            
            **Deliverables:**
            {phase2_deliverables}
            
            **Success Criteria:**
            {phase2_success_criteria}
            
            ### Phase 3: Integration & Testing ({phase3_start} - {phase3_end})
            
            **Objectives:**
            {phase3_objectives}
            
            **Key Activities:**
            {phase3_activities}
            
            **Deliverables:**
            {phase3_deliverables}
            
            **Success Criteria:**
            {phase3_success_criteria}
            
            ### Phase 4: Launch & Optimization ({phase4_start} - {phase4_end})
            
            **Objectives:**
            {phase4_objectives}
            
            **Key Activities:**
            {phase4_activities}
            
            **Deliverables:**
            {phase4_deliverables}
            
            **Success Criteria:**
            {phase4_success_criteria}
            
            ## Resource Allocation
            {resource_allocation}
            
            ## Risk Management
            {risk_management}
            
            ## Communication Plan
            {communication_plan}
            
            ## Training Schedule
            {training_schedule}
            """
        )
        
        new("proposal-generator-agent", capabilities, templates, ExecutionMetrics())
    end
end

# Customer Success Subagent - Health monitoring and retention
struct CustomerSuccessSubagent <: AbstractBusinessSubagent
    name::String
    capabilities::Vector{String}
    templates::Dict{String, String}
    performance_metrics::ExecutionMetrics
    
    function CustomerSuccessSubagent()
        capabilities = [
            "Customer health monitoring", "Onboarding optimization",
            "Usage analytics and insights", "Expansion opportunity identification",
            "Churn prediction and prevention", "Success plan creation",
            "Training program management", "Renewal optimization"
        ]
        
        templates = Dict{String, String}(
            "customer_health_report" => """
            # Customer Health Report - {customer_name}
            ## {report_period}
            
            ### Overall Health Score: {health_score}/100
            **Status**: {health_status}
            **Trend**: {health_trend}
            
            ---
            
            ### Health Score Breakdown
            
            #### Usage Metrics (Weight: 40%)
            **Score**: {usage_score}/40
            - **Daily Active Users**: {daily_active_users} ({dau_trend})
            - **Feature Adoption**: {feature_adoption}% ({adoption_trend})
            - **API Usage**: {api_calls}/month ({api_trend})
            - **Integration Depth**: {integration_depth}/10
            
            #### Engagement Metrics (Weight: 30%)
            **Score**: {engagement_score}/30
            - **Support Ticket Volume**: {support_tickets} ({ticket_trend})
            - **Documentation Access**: {doc_access_frequency}
            - **Community Participation**: {community_engagement}/10
            - **Training Completion**: {training_completion}%
            
            #### Business Value Metrics (Weight: 20%)
            **Score**: {business_value_score}/20
            - **ROI Achievement**: {roi_achievement}% of expected
            - **Success Milestones**: {milestones_completed}/{total_milestones}
            - **Goal Progress**: {goal_progress}%
            - **Value Realization**: {value_realization}/10
            
            #### Relationship Metrics (Weight: 10%)
            **Score**: {relationship_score}/10
            - **Stakeholder Engagement**: {stakeholder_engagement}/10
            - **Champion Strength**: {champion_strength}/10
            - **Renewal Sentiment**: {renewal_sentiment}/10
            
            ---
            
            ### Key Insights
            
            #### Strengths:
            {customer_strengths}
            
            #### Concerns:
            {customer_concerns}
            
            #### Opportunities:
            {expansion_opportunities}
            
            ---
            
            ### Risk Assessment
            
            **Churn Risk**: {churn_risk_level}
            **Risk Factors**:
            {risk_factors}
            
            **Mitigation Actions**:
            {mitigation_actions}
            
            ---
            
            ### Recommended Actions
            
            #### Immediate (Next 30 Days):
            {immediate_actions}
            
            #### Medium Term (30-90 Days):
            {medium_term_actions}
            
            #### Long Term (90+ Days):
            {long_term_actions}
            
            ---
            
            ### Success Plan Update
            
            **Current Phase**: {current_success_phase}
            **Next Milestone**: {next_milestone} (Due: {milestone_due_date})
            **Progress**: {milestone_progress}%
            
            **Upcoming Initiatives**:
            {upcoming_initiatives}
            
            ---
            
            ### Renewal Outlook
            
            **Renewal Date**: {renewal_date}
            **Renewal Probability**: {renewal_probability}%
            **Expansion Potential**: ${expansion_potential}
            **Recommended Actions for Renewal**:
            {renewal_actions}
            """,
            
            "onboarding_plan" => """
            # Customer Onboarding Plan - {customer_name}
            
            ## Onboarding Overview
            - **Customer**: {customer_name}
            - **Start Date**: {onboarding_start_date}
            - **Target Go-Live**: {target_go_live}
            - **Success Manager**: {success_manager}
            - **Technical Contact**: {technical_contact}
            
            ## Success Criteria
            {onboarding_success_criteria}
            
            ## Onboarding Phases
            
            ### Week 1: Foundation Setup
            **Objectives:**
            - Complete account configuration
            - Initial team training
            - Basic integrations setup
            
            **Key Activities:**
            - Welcome call and goal setting
            - Platform walkthrough
            - Initial schema setup for {primary_language}
            - Development environment configuration
            
            **Deliverables:**
            - Configured development environment
            - First schema-aligned project template
            - Training materials customized for team
            
            **Success Metrics:**
            - Platform access confirmed for all users
            - First successful schema validation
            - Team comfort level with basic features
            
            ### Week 2-3: Core Implementation
            **Objectives:**
            - Implement core workflows
            - Advanced feature training
            - Integration with existing tools
            
            **Key Activities:**
            - Schema design workshops
            - CI/CD pipeline integration
            - Advanced feature demonstrations
            - Custom workflow setup
            
            **Deliverables:**
            - Production-ready schema configurations
            - Integrated development workflow
            - Team proficiency in core features
            
            **Success Metrics:**
            - Successful integration with {integration_target}
            - Team productivity metrics baseline established
            - Advanced features adoption rate >60%
            
            ### Week 4-6: Optimization & Scaling
            **Objectives:**
            - Optimize performance
            - Scale across additional projects
            - Measure initial success metrics
            
            **Key Activities:**
            - Performance tuning workshops
            - Additional project onboarding
            - Success metrics review
            - Best practices establishment
            
            **Deliverables:**
            - Optimized performance configuration
            - Scaled implementation across projects
            - Initial ROI measurement report
            
            **Success Metrics:**
            - Performance improvement >20%
            - Additional projects successfully onboarded
            - Initial ROI targets met
            
            ### Month 2-3: Value Realization
            **Objectives:**
            - Achieve target business outcomes
            - Establish long-term success patterns
            - Prepare for expansion opportunities
            
            **Key Activities:**
            - Advanced optimization techniques
            - Cross-team collaboration setup
            - Expansion planning discussions
            - Success story documentation
            
            **Deliverables:**
            - Comprehensive optimization guide
            - Expansion roadmap
            - Success story case study
            
            **Success Metrics:**
            - Target ROI achievement
            - Team satisfaction >8/10
            - Expansion opportunities identified
            
            ## Risk Mitigation
            {risk_mitigation_strategies}
            
            ## Communication Schedule
            {communication_schedule}
            
            ## Training Resources
            {training_resources}
            """,
            
            "expansion_opportunity" => """
            # Expansion Opportunity Analysis - {customer_name}
            
            ## Executive Summary
            **Expansion Potential**: ${expansion_revenue_potential}
            **Implementation Effort**: {implementation_effort}
            **Success Probability**: {success_probability}%
            **Recommended Approach**: {recommended_approach}
            
            ## Current State Analysis
            
            ### Current Usage:
            - **Active Users**: {current_active_users}
            - **Projects Using Schemantics**: {current_projects}
            - **Monthly API Calls**: {current_api_usage}
            - **Feature Utilization**: {current_feature_utilization}%
            
            ### Current Value Delivery:
            - **Productivity Improvement**: {current_productivity_improvement}%
            - **Quality Metrics**: {current_quality_metrics}
            - **Developer Satisfaction**: {current_dev_satisfaction}/10
            - **ROI Achievement**: {current_roi}%
            
            ## Expansion Opportunities
            
            ### Opportunity 1: {opportunity_1_name}
            **Description**: {opportunity_1_description}
            **Potential Value**: ${opportunity_1_value}
            **Implementation**: {opportunity_1_implementation}
            **Timeline**: {opportunity_1_timeline}
            **Success Indicators**: {opportunity_1_indicators}
            
            ### Opportunity 2: {opportunity_2_name}
            **Description**: {opportunity_2_description}
            **Potential Value**: ${opportunity_2_value}
            **Implementation**: {opportunity_2_implementation}
            **Timeline**: {opportunity_2_timeline}
            **Success Indicators**: {opportunity_2_indicators}
            
            ### Opportunity 3: {opportunity_3_name}
            **Description**: {opportunity_3_description}
            **Potential Value**: ${opportunity_3_value}
            **Implementation**: {opportunity_3_implementation}
            **Timeline**: {opportunity_3_timeline}
            **Success Indicators**: {opportunity_3_indicators}
            
            ## Business Case
            
            ### Investment Required:
            - **Additional Licenses**: ${additional_license_cost}
            - **Implementation Services**: ${implementation_services_cost}
            - **Training**: ${additional_training_cost}
            - **Total Investment**: ${total_expansion_investment}
            
            ### Expected Returns:
            - **Additional Productivity**: {additional_productivity}%
            - **Quality Improvements**: {additional_quality_improvements}
            - **Cost Savings**: ${annual_cost_savings}
            - **Revenue Impact**: ${revenue_impact}
            
            ### ROI Projection:
            - **Payback Period**: {expansion_payback_period} months
            - **3-Year ROI**: {expansion_roi}%
            - **Net Present Value**: ${expansion_npv}
            
            ## Implementation Strategy
            {expansion_implementation_strategy}
            
            ## Risk Assessment
            {expansion_risk_assessment}
            
            ## Recommended Next Steps
            1. **Discovery Workshop** ({next_step_1_timeline})
            2. **Pilot Program** ({next_step_2_timeline})
            3. **Full Rollout** ({next_step_3_timeline})
            
            ## Success Metrics
            {expansion_success_metrics}
            """
        )
        
        new("customer-success-agent", capabilities, templates, ExecutionMetrics())
    end
end

# Implementation of execute_task for each subagent
function execute_task(subagent::LeadQualifierSubagent, task::SubagentTask)::SubagentOutput
    start_time = time_ns()
    
    try
        qualification_type = get(task.requirements, "qualification_type", "lead_qualification")
        lead_data = get(task.requirements, "lead_data", Dict{String, Any}())
        
        # Perform lead qualification analysis
        qualification_result = analyze_lead_qualification(lead_data, task.context)
        
        # Generate qualification report
        template = get(subagent.templates, "$(qualification_type)_report", subagent.templates["lead_qualification_report"])
        report = generate_qualification_report(template, qualification_result, task)
        
        metrics = Dict{String, Any}(
            "qualification_score" => qualification_result["qualification_score"],
            "budget_score" => qualification_result["budget_score"],
            "authority_score" => qualification_result["authority_score"],
            "need_score" => qualification_result["need_score"],
            "timeline_score" => qualification_result["timeline_score"],
            "fit_score" => qualification_result["fit_score"],
            "success_probability" => qualification_result["success_probability"]
        )
        
        execution_time = (time_ns() - start_time) ÷ 1_000_000
        
        output = SubagentOutput(
            task.task_id,
            COMPLETED,
            report,
            MARKDOWN,
            Dict{String, Any}(
                "qualification_type" => qualification_type,
                "lead_priority" => qualification_result["priority_level"],
                "recommended_actions_count" => length(qualification_result["next_actions"])
            ),
            metrics,
            [
                "Schedule personalized demo based on technical stack",
                "Prepare customized ROI analysis",
                "Engage technical decision makers",
                "Create tailored proposal with specific use cases"
            ],
            now(),
            execution_time,
            1.0
        )
        
        log_execution(subagent.name, task, output, subagent.performance_metrics)
        return output
        
    catch e
        execution_time = (time_ns() - start_time) ÷ 1_000_000
        return SubagentOutput(
            task.task_id, FAILED, "Lead qualification failed: $e", TEXT,
            Dict("error" => string(e)), Dict{String, Any}(), String[],
            now(), execution_time, 0.0
        )
    end
end

function execute_task(subagent::ProposalGeneratorSubagent, task::SubagentTask)::SubagentOutput
    start_time = time_ns()
    
    try
        proposal_type = get(task.requirements, "proposal_type", "technical_proposal")
        customer_data = get(task.requirements, "customer_data", Dict{String, Any}())
        qualification_data = get(task.requirements, "qualification_data", Dict{String, Any}())
        
        # Generate customized proposal
        proposal_result = generate_customized_proposal(customer_data, qualification_data, task.context)
        
        # Generate proposal document
        template = get(subagent.templates, proposal_type, subagent.templates["technical_proposal"])
        proposal = generate_proposal_document(template, proposal_result, task)
        
        metrics = Dict{String, Any}(
            "total_investment" => proposal_result["total_investment"],
            "roi_percentage" => proposal_result["roi_percentage"],
            "implementation_timeline_weeks" => proposal_result["implementation_weeks"],
            "success_probability" => proposal_result["success_probability"],
            "competitive_advantage_score" => proposal_result["competitive_score"]
        )
        
        execution_time = (time_ns() - start_time) ÷ 1_000_000
        
        output = SubagentOutput(
            task.task_id,
            COMPLETED,
            proposal,
            MARKDOWN,
            Dict{String, Any}(
                "proposal_type" => proposal_type,
                "customer_name" => get(customer_data, "company_name", "Customer"),
                "proposal_length_words" => length(split(proposal))
            ),
            metrics,
            [
                "Schedule proposal presentation meeting",
                "Prepare demo environment with customer-specific examples",
                "Create implementation timeline with key milestones",
                "Develop negotiation strategy based on proposal feedback"
            ],
            now(),
            execution_time,
            1.0
        )
        
        log_execution(subagent.name, task, output, subagent.performance_metrics)
        return output
        
    catch e
        execution_time = (time_ns() - start_time) ÷ 1_000_000
        return SubagentOutput(
            task.task_id, FAILED, "Proposal generation failed: $e", TEXT,
            Dict("error" => string(e)), Dict{String, Any}(), String[],
            now(), execution_time, 0.0
        )
    end
end

function execute_task(subagent::CustomerSuccessSubagent, task::SubagentTask)::SubagentOutput
    start_time = time_ns()
    
    try
        success_type = get(task.requirements, "success_type", "health_monitoring")
        customer_data = get(task.requirements, "customer_data", Dict{String, Any}())
        usage_data = get(task.requirements, "usage_data", Dict{String, Any}())
        
        # Analyze customer success metrics
        success_analysis = analyze_customer_success(customer_data, usage_data, task.context)
        
        # Generate success report
        template = get(subagent.templates, "customer_$(success_type)", subagent.templates["customer_health_report"])
        report = generate_success_report(template, success_analysis, task)
        
        metrics = Dict{String, Any}(
            "health_score" => success_analysis["health_score"],
            "churn_risk" => success_analysis["churn_risk"],
            "expansion_potential" => success_analysis["expansion_potential"],
            "satisfaction_score" => success_analysis["satisfaction_score"],
            "roi_achievement" => success_analysis["roi_achievement"]
        )
        
        execution_time = (time_ns() - start_time) ÷ 1_000_000
        
        output = SubagentOutput(
            task.task_id,
            COMPLETED,
            report,
            MARKDOWN,
            Dict{String, Any}(
                "success_type" => success_type,
                "customer_name" => get(customer_data, "company_name", "Customer"),
                "recommendations_count" => length(success_analysis["recommendations"])
            ),
            metrics,
            [
                "Implement automated health score monitoring",
                "Set up proactive intervention triggers",
                "Create expansion opportunity pipeline",
                "Schedule regular success reviews with customer"
            ],
            now(),
            execution_time,
            1.0
        )
        
        log_execution(subagent.name, task, output, subagent.performance_metrics)
        return output
        
    catch e
        execution_time = (time_ns() - start_time) ÷ 1_000_000
        return SubagentOutput(
            task.task_id, FAILED, "Customer success analysis failed: $e", TEXT,
            Dict("error" => string(e)), Dict{String, Any}(), String[],
            now(), execution_time, 0.0
        )
    end
end

# High-performance analysis functions
function analyze_lead_qualification(lead_data::Dict{String, Any}, context::Dict{String, Any})::Dict{String, Any}
    # Calculate BANT scores
    budget_score = calculate_budget_score(lead_data)
    authority_score = calculate_authority_score(lead_data)
    need_score = calculate_need_score(lead_data)
    timeline_score = calculate_timeline_score(lead_data)
    
    # Calculate total qualification score
    qualification_score = budget_score + authority_score + need_score + timeline_score
    
    # Calculate technical fit score
    fit_score = calculate_technical_fit_score(lead_data)
    
    # Determine priority level
    priority_level = determine_priority_level(qualification_score, fit_score)
    
    # Calculate success probability
    success_probability = calculate_success_probability(qualification_score, fit_score, lead_data)
    
    return Dict{String, Any}(
        "qualification_score" => qualification_score,
        "budget_score" => budget_score,
        "authority_score" => authority_score,
        "need_score" => need_score,
        "timeline_score" => timeline_score,
        "fit_score" => fit_score,
        "priority_level" => priority_level,
        "success_probability" => success_probability,
        "next_actions" => generate_qualification_actions(qualification_score, fit_score, lead_data),
        "personalization_notes" => generate_personalization_notes(lead_data),
        "competitive_info" => analyze_competitive_landscape(lead_data)
    )
end

function calculate_budget_score(lead_data::Dict{String, Any})::Int
    budget_range = get(lead_data, "budget_range", "unknown")
    company_size = get(lead_data, "company_size", 0)
    funding_stage = get(lead_data, "funding_stage", "unknown")
    
    score = 0
    
    # Budget range assessment
    if budget_range == "50k_plus"
        score += 15
    elseif budget_range == "20k_50k"
        score += 12
    elseif budget_range == "10k_20k"
        score += 8
    elseif budget_range == "5k_10k"
        score += 5
    end
    
    # Company size factor
    if company_size >= 100
        score += 5
    elseif company_size >= 50
        score += 3
    elseif company_size >= 20
        score += 2
    end
    
    # Funding stage factor
    if funding_stage in ["series_a", "series_b", "series_c", "public"]
        score += 5
    elseif funding_stage == "seed"
        score += 3
    end
    
    return min(25, score)
end

function calculate_authority_score(lead_data::Dict{String, Any})::Int
    contact_title = get(lead_data, "contact_title", "")
    decision_maker_level = get(lead_data, "decision_maker_level", "unknown")
    stakeholder_access = get(lead_data, "stakeholder_access", false)
    
    score = 0
    
    # Title-based scoring
    title_lower = lowercase(contact_title)
    if occursin("cto", title_lower) || occursin("vp engineering", title_lower) || occursin("chief", title_lower)
        score += 20
    elseif occursin("director", title_lower) || occursin("principal", title_lower)
        score += 15
    elseif occursin("senior", title_lower) || occursin("lead", title_lower)
        score += 10
    elseif occursin("manager", title_lower)
        score += 8
    else
        score += 5
    end
    
    # Decision maker access
    if decision_maker_level == "direct"
        score += 5
    elseif decision_maker_level == "indirect"
        score += 3
    end
    
    return min(25, score)
end

function calculate_need_score(lead_data::Dict{String, Any})::Int
    pain_points = get(lead_data, "pain_points", String[])
    current_solutions = get(lead_data, "current_solutions", String[])
    problem_severity = get(lead_data, "problem_severity", "medium")
    
    score = 0
    
    # Pain point alignment
    schema_related_pains = ["type_safety", "code_quality", "development_speed", "maintenance", "schema_management"]
    matching_pains = length(intersect(pain_points, schema_related_pains))
    score += min(15, matching_pains * 3)
    
    # Problem severity
    severity_scores = Dict("critical" => 10, "high" => 7, "medium" => 5, "low" => 2)
    score += get(severity_scores, problem_severity, 5)
    
    return min(25, score)
end

function calculate_timeline_score(lead_data::Dict{String, Any})::Int
    urgency_level = get(lead_data, "urgency_level", "medium")
    decision_timeline = get(lead_data, "decision_timeline", "unknown")
    
    score = 0
    
    # Urgency scoring
    urgency_scores = Dict("critical" => 15, "high" => 12, "medium" => 8, "low" => 4)
    score += get(urgency_scores, urgency_level, 8)
    
    # Timeline scoring
    timeline_scores = Dict("immediate" => 10, "1_month" => 8, "3_months" => 6, "6_months" => 4, "1_year" => 2)
    score += get(timeline_scores, decision_timeline, 4)
    
    return min(25, score)
end

function calculate_technical_fit_score(lead_data::Dict{String, Any})::Float64
    primary_languages = get(lead_data, "primary_languages", String[])
    tech_stack = get(lead_data, "tech_stack", String[])
    team_size = get(lead_data, "team_size", 0)
    
    schemantics_languages = ["julia", "rust", "typescript", "elixir"]
    language_match = length(intersect(lowercase.(primary_languages), schemantics_languages))
    
    fit_score = (language_match / max(1, length(primary_languages))) * 10
    
    # Team size adjustment
    if team_size >= 20
        fit_score *= 1.2
    elseif team_size >= 10
        fit_score *= 1.1
    end
    
    return min(10.0, fit_score)
end

function determine_priority_level(qualification_score::Int, fit_score::Float64)::String
    combined_score = qualification_score + (fit_score * 2)
    
    if combined_score >= 85
        return "Critical"
    elseif combined_score >= 70
        return "High"
    elseif combined_score >= 50
        return "Medium"
    else
        return "Low"
    end
end

function calculate_success_probability(qualification_score::Int, fit_score::Float64, lead_data::Dict{String, Any})::Float64
    base_probability = (qualification_score / 100.0) * 0.6 + (fit_score / 10.0) * 0.4
    
    # Adjust based on competitive situation
    competitive_situation = get(lead_data, "competitive_situation", "unknown")
    if competitive_situation == "preferred_vendor"
        base_probability *= 1.3
    elseif competitive_situation == "competitive_eval"
        base_probability *= 0.8
    elseif competitive_situation == "incumbent_replacement"
        base_probability *= 0.7
    end
    
    return min(1.0, base_probability) * 100  # Convert to percentage
end

function generate_qualification_actions(qualification_score::Int, fit_score::Float64, lead_data::Dict{String, Any})::Vector{String}
    actions = String[]
    
    if qualification_score >= 70
        push!(actions, "Schedule executive demo with technical deep dive")
        push!(actions, "Prepare customized ROI analysis")
        push!(actions, "Engage procurement team early")
    elseif qualification_score >= 50
        push!(actions, "Conduct discovery workshop")
        push!(actions, "Provide technical proof of concept")
        push!(actions, "Build champion relationship")
    else
        push!(actions, "Nurture with technical content")
        push!(actions, "Identify additional stakeholders")
        push!(actions, "Understand budget and timeline constraints")
    end
    
    if fit_score >= 8.0
        push!(actions, "Showcase language-specific benefits")
        push!(actions, "Connect with technical architecture team")
    end
    
    return actions
end

function generate_personalization_notes(lead_data::Dict{String, Any})::String
    company_name = get(lead_data, "company_name", "the company")
    industry = get(lead_data, "industry", "their industry")
    primary_languages = get(lead_data, "primary_languages", String[])
    
    notes = "Focus on $(company_name)'s specific use case in $industry. "
    
    if !isempty(primary_languages)
        notes *= "Emphasize benefits for their $(join(primary_languages, ", ")) development stack. "
    end
    
    notes *= "Prepare examples relevant to their technical challenges."
    
    return notes
end

function analyze_competitive_landscape(lead_data::Dict{String, Any})::String
    competitors = get(lead_data, "current_solutions", String[])
    
    if isempty(competitors)
        return "No current competitive solutions identified. Focus on status quo comparison."
    else
        return "Current solutions: $(join(competitors, ", ")). Prepare differentiation strategy."
    end
end

function generate_customized_proposal(customer_data::Dict{String, Any}, qualification_data::Dict{String, Any}, context::Dict{String, Any})::Dict{String, Any}
    company_size = get(customer_data, "team_size", 20)
    qualification_score = get(qualification_data, "qualification_score", 60)
    primary_languages = get(customer_data, "primary_languages", ["TypeScript"])
    
    # Calculate investment based on team size and complexity
    base_license_cost = company_size * 50  # $50 per user per month
    implementation_cost = base_license_cost * 2  # 2 months equivalent
    training_cost = company_size * 25  # $25 per user training
    
    total_investment = base_license_cost * 12 + implementation_cost + training_cost
    
    # Calculate ROI based on productivity improvements
    annual_dev_cost = company_size * 120000  # Average developer cost
    productivity_improvement = 0.15  # 15% improvement
    annual_savings = annual_dev_cost * productivity_improvement
    
    roi_percentage = ((annual_savings - (base_license_cost * 12)) / total_investment) * 100
    
    return Dict{String, Any}(
        "total_investment" => total_investment,
        "monthly_cost" => base_license_cost,
        "implementation_cost" => implementation_cost,
        "training_cost" => training_cost,
        "roi_percentage" => round(roi_percentage, digits=1),
        "annual_savings" => annual_savings,
        "payback_months" => round(total_investment / (annual_savings / 12), digits=1),
        "implementation_weeks" => max(8, round(company_size / 5) + 4),
        "success_probability" => min(95.0, 60.0 + (qualification_score - 50) * 0.5),
        "competitive_score" => rand(7.0:0.1:9.5),
        "primary_language" => first(primary_languages),
        "team_size" => company_size
    )
end

function generate_qualification_report(template::String, qualification_result::Dict{String, Any}, task::SubagentTask)::String
    report = template
    
    # Extract lead data from task
    lead_data = get(task.requirements, "lead_data", Dict{String, Any}())
    
    # Replace placeholders
    replacements = Dict{String, String}(
        "{lead_name}" => get(lead_data, "company_name", "Prospect"),
        "{company_name}" => get(lead_data, "company_name", "Prospect Company"),
        "{contact_name}" => get(lead_data, "contact_name", "Contact"),
        "{qualification_score}" => string(qualification_result["qualification_score"]),
        "{budget_score}" => string(qualification_result["budget_score"]),
        "{authority_score}" => string(qualification_result["authority_score"]),
        "{need_score}" => string(qualification_result["need_score"]),
        "{timeline_score}" => string(qualification_result["timeline_score"]),
        "{fit_score}" => string(round(qualification_result["fit_score"], digits=1)),
        "{success_probability}" => string(round(qualification_result["success_probability"], digits=1)),
        "{qualification_date}" => string(Date(now())),
        "{next_actions}" => join(qualification_result["next_actions"], "\n- "),
        "{personalization_notes}" => qualification_result["personalization_notes"],
        "{competitive_info}" => qualification_result["competitive_info"]
    )
    
    for (placeholder, value) in replacements
        report = replace(report, placeholder => value)
    end
    
    return report
end

function generate_proposal_document(template::String, proposal_result::Dict{String, Any}, task::SubagentTask)::String
    proposal = template
    
    # Extract customer data from task
    customer_data = get(task.requirements, "customer_data", Dict{String, Any}())
    
    # Replace placeholders
    replacements = Dict{String, String}(
        "{company_name}" => get(customer_data, "company_name", "Customer"),
        "{proposal_date}" => string(Date(now())),
        "{total_investment}" => string(proposal_result["total_investment"]),
        "{roi_percentage}" => string(proposal_result["roi_percentage"]),
        "{implementation_timeline}" => "$(proposal_result["implementation_weeks"]) weeks",
        "{primary_language}" => proposal_result["primary_language"],
        "{team_size}" => string(proposal_result["team_size"]),
        "{annual_savings}" => string(proposal_result["annual_savings"]),
        "{payback_months}" => string(proposal_result["payback_months"]),
        "{monthly_cost}" => string(proposal_result["monthly_cost"]),
        "{implementation_cost}" => string(proposal_result["implementation_cost"]),
        "{training_cost}" => string(proposal_result["training_cost"])
    )
    
    for (placeholder, value) in replacements
        proposal = replace(proposal, placeholder => value)
    end
    
    return proposal
end

function analyze_customer_success(customer_data::Dict{String, Any}, usage_data::Dict{String, Any}, context::Dict{String, Any})::Dict{String, Any}
    # Calculate health score components
    usage_score = calculate_usage_health(usage_data)
    engagement_score = calculate_engagement_health(usage_data)
    business_value_score = calculate_business_value_health(customer_data, usage_data)
    relationship_score = calculate_relationship_health(customer_data)
    
    # Calculate overall health score
    health_score = round(usage_score * 0.4 + engagement_score * 0.3 + business_value_score * 0.2 + relationship_score * 0.1)
    
    # Assess churn risk
    churn_risk = assess_churn_risk(health_score, usage_data)
    
    # Identify expansion opportunities
    expansion_potential = identify_expansion_opportunities(customer_data, usage_data, health_score)
    
    return Dict{String, Any}(
        "health_score" => health_score,
        "usage_score" => usage_score,
        "engagement_score" => engagement_score,
        "business_value_score" => business_value_score,
        "relationship_score" => relationship_score,
        "churn_risk" => churn_risk,
        "expansion_potential" => expansion_potential,
        "satisfaction_score" => rand(7.0:0.1:9.5),  # Simulated satisfaction
        "roi_achievement" => rand(80.0:1.0:150.0),  # ROI achievement percentage
        "recommendations" => generate_success_recommendations(health_score, churn_risk, expansion_potential)
    )
end

function calculate_usage_health(usage_data::Dict{String, Any})::Float64
    daily_active_users = get(usage_data, "daily_active_users", 0)
    total_users = get(usage_data, "total_users", 1)
    api_calls_monthly = get(usage_data, "api_calls_monthly", 0)
    feature_adoption_rate = get(usage_data, "feature_adoption_rate", 0.5)
    
    # Calculate usage health score out of 40
    dau_score = min(15.0, (daily_active_users / total_users) * 15)
    api_score = min(10.0, api_calls_monthly / 10000 * 10)  # Normalized to 10k calls
    adoption_score = feature_adoption_rate * 15
    
    return dau_score + api_score + adoption_score
end

function calculate_engagement_health(usage_data::Dict{String, Any})::Float64
    support_tickets = get(usage_data, "support_tickets_monthly", 5)
    doc_access = get(usage_data, "documentation_access_monthly", 10)
    community_engagement = get(usage_data, "community_engagement", 0.5)
    training_completion = get(usage_data, "training_completion", 0.7)
    
    # Calculate engagement health score out of 30
    support_score = max(0, 10 - support_tickets * 2)  # Fewer tickets is better
    doc_score = min(10.0, doc_access * 0.5)
    community_score = community_engagement * 5
    training_score = training_completion * 5
    
    return support_score + doc_score + community_score + training_score
end

function calculate_business_value_health(customer_data::Dict{String, Any}, usage_data::Dict{String, Any})::Float64
    roi_achievement = get(usage_data, "roi_achievement", 100.0) / 100.0  # Convert percentage to ratio
    milestones_completed = get(usage_data, "milestones_completed", 5)
    total_milestones = get(usage_data, "total_milestones", 8)
    
    # Calculate business value score out of 20
    roi_score = min(10.0, roi_achievement * 10)
    milestone_score = (milestones_completed / total_milestones) * 10
    
    return roi_score + milestone_score
end

function calculate_relationship_health(customer_data::Dict{String, Any})::Float64
    stakeholder_engagement = get(customer_data, "stakeholder_engagement", 7.0) / 10.0
    champion_strength = get(customer_data, "champion_strength", 8.0) / 10.0
    renewal_sentiment = get(customer_data, "renewal_sentiment", 7.5) / 10.0
    
    # Calculate relationship score out of 10
    return (stakeholder_engagement + champion_strength + renewal_sentiment) / 3 * 10
end

function assess_churn_risk(health_score::Float64, usage_data::Dict{String, Any})::String
    if health_score >= 80
        return "Low"
    elseif health_score >= 60
        return "Medium"
    elseif health_score >= 40
        return "High"
    else
        return "Critical"
    end
end

function identify_expansion_opportunities(customer_data::Dict{String, Any}, usage_data::Dict{String, Any}, health_score::Float64)::Float64
    team_size = get(customer_data, "team_size", 20)
    current_usage = get(usage_data, "feature_adoption_rate", 0.5)
    satisfaction = get(customer_data, "satisfaction_score", 8.0)
    
    # Calculate expansion potential in USD
    base_expansion = team_size * 50 * 12  # Current annual value
    
    if health_score >= 80 && satisfaction >= 8.0
        return base_expansion * 1.5  # 50% expansion potential
    elseif health_score >= 60 && satisfaction >= 7.0
        return base_expansion * 1.2  # 20% expansion potential
    else
        return base_expansion * 0.8  # Focus on retention
    end
end

function generate_success_recommendations(health_score::Float64, churn_risk::String, expansion_potential::Float64)::Vector{String}
    recommendations = String[]
    
    if churn_risk == "Critical" || churn_risk == "High"
        push!(recommendations, "Immediate intervention required - schedule executive review")
        push!(recommendations, "Conduct comprehensive success audit")
        push!(recommendations, "Implement dedicated customer success plan")
    end
    
    if health_score >= 80
        push!(recommendations, "Explore expansion opportunities")
        push!(recommendations, "Develop case study for reference")
        push!(recommendations, "Consider executive advocacy program")
    end
    
    if expansion_potential > 50000
        push!(recommendations, "Prepare expansion business case")
        push!(recommendations, "Schedule expansion discovery workshop")
    end
    
    return recommendations
end

function generate_success_report(template::String, success_analysis::Dict{String, Any}, task::SubagentTask)::String
    report = template
    
    # Extract customer data from task
    customer_data = get(task.requirements, "customer_data", Dict{String, Any}())
    
    # Replace placeholders
    replacements = Dict{String, String}(
        "{customer_name}" => get(customer_data, "company_name", "Customer"),
        "{health_score}" => string(round(success_analysis["health_score"])),
        "{churn_risk_level}" => success_analysis["churn_risk"],
        "{expansion_potential}" => string(round(success_analysis["expansion_potential"])),
        "{satisfaction_score}" => string(round(success_analysis["satisfaction_score"], digits=1)),
        "{roi_achievement}" => string(round(success_analysis["roi_achievement"], digits=1)),
        "{report_period}" => "Last 30 Days",
        "{recommendations}" => join(success_analysis["recommendations"], "\n- ")
    )
    
    for (placeholder, value) in replacements
        report = replace(report, placeholder => value)
    end
    
    return report
end

# High-performance concurrent operations
function qualify_leads(subagents::Vector{LeadQualifierSubagent}, lead_tasks::Vector{SubagentTask})::Vector{SubagentOutput}
    @info "Qualifying leads concurrently" leads_count=length(lead_tasks)
    
    results = @distributed (vcat) for i in 1:length(subagents)
        execute_task(subagents[i], lead_tasks[i])
    end
    
    qualified_leads = count(r -> get(r.metadata, "lead_priority", "Low") in ["High", "Critical"], results)
    @info "Lead qualification completed" qualified_count=qualified_leads total_leads=length(results)
    
    return results
end

function generate_proposals(subagents::Vector{ProposalGeneratorSubagent}, proposal_tasks::Vector{SubagentTask})::Vector{SubagentOutput}
    @info "Generating proposals concurrently" proposals_count=length(proposal_tasks)
    
    results = @distributed (vcat) for i in 1:length(subagents)
        execute_task(subagents[i], proposal_tasks[i])
    end
    
    successful_proposals = count(r -> r.status == COMPLETED, results)
    @info "Proposal generation completed" successful_count=successful_proposals total_proposals=length(results)
    
    return results
end

function monitor_customer_health(subagents::Vector{CustomerSuccessSubagent}, health_tasks::Vector{SubagentTask})::Vector{SubagentOutput}
    @info "Monitoring customer health concurrently" customers_count=length(health_tasks)
    
    results = @distributed (vcat) for i in 1:length(subagents)
        execute_task(subagents[i], health_tasks[i])
    end
    
    at_risk_customers = count(r -> get(r.metrics, "churn_risk", "Low") in ["High", "Critical"], results)
    expansion_opportunities = count(r -> get(r.metrics, "expansion_potential", 0) > 50000, results)
    
    @info "Customer health monitoring completed" at_risk=at_risk_customers expansions=expansion_opportunities total_customers=length(results)
    
    return results
end

# Get capabilities and templates for each subagent type
get_capabilities(subagent::LeadQualifierSubagent) = subagent.capabilities
get_capabilities(subagent::ProposalGeneratorSubagent) = subagent.capabilities
get_capabilities(subagent::CustomerSuccessSubagent) = subagent.capabilities

get_templates(subagent::LeadQualifierSubagent) = subagent.templates
get_templates(subagent::ProposalGeneratorSubagent) = subagent.templates
get_templates(subagent::CustomerSuccessSubagent) = subagent.templates

end # module SalesCustomerSuccessSubagents