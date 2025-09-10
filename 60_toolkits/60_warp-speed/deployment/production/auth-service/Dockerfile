# Secure Authentication Service for Warp-Speed Platform
FROM node:18-alpine AS builder

# Security: Run as non-root user
RUN addgroup -g 1000 -S appuser && \
    adduser -u 1000 -S appuser -G appuser

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies with security audit
RUN npm ci --only=production && \
    npm audit fix

# Copy application code
COPY --chown=appuser:appuser . .

# Runtime stage
FROM node:18-alpine

# Install security updates
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
    dumb-init \
    && rm -rf /var/cache/apk/*

# Create non-root user
RUN addgroup -g 1000 -S appuser && \
    adduser -u 1000 -S appuser -G appuser

WORKDIR /app

# Copy from builder
COPY --from=builder --chown=appuser:appuser /app/node_modules ./node_modules
COPY --chown=appuser:appuser . .

# Security configurations
USER appuser
EXPOSE 8443

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node healthcheck.js || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server.js"]