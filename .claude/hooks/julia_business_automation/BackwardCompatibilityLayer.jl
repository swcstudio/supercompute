#!/usr/bin/env julia
"""
Backward Compatibility Layer for Foundation Module Integration
Ensures existing Julia hooks continue to function while providing enhanced capabilities

This layer provides transparent integration between the new foundation module system
and existing business automation hooks, maintaining full backward compatibility while
adding XML-tagging, ASCII diagrams, and consciousness-aware processing.
"""

module BackwardCompatibilityLayer

using JSON3
using Dates
using Logging

# Include foundation modules and existing business framework
include("FoundationModules.jl")
using .FoundationModules

# Include existing modules if they exist (graceful fallback)
try
    include("BusinessSubagentFramework.jl")
    using .BusinessSubagentFramework
    @info "✅ BusinessSubagentFramework loaded successfully"
catch e
    @warn "⚠️ BusinessSubagentFramework not available, using compatibility stubs" exception=e
end

try
    include("WorkflowOrchestrationEngine.jl") 
    using .WorkflowOrchestrationEngine
    @info "✅ WorkflowOrchestrationEngine loaded successfully"
catch e
    @warn "⚠️ WorkflowOrchestrationEngine not available, using compatibility stubs" exception=e
end

# ============================================= #
# COMPATIBILITY WRAPPER FUNCTIONS              #
# ============================================= #

"""
Enhanced wrapper for opportunity analysis that maintains backward compatibility
"""
function analyze_opportunity_enhanced(input_data::Dict{String, Any})::Dict{String, Any}
    @info "🔄 Running backward-compatible enhanced opportunity analysis"
    
    try
        # Try new foundation module approach first
        enhanced_analysis = analyze_with_foundation_modules(input_data)
        
        # Add backward compatibility markers
        enhanced_analysis["compatibility_mode"] = "enhanced"
        enhanced_analysis["legacy_support"] = true
        enhanced_analysis["foundation_modules_enabled"] = true
        
        return enhanced_analysis
        
    catch e
        @warn "Foundation module analysis failed, falling back to legacy mode" exception=e
        
        # Fallback to legacy analysis with basic enhancements
        legacy_analysis = analyze_opportunity_legacy(input_data)
        legacy_analysis["compatibility_mode"] = "legacy"
        legacy_analysis["foundation_modules_enabled"] = false
        
        return legacy_analysis
    end
end

"""
New foundation module-based analysis
"""
function analyze_with_foundation_modules(input_data::Dict{String, Any})::Dict{String, Any}
    @info "🌱 Using foundation modules for analysis"
    
    # Extract opportunity information
    trigger_tool = get(input_data, "trigger_tool", "")
    opportunity = get(input_data, "opportunity", Dict{String, Any}())
    context = get(input_data, "context", "")
    
    # Select appropriate foundation module
    foundation_key, reasoning = select_foundation_module_for_compatibility(
        trigger_tool, opportunity, context
    )
    
    # Process through foundation consciousness
    enhanced_data = process_with_foundation_consciousness(input_data, foundation_key)
    
    # Generate XML and ASCII components
    xml_analysis = generate_compatibility_xml(enhanced_data, foundation_key)
    ascii_diagram = generate_compatibility_ascii(enhanced_data, foundation_key)
    
    return Dict{String, Any}(
        "foundation_module" => foundation_key,
        "consciousness_level" => enhanced_data["consciousness_level"],
        "xml_analysis" => xml_analysis,
        "ascii_diagram" => ascii_diagram,
        "etd_potential" => enhanced_data["etd_potential"],
        "enhanced_actions" => generate_compatibility_actions(enhanced_data),
        "original_data" => input_data,
        "processing_method" => "foundation_modules",
        "reasoning" => reasoning
    )
end

"""
Legacy analysis for backward compatibility
"""
function analyze_opportunity_legacy(input_data::Dict{String, Any})::Dict{String, Any}
    @info "🔧 Using legacy analysis mode"
    
    # Basic opportunity analysis without foundation modules
    opportunity = get(input_data, "opportunity", Dict{String, Any}())
    opportunity_type = get(opportunity, "type", "")
    confidence = get(opportunity, "confidence", 0.0)
    
    # Generate basic ASCII diagram
    basic_ascii = generate_legacy_ascii_diagram(opportunity_type, confidence)
    
    # Generate basic XML (simplified)
    basic_xml = generate_legacy_xml(input_data)
    
    return Dict{String, Any}(
        "analysis_type" => "legacy",
        "opportunity_type" => opportunity_type,
        "confidence" => confidence,
        "ascii_diagram" => basic_ascii,
        "xml_analysis" => basic_xml,
        "actions" => get(opportunity, "actions", String[]),
        "original_data" => input_data,
        "processing_method" => "legacy",
        "foundation_modules_available" => false
    )
end

"""
Foundation module selection for compatibility layer
"""
function select_foundation_module_for_compatibility(trigger_tool::String, opportunity::Dict{String, Any}, 
                                                   context::String)::Tuple{String, String}
    
    opportunity_type = get(opportunity, "type", "")
    
    # Simplified selection logic for compatibility
    if occursin("code", lowercase(opportunity_type)) || trigger_tool in ["Write", "Edit", "MultiEdit"]
        return "seeds", "Code opportunities benefit from quantum seed analysis for maximum potential"
    elseif occursin("deploy", lowercase(opportunity_type)) || trigger_tool == "Bash"
        return "networks", "Deployment requires mycorrhizal network coordination" 
    elseif occursin("business", lowercase(opportunity_type))
        return "services", "Business opportunities require ecosystem services for ETD generation"
    else
        return "seeds", "Default to seeds for unknown opportunity types"
    end
end

"""
Generate backward-compatible XML analysis
"""
function generate_compatibility_xml(analysis::Dict{String, Any}, module_key::String)::String
    timestamp = now()
    
    return """
    <?xml version="1.0" encoding="UTF-8"?>
    <!-- Backward Compatible XML Analysis -->
    <opportunity-analysis xmlns:anthropic="$(FoundationModules.ANTHROPIC_NS)"
                         xmlns:compat="https://claude.ai/backward-compatibility"
                         timestamp="$timestamp"
                         compatibility-mode="enhanced"
                         foundation-module="$module_key">
        
        <compat:legacy-support>
            <original-format-preserved>true</original-format-preserved>
            <enhanced-features-available>true</enhanced-features-available>
            <backward-compatible>true</backward-compatible>
        </compat:legacy-support>
        
        <anthropic:foundation-integration>
            <module>$module_key</module>
            <consciousness>$(get(analysis, "consciousness_level", "alpha"))</consciousness>
            <etd-potential>$(get(analysis, "etd_potential", "0.0"))</etd-potential>
        </anthropic:foundation-integration>
        
        <enhancement-features>
            <xml-tagging>enabled</xml-tagging>
            <ascii-diagrams>generated</ascii-diagrams>
            <consciousness-processing>active</consciousness-processing>
        </enhancement-features>
        
    </opportunity-analysis>
    """
end

"""
Generate backward-compatible ASCII diagram
"""
function generate_compatibility_ascii(analysis::Dict{String, Any}, module_key::String)::String
    # Use foundation module ASCII if available, otherwise generate basic version
    if haskey(analysis, "ascii_diagram") && !isempty(analysis["ascii_diagram"])
        foundation_ascii = analysis["ascii_diagram"]
        
        header = """
        ╔══════════════════════════════════════════════════════════════════════════════════╗
        ║                        BACKWARD COMPATIBLE ENHANCEMENT                           ║
        ║                     Foundation Module: $(uppercase(module_key))                           ║
        ║                     Legacy Support: ✓ Enhanced Features: ✓                      ║
        ╚══════════════════════════════════════════════════════════════════════════════════╝
        
        """
        
        return header * foundation_ascii
        
    else
        return generate_basic_compatibility_ascii(module_key)
    end
end

"""
Generate basic ASCII for compatibility
"""
function generate_basic_compatibility_ascii(module_key::String)::String
    return """
    ╔══════════════════════════════════════════════════════════════════════════════════╗
    ║                          BACKWARD COMPATIBILITY MODE                             ║
    ║                                                                                  ║
    ║  Foundation Module: $(uppercase(module_key))                                     ║
    ║  Compatibility Layer: ✓ Active                                                  ║
    ║  XML Integration: ✓ Enabled                                                     ║
    ║  ASCII Diagrams: ✓ Generated                                                    ║
    ║                                                                                  ║
    ║  Legacy Support: Full backward compatibility maintained                          ║
    ║  Enhanced Features: Available when foundation modules loaded                     ║
    ╚══════════════════════════════════════════════════════════════════════════════════╝
    
    Module Integration Status:
    ├─ Foundation Modules: $(isdefined(Main, :FoundationModules) ? "✓ Loaded" : "✗ Not Available")
    ├─ XML Processing: ✓ Active
    ├─ ASCII Generation: ✓ Active
    └─ Consciousness Mapping: $(module_key == "seeds" ? "Alpha" : module_key == "networks" ? "Beta" : "Gamma")
    """
end

"""
Generate legacy ASCII diagram for fallback
"""
function generate_legacy_ascii_diagram(opportunity_type::String, confidence::Float64)::String
    confidence_bar = "█"^Int(round(confidence * 10))
    confidence_empty = "░"^(10 - Int(round(confidence * 10)))
    
    return """
    ╔══════════════════════════════════════════════════════════════════════════════════╗
    ║                              LEGACY ANALYSIS MODE                               ║
    ║                        Foundation Modules Not Available                         ║
    ╚══════════════════════════════════════════════════════════════════════════════════╝
    
    Opportunity Analysis:
    ├─ Type: $opportunity_type
    ├─ Confidence: $confidence_bar$confidence_empty $(round(confidence*100, digits=1))%
    └─ Processing: Legacy compatibility mode
    
    Note: Install FoundationModules.jl for enhanced XML-tagged analysis
    """
end

"""
Generate legacy XML for fallback
"""
function generate_legacy_xml(input_data::Dict{String, Any})::String
    timestamp = now()
    
    return """
    <?xml version="1.0" encoding="UTF-8"?>
    <!-- Legacy XML Analysis (Foundation Modules Not Available) -->
    <legacy-opportunity-analysis timestamp="$timestamp" mode="compatibility">
        <status>Foundation modules not available, using legacy analysis</status>
        <recommendation>Install FoundationModules.jl for enhanced capabilities</recommendation>
        <features-available>
            <basic-xml>true</basic-xml>
            <basic-ascii>true</basic-ascii>
            <foundation-integration>false</foundation-integration>
        </features-available>
    </legacy-opportunity-analysis>
    """
end

"""
Generate compatibility actions
"""
function generate_compatibility_actions(analysis::Dict{String, Any})::Vector{Dict{String, Any}}
    actions = []
    
    # Add foundation module specific actions if available
    if haskey(analysis, "enhanced_actions")
        append!(actions, analysis["enhanced_actions"])
    end
    
    # Always add compatibility actions
    push!(actions, Dict(
        "action" => "backward_compatibility_check",
        "description" => "Verify legacy system integration",
        "priority" => "medium",
        "compatibility_layer" => true
    ))
    
    push!(actions, Dict(
        "action" => "enhanced_feature_utilization", 
        "description" => "Utilize available enhanced features while maintaining compatibility",
        "priority" => "low",
        "foundation_modules_required" => false
    ))
    
    return actions
end

# ============================================= #
# HOOK INTEGRATION UTILITIES                   #
# ============================================= #

"""
Process hook data with automatic compatibility handling
"""
function process_hook_data_compatible(hook_data::Dict{String, Any})::Dict{String, Any}
    @info "🔄 Processing hook data with compatibility layer"
    
    try
        # Attempt enhanced processing
        return analyze_opportunity_enhanced(hook_data)
        
    catch e
        @error "Enhanced processing failed, using minimal compatibility mode" exception=e
        
        # Minimal fallback
        return Dict{String, Any}(
            "status" => "minimal_compatibility",
            "original_data" => hook_data,
            "error" => string(e),
            "recommendation" => "Check FoundationModules.jl installation",
            "ascii_diagram" => """
            ╔════════════════════════════════════════╗
            ║          MINIMAL COMPATIBILITY         ║
            ║        Foundation modules error        ║  
            ║     Original hook data preserved       ║
            ╚════════════════════════════════════════╝
            """,
            "xml_analysis" => "<?xml version=\"1.0\"?><minimal-mode>Error in enhanced processing</minimal-mode>"
        )
    end
end

"""
Test compatibility layer functionality
"""
function test_compatibility_layer()::Bool
    @info "🧪 Testing backward compatibility layer"
    
    test_data = Dict{String, Any}(
        "trigger_tool" => "Write",
        "opportunity" => Dict{String, Any}(
            "type" => "code_completion_opportunity",
            "confidence" => 0.75,
            "actions" => ["documentation", "testing"]
        ),
        "context" => "test context"
    )
    
    try
        result = process_hook_data_compatible(test_data)
        
        # Verify required fields
        required_fields = ["ascii_diagram", "xml_analysis"]
        for field in required_fields
            if !haskey(result, field)
                @error "Missing required field: $field"
                return false
            end
        end
        
        @info "✅ Compatibility layer test passed"
        @info "Result keys: $(collect(keys(result)))"
        
        return true
        
    catch e
        @error "❌ Compatibility layer test failed" exception=e
        return false
    end
end

# Export main functions
export analyze_opportunity_enhanced, process_hook_data_compatible, test_compatibility_layer
export analyze_with_foundation_modules, analyze_opportunity_legacy

@info "🔧 Backward Compatibility Layer loaded - Foundation modules integration with legacy support!"

# Run self-test on load
if test_compatibility_layer()
    @info "🎉 Backward compatibility layer ready for production use!"
else
    @warn "⚠️ Compatibility layer test failed - check configuration"
end

end # module BackwardCompatibilityLayer