"""
    DemonstrationLearning

Production-focused learning system based on demonstrations rather than fine-tuning.
Implements "how to move" methodology for teaching AI agents through example.
"""
module DemonstrationLearning

using DataFrames
using Statistics
using LinearAlgebra
using Random
using JSON3

export Demonstration, Trajectory, IssueTracker, KnowledgeGraph
export create_demonstration, train_on_demonstration, generate_similar_issues
export evaluate_solution, calculate_similarity_score, build_knowledge_graph

# ============================================================================
# Core Types
# ============================================================================

"""
    ToolCall

Represents a single tool invocation by an AI agent.
"""
struct ToolCall
    tool_name::String
    parameters::Dict{Symbol, Any}
    result::Any
    timestamp::Float64
    success::Bool
end

"""
    Trajectory

Complete path of actions taken to solve an issue.
"""
struct Trajectory
    id::String
    issue_id::String
    agent_id::UInt64
    tool_calls::Vector{ToolCall}
    files_checked::Vector{String}
    files_modified::Vector{String}
    code_written::Dict{String, String}
    review_steps::Vector{String}
    total_time::Float64
    success::Bool
    etd_value::Float64
end

"""
    Demonstration

A validated example of solving a production issue.
"""
struct Demonstration
    trajectory::Trajectory
    issue::Issue
    variations::Vector{Issue}  # Similar issues for few-shot learning
    similarity_scores::Vector{Float64}
    knowledge_extracted::Dict{Symbol, Any}
    proof_hash::String
end

"""
    Issue

Represents a production issue from the tracker.
"""
struct Issue
    id::String
    title::String
    description::String
    complexity::Symbol  # :low, :medium, :high, :critical
    category::Symbol
    tags::Vector{String}
    created_at::Float64
    priority::Int
    estimated_hours::Float64
end

"""
    IssueTracker

Manages production issues for demonstration learning.
"""
mutable struct IssueTracker
    open_issues::Vector{Issue}
    solved_issues::Vector{Issue}
    demonstrations::Vector{Demonstration}
    solution_map::Dict{String, Trajectory}
end

"""
    KnowledgeGraph

Graph structure representing learned relationships between issues and solutions.
"""
struct KnowledgeGraph
    nodes::Dict{String, Union{Issue, Demonstration}}
    edges::Vector{Tuple{String, String, Float64}}  # (from, to, weight)
    embeddings::Dict{String, Vector{Float64}}
    clusters::Dict{Int, Vector{String}}
end

# ============================================================================
# Demonstration Creation
# ============================================================================

"""
    create_demonstration(agent_id::UInt64, issue::Issue, trajectory::Trajectory)

Create a demonstration from a successful solution.
"""
function create_demonstration(agent_id::UInt64, issue::Issue, trajectory::Trajectory)
    # Generate similar issues for few-shot learning
    variations = generate_similar_issues(issue, num_variations=4)
    
    # Calculate similarity scores
    similarity_scores = [calculate_similarity_score(issue, var) for var in variations]
    
    # Extract knowledge patterns
    knowledge = extract_knowledge_patterns(trajectory)
    
    # Create proof hash for blockchain
    proof_data = Dict(
        :issue_id => issue.id,
        :trajectory_id => trajectory.id,
        :agent_id => agent_id,
        :timestamp => time()
    )
    proof_hash = bytes2hex(sha256(JSON3.write(proof_data)))[1:64]
    
    return Demonstration(
        trajectory,
        issue,
        variations,
        similarity_scores,
        knowledge,
        proof_hash
    )
end

"""
    generate_similar_issues(issue::Issue; num_variations::Int=4)

Generate variations of an issue for few-shot learning.
"""
function generate_similar_issues(issue::Issue; num_variations::Int=4)
    variations = Issue[]
    
    for i in 1:num_variations
        # Vary the issue slightly
        variation = Issue(
            "$(issue.id)_var_$i",
            mutate_text(issue.title, 0.1),
            mutate_text(issue.description, 0.2),
            issue.complexity,
            issue.category,
            shuffle_subset(issue.tags, 0.3),
            time(),
            issue.priority + rand(-1:1),
            issue.estimated_hours * (1 + randn() * 0.2)
        )
        push!(variations, variation)
    end
    
    return variations
end

"""
    mutate_text(text::String, mutation_rate::Float64)

Apply mutations to text for creating variations.
"""
function mutate_text(text::String, mutation_rate::Float64)
    words = split(text)
    mutated_words = String[]
    
    synonyms = Dict(
        "fix" => ["repair", "resolve", "correct", "address"],
        "bug" => ["issue", "problem", "defect", "error"],
        "feature" => ["functionality", "capability", "component", "module"],
        "update" => ["modify", "change", "revise", "improve"],
        "implement" => ["create", "build", "develop", "add"]
    )
    
    for word in words
        if rand() < mutation_rate && haskey(synonyms, lowercase(word))
            # Replace with synonym
            push!(mutated_words, rand(synonyms[lowercase(word)]))
        else
            push!(mutated_words, word)
        end
    end
    
    return join(mutated_words, " ")
end

"""
    shuffle_subset(items::Vector, shuffle_rate::Float64)

Shuffle a subset of items for variation.
"""
function shuffle_subset(items::Vector{T}, shuffle_rate::Float64) where T
    if isempty(items)
        return items
    end
    
    shuffled = copy(items)
    n_shuffle = Int(floor(length(items) * shuffle_rate))
    
    if n_shuffle > 0
        indices = randperm(length(items))[1:n_shuffle]
        shuffled[indices] = shuffle(shuffled[indices])
    end
    
    return shuffled
end

"""
    extract_knowledge_patterns(trajectory::Trajectory)

Extract reusable knowledge from a successful trajectory.
"""
function extract_knowledge_patterns(trajectory::Trajectory)
    knowledge = Dict{Symbol, Any}()
    
    # Tool usage patterns
    tool_sequence = [tc.tool_name for tc in trajectory.tool_calls]
    knowledge[:tool_pattern] = identify_tool_patterns(tool_sequence)
    
    # File interaction patterns
    knowledge[:file_pattern] = Dict(
        :checks_before_modify => length(trajectory.files_checked) / max(1, length(trajectory.files_modified)),
        :modification_rate => length(trajectory.files_modified) / max(1, length(trajectory.files_checked))
    )
    
    # Success indicators
    successful_tools = [tc for tc in trajectory.tool_calls if tc.success]
    knowledge[:success_rate] = length(successful_tools) / max(1, length(trajectory.tool_calls))
    
    # Time efficiency
    knowledge[:time_efficiency] = trajectory.etd_value / trajectory.total_time
    
    # Code patterns
    if !isempty(trajectory.code_written)
        knowledge[:code_patterns] = analyze_code_patterns(trajectory.code_written)
    end
    
    return knowledge
end

"""
    identify_tool_patterns(tool_sequence::Vector{String})

Identify common patterns in tool usage.
"""
function identify_tool_patterns(tool_sequence::Vector{String})
    patterns = Dict{Vector{String}, Int}()
    
    # Look for n-grams (sequences of tools)
    for n in 2:min(5, length(tool_sequence))
        for i in 1:length(tool_sequence)-n+1
            ngram = tool_sequence[i:i+n-1]
            patterns[ngram] = get(patterns, ngram, 0) + 1
        end
    end
    
    # Return most common patterns
    sorted_patterns = sort(collect(patterns), by=x->x[2], rev=true)
    return length(sorted_patterns) > 0 ? sorted_patterns[1:min(5, length(sorted_patterns))] : []
end

"""
    analyze_code_patterns(code_written::Dict{String, String})

Analyze patterns in written code.
"""
function analyze_code_patterns(code_written::Dict{String, String})
    patterns = Dict{Symbol, Any}()
    
    # Calculate metrics
    total_lines = sum(count(c -> c == '\n', code) for code in values(code_written))
    patterns[:total_lines] = total_lines
    patterns[:files_modified] = length(code_written)
    patterns[:avg_lines_per_file] = total_lines / max(1, length(code_written))
    
    # Language detection (simplified)
    for (file, code) in code_written
        if endswith(file, ".jl")
            patterns[:language] = :julia
        elseif endswith(file, ".py")
            patterns[:language] = :python
        elseif endswith(file, ".js") || endswith(file, ".ts")
            patterns[:language] = :javascript
        end
    end
    
    return patterns
end

# ============================================================================
# Training on Demonstrations
# ============================================================================

"""
    train_on_demonstration(agents::Vector, demo::Demonstration, mutation_rate::Float64)

Train a population of agents on a demonstration.
"""
function train_on_demonstration(agents::Vector, demo::Demonstration, mutation_rate::Float64=0.1)
    trained_agents = []
    
    for agent in agents
        # Learn from the demonstration
        updated_agent = apply_demonstration_learning(agent, demo)
        
        # Apply mutations for diversity
        if rand() < mutation_rate
            updated_agent = mutate_agent(updated_agent)
        end
        
        push!(trained_agents, updated_agent)
    end
    
    return trained_agents
end

"""
    apply_demonstration_learning(agent, demo::Demonstration)

Update an agent based on a demonstration.
"""
function apply_demonstration_learning(agent, demo::Demonstration)
    # This is a simplified representation
    # In production, this would update the agent's neural network or policy
    
    updated = deepcopy(agent)
    
    # Transfer knowledge patterns
    if isdefined(agent, :knowledge_base)
        merge!(agent.knowledge_base, demo.knowledge_extracted)
    end
    
    # Update tool preferences based on successful trajectory
    if isdefined(agent, :tool_preferences)
        for tc in demo.trajectory.tool_calls
            if tc.success
                agent.tool_preferences[tc.tool_name] = get(agent.tool_preferences, tc.tool_name, 0.0) + 0.1
            end
        end
    end
    
    return updated
end

"""
    mutate_agent(agent)

Apply random mutations to an agent for evolutionary diversity.
"""
function mutate_agent(agent)
    mutated = deepcopy(agent)
    
    # Random parameter perturbations
    if isdefined(mutated, :parameters)
        for (key, value) in mutated.parameters
            if isa(value, Number)
                mutated.parameters[key] = value * (1 + randn() * 0.1)
            end
        end
    end
    
    return mutated
end

# ============================================================================
# Similarity and Evaluation
# ============================================================================

"""
    calculate_similarity_score(issue1::Issue, issue2::Issue)

Calculate similarity between two issues.
"""
function calculate_similarity_score(issue1::Issue, issue2::Issue)
    score = 0.0
    weights = Dict(
        :title => 0.3,
        :description => 0.3,
        :category => 0.2,
        :tags => 0.1,
        :complexity => 0.1
    )
    
    # Title similarity (simplified Jaccard)
    title_sim = jaccard_similarity(split(issue1.title), split(issue2.title))
    score += weights[:title] * title_sim
    
    # Description similarity
    desc_sim = jaccard_similarity(split(issue1.description), split(issue2.description))
    score += weights[:description] * desc_sim
    
    # Category match
    if issue1.category == issue2.category
        score += weights[:category]
    end
    
    # Tag overlap
    tag_sim = jaccard_similarity(issue1.tags, issue2.tags)
    score += weights[:tags] * tag_sim
    
    # Complexity match
    if issue1.complexity == issue2.complexity
        score += weights[:complexity]
    end
    
    return score
end

"""
    jaccard_similarity(set1::Vector, set2::Vector)

Calculate Jaccard similarity between two sets.
"""
function jaccard_similarity(set1::Vector, set2::Vector)
    if isempty(set1) && isempty(set2)
        return 1.0
    end
    
    intersection = length(intersect(set1, set2))
    union = length(union(set1, set2))
    
    return union > 0 ? intersection / union : 0.0
end

"""
    evaluate_solution(trajectory::Trajectory, issue::Issue)

Evaluate the quality of a solution.
"""
function evaluate_solution(trajectory::Trajectory, issue::Issue)
    metrics = Dict{Symbol, Float64}()
    
    # Success metric
    metrics[:success] = trajectory.success ? 1.0 : 0.0
    
    # Efficiency metric
    expected_time = issue.estimated_hours * 3600  # Convert to seconds
    actual_time = trajectory.total_time
    metrics[:efficiency] = expected_time / max(actual_time, 1.0)
    
    # Tool efficiency
    total_tools = length(trajectory.tool_calls)
    successful_tools = count(tc -> tc.success, trajectory.tool_calls)
    metrics[:tool_efficiency] = successful_tools / max(total_tools, 1)
    
    # File efficiency
    files_ratio = length(trajectory.files_modified) / max(length(trajectory.files_checked), 1)
    metrics[:file_efficiency] = 1.0 - abs(files_ratio - 0.3)  # Optimal is ~30% modification
    
    # ETD value
    metrics[:etd_score] = trajectory.etd_value / 1000.0  # Normalize to thousands
    
    # Overall score
    weights = [0.3, 0.2, 0.2, 0.1, 0.2]  # Weights for each metric
    overall = sum(weights[i] * collect(values(metrics))[i] for i in 1:5)
    metrics[:overall] = overall
    
    return metrics
end

# ============================================================================
# Knowledge Graph Construction
# ============================================================================

"""
    build_knowledge_graph(demonstrations::Vector{Demonstration})

Build a knowledge graph from demonstrations.
"""
function build_knowledge_graph(demonstrations::Vector{Demonstration})
    nodes = Dict{String, Union{Issue, Demonstration}}()
    edges = Vector{Tuple{String, String, Float64}}()
    embeddings = Dict{String, Vector{Float64}}()
    
    # Add nodes for issues and demonstrations
    for demo in demonstrations
        # Add issue node
        nodes[demo.issue.id] = demo.issue
        embeddings[demo.issue.id] = create_embedding(demo.issue)
        
        # Add demonstration node
        demo_id = "demo_$(demo.trajectory.id)"
        nodes[demo_id] = demo
        embeddings[demo_id] = create_embedding(demo)
        
        # Connect issue to demonstration
        push!(edges, (demo.issue.id, demo_id, 1.0))
        
        # Connect to similar issues
        for (i, var) in enumerate(demo.variations)
            nodes[var.id] = var
            embeddings[var.id] = create_embedding(var)
            push!(edges, (demo.issue.id, var.id, demo.similarity_scores[i]))
        end
    end
    
    # Cluster nodes based on embeddings
    clusters = cluster_nodes(embeddings)
    
    return KnowledgeGraph(nodes, edges, embeddings, clusters)
end

"""
    create_embedding(item::Union{Issue, Demonstration})

Create a vector embedding for an item.
"""
function create_embedding(item::Union{Issue, Demonstration})
    # Simplified embedding creation
    # In production, use actual NLP embeddings
    
    if isa(item, Issue)
        # Create embedding from issue features
        embedding = Float64[]
        
        # Complexity encoding
        complexity_val = Dict(:low => 0.25, :medium => 0.5, :high => 0.75, :critical => 1.0)
        push!(embedding, complexity_val[item.complexity])
        
        # Priority encoding
        push!(embedding, item.priority / 10.0)
        
        # Estimated hours encoding
        push!(embedding, tanh(item.estimated_hours / 40.0))
        
        # Category hash encoding
        push!(embedding, (hash(item.category) % 100) / 100.0)
        
        # Add random features for higher dimensionality
        append!(embedding, rand(6))
        
    else  # Demonstration
        # Create embedding from demonstration features
        embedding = Float64[]
        
        # Success encoding
        push!(embedding, item.trajectory.success ? 1.0 : 0.0)
        
        # ETD value encoding
        push!(embedding, tanh(item.trajectory.etd_value / 10000.0))
        
        # Tool usage encoding
        push!(embedding, length(item.trajectory.tool_calls) / 100.0)
        
        # Knowledge features
        for (key, value) in item.knowledge_extracted
            if isa(value, Number)
                push!(embedding, Float64(value))
            end
        end
        
        # Pad to fixed size
        while length(embedding) < 10
            push!(embedding, 0.0)
        end
    end
    
    # Normalize
    norm = sqrt(sum(embedding .^ 2))
    if norm > 0
        embedding ./= norm
    end
    
    return embedding
end

"""
    cluster_nodes(embeddings::Dict{String, Vector{Float64}})

Cluster nodes based on their embeddings.
"""
function cluster_nodes(embeddings::Dict{String, Vector{Float64}}; n_clusters::Int=5)
    if isempty(embeddings)
        return Dict{Int, Vector{String}}()
    end
    
    # Simple k-means clustering
    node_ids = collect(keys(embeddings))
    vectors = [embeddings[id] for id in node_ids]
    
    # Initialize cluster centers randomly
    centers = [vectors[rand(1:length(vectors))] for _ in 1:min(n_clusters, length(vectors))]
    
    clusters = Dict{Int, Vector{String}}()
    
    # Iterate clustering
    for iteration in 1:10
        # Clear clusters
        for i in 1:n_clusters
            clusters[i] = String[]
        end
        
        # Assign nodes to nearest center
        for (i, vec) in enumerate(vectors)
            distances = [norm(vec - center) for center in centers]
            nearest = argmin(distances)
            push!(clusters[nearest], node_ids[i])
        end
        
        # Update centers
        for i in 1:n_clusters
            if !isempty(clusters[i])
                cluster_vecs = [embeddings[id] for id in clusters[i]]
                centers[i] = mean(cluster_vecs)
            end
        end
    end
    
    return clusters
end

"""
    find_similar_demonstrations(graph::KnowledgeGraph, issue::Issue; k::Int=5)

Find the k most similar demonstrations for an issue.
"""
function find_similar_demonstrations(graph::KnowledgeGraph, issue::Issue; k::Int=5)
    issue_embedding = create_embedding(issue)
    
    # Calculate distances to all demonstrations
    distances = Dict{String, Float64}()
    
    for (node_id, node) in graph.nodes
        if isa(node, Demonstration)
            demo_embedding = graph.embeddings[node_id]
            distance = norm(issue_embedding - demo_embedding)
            distances[node_id] = distance
        end
    end
    
    # Sort and return top k
    sorted_demos = sort(collect(distances), by=x->x[2])
    top_k = sorted_demos[1:min(k, length(sorted_demos))]
    
    return [graph.nodes[demo_id] for (demo_id, _) in top_k]
end

# Utility functions
norm(v::Vector) = sqrt(sum(v .^ 2))
sha256(s::String) = Vector{UInt8}(sha2_256(s))

end # module DemonstrationLearning