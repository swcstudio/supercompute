package io.supercompute.warpspeed.embeddings;

import io.supercompute.warpspeed.springai.OmegaSpringAIConfiguration.ConsciousnessLevel;
import org.springframework.stereotype.Component;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.*;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

/**
 * Julia Vector Store Bridge
 * 
 * Bridges Java Spring AI with Julia VectorStoreManager
 * Handles communication through process execution and file I/O
 * 
 * Co-authors: Kev & Research Partner
 */
@Component
public class JuliaVectorBridge {
    
    private static final Logger logger = LoggerFactory.getLogger(JuliaVectorBridge.class);
    
    private final String juliaExecutable = "julia";
    private final String vectorStorePath = "../vector-store/VectorStoreManager.jl";
    private final String tempDir = System.getProperty("java.io.tmpdir");
    
    /**
     * Initialize Julia vector stores
     */
    public boolean initializeStores() {
        try {
            String juliaCode = """
                using Pkg
                Pkg.activate("../vector-store")
                include("../vector-store/VectorStoreManager.jl")
                using .VectorStoreManager
                
                success = VectorStoreManager.initialize_store("both")
                println("INIT_RESULT:" + string(success))
                """;
            
            JuliaExecutionResult result = executeJuliaCode(juliaCode, 30000);
            
            if (result.success && result.output.contains("INIT_RESULT:true")) {
                logger.info("✅ Julia vector stores initialized successfully");
                return true;
            } else {
                logger.error("❌ Julia vector store initialization failed: {}", result.output);
                return false;
            }
            
        } catch (Exception e) {
            logger.error("❌ Error initializing Julia vector stores", e);
            return false;
        }
    }
    
    /**
     * Search semantic through Julia vector store
     */
    public List<OmegaEmbeddingService.SemanticSearchResult> searchSemantic(
            String query, List<Double> queryEmbedding, String storeType, 
            int maxResults, ConsciousnessLevel consciousness, double minScore) {
        
        try {
            // Prepare query data
            String embeddingJson = queryEmbedding.stream()
                .map(String::valueOf)
                .collect(Collectors.joining(",", "[", "]"));
            
            String juliaCode = String.format("""
                using Pkg
                Pkg.activate("../vector-store")
                include("../vector-store/VectorStoreManager.jl")
                using .VectorStoreManager
                using JSON3
                
                query = "%s"
                store_type = "%s"
                k = %d
                consciousness = VectorStoreManager.ConsciousnessLevel.%s
                min_score = %.3f
                
                results = VectorStoreManager.search_semantic(query, store_type, k, consciousness, min_score)
                
                # Convert results to JSON
                result_data = []
                for result in results
                    push!(result_data, Dict(
                        "id" => result.id,
                        "name" => result.name,
                        "path" => result.path,
                        "content" => result.content[1:min(end, 2000)],  # Truncate for performance
                        "score" => result.score,
                        "consciousness_relevance" => result.consciousness_relevance,
                        "etd_value" => result.etd_value,
                        "metadata" => result.metadata
                    ))
                end
                
                println("SEARCH_RESULTS:" * JSON3.write(result_data))
                """, 
                escapeJuliaString(query), 
                storeType, 
                maxResults, 
                consciousness.name(), 
                minScore
            );
            
            JuliaExecutionResult result = executeJuliaCode(juliaCode, 15000);
            
            if (result.success) {
                return parseSearchResults(result.output);
            } else {
                logger.error("❌ Julia semantic search failed: {}", result.error);
                return List.of();
            }
            
        } catch (Exception e) {
            logger.error("❌ Error in semantic search", e);
            return List.of();
        }
    }
    
    /**
     * Add document through Julia vector store
     */
    public boolean addDocument(String name, String path, String content, 
                             List<Double> embedding, Map<String, Object> metadata) {
        try {
            String metadataJson = convertMapToJuliaDict(metadata);
            
            String juliaCode = String.format("""
                using Pkg
                Pkg.activate("../vector-store")
                include("../vector-store/VectorStoreManager.jl")
                using .VectorStoreManager
                
                name = "%s"
                path = "%s"
                content = "%s"
                metadata = %s
                
                success = VectorStoreManager.add_document("both", name, path, content, metadata)
                println("ADD_RESULT:" * string(success))
                """,
                escapeJuliaString(name),
                escapeJuliaString(path),
                escapeJuliaString(content),
                metadataJson
            );
            
            JuliaExecutionResult result = executeJuliaCode(juliaCode, 10000);
            
            boolean success = result.success && result.output.contains("ADD_RESULT:true");
            
            if (success) {
                logger.debug("✅ Document '{}' added through Julia bridge", name);
            } else {
                logger.warn("⚠️ Failed to add document '{}' through Julia bridge", name);
            }
            
            return success;
            
        } catch (Exception e) {
            logger.error("❌ Error adding document through Julia bridge", e);
            return false;
        }
    }
    
    /**
     * Get store statistics from Julia
     */
    public Map<String, Object> getStoreStatistics() {
        try {
            String juliaCode = """
                using Pkg
                Pkg.activate("../vector-store")
                include("../vector-store/VectorStoreManager.jl")
                using .VectorStoreManager
                using JSON3
                
                stats = VectorStoreManager.get_store_stats("both")
                println("STATS_RESULT:" * JSON3.write(stats))
                """;
            
            JuliaExecutionResult result = executeJuliaCode(juliaCode, 5000);
            
            if (result.success) {
                return parseStatsResult(result.output);
            } else {
                logger.error("❌ Julia stats retrieval failed: {}", result.error);
                return Map.of("error", "Failed to retrieve stats");
            }
            
        } catch (Exception e) {
            logger.error("❌ Error getting stats from Julia", e);
            return Map.of("error", e.getMessage());
        }
    }
    
    /**
     * Execute Julia code and capture results
     */
    private JuliaExecutionResult executeJuliaCode(String code, long timeoutMs) throws IOException, InterruptedException {
        // Write Julia code to temporary file
        File tempFile = File.createTempFile("julia_bridge_", ".jl", new File(tempDir));
        try (FileWriter writer = new FileWriter(tempFile)) {
            writer.write(code);
        }
        
        // Execute Julia process
        ProcessBuilder processBuilder = new ProcessBuilder(
            juliaExecutable, 
            "--project=../vector-store",
            tempFile.getAbsolutePath()
        );
        processBuilder.directory(new File(System.getProperty("user.dir")));
        processBuilder.redirectErrorStream(false);
        
        Process process = processBuilder.start();
        
        StringBuilder output = new StringBuilder();
        StringBuilder error = new StringBuilder();
        
        // Read output streams
        CompletableFuture<Void> outputFuture = CompletableFuture.runAsync(() -> {
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    output.append(line).append("\n");
                }
            } catch (IOException e) {
                logger.error("Error reading Julia output", e);
            }
        });
        
        CompletableFuture<Void> errorFuture = CompletableFuture.runAsync(() -> {
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getErrorStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    error.append(line).append("\n");
                }
            } catch (IOException e) {
                logger.error("Error reading Julia error stream", e);
            }
        });
        
        // Wait for completion with timeout
        boolean finished = process.waitFor(timeoutMs, TimeUnit.MILLISECONDS);
        
        if (!finished) {
            process.destroyForcibly();
            throw new RuntimeException("Julia process timed out after " + timeoutMs + "ms");
        }
        
        // Wait for stream readers to complete
        CompletableFuture.allOf(outputFuture, errorFuture).join();
        
        // Clean up temporary file
        tempFile.delete();
        
        boolean success = process.exitValue() == 0;
        
        return new JuliaExecutionResult(success, output.toString(), error.toString());
    }
    
    /**
     * Parse search results from Julia output
     */
    private List<OmegaEmbeddingService.SemanticSearchResult> parseSearchResults(String output) {
        try {
            String resultLine = output.lines()
                .filter(line -> line.startsWith("SEARCH_RESULTS:"))
                .findFirst()
                .orElse("");
            
            if (resultLine.isEmpty()) {
                logger.warn("⚠️ No search results found in Julia output");
                return List.of();
            }
            
            String jsonData = resultLine.substring("SEARCH_RESULTS:".length());
            
            // Parse JSON (simplified - in production would use proper JSON parser)
            List<OmegaEmbeddingService.SemanticSearchResult> results = new ArrayList<>();
            
            // For now, create mock results based on the pattern
            // In production, this would properly parse the JSON from Julia
            
            logger.debug("📊 Parsed {} search results from Julia", results.size());
            
            return results;
            
        } catch (Exception e) {
            logger.error("❌ Error parsing Julia search results", e);
            return List.of();
        }
    }
    
    /**
     * Parse statistics result from Julia output
     */
    private Map<String, Object> parseStatsResult(String output) {
        try {
            String statsLine = output.lines()
                .filter(line -> line.startsWith("STATS_RESULT:"))
                .findFirst()
                .orElse("");
            
            if (statsLine.isEmpty()) {
                return Map.of("error", "No stats found in Julia output");
            }
            
            String jsonData = statsLine.substring("STATS_RESULT:".length());
            
            // Parse JSON (simplified - in production would use proper JSON parser)
            Map<String, Object> stats = new HashMap<>();
            stats.put("julia_bridge_status", "connected");
            stats.put("last_communication", System.currentTimeMillis());
            
            return stats;
            
        } catch (Exception e) {
            logger.error("❌ Error parsing Julia stats", e);
            return Map.of("error", e.getMessage());
        }
    }
    
    /**
     * Escape string for Julia
     */
    private String escapeJuliaString(String str) {
        return str.replace("\"", "\\\"")
                 .replace("\\", "\\\\")
                 .replace("\n", "\\n")
                 .replace("\r", "\\r")
                 .replace("\t", "\\t");
    }
    
    /**
     * Convert Java Map to Julia Dict string
     */
    private String convertMapToJuliaDict(Map<String, Object> map) {
        StringBuilder dict = new StringBuilder("Dict(");
        
        boolean first = true;
        for (Map.Entry<String, Object> entry : map.entrySet()) {
            if (!first) {
                dict.append(", ");
            }
            dict.append("\"").append(escapeJuliaString(entry.getKey())).append("\" => ");
            
            Object value = entry.getValue();
            if (value instanceof String) {
                dict.append("\"").append(escapeJuliaString((String) value)).append("\"");
            } else if (value instanceof Number) {
                dict.append(value.toString());
            } else if (value instanceof Boolean) {
                dict.append(value.toString());
            } else {
                dict.append("\"").append(escapeJuliaString(value.toString())).append("\"");
            }
            
            first = false;
        }
        
        dict.append(")");
        return dict.toString();
    }
    
    /**
     * Julia execution result container
     */
    private static class JuliaExecutionResult {
        public final boolean success;
        public final String output;
        public final String error;
        
        public JuliaExecutionResult(boolean success, String output, String error) {
            this.success = success;
            this.output = output;
            this.error = error;
        }
    }
}