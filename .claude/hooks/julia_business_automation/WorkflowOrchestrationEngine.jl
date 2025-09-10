"""
High-Performance Workflow Orchestration Engine for Schemantics
Concurrent multi-agent workflow coordination with schema-stacked intelligence
"""

module WorkflowOrchestrationEngine

using JSON3
using UUIDs
using Dates
using DataFrames
using Distributed
using Logging

include("BusinessSubagentFramework.jl")
using .BusinessSubagentFramework

include("Subagents/MarketingSubagents.jl")
using .MarketingSubagents

include("Subagents/SalesCustomerSuccessSubagents.jl")
using .SalesCustomerSuccessSubagents

export WorkflowEngine, SchemaStackedWorkflow, WorkflowStep, execute_workflow, create_predefined_workflows
export WorkflowStatus, WorkflowMetrics, BusinessWorkflowTemplate

@enum WorkflowStatus begin
    PENDING = 1
    RUNNING = 2
    COMPLETED = 3
    FAILED = 4
    PAUSED = 5
    CANCELLED = 6
end

struct WorkflowStep
    step_id::String
    agent_type::String
    task_description::String
    dependencies::Vector{String}
    timeout_seconds::Int
    retry_count::Int
    conditions::Dict{String, Any}
    output_mapping::Dict{String, String}
    schema_requirements::Dict{String, Any}
    
    function WorkflowStep(
        step_id::String,
        agent_type::String,
        task_description::String,
        dependencies::Vector{String} = String[],
        timeout_seconds::Int = 1800,  # 30 minutes default
        retry_count::Int = 3,
        conditions::Dict{String, Any} = Dict{String, Any}(),
        output_mapping::Dict{String, String} = Dict{String, String}(),
        schema_requirements::Dict{String, Any} = Dict{String, Any}()
    )
        new(step_id, agent_type, task_description, dependencies, timeout_seconds, 
            retry_count, conditions, output_mapping, schema_requirements)
    end
end

mutable struct SchemaStackedWorkflow
    workflow_id::String
    name::String
    description::String
    domain::BusinessDomain
    priority::TaskPriority
    steps::Vector{WorkflowStep}
    success_criteria::Dict{String, Any}
    failure_conditions::Dict{String, Any}
    schema_requirements::Dict{String, Any}
    business_context::BusinessContext
    estimated_duration_minutes::Int
    
    # Execution tracking
    status::WorkflowStatus
    started_at::Union{DateTime, Nothing}
    completed_at::Union{DateTime, Nothing}
    current_step::Union{String, Nothing}
    execution_log::Vector{Dict{String, Any}}
    step_outputs::Dict{String, Any}
    performance_metrics::Dict{String, Any}
    
    function SchemaStackedWorkflow(
        workflow_id::String,
        name::String,
        description::String,
        domain::BusinessDomain,
        priority::TaskPriority,
        steps::Vector{WorkflowStep},
        success_criteria::Dict{String, Any} = Dict{String, Any}(),
        failure_conditions::Dict{String, Any} = Dict{String, Any}(),
        schema_requirements::Dict{String, Any} = Dict{String, Any}(),
        business_context::BusinessContext = BusinessContext(),
        estimated_duration_minutes::Int = length(steps) * 30
    )
        new(workflow_id, name, description, domain, priority, steps,
            success_criteria, failure_conditions, schema_requirements, 
            business_context, estimated_duration_minutes,
            PENDING, nothing, nothing, nothing, Dict{String, Any}[], 
            Dict{String, Any}(), Dict{String, Any}())
    end
end

struct WorkflowMetrics
    total_execution_time_ms::Int64
    successful_steps::Int
    failed_steps::Int
    retry_count::Int
    schema_compliance_score::Float64
    performance_score::Float64
    cost_efficiency::Float64
    
    function WorkflowMetrics(
        total_execution_time_ms::Int64,
        successful_steps::Int,
        failed_steps::Int,
        retry_count::Int = 0,
        schema_compliance_score::Float64 = 1.0,
        performance_score::Float64 = 0.0,
        cost_efficiency::Float64 = 0.0
    )
        new(total_execution_time_ms, successful_steps, failed_steps, retry_count,
            schema_compliance_score, performance_score, cost_efficiency)
    end
end

struct BusinessWorkflowTemplate
    template_id::String
    name::String
    description::String
    domain::BusinessDomain
    trigger_patterns::Vector{String}
    step_templates::Vector{WorkflowStep}
    success_metrics::Dict{String, Any}
    estimated_value::Float64
    
    function BusinessWorkflowTemplate(
        template_id::String,
        name::String,
        description::String,
        domain::BusinessDomain,
        trigger_patterns::Vector{String},
        step_templates::Vector{WorkflowStep},
        success_metrics::Dict{String, Any} = Dict{String, Any}(),
        estimated_value::Float64 = 1000.0
    )
        new(template_id, name, description, domain, trigger_patterns, 
            step_templates, success_metrics, estimated_value)
    end
end

mutable struct WorkflowEngine
    config::Dict{String, Any}
    active_workflows::Dict{String, SchemaStackedWorkflow}
    workflow_history::Vector{SchemaStackedWorkflow}
    subagent_registry::Dict{String, Function}
    performance_data::Dict{String, Any}
    schema_patterns::Dict{String, Any}
    
    function WorkflowEngine()
        config = load_workflow_config()
        subagent_registry = initialize_subagent_registry()
        performance_data = load_performance_data()
        schema_patterns = load_schema_patterns()
        
        new(config, Dict{String, SchemaStackedWorkflow}(), SchemaStackedWorkflow[],
            subagent_registry, performance_data, schema_patterns)
    end
end

function load_workflow_config()::Dict{String, Any}
    config_file = "/home/ubuntu/.claude/hooks/julia_business_automation/workflow_config.json"
    
    if isfile(config_file)
        try
            return JSON3.read(read(config_file, String), Dict{String, Any})
        catch e
            @warn "Failed to load workflow config" error=e
        end
    end
    
    # Default configuration
    default_config = Dict{String, Any}(
        "max_concurrent_workflows" => 8,
        "max_concurrent_steps" => 12,
        "default_timeout_seconds" => 1800,
        "retry_delays_seconds" => [30, 120, 300],
        "schema_validation" => true,
        "auto_dependency_resolution" => true,
        "failure_escalation" => true,
        "performance_monitoring" => true,
        "parallel_execution" => true,
        "distributed_processing" => true
    )
    
    # Save default config
    open(config_file, "w") do io
        JSON3.write(io, default_config)
    end
    
    return default_config
end

function initialize_subagent_registry()::Dict{String, Function}
    return Dict{String, Function}(
        # Marketing subagents
        "email-campaign" => create_email_campaign_subagent,
        "seo-optimizer" => create_seo_optimizer_subagent,
        "analytics-tracker" => create_analytics_tracker_subagent,
        "social-media" => create_social_media_subagent,
        
        # Sales & Customer Success subagents
        "lead-qualifier" => create_lead_qualifier_subagent,
        "proposal-generator" => create_proposal_generator_subagent,
        "customer-success" => create_customer_success_subagent,
        
        # Core Claude Code subagents (shell integration)
        "devin-software-engineer" => create_devin_integration,
        "v0-ui-generator" => create_v0_integration,
        "corki-coverage-guardian" => create_corki_integration,
        "veigar-security-reviewer" => create_veigar_integration,
        "general-purpose" => create_general_purpose_integration
    )
end

# Subagent creation functions
function create_email_campaign_subagent()
    return EmailCampaignSubagent()
end

function create_seo_optimizer_subagent()
    return SEOOptimizerSubagent()
end

function create_analytics_tracker_subagent()
    return AnalyticsTrackerSubagent()
end

function create_social_media_subagent()
    return SocialMediaSubagent()
end

function create_lead_qualifier_subagent()
    return LeadQualifierSubagent()
end

function create_proposal_generator_subagent()
    return ProposalGeneratorSubagent()
end

function create_customer_success_subagent()
    return CustomerSuccessSubagent()
end

# Claude Code subagent integrations (shell command wrappers)
function create_devin_integration()
    return (task::SubagentTask) -> execute_claude_code_subagent("devin-software-engineer", task)
end

function create_v0_integration()
    return (task::SubagentTask) -> execute_claude_code_subagent("v0-ui-generator", task)
end

function create_corki_integration()
    return (task::SubagentTask) -> execute_claude_code_subagent("corki-coverage-guardian", task)
end

function create_veigar_integration()
    return (task::SubagentTask) -> execute_claude_code_subagent("veigar-security-reviewer", task)
end

function create_general_purpose_integration()
    return (task::SubagentTask) -> execute_claude_code_subagent("general-purpose", task)
end

function execute_claude_code_subagent(agent_type::String, task::SubagentTask)::SubagentOutput
    start_time = time_ns()
    
    try
        # Create task JSON for Claude Code
        task_json = JSON3.write(Dict{String, Any}(
            "description" => task.description,
            "context" => task.context,
            "requirements" => task.requirements,
            "success_criteria" => task.success_criteria
        ))
        
        # Execute Claude Code subagent via task tool
        cmd = `claude task $agent_type $task_json`
        result = read(cmd, String)
        
        # Parse result
        try
            parsed_result = JSON3.read(result, Dict{String, Any})
            execution_time = (time_ns() - start_time) ÷ 1_000_000
            
            return SubagentOutput(
                task.task_id,
                COMPLETED,
                get(parsed_result, "content", result),
                TEXT,
                Dict{String, Any}("agent_type" => agent_type),
                Dict{String, Any}("claude_code_execution" => true),
                String[],
                now(),
                execution_time,
                1.0
            )
        catch
            # Fallback for non-JSON responses
            execution_time = (time_ns() - start_time) ÷ 1_000_000
            return SubagentOutput(
                task.task_id,
                COMPLETED,
                result,
                TEXT,
                Dict{String, Any}("agent_type" => agent_type),
                Dict{String, Any}("claude_code_execution" => true),
                String[],
                now(),
                execution_time,
                1.0
            )
        end
        
    catch e
        execution_time = (time_ns() - start_time) ÷ 1_000_000
        return SubagentOutput(
            task.task_id, FAILED, "Claude Code subagent execution failed: $e", TEXT,
            Dict("error" => string(e)), Dict{String, Any}(), String[],
            now(), execution_time, 0.0
        )
    end
end

function load_performance_data()::Dict{String, Any}
    performance_file = "/home/ubuntu/.claude/hooks/julia_business_automation/performance_data.json"
    
    if isfile(performance_file)
        try
            return JSON3.read(read(performance_file, String), Dict{String, Any})
        catch
            return Dict{String, Any}()
        end
    end
    
    return Dict{String, Any}()
end

function load_schema_patterns()::Dict{String, Any}
    patterns_file = "/home/ubuntu/.claude/hooks/julia_business_automation/schema_patterns.json"
    
    if isfile(patterns_file)
        try
            return JSON3.read(read(patterns_file, String), Dict{String, Any})
        catch
        end
    end
    
    # Default schema patterns for high-performance workflows
    default_patterns = Dict{String, Any}(
        "data_flow_schemas" => Dict{String, Any}(
            "customer_acquisition_flow" => Dict{String, Any}(
                "input_schema" => Dict{String, Any}(
                    "lead_data" => Dict("type" => "object", "required" => ["contact_info", "company", "interest_level"]),
                    "qualification_criteria" => Dict("type" => "object", "required" => ["budget", "timeline", "decision_maker"])
                ),
                "intermediate_schemas" => Dict{String, Any}(
                    "qualified_lead" => Dict("type" => "object", "required" => ["score", "stage", "next_action"]),
                    "content_created" => Dict("type" => "object", "required" => ["content_type", "target_audience", "distribution_channels"]),
                    "campaigns_launched" => Dict("type" => "object", "required" => ["email_campaign", "social_campaign", "performance_tracking"])
                ),
                "output_schema" => Dict{String, Any}(
                    "customer" => Dict("type" => "object", "required" => ["account_id", "onboarding_plan", "success_metrics"])
                )
            ),
            
            "product_launch_flow" => Dict{String, Any}(
                "input_schema" => Dict{String, Any}(
                    "product_info" => Dict("type" => "object", "required" => ["name", "features", "target_audience", "pricing"]),
                    "launch_timeline" => Dict("type" => "object", "required" => ["announcement_date", "availability_date", "marketing_duration"])
                ),
                "intermediate_schemas" => Dict{String, Any}(
                    "content_assets" => Dict("type" => "object", "required" => ["announcement_content", "feature_descriptions", "technical_documentation"]),
                    "marketing_campaigns" => Dict("type" => "object", "required" => ["email_sequences", "social_campaigns", "seo_content"]),
                    "launch_coordination" => Dict("type" => "object", "required" => ["synchronized_publishing", "performance_monitoring", "feedback_collection"])
                ),
                "output_schema" => Dict{String, Any}(
                    "launch_results" => Dict("type" => "object", "required" => ["performance_metrics", "customer_feedback", "revenue_impact"])
                )
            )
        ),
        
        "performance_optimization" => Dict{String, Any}(
            "concurrent_execution" => Dict{String, Any}(
                "max_parallel_steps" => 12,
                "step_timeout_multiplier" => 1.5,
                "retry_backoff_factor" => 2.0,
                "memory_optimization" => true
            ),
            "schema_validation" => Dict{String, Any}(
                "compile_time_validation" => true,
                "runtime_validation" => true,
                "validation_cache" => true,
                "schema_evolution" => true
            )
        ),
        
        "business_metrics" => Dict{String, Any}(
            "success_criteria" => Dict{String, Any}(
                "min_completion_rate" => 0.85,
                "max_execution_time_variance" => 0.3,
                "min_schema_compliance" => 0.95,
                "max_error_rate" => 0.05
            ),
            "performance_targets" => Dict{String, Any}(
                "avg_step_execution_ms" => 30000,
                "workflow_throughput_per_hour" => 10,
                "resource_utilization_target" => 0.75
            )
        )
    )
    
    # Save default patterns
    open(patterns_file, "w") do io
        JSON3.write(io, default_patterns)
    end
    
    return default_patterns
end

function execute_workflow(engine::WorkflowEngine, workflow::SchemaStackedWorkflow)::WorkflowMetrics
    @info "Starting workflow execution" workflow_id=workflow.workflow_id name=workflow.name steps=length(workflow.steps)
    
    workflow.status = RUNNING
    workflow.started_at = now()
    engine.active_workflows[workflow.workflow_id] = workflow
    
    try
        # Execute workflow steps with dependency resolution and parallelization
        step_results = execute_workflow_steps(engine, workflow)
        
        # Calculate performance metrics
        metrics = calculate_workflow_metrics(workflow, step_results)
        
        # Validate success criteria
        workflow.status = validate_workflow_success(workflow, step_results, metrics) ? COMPLETED : FAILED
        workflow.completed_at = now()
        
        # Update performance data
        update_performance_data(engine, workflow, metrics)
        
        # Clean up active workflow
        delete!(engine.active_workflows, workflow.workflow_id)
        push!(engine.workflow_history, workflow)
        
        @info "Workflow execution completed" workflow_id=workflow.workflow_id status=workflow.status duration_ms=metrics.total_execution_time_ms
        
        return metrics
        
    catch e
        workflow.status = FAILED
        workflow.completed_at = now()
        
        # Log error
        push!(workflow.execution_log, Dict{String, Any}(
            "timestamp" => now(),
            "event" => "workflow_error",
            "error" => string(e),
            "stack_trace" => string(stacktrace())
        ))
        
        @error "Workflow execution failed" workflow_id=workflow.workflow_id error=e
        
        # Clean up
        delete!(engine.active_workflows, workflow.workflow_id)
        push!(engine.workflow_history, workflow)
        
        return WorkflowMetrics(0, 0, length(workflow.steps), 0, 0.0, 0.0, 0.0)
    end
end

function execute_workflow_steps(engine::WorkflowEngine, workflow::SchemaStackedWorkflow)::Dict{String, SubagentOutput}
    step_results = Dict{String, SubagentOutput}()
    completed_steps = Set{String}()
    pending_steps = Dict(step.step_id => step for step in workflow.steps)
    
    max_iterations = length(workflow.steps) * 2  # Prevent infinite loops
    iteration = 0
    
    while !isempty(pending_steps) && iteration < max_iterations
        iteration += 1
        
        # Find steps ready to execute (dependencies satisfied)
        ready_steps = filter(step -> all(dep in completed_steps for dep in step.second.dependencies), pending_steps)
        
        if isempty(ready_steps)
            # Check for circular dependencies
            remaining_deps = Set{String}()
            for step in values(pending_steps)
                union!(remaining_deps, step.dependencies)
            end
            
            if issubset(remaining_deps, Set(keys(pending_steps)))
                throw(ErrorException("Circular dependency detected in workflow steps"))
            else
                throw(ErrorException("Unresolvable dependencies in workflow steps"))
            end
        end
        
        # Execute ready steps concurrently for maximum performance
        if engine.config["parallel_execution"]
            step_futures = []
            
            for (step_id, step) in ready_steps
                future = @spawn execute_single_workflow_step(engine, workflow, step, step_results)
                push!(step_futures, (step_id, future))
            end
            
            # Collect results
            for (step_id, future) in step_futures
                try
                    result = fetch(future)
                    step_results[step_id] = result
                    push!(completed_steps, step_id)
                    delete!(pending_steps, step_id)
                    
                    # Log step completion
                    push!(workflow.execution_log, Dict{String, Any}(
                        "timestamp" => now(),
                        "event" => "step_completed",
                        "step_id" => step_id,
                        "status" => string(result.status),
                        "execution_time_ms" => result.execution_time_ms
                    ))
                    
                catch e
                    # Step failed
                    failed_output = SubagentOutput(
                        step_id, FAILED, "Step execution failed: $e", TEXT,
                        Dict("error" => string(e)), Dict{String, Any}(), String[],
                        now(), 0, 0.0
                    )
                    
                    step_results[step_id] = failed_output
                    push!(completed_steps, step_id)
                    delete!(pending_steps, step_id)
                    
                    @error "Workflow step failed" workflow_id=workflow.workflow_id step_id=step_id error=e
                end
            end
        else
            # Sequential execution
            for (step_id, step) in ready_steps
                try
                    result = execute_single_workflow_step(engine, workflow, step, step_results)
                    step_results[step_id] = result
                    push!(completed_steps, step_id)
                    delete!(pending_steps, step_id)
                    
                    push!(workflow.execution_log, Dict{String, Any}(
                        "timestamp" => now(),
                        "event" => "step_completed",
                        "step_id" => step_id,
                        "status" => string(result.status),
                        "execution_time_ms" => result.execution_time_ms
                    ))
                    
                catch e
                    failed_output = SubagentOutput(
                        step_id, FAILED, "Step execution failed: $e", TEXT,
                        Dict("error" => string(e)), Dict{String, Any}(), String[],
                        now(), 0, 0.0
                    )
                    
                    step_results[step_id] = failed_output
                    push!(completed_steps, step_id)
                    delete!(pending_steps, step_id)
                    
                    @error "Workflow step failed" workflow_id=workflow.workflow_id step_id=step_id error=e
                end
            end
        end
    end
    
    return step_results
end

function execute_single_workflow_step(engine::WorkflowEngine, workflow::SchemaStackedWorkflow, step::WorkflowStep, previous_outputs::Dict{String, SubagentOutput})::SubagentOutput
    workflow.current_step = step.step_id
    
    # Prepare task input with schema stacking
    task_input = prepare_schema_stacked_task(workflow, step, previous_outputs)
    
    # Get subagent for this step
    if !haskey(engine.subagent_registry, step.agent_type)
        throw(ErrorException("Unknown subagent type: $(step.agent_type)"))
    end
    
    subagent_creator = engine.subagent_registry[step.agent_type]
    
    # Execute with retries and timeout
    for attempt in 1:step.retry_count
        try
            # Create subagent instance
            if step.agent_type in ["devin-software-engineer", "v0-ui-generator", "corki-coverage-guardian", "veigar-security-reviewer", "general-purpose"]
                # Claude Code integration
                subagent_func = subagent_creator()
                result = subagent_func(task_input)
            else
                # Julia subagent
                subagent = subagent_creator()
                result = execute_task(subagent, task_input)
            end
            
            # Validate schema compliance
            if engine.config["schema_validation"]
                if !validate_step_output_schema(workflow, step, result)
                    throw(ErrorException("Step output does not meet schema requirements"))
                end
            end
            
            return result
            
        catch e
            if attempt == step.retry_count
                rethrow(e)
            end
            
            # Wait before retry
            retry_delays = engine.config["retry_delays_seconds"]
            delay_index = min(attempt, length(retry_delays))
            sleep(retry_delays[delay_index])
            
            @warn "Step execution attempt failed, retrying" workflow_id=workflow.workflow_id step_id=step.step_id attempt=attempt error=e
        end
    end
end

function prepare_schema_stacked_task(workflow::SchemaStackedWorkflow, step::WorkflowStep, previous_outputs::Dict{String, SubagentOutput})::SubagentTask
    # Create comprehensive task with schema-aligned inputs
    task = SubagentTask(
        "$(workflow.workflow_id)_$(step.step_id)",
        step.task_description,
        workflow.domain,
        workflow.priority,
        nothing,  # deadline
        Dict{String, Any}(
            "workflow_id" => workflow.workflow_id,
            "workflow_name" => workflow.name,
            "business_context" => workflow.business_context,
            "step_position" => "$(findfirst(s -> s.step_id == step.step_id, workflow.steps))/$(length(workflow.steps))"
        ),
        Dict{String, Any}(),  # requirements
        get(workflow.success_criteria, step.step_id, Dict{String, Any}()),
        step.schema_requirements
    )
    
    # Add dependency outputs with schema mapping
    for dep_id in step.dependencies
        if haskey(previous_outputs, dep_id)
            mapped_key = get(step.output_mapping, dep_id, "$(dep_id)_output")
            
            # Extract relevant data from previous output
            dep_output = previous_outputs[dep_id]
            task.requirements[mapped_key] = Dict{String, Any}(
                "content" => dep_output.content,
                "metadata" => dep_output.metadata,
                "metrics" => dep_output.metrics,
                "format" => string(dep_output.format)
            )
        end
    end
    
    # Add step-specific conditions
    for (key, value) in step.conditions
        task.requirements[key] = value
    end
    
    return task
end

function validate_step_output_schema(workflow::SchemaStackedWorkflow, step::WorkflowStep, output::SubagentOutput)::Bool
    # Basic schema validation - can be extended with more sophisticated validation
    if output.status != COMPLETED
        return false  # Failed steps don't meet schema requirements
    end
    
    # Check required fields
    schema_reqs = step.schema_requirements
    required_fields = get(schema_reqs, "required_fields", String[])
    
    for field in required_fields
        if !haskey(output.metadata, field)
            @warn "Missing required field in output" field=field step_id=step.step_id
            return false
        end
    end
    
    # Check output format requirements
    expected_format = get(schema_reqs, "output_format", nothing)
    if expected_format !== nothing && string(output.format) != expected_format
        @warn "Output format mismatch" expected=expected_format actual=string(output.format) step_id=step.step_id
        return false
    end
    
    # Validate business context compliance
    if haskey(workflow.schema_requirements, "business_context_required") && 
       workflow.schema_requirements["business_context_required"]
        if !haskey(output.metadata, "business_impact") || 
           !haskey(output.metadata, "target_audience")
            @warn "Missing business context in output" step_id=step.step_id
            return false
        end
    end
    
    return true
end

function calculate_workflow_metrics(workflow::SchemaStackedWorkflow, step_results::Dict{String, SubagentOutput})::WorkflowMetrics
    if isempty(step_results)
        return WorkflowMetrics(0, 0, 0)
    end
    
    # Calculate execution time
    total_execution_time = sum([result.execution_time_ms for result in values(step_results)])
    
    # Count successful and failed steps
    successful_steps = count(result -> result.status == COMPLETED, values(step_results))
    failed_steps = count(result -> result.status == FAILED, values(step_results))
    
    # Calculate schema compliance score
    schema_scores = [result.schema_compliance_score for result in values(step_results)]
    schema_compliance_score = isempty(schema_scores) ? 0.0 : sum(schema_scores) / length(schema_scores)
    
    # Calculate performance score (based on execution time vs estimates)
    estimated_time = workflow.estimated_duration_minutes * 60 * 1000  # Convert to milliseconds
    performance_score = estimated_time > 0 ? max(0.0, min(1.0, estimated_time / total_execution_time)) : 0.0
    
    # Calculate cost efficiency (successful steps / total execution time)
    cost_efficiency = total_execution_time > 0 ? (successful_steps * 1000.0) / total_execution_time : 0.0
    
    return WorkflowMetrics(
        total_execution_time,
        successful_steps,
        failed_steps,
        0,  # retry_count - would need to track this separately
        schema_compliance_score,
        performance_score,
        cost_efficiency
    )
end

function validate_workflow_success(workflow::SchemaStackedWorkflow, step_results::Dict{String, SubagentOutput}, metrics::WorkflowMetrics)::Bool
    # Check minimum success criteria
    min_successful_steps = get(workflow.success_criteria, "min_successful_steps", length(workflow.steps))
    if metrics.successful_steps < min_successful_steps
        @warn "Insufficient successful steps" successful=metrics.successful_steps required=min_successful_steps
        return false
    end
    
    # Check required outputs
    required_outputs = get(workflow.success_criteria, "required_outputs", String[])
    for required_output in required_outputs
        if !haskey(step_results, required_output) || step_results[required_output].status != COMPLETED
            @warn "Required output missing or failed" output=required_output
            return false
        end
    end
    
    # Check schema compliance threshold
    min_schema_compliance = get(workflow.success_criteria, "min_schema_compliance", 0.90)
    if metrics.schema_compliance_score < min_schema_compliance
        @warn "Schema compliance below threshold" compliance=metrics.schema_compliance_score required=min_schema_compliance
        return false
    end
    
    # Check performance requirements
    max_execution_time = get(workflow.success_criteria, "max_execution_time_ms", workflow.estimated_duration_minutes * 60 * 1000 * 2)
    if metrics.total_execution_time_ms > max_execution_time
        @warn "Execution time exceeded threshold" actual=metrics.total_execution_time_ms max=max_execution_time
        return false
    end
    
    return true
end

function update_performance_data(engine::WorkflowEngine, workflow::SchemaStackedWorkflow, metrics::WorkflowMetrics)
    # Update workflow performance statistics
    workflow_type = "$(workflow.domain)_$(workflow.name)"
    
    if !haskey(engine.performance_data, workflow_type)
        engine.performance_data[workflow_type] = Dict{String, Any}(
            "executions" => 0,
            "successful_executions" => 0,
            "total_execution_time_ms" => 0,
            "avg_execution_time_ms" => 0.0,
            "success_rate" => 0.0,
            "avg_schema_compliance" => 0.0
        )
    end
    
    perf_data = engine.performance_data[workflow_type]
    perf_data["executions"] += 1
    
    if workflow.status == COMPLETED
        perf_data["successful_executions"] += 1
    end
    
    perf_data["total_execution_time_ms"] += metrics.total_execution_time_ms
    perf_data["avg_execution_time_ms"] = perf_data["total_execution_time_ms"] / perf_data["executions"]
    perf_data["success_rate"] = perf_data["successful_executions"] / perf_data["executions"]
    
    # Update schema compliance average
    current_compliance = perf_data["avg_schema_compliance"]
    perf_data["avg_schema_compliance"] = (current_compliance * (perf_data["executions"] - 1) + metrics.schema_compliance_score) / perf_data["executions"]
    
    # Save updated performance data
    performance_file = "/home/ubuntu/.claude/hooks/julia_business_automation/performance_data.json"
    open(performance_file, "w") do io
        JSON3.write(io, engine.performance_data)
    end
end

function create_predefined_workflows()::Dict{String, BusinessWorkflowTemplate}
    templates = Dict{String, BusinessWorkflowTemplate}()
    
    # Customer Acquisition Workflow Template
    templates["customer_acquisition"] = BusinessWorkflowTemplate(
        "customer_acquisition_flow",
        "End-to-End Customer Acquisition",
        "Complete customer acquisition from content creation to onboarding",
        MARKETING,
        ["new lead", "prospect identified", "customer acquisition", "lead generation"],
        [
            WorkflowStep(
                "content_creation",
                "email-campaign", 
                "Create lead magnet content and nurture sequences",
                String[],
                1800,
                3,
                Dict{String, Any}("campaign_type" => "lead_magnet"),
                Dict{String, String}(),
                Dict{String, Any}("required_fields" => ["content", "target_audience"])
            ),
            WorkflowStep(
                "seo_optimization",
                "seo-optimizer",
                "Optimize content for search engines and lead generation",
                ["content_creation"],
                1200,
                2,
                Dict{String, Any}("optimization_type" => "lead_generation"),
                Dict{String, String}("content_creation" => "content_to_optimize"),
                Dict{String, Any}("required_fields" => ["keywords_optimized", "seo_score"])
            ),
            WorkflowStep(
                "social_promotion", 
                "social-media",
                "Create social media promotion campaign",
                ["content_creation"],
                900,
                2,
                Dict{String, Any}("platform" => "linkedin", "content_type" => "lead_generation"),
                Dict{String, String}("content_creation" => "content_to_promote"),
                Dict{String, Any}("required_fields" => ["posts_created", "estimated_reach"])
            ),
            WorkflowStep(
                "analytics_setup",
                "analytics-tracker",
                "Set up tracking and analytics for lead generation campaigns",
                ["seo_optimization", "social_promotion"],
                600,
                2,
                Dict{String, Any}("analysis_type" => "lead_tracking"),
                Dict{String, String}(),
                Dict{String, Any}("required_fields" => ["tracking_setup", "conversion_funnel"])
            ),
            WorkflowStep(
                "lead_qualification",
                "lead-qualifier",
                "Set up automated lead qualification and scoring",
                ["analytics_setup"],
                1800,
                3,
                Dict{String, Any}("qualification_type" => "automated_scoring"),
                Dict{String, String}("analytics_setup" => "tracking_data"),
                Dict{String, Any}("required_fields" => ["scoring_criteria", "qualification_process"])
            ),
            WorkflowStep(
                "customer_onboarding",
                "customer-success",
                "Create customer onboarding and success processes",
                ["lead_qualification"],
                2400,
                2,
                Dict{String, Any}("success_type" => "onboarding_plan"),
                Dict{String, String}("lead_qualification" => "qualified_leads"),
                Dict{String, Any}("required_fields" => ["onboarding_plan", "success_metrics"])
            )
        ],
        Dict{String, Any}(
            "min_successful_steps" => 5,
            "required_outputs" => ["content_creation", "lead_qualification", "customer_onboarding"],
            "min_schema_compliance" => 0.90,
            "max_execution_time_ms" => 480000  # 8 minutes
        ),
        2500.0  # Estimated value
    )
    
    # Product Launch Campaign Template
    templates["product_launch"] = BusinessWorkflowTemplate(
        "product_launch_campaign",
        "Complete Product Launch Campaign",
        "Coordinated multi-channel product launch with performance tracking",
        MARKETING,
        ["product launch", "feature announcement", "new release", "launch campaign"],
        [
            WorkflowStep(
                "launch_content",
                "email-campaign",
                "Create product launch announcement and email campaigns",
                String[],
                2400,
                2,
                Dict{String, Any}("campaign_type" => "product_announcement"),
                Dict{String, String}(),
                Dict{String, Any}("required_fields" => ["announcement_content", "email_sequence"])
            ),
            WorkflowStep(
                "launch_seo",
                "seo-optimizer",
                "Optimize launch content for maximum visibility",
                ["launch_content"],
                1800,
                2,
                Dict{String, Any}("optimization_type" => "product_launch"),
                Dict{String, String}("launch_content" => "content_to_optimize"),
                Dict{String, Any}("required_fields" => ["seo_optimized_content", "keyword_strategy"])
            ),
            WorkflowStep(
                "social_campaign",
                "social-media",
                "Create comprehensive social media launch campaign",
                ["launch_content"],
                1200,
                2,
                Dict{String, Any}("content_type" => "social_campaign", "platform" => "multi_platform"),
                Dict{String, String}("launch_content" => "content_base"),
                Dict{String, Any}("required_fields" => ["social_posts", "campaign_schedule"])
            ),
            WorkflowStep(
                "launch_analytics",
                "analytics-tracker",
                "Set up comprehensive launch performance tracking",
                ["launch_seo", "social_campaign"],
                900,
                2,
                Dict{String, Any}("analysis_type" => "product_launch_tracking"),
                Dict{String, String}(),
                Dict{String, Any}("required_fields" => ["performance_dashboard", "success_metrics"])
            )
        ],
        Dict{String, Any}(
            "min_successful_steps" => 3,
            "required_outputs" => ["launch_content", "social_campaign", "launch_analytics"],
            "min_schema_compliance" => 0.95,
            "max_execution_time_ms" => 360000  # 6 minutes
        ),
        1800.0
    )
    
    # Customer Expansion Workflow Template
    templates["customer_expansion"] = BusinessWorkflowTemplate(
        "customer_expansion_flow",
        "Customer Expansion and Upsell Campaign",
        "Identify and execute customer expansion opportunities",
        SALES,
        ["customer expansion", "upsell opportunity", "account growth", "expansion potential"],
        [
            WorkflowStep(
                "expansion_analysis",
                "customer-success",
                "Analyze customer health and expansion opportunities",
                String[],
                1800,
                2,
                Dict{String, Any}("success_type" => "expansion_opportunity"),
                Dict{String, String}(),
                Dict{String, Any}("required_fields" => ["expansion_potential", "health_score"])
            ),
            WorkflowStep(
                "proposal_generation",
                "proposal-generator", 
                "Create customized expansion proposals",
                ["expansion_analysis"],
                3600,
                2,
                Dict{String, Any}("proposal_type" => "expansion_proposal"),
                Dict{String, String}("expansion_analysis" => "expansion_data"),
                Dict{String, Any}("required_fields" => ["proposal_content", "roi_analysis"])
            ),
            WorkflowStep(
                "outreach_campaign",
                "email-campaign",
                "Execute personalized expansion outreach",
                ["proposal_generation"],
                1200,
                2,
                Dict{String, Any}("campaign_type" => "expansion_outreach"),
                Dict{String, String}("proposal_generation" => "proposal_content"),
                Dict{String, Any}("required_fields" => ["outreach_sequence", "personalization"])
            ),
            WorkflowStep(
                "success_tracking",
                "analytics-tracker",
                "Track expansion campaign performance and success",
                ["outreach_campaign"],
                900,
                2,
                Dict{String, Any}("analysis_type" => "expansion_tracking"),
                Dict{String, String}(),
                Dict{String, Any}("required_fields" => ["conversion_tracking", "roi_measurement"])
            )
        ],
        Dict{String, Any}(
            "min_successful_steps" => 3,
            "required_outputs" => ["expansion_analysis", "proposal_generation", "success_tracking"],
            "min_schema_compliance" => 0.90,
            "max_execution_time_ms" => 450000  # 7.5 minutes
        ),
        5000.0
    )
    
    return templates
end

function create_workflow_from_template(template::BusinessWorkflowTemplate, context_data::Dict{String, Any} = Dict{String, Any}())::SchemaStackedWorkflow
    workflow_id = "$(template.template_id)_$(string(uuid4())[1:8])_$(Dates.format(now(), "yyyymmdd_HHMMSS"))"
    
    # Customize steps based on context
    customized_steps = WorkflowStep[]
    for step_template in template.step_templates
        # Add context-specific modifications to step descriptions
        customized_description = step_template.task_description
        if haskey(context_data, "target_audience")
            customized_description *= " [Target: $(context_data["target_audience"])]"
        end
        if haskey(context_data, "priority")
            customized_description *= " [Priority: $(context_data["priority"])]"
        end
        
        customized_step = WorkflowStep(
            step_template.step_id,
            step_template.agent_type,
            customized_description,
            step_template.dependencies,
            step_template.timeout_seconds,
            step_template.retry_count,
            merge(step_template.conditions, context_data),
            step_template.output_mapping,
            step_template.schema_requirements
        )
        
        push!(customized_steps, customized_step)
    end
    
    # Create business context
    business_context = BusinessContext(
        get(context_data, "company_name", "Schemantics"),
        get(context_data, "industry", "Software Development Tools"),
        get(context_data, "target_audience", "Software Developers"),
        get(context_data, "brand_voice", "Technical, Helpful, Innovative"),
        get(context_data, "primary_languages", ["Julia", "Rust", "TypeScript", "Elixir"]),
        get(context_data, "key_metrics", Dict(
            "user_acquisition" => "monthly_signups",
            "engagement" => "daily_active_users",
            "retention" => "monthly_retention_rate",
            "revenue" => "monthly_recurring_revenue"
        ))
    )
    
    return SchemaStackedWorkflow(
        workflow_id,
        template.name,
        template.description,
        template.domain,
        get(context_data, "priority", MEDIUM) isa TaskPriority ? context_data["priority"] : MEDIUM,
        customized_steps,
        template.success_metrics,
        Dict{String, Any}(),  # failure_conditions
        Dict{String, Any}(),  # schema_requirements
        business_context,
        sum([step.timeout_seconds for step in customized_steps]) ÷ 60  # Convert to minutes
    )
end

function get_workflow_performance_summary(engine::WorkflowEngine)::Dict{String, Any}
    summary = Dict{String, Any}(
        "total_workflows_executed" => length(engine.workflow_history),
        "active_workflows" => length(engine.active_workflows),
        "performance_by_type" => Dict{String, Any}()
    )
    
    # Calculate overall performance statistics
    if !isempty(engine.workflow_history)
        completed_workflows = filter(w -> w.status == COMPLETED, engine.workflow_history)
        summary["overall_success_rate"] = length(completed_workflows) / length(engine.workflow_history)
        
        if !isempty(completed_workflows)
            execution_times = [Dates.value(w.completed_at - w.started_at) for w in completed_workflows if w.completed_at !== nothing && w.started_at !== nothing]
            if !isempty(execution_times)
                summary["avg_execution_time_ms"] = sum(execution_times) / length(execution_times)
                summary["min_execution_time_ms"] = minimum(execution_times)
                summary["max_execution_time_ms"] = maximum(execution_times)
            end
        end
    end
    
    # Add performance data by workflow type
    summary["performance_by_type"] = engine.performance_data
    
    return summary
end

end # module WorkflowOrchestrationEngine