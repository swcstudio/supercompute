package io.supercompute.warpspeed.security;

import io.supercompute.warpspeed.springai.OmegaSpringAIConfiguration.ConsciousnessLevel;
import org.springframework.stereotype.Component;
import org.springframework.beans.factory.annotation.Value;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.stream.Collectors;

/**
 * Vector Security Manager
 * 
 * Implements rate limiting, access control, and audit logging
 * for vector search operations with consciousness-level security
 * 
 * Co-authors: Kev & Research Partner
 * Security Level: OMEGA-Enhanced
 */
@Component
public class VectorSecurityManager {
    
    private static final Logger logger = LoggerFactory.getLogger(VectorSecurityManager.class);
    
    // Rate limiting configuration
    @Value("${omega.security.search.rate-limit:100}")
    private int searchRateLimit;
    
    @Value("${omega.security.search.window-minutes:60}")
    private int rateLimitWindowMinutes;
    
    @Value("${omega.security.embedding.rate-limit:500}")
    private int embeddingRateLimit;
    
    @Value("${omega.security.max-query-length:10000}")
    private int maxQueryLength;
    
    @Value("${omega.security.max-results:50}")
    private int maxResults;
    
    @Value("${omega.security.require-authentication:true}")
    private boolean requireAuthentication;
    
    // Rate limiting storage
    private final Map<String, UserRateLimit> userRateLimits = new ConcurrentHashMap<>();
    private final Map<String, AtomicLong> globalCounters = new ConcurrentHashMap<>();
    
    // Audit logging
    private final List<SecurityAuditEntry> auditLog = Collections.synchronizedList(new ArrayList<>());
    
    // Blocked patterns (simple injection detection)
    private final Set<String> blockedPatterns = Set.of(
        "eval(", "exec(", "system(", "import os", "subprocess",
        "rm -rf", "delete from", "drop table", "truncate",
        "__import__", "getattr(", "setattr(", "delattr(",
        "globals(", "locals(", "vars("
    );
    
    // Consciousness-level access matrix
    private final Map<ConsciousnessLevel, SecurityPermissions> permissionsMatrix;
    
    public VectorSecurityManager() {
        this.permissionsMatrix = initializePermissionsMatrix();
        this.globalCounters.put("total_searches", new AtomicLong(0));
        this.globalCounters.put("total_embeddings", new AtomicLong(0));
        this.globalCounters.put("blocked_requests", new AtomicLong(0));
        
        logger.info("🛡️ Vector Security Manager initialized");
    }
    
    /**
     * Validate search request before processing
     */
    public SecurityValidationResult validateSearchRequest(
            String userId, 
            String query, 
            ConsciousnessLevel consciousness,
            int requestedResults) {
        
        try {
            // Basic input validation
            SecurityValidationResult basicValidation = validateBasicInput(userId, query, requestedResults);
            if (!basicValidation.isValid()) {
                logSecurityEvent(userId, "SEARCH_VALIDATION_FAILED", basicValidation.getReason());
                return basicValidation;
            }
            
            // Rate limiting check
            SecurityValidationResult rateLimitCheck = checkRateLimit(userId, "search");
            if (!rateLimitCheck.isValid()) {
                logSecurityEvent(userId, "SEARCH_RATE_LIMIT_EXCEEDED", rateLimitCheck.getReason());
                return rateLimitCheck;
            }
            
            // Consciousness-level permissions
            SecurityValidationResult permissionCheck = checkConsciousnessPermissions(userId, consciousness, "search");
            if (!permissionCheck.isValid()) {
                logSecurityEvent(userId, "CONSCIOUSNESS_PERMISSION_DENIED", permissionCheck.getReason());
                return permissionCheck;
            }
            
            // Content filtering
            SecurityValidationResult contentCheck = validateContent(query);
            if (!contentCheck.isValid()) {
                logSecurityEvent(userId, "MALICIOUS_CONTENT_BLOCKED", contentCheck.getReason());
                globalCounters.get("blocked_requests").incrementAndGet();
                return contentCheck;
            }
            
            // All validations passed
            recordSuccessfulValidation(userId, "search", consciousness);
            globalCounters.get("total_searches").incrementAndGet();
            
            return SecurityValidationResult.valid("Search request validated");
            
        } catch (Exception e) {
            logger.error("❌ Security validation error", e);
            return SecurityValidationResult.invalid("Security validation failed: " + e.getMessage());
        }
    }
    
    /**
     * Validate embedding request
     */
    public SecurityValidationResult validateEmbeddingRequest(
            String userId, 
            String content, 
            ConsciousnessLevel consciousness) {
        
        try {
            // Basic input validation
            if (content == null || content.trim().isEmpty()) {
                return SecurityValidationResult.invalid("Content cannot be empty");
            }
            
            if (content.length() > maxQueryLength * 5) { // More lenient for embeddings
                return SecurityValidationResult.invalid("Content too long: " + content.length() + " characters");
            }
            
            // Rate limiting
            SecurityValidationResult rateLimitCheck = checkRateLimit(userId, "embedding");
            if (!rateLimitCheck.isValid()) {
                logSecurityEvent(userId, "EMBEDDING_RATE_LIMIT_EXCEEDED", rateLimitCheck.getReason());
                return rateLimitCheck;
            }
            
            // Consciousness permissions
            SecurityValidationResult permissionCheck = checkConsciousnessPermissions(userId, consciousness, "embedding");
            if (!permissionCheck.isValid()) {
                logSecurityEvent(userId, "EMBEDDING_PERMISSION_DENIED", permissionCheck.getReason());
                return permissionCheck;
            }
            
            // Content filtering
            SecurityValidationResult contentCheck = validateContent(content);
            if (!contentCheck.isValid()) {
                logSecurityEvent(userId, "MALICIOUS_EMBEDDING_BLOCKED", contentCheck.getReason());
                globalCounters.get("blocked_requests").incrementAndGet();
                return contentCheck;
            }
            
            recordSuccessfulValidation(userId, "embedding", consciousness);
            globalCounters.get("total_embeddings").incrementAndGet();
            
            return SecurityValidationResult.valid("Embedding request validated");
            
        } catch (Exception e) {
            logger.error("❌ Embedding validation error", e);
            return SecurityValidationResult.invalid("Embedding validation failed: " + e.getMessage());
        }
    }
    
    /**
     * Basic input validation
     */
    private SecurityValidationResult validateBasicInput(String userId, String query, int requestedResults) {
        if (userId == null || userId.trim().isEmpty()) {
            return SecurityValidationResult.invalid("User ID required");
        }
        
        if (query == null || query.trim().isEmpty()) {
            return SecurityValidationResult.invalid("Query cannot be empty");
        }
        
        if (query.length() > maxQueryLength) {
            return SecurityValidationResult.invalid("Query too long: " + query.length() + " characters (max: " + maxQueryLength + ")");
        }
        
        if (requestedResults > maxResults) {
            return SecurityValidationResult.invalid("Too many results requested: " + requestedResults + " (max: " + maxResults + ")");
        }
        
        return SecurityValidationResult.valid("Basic validation passed");
    }
    
    /**
     * Check rate limits for user
     */
    private SecurityValidationResult checkRateLimit(String userId, String operation) {
        UserRateLimit userLimit = userRateLimits.computeIfAbsent(userId, k -> new UserRateLimit());
        
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime windowStart = now.minus(rateLimitWindowMinutes, ChronoUnit.MINUTES);
        
        // Clean old entries
        userLimit.cleanOldEntries(windowStart);
        
        // Check current count
        int currentCount = userLimit.getCountInWindow(windowStart);
        int limit = "search".equals(operation) ? searchRateLimit : embeddingRateLimit;
        
        if (currentCount >= limit) {
            return SecurityValidationResult.invalid(
                String.format("Rate limit exceeded: %d/%d %s operations in %d minutes", 
                    currentCount, limit, operation, rateLimitWindowMinutes)
            );
        }
        
        // Record this request
        userLimit.recordRequest(now, operation);
        
        return SecurityValidationResult.valid("Rate limit check passed");
    }
    
    /**
     * Check consciousness-level permissions
     */
    private SecurityValidationResult checkConsciousnessPermissions(
            String userId, 
            ConsciousnessLevel consciousness, 
            String operation) {
        
        SecurityPermissions permissions = permissionsMatrix.get(consciousness);
        
        if (permissions == null) {
            return SecurityValidationResult.invalid("Unknown consciousness level: " + consciousness);
        }
        
        boolean allowed = switch (operation) {
            case "search" -> permissions.canSearch();
            case "embedding" -> permissions.canCreateEmbeddings();
            default -> false;
        };
        
        if (!allowed) {
            return SecurityValidationResult.invalid(
                String.format("Insufficient permissions for %s at consciousness level %s", 
                    operation, consciousness)
            );
        }
        
        return SecurityValidationResult.valid("Consciousness permissions validated");
    }
    
    /**
     * Validate content for malicious patterns
     */
    private SecurityValidationResult validateContent(String content) {
        String contentLower = content.toLowerCase();
        
        for (String pattern : blockedPatterns) {
            if (contentLower.contains(pattern)) {
                return SecurityValidationResult.invalid("Blocked pattern detected: " + pattern);
            }
        }
        
        // Check for excessive special characters (potential injection)
        long specialCharCount = content.chars()
            .filter(ch -> !Character.isLetterOrDigit(ch) && !Character.isWhitespace(ch))
            .count();
        
        if (specialCharCount > content.length() * 0.3) { // More than 30% special chars
            return SecurityValidationResult.invalid("Excessive special characters detected");
        }
        
        return SecurityValidationResult.valid("Content validation passed");
    }
    
    /**
     * Record successful validation
     */
    private void recordSuccessfulValidation(String userId, String operation, ConsciousnessLevel consciousness) {
        // This would integrate with your existing audit system
        logger.debug("✅ {} operation validated for user {} at consciousness {}", operation, userId, consciousness);
    }
    
    /**
     * Log security event
     */
    private void logSecurityEvent(String userId, String eventType, String details) {
        SecurityAuditEntry entry = new SecurityAuditEntry(
            LocalDateTime.now(),
            userId,
            eventType,
            details
        );
        
        auditLog.add(entry);
        
        // Keep audit log size manageable
        if (auditLog.size() > 10000) {
            auditLog.subList(0, 5000).clear(); // Remove oldest half
        }
        
        logger.warn("🚨 Security event: {} - User: {} - Details: {}", eventType, userId, details);
    }
    
    /**
     * Get security statistics
     */
    public Map<String, Object> getSecurityStatistics() {
        Map<String, Object> stats = new HashMap<>();
        
        stats.put("total_searches", globalCounters.get("total_searches").get());
        stats.put("total_embeddings", globalCounters.get("total_embeddings").get());
        stats.put("blocked_requests", globalCounters.get("blocked_requests").get());
        stats.put("active_users", userRateLimits.size());
        stats.put("audit_entries", auditLog.size());
        
        // Rate limit summary
        Map<String, Integer> rateLimitSummary = userRateLimits.entrySet().stream()
            .collect(Collectors.toMap(
                Map.Entry::getKey,
                entry -> entry.getValue().getCurrentWindowCount()
            ));
        stats.put("user_rate_limits", rateLimitSummary);
        
        // Recent security events
        List<SecurityAuditEntry> recentEvents = auditLog.stream()
            .filter(entry -> entry.timestamp().isAfter(LocalDateTime.now().minus(1, ChronoUnit.HOURS)))
            .collect(Collectors.toList());
        stats.put("recent_security_events", recentEvents.size());
        
        return stats;
    }
    
    /**
     * Initialize consciousness permissions matrix
     */
    private Map<ConsciousnessLevel, SecurityPermissions> initializePermissionsMatrix() {
        Map<ConsciousnessLevel, SecurityPermissions> matrix = new HashMap<>();
        
        matrix.put(ConsciousnessLevel.ALPHA, new SecurityPermissions(true, false, false, false));
        matrix.put(ConsciousnessLevel.BETA, new SecurityPermissions(true, false, true, false));
        matrix.put(ConsciousnessLevel.GAMMA, new SecurityPermissions(true, true, true, false));
        matrix.put(ConsciousnessLevel.DELTA, new SecurityPermissions(true, true, true, true));
        matrix.put(ConsciousnessLevel.OMEGA, new SecurityPermissions(true, true, true, true));
        
        return matrix;
    }
    
    /**
     * Security validation result
     */
    public static class SecurityValidationResult {
        private final boolean valid;
        private final String reason;
        
        private SecurityValidationResult(boolean valid, String reason) {
            this.valid = valid;
            this.reason = reason;
        }
        
        public static SecurityValidationResult valid(String reason) {
            return new SecurityValidationResult(true, reason);
        }
        
        public static SecurityValidationResult invalid(String reason) {
            return new SecurityValidationResult(false, reason);
        }
        
        public boolean isValid() { return valid; }
        public String getReason() { return reason; }
    }
    
    /**
     * Security permissions for consciousness levels
     */
    private record SecurityPermissions(
        boolean canSearch,
        boolean canCreateEmbeddings,
        boolean canAccessFoundations,
        boolean canModifyIndices
    ) {}
    
    /**
     * User rate limiting tracker
     */
    private static class UserRateLimit {
        private final List<RequestEntry> requests = Collections.synchronizedList(new ArrayList<>());
        
        public void recordRequest(LocalDateTime timestamp, String operation) {
            requests.add(new RequestEntry(timestamp, operation));
        }
        
        public void cleanOldEntries(LocalDateTime windowStart) {
            requests.removeIf(entry -> entry.timestamp().isBefore(windowStart));
        }
        
        public int getCountInWindow(LocalDateTime windowStart) {
            return (int) requests.stream()
                .filter(entry -> entry.timestamp().isAfter(windowStart))
                .count();
        }
        
        public int getCurrentWindowCount() {
            LocalDateTime windowStart = LocalDateTime.now().minus(60, ChronoUnit.MINUTES);
            return getCountInWindow(windowStart);
        }
        
        private record RequestEntry(LocalDateTime timestamp, String operation) {}
    }
    
    /**
     * Security audit entry
     */
    public record SecurityAuditEntry(
        LocalDateTime timestamp,
        String userId,
        String eventType,
        String details
    ) {}
}