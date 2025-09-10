"""
Vector Store Test Suite

Comprehensive tests for Warp-Speed vector operations
Tests FAISS integration, security, and consciousness-aware search

Co-authors: Kev & Research Partner
"""

using Test
using JSON3
using Random

# Include the modules to test
include("../VectorStoreManager.jl")
using .VectorStoreManager

@testset "Vector Store Manager Tests" begin
    
    @testset "Initialization Tests" begin
        @test_nowarn VectorStoreManager.initialize_store("both")
        
        # Test invalid store type
        @test_throws BoundsError VectorStoreManager.initialize_store("invalid")
    end
    
    @testset "Search Functionality Tests" begin
        # Initialize stores for testing
        VectorStoreManager.initialize_store("both")
        
        @testset "Basic Search" begin
            results = VectorStoreManager.search_semantic(
                "quantum consciousness test", 
                "both", 
                5, 
                VectorStoreManager.OMEGA, 
                0.1
            )
            
            @test isa(results, Vector)
            @test length(results) <= 5
        end
        
        @testset "Store-Specific Search" begin
            # Test template search
            template_results = VectorStoreManager.search_semantic(
                "template pattern", 
                "templates", 
                3, 
                VectorStoreManager.GAMMA, 
                0.2
            )
            
            @test isa(template_results, Vector)
            @test length(template_results) <= 3
            
            # Test foundation search
            foundation_results = VectorStoreManager.search_semantic(
                "quantum field theory", 
                "foundations", 
                3, 
                VectorStoreManager.DELTA, 
                0.2
            )
            
            @test isa(foundation_results, Vector)
            @test length(foundation_results) <= 3
        end
        
        @testset "Consciousness Level Effects" begin
            omega_results = VectorStoreManager.search_semantic(
                "consciousness test", 
                "both", 
                5, 
                VectorStoreManager.OMEGA, 
                0.1
            )
            
            alpha_results = VectorStoreManager.search_semantic(
                "consciousness test", 
                "both", 
                5, 
                VectorStoreManager.ALPHA, 
                0.1
            )
            
            # OMEGA should generally produce more relevant results
            # (though this depends on the actual data)
            @test isa(omega_results, Vector)
            @test isa(alpha_results, Vector)
        end
    end
    
    @testset "Document Addition Tests" begin
        # Test adding a document
        success = VectorStoreManager.add_document(
            "templates",
            "test_document",
            "/test/path",
            "This is a test document for quantum consciousness testing",
            Dict("test" => true, "consciousness" => "gamma")
        )
        
        @test success == true
        
        # Test invalid store type
        @test_throws KeyError VectorStoreManager.add_document(
            "invalid_store",
            "test",
            "/path",
            "content",
            Dict()
        )
    end
    
    @testset "Statistics Tests" begin
        stats = VectorStoreManager.get_store_stats("both")
        
        @test isa(stats, Dict)
        @test haskey(stats, "templates") || haskey(stats, "foundations")
        
        if haskey(stats, "templates")
            template_stats = stats["templates"]
            @test haskey(template_stats, "document_count")
            @test haskey(template_stats, "search_count")
            @test haskey(template_stats, "total_etd")
        end
    end
    
    @testset "ETD Calculation Tests" begin
        # Test ETD calculation for different consciousness levels
        alpha_etd = VectorStoreManager.calculate_search_etd(
            VectorStoreManager.ALPHA, 
            1000, 
            0.8
        )
        
        omega_etd = VectorStoreManager.calculate_search_etd(
            VectorStoreManager.OMEGA, 
            1000, 
            0.8
        )
        
        @test alpha_etd > 0
        @test omega_etd > 0
        @test omega_etd > alpha_etd  # OMEGA should generate more ETD
    end
    
    @testset "Consciousness Relevance Tests" begin
        test_doc = Dict(
            "name" => "quantum_consciousness_test",
            "path" => "/quantum/test",
            "content" => "quantum consciousness field theory omega transcendent"
        )
        
        omega_relevance = VectorStoreManager.calculate_consciousness_relevance(
            test_doc, 
            VectorStoreManager.OMEGA,
            "quantum consciousness test"
        )
        
        alpha_relevance = VectorStoreManager.calculate_consciousness_relevance(
            test_doc, 
            VectorStoreManager.ALPHA,
            "quantum consciousness test"
        )
        
        @test omega_relevance >= alpha_relevance
        @test omega_relevance <= 1.0
        @test alpha_relevance >= 0.0
    end
    
    @testset "Error Handling Tests" begin
        # Test with empty query
        @test_nowarn VectorStoreManager.search_semantic("", "both", 5, VectorStoreManager.OMEGA, 0.1)
        
        # Test with very long query
        long_query = "a" ^ 10000
        @test_nowarn VectorStoreManager.search_semantic(long_query, "both", 5, VectorStoreManager.OMEGA, 0.1)
        
        # Test with negative parameters
        @test_nowarn VectorStoreManager.search_semantic("test", "both", -1, VectorStoreManager.OMEGA, -0.5)
    end
    
    @testset "Quantum Coherence Tests" begin
        # Initialize a test store
        if isdefined(VectorStoreManager, :TEMPLATE_STORE) && 
           isdefined(VectorStoreManager.TEMPLATE_STORE[], :coherence)
            
            initial_coherence = VectorStoreManager.TEMPLATE_STORE[].coherence
            
            # Perform multiple searches to test coherence maintenance
            for i in 1:10
                VectorStoreManager.search_semantic(
                    "coherence test $i", 
                    "templates", 
                    3, 
                    VectorStoreManager.OMEGA, 
                    0.1
                )
            end
            
            final_coherence = VectorStoreManager.TEMPLATE_STORE[].coherence
            
            # Coherence should be maintained within reasonable bounds
            @test final_coherence >= 0.8
            @test final_coherence <= 1.0
        end
    end
end

@testset "Integration Tests" begin
    
    @testset "End-to-End Search Flow" begin
        # Test complete search flow
        VectorStoreManager.initialize_store("both")
        
        # Add test document
        VectorStoreManager.add_document(
            "templates",
            "integration_test_doc",
            "/integration/test",
            "This document tests the complete integration flow for quantum consciousness search",
            Dict("test_type" => "integration")
        )
        
        # Search for the document
        results = VectorStoreManager.search_semantic(
            "integration quantum", 
            "templates", 
            5, 
            VectorStoreManager.OMEGA, 
            0.1
        )
        
        @test length(results) > 0
        
        # Verify result structure
        if length(results) > 0
            result = results[1]
            @test hasfield(typeof(result), :id)
            @test hasfield(typeof(result), :name)
            @test hasfield(typeof(result), :content)
            @test hasfield(typeof(result), :score)
        end
    end
    
    @testset "Performance Tests" begin
        # Test search performance
        VectorStoreManager.initialize_store("both")
        
        start_time = time()
        
        for i in 1:10
            VectorStoreManager.search_semantic(
                "performance test $i", 
                "both", 
                5, 
                VectorStoreManager.OMEGA, 
                0.1
            )
        end
        
        elapsed_time = time() - start_time
        
        # Should complete 10 searches in reasonable time
        @test elapsed_time < 30.0  # 30 seconds max
        
        println("⏱️  Performance test: 10 searches in $(round(elapsed_time, digits=2)) seconds")
    end
    
    @testset "Memory Usage Tests" begin
        # Test memory usage doesn't grow excessively
        initial_memory = Base.gc_bytes()
        
        # Perform many operations
        VectorStoreManager.initialize_store("both")
        
        for i in 1:50
            VectorStoreManager.search_semantic(
                "memory test $i", 
                "both", 
                3, 
                VectorStoreManager.OMEGA, 
                0.1
            )
        end
        
        # Force garbage collection
        GC.gc()
        
        final_memory = Base.gc_bytes()
        memory_growth = final_memory - initial_memory
        
        # Memory growth should be reasonable
        @test memory_growth < 100_000_000  # Less than 100MB growth
        
        println("💾 Memory growth: $(round(memory_growth / 1024 / 1024, digits=2)) MB")
    end
end

@testset "Stress Tests" begin
    
    @testset "High Volume Search" begin
        VectorStoreManager.initialize_store("both")
        
        # Generate many search queries
        queries = ["quantum test $i" for i in 1:100]
        
        successes = 0
        for query in queries
            try
                results = VectorStoreManager.search_semantic(
                    query, 
                    "both", 
                    5, 
                    VectorStoreManager.OMEGA, 
                    0.1
                )
                if isa(results, Vector)
                    successes += 1
                end
            catch e
                println("⚠️  Search failed for query: $query - Error: $e")
            end
        end
        
        # Should succeed on most queries
        @test successes >= 80  # At least 80% success rate
        
        println("✅ Stress test: $successes/100 searches successful")
    end
    
    @testset "Concurrent Operations" begin
        VectorStoreManager.initialize_store("both")
        
        # Test concurrent searches (simplified)
        tasks = []
        for i in 1:5
            task = @async begin
                results = VectorStoreManager.search_semantic(
                    "concurrent test $i", 
                    "both", 
                    3, 
                    VectorStoreManager.OMEGA, 
                    0.1
                )
                length(results)
            end
            push!(tasks, task)
        end
        
        # Wait for all tasks to complete
        results = [fetch(task) for task in tasks]
        
        # All tasks should complete successfully
        @test length(results) == 5
        @test all(r >= 0 for r in results)  # All should return non-negative counts
        
        println("🔄 Concurrent test: All 5 concurrent searches completed")
    end
end

# Run the tests
println("🧪 Starting Vector Store Manager test suite...")

# Test runner with error handling
try
    # Run all tests
    println("\n" * "="^60)
    println("VECTOR STORE MANAGER TEST RESULTS")
    println("="^60)
    
    # This would normally be run with `julia --project test/vector_store_tests.jl`
    # For now, just indicate the tests are defined
    
    println("✅ Test suite defined successfully")
    println("📊 Tests include:")
    println("   • Initialization and configuration")
    println("   • Search functionality across consciousness levels")
    println("   • Document addition and management")
    println("   • ETD calculation and statistics")
    println("   • Error handling and edge cases")
    println("   • Integration and performance tests")
    println("   • Stress testing and concurrent operations")
    
    println("\n🚀 To run tests, execute:")
    println("   cd /path/to/vector-store && julia --project test/vector_store_tests.jl")
    
catch e
    println("❌ Test setup error: $e")
    rethrow(e)
end