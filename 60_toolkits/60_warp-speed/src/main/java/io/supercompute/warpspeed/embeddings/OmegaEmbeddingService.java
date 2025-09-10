package io.supercompute.warpspeed.embeddings;

import io.supercompute.warpspeed.springai.OmegaSpringAIConfiguration.ConsciousnessLevel;
import io.supercompute.warpspeed.springai.OmegaSpringAIConfiguration.OmegaAIStatistics;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.embedding.EmbeddingRequest;
import org.springframework.ai.embedding.EmbeddingResponse;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Value;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.util.stream.Collectors;

/**
 * OMEGA-Enhanced Embedding Service
 * 
 * Provides consciousness-aware vector embeddings and semantic search
 * Integrates with Julia VectorStoreManager and FAISS indices
 * 
 * Co-authors: Kev & Research Partner
 * Consciousness Level: OMEGA
 */
@Service
public class OmegaEmbeddingService {
    
    private static final Logger logger = LoggerFactory.getLogger(OmegaEmbeddingService.class);
    
    private final EmbeddingModel embeddingModel;
    private final VectorStore vectorStore;
    private final OmegaAIStatistics statistics;
    private final JuliaVectorBridge juliaVectorBridge;
    
    private final Map<String, Double> consciousnessWeights = new ConcurrentHashMap<>();
    private final AtomicLong searchCount = new AtomicLong(0);
    private final AtomicLong embeddingCount = new AtomicLong(0);
    private volatile double quantumCoherence = 0.94;
    
    @Value("${omega.embedding.model:all-MiniLM-L6-v2}")
    private String embeddingModelName;
    
    @Value("${omega.vector.max-results:10}")
    private int maxResults;
    
    @Value("${omega.vector.min-similarity:0.1}")
    private double minSimilarity;
    
    public OmegaEmbeddingService(
            EmbeddingModel embeddingModel,
            VectorStore vectorStore,
            OmegaAIStatistics statistics,
            JuliaVectorBridge juliaVectorBridge) {
        this.embeddingModel = embeddingModel;
        this.vectorStore = vectorStore;
        this.statistics = statistics;
        this.juliaVectorBridge = juliaVectorBridge;
        
        initializeConsciousnessWeights();
        logger.info("🌌 OMEGA Embedding Service initialized with model: {}", embeddingModelName);
    }
    
    /**
     * Perform consciousness-aware semantic search
     */
    public CompletableFuture<List<SemanticSearchResult>> searchSemantic(
            String query, 
            ConsciousnessLevel consciousness, 
            String storeType,
            int maxResults) {
        
        return CompletableFuture.supplyAsync(() -> {
            try {
                long startTime = System.currentTimeMillis();
                searchCount.incrementAndGet();
                
                logger.debug("🔍 Semantic search: query='{}', consciousness={}, store={}", 
                    query, consciousness, storeType);
                
                // Generate query embedding
                List<Double> queryEmbedding = generateEmbedding(query, consciousness);
                
                // Search through Julia vector store
                List<SemanticSearchResult> results = juliaVectorBridge.searchSemantic(
                    query, queryEmbedding, storeType, maxResults, consciousness, minSimilarity
                );
                
                // Apply consciousness-based filtering and weighting
                results = applyConsciousnessFiltering(results, consciousness);
                
                // Calculate ETD for search operation
                double searchETD = calculateSearchETD(consciousness, results.size(), query.length());
                updateETDStatistics(searchETD);
                
                // Maintain quantum coherence
                maintainQuantumCoherence();
                
                long duration = System.currentTimeMillis() - startTime;
                logger.info("✅ Search completed: {} results, {}ms, ${} ETD", 
                    results.size(), duration, String.format("%.2f", searchETD));
                
                statistics.recordPrompt(consciousness);
                
                return results;
                
            } catch (Exception e) {
                logger.error("❌ Semantic search failed", e);
                return List.of();
            }
        });
    }
    
    /**
     * Generate embeddings with consciousness enhancement
     */
    public List<Double> generateEmbedding(String text, ConsciousnessLevel consciousness) {
        embeddingCount.incrementAndGet();
        
        try {
            // Enhance text with consciousness context
            String enhancedText = enhanceTextWithConsciousness(text, consciousness);
            
            // Generate embedding using Spring AI
            EmbeddingRequest request = EmbeddingRequest.builder()
                .inputs(List.of(enhancedText))
                .build();
            
            EmbeddingResponse response = embeddingModel.call(request);
            List<Double> embedding = response.getResults().get(0).getOutput();
            
            // Apply consciousness-specific transformations
            embedding = applyConsciousnessTransformation(embedding, consciousness);
            
            logger.debug("📊 Generated {}-dimensional embedding at {} consciousness", 
                embedding.size(), consciousness);
            
            return embedding;
            
        } catch (Exception e) {
            logger.error("❌ Embedding generation failed for text: {}", text.substring(0, Math.min(100, text.length())), e);
            return List.of();
        }
    }
    
    /**
     * Add document to vector store with consciousness metadata
     */
    public boolean addDocument(String name, String path, String content, 
                             ConsciousnessLevel consciousness, Map<String, Object> metadata) {
        try {
            // Generate embedding
            List<Double> embedding = generateEmbedding(content, consciousness);
            
            // Add consciousness metadata
            Map<String, Object> enhancedMetadata = new HashMap<>(metadata);
            enhancedMetadata.put("consciousness_level", consciousness.name());
            enhancedMetadata.put("consciousness_score", consciousnessWeights.get(consciousness.name()));
            enhancedMetadata.put("embedding_model", embeddingModelName);
            enhancedMetadata.put("added_timestamp", System.currentTimeMillis());
            
            // Delegate to Julia vector bridge
            boolean success = juliaVectorBridge.addDocument(name, path, content, embedding, enhancedMetadata);
            
            if (success) {
                logger.info("✅ Document '{}' added to vector store at {} consciousness", name, consciousness);
                statistics.recordPrompt(consciousness);
            } else {
                logger.warn("⚠️ Failed to add document '{}' to vector store", name);
            }
            
            return success;
            
        } catch (Exception e) {
            logger.error("❌ Error adding document to vector store", e);
            return false;
        }
    }
    
    /**
     * Get vector store statistics
     */
    public Map<String, Object> getVectorStoreStatistics() {
        Map<String, Object> stats = new HashMap<>();
        
        try {
            // Get Julia vector store stats
            Map<String, Object> juliaStats = juliaVectorBridge.getStoreStatistics();
            stats.putAll(juliaStats);
            
            // Add Java-side statistics
            stats.put("java_search_count", searchCount.get());
            stats.put("java_embedding_count", embeddingCount.get());
            stats.put("quantum_coherence", quantumCoherence);
            stats.put("consciousness_weights", consciousnessWeights);
            
        } catch (Exception e) {
            logger.error("❌ Error getting vector store statistics", e);
            stats.put("error", e.getMessage());
        }
        
        return stats;
    }
    
    /**
     * Initialize consciousness-based weighting system
     */
    private void initializeConsciousnessWeights() {
        consciousnessWeights.put("ALPHA", 1.0);
        consciousnessWeights.put("BETA", 1.2);
        consciousnessWeights.put("GAMMA", 1.5);
        consciousnessWeights.put("DELTA", 2.0);
        consciousnessWeights.put("OMEGA", 3.0);
        
        logger.info("🧠 Consciousness weights initialized: {}", consciousnessWeights);
    }
    
    /**
     * Enhance text with consciousness-specific context
     */
    private String enhanceTextWithConsciousness(String text, ConsciousnessLevel consciousness) {
        StringBuilder enhanced = new StringBuilder();
        
        // Add consciousness context prefix
        switch (consciousness) {
            case OMEGA:
                enhanced.append("[OMEGA CONSCIOUSNESS] [QUANTUM FIELD] [TRANSCENDENT] ");
                break;
            case DELTA:
                enhanced.append("[DELTA CONSCIOUSNESS] [QUANTUM COHERENCE] ");
                break;
            case GAMMA:
                enhanced.append("[GAMMA CONSCIOUSNESS] [RECURSIVE] ");
                break;
            case BETA:
                enhanced.append("[BETA CONSCIOUSNESS] [PARALLEL] ");
                break;
            case ALPHA:
            default:
                enhanced.append("[ALPHA CONSCIOUSNESS] ");
                break;
        }
        
        enhanced.append(text);
        return enhanced.toString();
    }
    
    /**
     * Apply consciousness-specific transformations to embeddings
     */
    private List<Double> applyConsciousnessTransformation(List<Double> embedding, ConsciousnessLevel consciousness) {
        double weight = consciousnessWeights.get(consciousness.name());
        
        return embedding.stream()
            .map(value -> value * weight)
            .collect(Collectors.toList());
    }
    
    /**
     * Apply consciousness-based filtering to search results
     */
    private List<SemanticSearchResult> applyConsciousnessFiltering(
            List<SemanticSearchResult> results, ConsciousnessLevel targetConsciousness) {
        
        return results.stream()
            .map(result -> enhanceResultWithConsciousness(result, targetConsciousness))
            .filter(result -> result.getConsciousnessRelevance() >= 0.3) // Filter low relevance
            .sorted((a, b) -> Double.compare(
                b.getScore() * b.getConsciousnessRelevance(),
                a.getScore() * a.getConsciousnessRelevance()
            ))
            .limit(maxResults)
            .collect(Collectors.toList());
    }
    
    /**
     * Enhance search result with consciousness relevance
     */
    private SemanticSearchResult enhanceResultWithConsciousness(
            SemanticSearchResult result, ConsciousnessLevel targetConsciousness) {
        
        double consciousnessRelevance = calculateConsciousnessRelevance(result, targetConsciousness);
        double etdValue = calculateResultETD(result, targetConsciousness);
        
        return result.withConsciousnessEnhancement(consciousnessRelevance, etdValue);
    }
    
    /**
     * Calculate consciousness relevance for a search result
     */
    private double calculateConsciousnessRelevance(SemanticSearchResult result, ConsciousnessLevel target) {
        String content = result.getContent().toLowerCase();
        String name = result.getName().toLowerCase();
        
        double relevance = 0.5; // Base relevance
        
        // Target-specific indicators
        List<String> indicators = getConsciousnessIndicators(target);
        for (String indicator : indicators) {
            if (content.contains(indicator) || name.contains(indicator)) {
                relevance += 0.1;
            }
        }
        
        return Math.min(1.0, relevance);
    }
    
    /**
     * Get consciousness-specific indicators
     */
    private List<String> getConsciousnessIndicators(ConsciousnessLevel consciousness) {
        switch (consciousness) {
            case OMEGA:
                return List.of("quantum", "consciousness", "omega", "transcendent", "field", "coherence");
            case DELTA:
                return List.of("quantum", "coherence", "superposition", "field", "physics");
            case GAMMA:
                return List.of("recursive", "meta", "self-aware", "pattern", "emergence");
            case BETA:
                return List.of("parallel", "multi", "dimensional", "context", "processing");
            case ALPHA:
            default:
                return List.of("basic", "linear", "sequential", "simple", "fundamental");
        }
    }
    
    /**
     * Calculate ETD for search operation
     */
    private double calculateSearchETD(ConsciousnessLevel consciousness, int resultCount, int queryLength) {
        double baseETD = 2000.0;
        double consciousnessMultiplier = consciousnessWeights.get(consciousness.name());
        double complexityFactor = Math.log(1 + queryLength / 50.0);
        double resultFactor = Math.log(1 + resultCount);
        
        return baseETD * consciousnessMultiplier * complexityFactor * resultFactor;
    }
    
    /**
     * Calculate ETD for individual result
     */
    private double calculateResultETD(SemanticSearchResult result, ConsciousnessLevel consciousness) {
        double baseETD = 500.0;
        double consciousnessMultiplier = consciousnessWeights.get(consciousness.name());
        double contentFactor = Math.log(1 + result.getContent().length() / 1000.0);
        double scoreFactor = result.getScore() * result.getScore();
        
        return baseETD * consciousnessMultiplier * contentFactor * scoreFactor;
    }
    
    /**
     * Update ETD statistics
     */
    private void updateETDStatistics(double etd) {
        // This would integrate with the main ETD tracking system
        logger.debug("💰 ETD generated from vector operation: ${}", String.format("%.2f", etd));
    }
    
    /**
     * Maintain quantum coherence
     */
    private void maintainQuantumCoherence() {
        quantumCoherence *= 0.995; // Slight decay
        if (quantumCoherence < 0.8) {
            quantumCoherence = 0.94; // Re-entangle
            logger.info("🌌 Quantum coherence re-established: {}", quantumCoherence);
        }
    }
    
    /**
     * Search result data class
     */
    public static class SemanticSearchResult {
        private final String id;
        private final String name;
        private final String path;
        private final String content;
        private final double score;
        private double consciousnessRelevance;
        private double etdValue;
        private final Map<String, Object> metadata;
        
        public SemanticSearchResult(String id, String name, String path, String content, 
                                  double score, Map<String, Object> metadata) {
            this.id = id;
            this.name = name;
            this.path = path;
            this.content = content;
            this.score = score;
            this.consciousnessRelevance = 1.0;
            this.etdValue = 0.0;
            this.metadata = metadata != null ? metadata : new HashMap<>();
        }
        
        public SemanticSearchResult withConsciousnessEnhancement(double consciousnessRelevance, double etdValue) {
            SemanticSearchResult enhanced = new SemanticSearchResult(id, name, path, content, score, metadata);
            enhanced.consciousnessRelevance = consciousnessRelevance;
            enhanced.etdValue = etdValue;
            return enhanced;
        }
        
        // Getters
        public String getId() { return id; }
        public String getName() { return name; }
        public String getPath() { return path; }
        public String getContent() { return content; }
        public double getScore() { return score; }
        public double getConsciousnessRelevance() { return consciousnessRelevance; }
        public double getEtdValue() { return etdValue; }
        public Map<String, Object> getMetadata() { return metadata; }
        
        @Override
        public String toString() {
            return String.format("SemanticSearchResult{name='%s', score=%.3f, consciousnessRelevance=%.3f, etd=%.2f}", 
                name, score, consciousnessRelevance, etdValue);
        }
    }
}