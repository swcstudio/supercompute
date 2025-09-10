"""
    TeamProtocols

Team collaboration interfaces and protocols for enterprise SDLC systems.
Provides standardized communication patterns, workflow orchestration,
and team synchronization for distributed agile development teams.

## [ascii_diagrams]

**Team Collaboration Architecture**

```
TeamProtocols.jl - Enterprise Collaboration System
├── [Team Structure]
│   ├── Team                # Core team organization unit
│   ├── TeamMember          # Individual contributor profiles
│   ├── TeamRole           # Role-based access & responsibilities
│   └── TeamCapacity       # Resource planning & allocation
├── [Workflow Orchestration]
│   ├── Workflow           # Multi-step process definitions
│   ├── WorkflowStep       # Individual task specifications  
│   ├── WorkflowState      # Progress tracking & validation
│   └── WorkflowMetrics    # Performance & efficiency measures
├── [Communication Layer]
│   ├── CommunicationChannel # Slack/Teams/Email integration
│   ├── Notification       # Event-driven messaging
│   ├── CollaborationSession # Real-time work sessions
│   └── ReviewProcess      # Code/design review workflows
└── [Integration Points]
    ├── SDLC Phase Gates   # Quality gate coordination
    ├── Performance Metrics # Team velocity & health
    └── Enterprise Security # Access control & auditing
```

**Team Workflow Orchestration Flow**

```
Workflow Execution Pipeline:
Team Formation → Workflow Assignment → Task Distribution → Progress Tracking
    │                    │                    │                    │
    ▼                    ▼                    ▼                    ▼
Role Assignment → Step Validation → Collaboration → Quality Gates
    │                    │                    │                    │
    ▼                    ▼                    ▼                    ▼
Capacity Planning → Notification → Session Management → Review Process
    │                    │                    │                    │
    ▼                    ▼                    ▼                    ▼
Metrics ← Team Reports ← Performance Data ← Completion Status
        ↑____________________feedback/retrospectives_____________________|
```

**Team Communication Matrix**

```
Communication Patterns:
┌─────────────────┬──────────────┬─────────────┬──────────────┐
│ Channel Type    │ Use Case     │ Frequency   │ Stakeholders │
├─────────────────┼──────────────┼─────────────┼──────────────┤
│ Instant Message │ Quick Q&A    │ Real-time   │ Team Members │
│ Code Review     │ Quality Gate │ Per PR      │ Reviewers    │
│ Sprint Planning │ Workflow     │ Bi-weekly   │ Full Team    │
│ Retrospective   │ Improvement  │ Bi-weekly   │ Full Team    │
│ Stakeholder     │ Status       │ Weekly      │ Leadership   │
└─────────────────┴──────────────┴─────────────┴──────────────┘
```
"""
module TeamProtocols

using ..SDLCTypes
using Dates
using JSON3

export Team, TeamMember, Workflow, WorkflowStep, Notification
export CommunicationChannel, CollaborationSession, ReviewProcess
export create_team, assign_workflow, notify_team, schedule_review
export track_workflow_progress, generate_team_report

# ============================================================================
# Team Structure Types
# ============================================================================

"""
    TeamMember

Individual team member with skills, availability, and preferences.
"""
struct TeamMember
    user_id::String
    name::String
    email::String
    role::TeamRole
    skills::Vector{String}
    experience_level::String             # "junior", "mid", "senior", "lead"
    availability::Float64                # Percentage availability (0-1)
    timezone::String                     # e.g., "UTC", "PST", "EST"
    preferred_communication::Vector{String} # ["slack", "email", "teams"]
    current_workload::Float64           # Story points or hours
    performance_rating::Float64         # Performance score (0-1)
    certifications::Vector{String}      # Professional certifications
    joined_date::Date
    last_active::DateTime
end

"""
    Team

Agile development team with members, processes, and metrics.
"""
struct Team
    team_id::String
    name::String
    description::String
    team_type::String                   # "scrum", "kanban", "devops", "feature"
    members::Vector{TeamMember}
    team_lead::String                   # User ID of team lead
    scrum_master::Union{String,Nothing} # User ID of scrum master
    product_owner::Union{String,Nothing} # User ID of product owner
    sprint_length::Int                  # Sprint length in days
    capacity::Float64                   # Team capacity (story points per sprint)
    velocity::Vector{Float64}          # Historical velocity data
    communication_channels::Vector{CommunicationChannel}
    workflows::Vector{Workflow}
    created_date::Date
    status::String                      # "active", "inactive", "dissolved"
end

"""
    CommunicationChannel

Team communication channel configuration.
"""
struct CommunicationChannel
    channel_id::String
    name::String
    type::String                        # "slack", "teams", "discord", "email"
    purpose::String                     # "general", "development", "alerts", "standups"
    members::Vector{String}             # User IDs of channel members
    notification_settings::Dict{String,Bool}
    integration_webhooks::Vector{String}
    created_date::DateTime
    archived::Bool
end

# ============================================================================
# Workflow & Process Types
# ============================================================================

"""
    WorkflowStep

Individual step in a team workflow process.
"""
struct WorkflowStep
    step_id::String
    name::String
    description::String
    step_type::String                   # "automated", "manual", "review", "approval"
    required_role::Union{TeamRole,Nothing}
    estimated_duration::Float64         # Hours
    dependencies::Vector{String}        # Step IDs this depends on
    automation_script::Union{String,Nothing}
    quality_gates::Vector{QualityGate}
    success_criteria::Vector{String}
    failure_actions::Vector{String}
    timeout_hours::Float64
    retry_count::Int
end

"""
    Workflow

Complete workflow definition for team processes.
"""
struct Workflow
    workflow_id::String
    name::String
    description::String
    workflow_type::String               # "feature_development", "bug_fix", "release", "hotfix"
    trigger_conditions::Vector{String}  # Conditions that start this workflow
    steps::Vector{WorkflowStep}
    parallel_execution::Bool
    approval_required::Bool
    notification_points::Vector{String} # Step IDs where notifications are sent
    sla_hours::Float64                  # Service level agreement
    owner::String                       # User ID of workflow owner
    version::String
    created_date::DateTime
    last_modified::DateTime
    active::Bool
end

"""
    WorkflowInstance

Running instance of a workflow with current state.
"""
mutable struct WorkflowInstance
    instance_id::String
    workflow_id::String
    triggered_by::String                # User ID who triggered
    trigger_data::Dict{String,Any}
    current_step::Union{String,Nothing} # Current step ID
    completed_steps::Vector{String}     # Completed step IDs
    failed_steps::Vector{String}       # Failed step IDs
    started_at::DateTime
    estimated_completion::DateTime
    actual_completion::Union{DateTime,Nothing}
    status::String                      # "running", "paused", "completed", "failed", "cancelled"
    step_data::Dict{String,Any}        # Data passed between steps
    notifications_sent::Vector{String}
    blocking_issues::Vector{String}
end

# ============================================================================
# Communication & Notification Types
# ============================================================================

"""
    Notification

Team notification with routing and delivery tracking.
"""
struct Notification
    notification_id::String
    title::String
    message::String
    priority::String                    # "low", "normal", "high", "urgent"
    category::String                    # "workflow", "alert", "reminder", "announcement"
    sender::String                      # User ID of sender
    recipients::Vector{String}          # User IDs of recipients
    channels::Vector{String}            # Channel IDs for delivery
    delivery_method::Vector{String}     # "push", "email", "sms", "webhook"
    scheduled_time::Union{DateTime,Nothing}
    sent_time::Union{DateTime,Nothing}
    read_receipts::Dict{String,DateTime} # User ID -> read timestamp
    action_required::Bool
    action_url::Union{String,Nothing}
    expires_at::Union{DateTime,Nothing}
    metadata::Dict{String,Any}
end

"""
    CollaborationSession

Real-time collaboration session for pair programming, reviews, etc.
"""
mutable struct CollaborationSession
    session_id::String
    session_type::String               # "pair_programming", "code_review", "planning", "retrospective"
    title::String
    description::String
    host::String                       # User ID of session host
    participants::Vector{String}       # User IDs of participants
    invited::Vector{String}            # User IDs of invited but not joined
    started_at::DateTime
    estimated_duration::Float64        # Hours
    actual_duration::Union{Float64,Nothing} # Actual duration when ended
    status::String                     # "scheduled", "active", "paused", "completed", "cancelled"
    artifacts::Vector{String}          # File paths or URLs of created artifacts
    decisions_made::Vector{String}     # Decisions or outcomes
    action_items::Vector{Dict{String,Any}} # Action items with assignees
    recording_url::Union{String,Nothing}
    transcript::Union{String,Nothing}
    tools_used::Vector{String}         # Collaboration tools used
end

"""
    ReviewProcess

Code review or design review process management.
"""
struct ReviewProcess
    review_id::String
    review_type::String                # "code_review", "design_review", "security_review"
    title::String
    description::String
    author::String                     # User ID of review author
    reviewers::Vector{String}          # User IDs of assigned reviewers
    required_reviewers::Int            # Minimum reviewers needed
    artifacts::Vector{String}          # Files, documents, or URLs to review
    review_criteria::Vector{String}    # Review checklist items
    comments::Vector{Dict{String,Any}} # Review comments
    approvals::Vector{String}          # User IDs who approved
    rejections::Vector{String}         # User IDs who rejected
    status::String                     # "draft", "ready", "in_review", "approved", "rejected", "merged"
    created_at::DateTime
    due_date::Union{DateTime,Nothing}
    completed_at::Union{DateTime,Nothing}
    merge_commit::Union{String,Nothing}
    quality_score::Union{Float64,Nothing} # Calculated quality score
end

# ============================================================================
# Core Team Functions
# ============================================================================

"""
    create_team(name::String, team_type::String, members::Vector{TeamMember}, 
                team_lead::String, sprint_length::Int) -> Team

Create a new agile development team with specified configuration.
"""
function create_team(name::String, team_type::String, members::Vector{TeamMember},
                    team_lead::String, sprint_length::Int)
    team_id = "team_$(randstring(8))"
    
    # Calculate team capacity based on member availability
    total_capacity = sum(member.availability * 40.0 for member in members)  # 40 hours per week
    sprint_capacity = (total_capacity * sprint_length) / 7.0  # Convert to sprint capacity
    
    # Find scrum master and product owner
    scrum_master = nothing
    product_owner = nothing
    
    for member in members
        if member.role == SCRUM_MASTER
            scrum_master = member.user_id
        elseif member.role == PRODUCT_OWNER
            product_owner = member.user_id
        end
    end
    
    # Create default communication channels
    channels = [
        CommunicationChannel(
            "$(team_id)_general",
            "General Discussion",
            "slack",
            "general",
            [member.user_id for member in members],
            Dict("mentions" => true, "workflow_updates" => true),
            String[],
            now(),
            false
        ),
        CommunicationChannel(
            "$(team_id)_dev",
            "Development Updates",
            "slack",
            "development", 
            [member.user_id for member in members if member.role in [DEVELOPER, SENIOR_DEVELOPER, ARCHITECT]],
            Dict("code_reviews" => true, "build_status" => true),
            String[],
            now(),
            false
        )
    ]
    
    return Team(
        team_id, name, "Agile development team", team_type, members,
        team_lead, scrum_master, product_owner, sprint_length,
        sprint_capacity, Float64[], channels, Workflow[],
        today(), "active"
    )
end

"""
    assign_workflow(team::Team, workflow::Workflow, trigger_data::Dict{String,Any}, 
                   triggered_by::String) -> WorkflowInstance

Assign a workflow to a team and create a running instance.
"""
function assign_workflow(team::Team, workflow::Workflow, trigger_data::Dict{String,Any},
                        triggered_by::String)
    instance_id = "wf_$(randstring(10))"
    
    # Estimate completion time based on workflow steps
    total_duration = sum(step.estimated_duration for step in workflow.steps)
    estimated_completion = now() + Dates.Hour(Int(ceil(total_duration)))
    
    # Find first step (no dependencies)
    first_step = nothing
    for step in workflow.steps
        if isempty(step.dependencies)
            first_step = step.step_id
            break
        end
    end
    
    instance = WorkflowInstance(
        instance_id, workflow.workflow_id, triggered_by, trigger_data,
        first_step, String[], String[], now(), estimated_completion,
        nothing, "running", Dict{String,Any}(), String[], String[]
    )
    
    # Send initial notification
    notification = Notification(
        "notif_$(randstring(8))",
        "Workflow Started: $(workflow.name)",
        "Workflow $(workflow.name) has been assigned to team $(team.name) and is now running.",
        "normal", "workflow", triggered_by,
        [member.user_id for member in team.members],
        [channel.channel_id for channel in team.communication_channels if channel.purpose == "general"],
        ["push"], nothing, now(), Dict{String,DateTime}(),
        false, nothing, nothing, Dict{String,Any}()
    )
    
    return instance
end

"""
    notify_team(team::Team, notification::Notification) -> Bool

Send notification to team members through configured channels.
"""
function notify_team(team::Team, notification::Notification)
    try
        # Route notification based on priority and channels
        for channel_id in notification.channels
            channel = findfirst(c -> c.channel_id == channel_id, team.communication_channels)
            if channel !== nothing
                # Send to channel (mock implementation)
                @info "Sending notification to $(channel.name): $(notification.title)"
            end
        end
        
        # Send direct notifications for high/urgent priority
        if notification.priority in ["high", "urgent"]
            for recipient in notification.recipients
                member = findfirst(m -> m.user_id == recipient, team.members)
                if member !== nothing
                    # Send direct notification based on member preferences
                    for method in member.preferred_communication
                        @info "Direct notification to $(member.name) via $method: $(notification.title)"
                    end
                end
            end
        end
        
        return true
    catch e
        @error "Failed to send team notification: $e"
        return false
    end
end

"""
    schedule_review(team::Team, review_type::String, title::String, author::String,
                   reviewers::Vector{String}, artifacts::Vector{String}) -> ReviewProcess

Schedule a review process with the specified team members.
"""
function schedule_review(team::Team, review_type::String, title::String, author::String,
                        reviewers::Vector{String}, artifacts::Vector{String})
    review_id = "review_$(randstring(8))"
    
    # Set review criteria based on type
    criteria = if review_type == "code_review"
        ["Code quality", "Test coverage", "Security", "Performance", "Documentation"]
    elseif review_type == "design_review"
        ["Architecture", "Scalability", "Security", "User experience", "Technical feasibility"]
    elseif review_type == "security_review"
        ["Vulnerability assessment", "Access control", "Data protection", "Compliance", "Threat modeling"]
    else
        ["Quality", "Completeness", "Compliance"]
    end
    
    # Calculate due date based on team capacity and review complexity
    base_hours = length(artifacts) * 2.0  # 2 hours per artifact
    due_date = now() + Dates.Hour(Int(ceil(base_hours)))
    
    review = ReviewProcess(
        review_id, review_type, title, "Review request for $title",
        author, reviewers, min(length(reviewers), 2), artifacts, criteria,
        Dict{String,Any}[], String[], String[], "ready", now(),
        due_date, nothing, nothing, nothing
    )
    
    # Notify reviewers
    notification = Notification(
        "notif_$(randstring(8))",
        "Review Request: $title",
        "You have been assigned to review: $title. Due date: $due_date",
        "high", "workflow", author, reviewers,
        [team.communication_channels[1].channel_id],  # General channel
        ["push", "email"], nothing, now(), Dict{String,DateTime}(),
        true, "/reviews/$(review_id)", due_date, Dict{String,Any}()
    )
    
    notify_team(team, notification)
    
    return review
end

"""
    track_workflow_progress(instance::WorkflowInstance, workflow::Workflow) -> Dict{String,Any}

Track and report workflow progress with bottleneck analysis.
"""
function track_workflow_progress(instance::WorkflowInstance, workflow::Workflow)
    # Calculate progress metrics
    total_steps = length(workflow.steps)
    completed_steps = length(instance.completed_steps)
    failed_steps = length(instance.failed_steps)
    progress_percentage = (completed_steps / total_steps) * 100.0
    
    # Calculate elapsed and remaining time
    elapsed_time = (now() - instance.started_at).value / (1000 * 3600)  # Hours
    remaining_time = if instance.status == "completed"
        0.0
    else
        max(0.0, (instance.estimated_completion - now()).value / (1000 * 3600))
    end
    
    # Identify current bottlenecks
    bottlenecks = String[]
    if instance.status == "running" && !isempty(instance.blocking_issues)
        bottlenecks = instance.blocking_issues
    end
    
    # Calculate velocity
    velocity = if elapsed_time > 0
        completed_steps / elapsed_time  # Steps per hour
    else
        0.0
    end
    
    return Dict(
        "instance_id" => instance.instance_id,
        "workflow_name" => workflow.name,
        "status" => instance.status,
        "progress_percentage" => progress_percentage,
        "completed_steps" => completed_steps,
        "total_steps" => total_steps,
        "failed_steps" => failed_steps,
        "elapsed_hours" => elapsed_time,
        "remaining_hours" => remaining_time,
        "velocity_steps_per_hour" => velocity,
        "bottlenecks" => bottlenecks,
        "on_schedule" => elapsed_time <= (instance.estimated_completion - instance.started_at).value / (1000 * 3600),
        "current_step" => instance.current_step
    )
end

"""
    generate_team_report(team::Team, period_days::Int = 30) -> Dict{String,Any}

Generate comprehensive team performance and activity report.
"""
function generate_team_report(team::Team, period_days::Int = 30)
    # Calculate team metrics
    avg_velocity = isempty(team.velocity) ? 0.0 : sum(team.velocity) / length(team.velocity)
    velocity_trend = if length(team.velocity) >= 2
        (team.velocity[end] - team.velocity[1]) / team.velocity[1] * 100.0
    else
        0.0
    end
    
    # Member performance analysis
    member_performance = Dict{String,Any}()
    for member in team.members
        member_performance[member.name] = Dict(
            "role" => string(member.role),
            "availability" => member.availability,
            "workload" => member.current_workload,
            "performance_rating" => member.performance_rating,
            "experience" => member.experience_level,
            "skills_count" => length(member.skills)
        )
    end
    
    # Communication activity
    active_channels = count(c -> !c.archived, team.communication_channels)
    
    return Dict(
        "team_id" => team.team_id,
        "team_name" => team.name,
        "report_period_days" => period_days,
        "report_generated" => now(),
        "team_size" => length(team.members),
        "team_capacity" => team.capacity,
        "average_velocity" => avg_velocity,
        "velocity_trend_percent" => velocity_trend,
        "sprint_length_days" => team.sprint_length,
        "active_communication_channels" => active_channels,
        "team_status" => team.status,
        "member_performance" => member_performance,
        "recommendations" => generate_team_recommendations(team)
    )
end

"""
    generate_team_recommendations(team::Team) -> Vector{String}

Generate actionable recommendations for team improvement.
"""
function generate_team_recommendations(team::Team)
    recommendations = String[]
    
    # Check team size
    if length(team.members) < 5
        push!(recommendations, "Consider adding team members - current size ($(length(team.members))) is below optimal range (5-9)")
    elseif length(team.members) > 9
        push!(recommendations, "Consider splitting team - current size ($(length(team.members))) is above optimal range (5-9)")
    end
    
    # Check role distribution
    role_counts = Dict{TeamRole,Int}()
    for member in team.members
        role_counts[member.role] = get(role_counts, member.role, 0) + 1
    end
    
    if !haskey(role_counts, SCRUM_MASTER)
        push!(recommendations, "Assign a Scrum Master to improve team process facilitation")
    end
    
    if !haskey(role_counts, PRODUCT_OWNER)
        push!(recommendations, "Assign a Product Owner to improve requirements clarity")
    end
    
    # Check capacity utilization
    total_workload = sum(member.current_workload for member in team.members)
    if total_workload / team.capacity > 0.95
        push!(recommendations, "Team is over capacity ($(round(total_workload/team.capacity*100, digits=1))%) - consider reducing sprint commitment")
    elseif total_workload / team.capacity < 0.7
        push!(recommendations, "Team capacity underutilized ($(round(total_workload/team.capacity*100, digits=1))%) - consider taking on additional work")
    end
    
    # Check velocity trend
    if length(team.velocity) >= 3
        recent_avg = sum(team.velocity[end-2:end]) / 3
        older_avg = sum(team.velocity[1:3]) / 3
        if recent_avg < older_avg * 0.9
            push!(recommendations, "Velocity declining - investigate blockers and team impediments")
        end
    end
    
    return recommendations
end

end # module TeamProtocols