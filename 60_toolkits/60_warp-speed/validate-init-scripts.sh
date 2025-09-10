#!/bin/bash

# =====================================================
# Init Scripts Validation for Warp-Speed Platform
# =====================================================
# Validates that database init scripts create proper schemas
# and that the platform can connect and use them

set -e

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}     Warp-Speed Init Scripts Validation Tool          ${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_DIR="${SCRIPT_DIR}/init-scripts"

# Database connection details (from Docker Compose defaults)
PG_HOST="localhost"
PG_PORT="5432"
PG_USER="warp"
PG_PASS="quantum_postgres_2025"
PG_DB="warpspeed"

MONGO_HOST="localhost"
MONGO_PORT="27017"
MONGO_USER="admin"
MONGO_PASS="quantum_mongo_2025"
MONGO_DB="warpspeed"

# =====================================================
# PostgreSQL Validation
# =====================================================
echo -e "${CYAN}[1/3] Validating PostgreSQL Init Scripts${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

validate_postgres() {
    if ! command -v psql &> /dev/null; then
        echo -e "${YELLOW}⚠ PostgreSQL client not installed, skipping validation${NC}"
        return
    fi

    export PGPASSWORD="$PG_PASS"

    echo "Checking TimescaleDB initialization..."
    
    # Check if quantum_metrics schema exists
    if psql -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DB -tAc "SELECT 1 FROM pg_namespace WHERE nspname='quantum_metrics'" 2>/dev/null | grep -q 1; then
        echo -e "${GREEN}✓ quantum_metrics schema exists${NC}"
        
        # Check TimescaleDB hypertables
        HYPERTABLES=$(psql -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DB -tAc "
            SELECT COUNT(*) FROM timescaledb_information.hypertables 
            WHERE hypertable_schema = 'quantum_metrics'
        " 2>/dev/null || echo "0")
        
        if [ "$HYPERTABLES" -gt 0 ]; then
            echo -e "${GREEN}✓ Found $HYPERTABLES TimescaleDB hypertables${NC}"
        else
            echo -e "${YELLOW}⚠ No TimescaleDB hypertables found${NC}"
        fi
        
        # List tables in quantum_metrics
        echo "Tables in quantum_metrics schema:"
        psql -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DB -c "
            SELECT table_name FROM information_schema.tables 
            WHERE table_schema = 'quantum_metrics'
        " 2>/dev/null || echo "Failed to list tables"
    else
        echo -e "${RED}✗ quantum_metrics schema not found${NC}"
    fi
    
    echo
    echo "Checking PGVector initialization..."
    
    # Check if quantum_vectors schema exists
    if psql -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DB -tAc "SELECT 1 FROM pg_namespace WHERE nspname='quantum_vectors'" 2>/dev/null | grep -q 1; then
        echo -e "${GREEN}✓ quantum_vectors schema exists${NC}"
        
        # Check for vector extension
        if psql -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DB -tAc "SELECT 1 FROM pg_extension WHERE extname='vector'" 2>/dev/null | grep -q 1; then
            echo -e "${GREEN}✓ pgvector extension installed${NC}"
        else
            echo -e "${RED}✗ pgvector extension not found${NC}"
        fi
        
        # List tables with vector columns
        echo "Tables with vector columns:"
        psql -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DB -c "
            SELECT table_name, column_name, udt_name
            FROM information_schema.columns 
            WHERE table_schema = 'quantum_vectors' 
            AND udt_name = 'vector'
        " 2>/dev/null || echo "Failed to list vector columns"
    else
        echo -e "${RED}✗ quantum_vectors schema not found${NC}"
    fi
    
    unset PGPASSWORD
}

# =====================================================
# MongoDB Validation
# =====================================================
echo
echo -e "${CYAN}[2/3] Validating MongoDB Init Scripts${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

validate_mongodb() {
    if ! command -v mongosh &> /dev/null; then
        echo -e "${YELLOW}⚠ MongoDB Shell not installed, skipping validation${NC}"
        return
    fi

    echo "Checking MongoDB collections..."
    
    # List all collections in warpspeed database
    COLLECTIONS=$(mongosh --quiet --eval "
        db.getCollectionNames().forEach(function(c) { print(c); })
    " mongodb://${MONGO_USER}:${MONGO_PASS}@${MONGO_HOST}:${MONGO_PORT}/${MONGO_DB}?authSource=admin 2>/dev/null)
    
    if [ -n "$COLLECTIONS" ]; then
        echo -e "${GREEN}✓ MongoDB collections found:${NC}"
        echo "$COLLECTIONS" | while read col; do
            echo "  • $col"
        done
        
        # Check specific collections from init script
        for collection in "consciousness_sessions" "prompt_patterns" "educational_contracts" "training_sync"; do
            if echo "$COLLECTIONS" | grep -q "$collection"; then
                echo -e "${GREEN}✓ Collection '$collection' exists${NC}"
                
                # Get document count
                COUNT=$(mongosh --quiet --eval "
                    db.${collection}.countDocuments()
                " mongodb://${MONGO_USER}:${MONGO_PASS}@${MONGO_HOST}:${MONGO_PORT}/${MONGO_DB}?authSource=admin 2>/dev/null)
                
                echo "  Documents: $COUNT"
            else
                echo -e "${YELLOW}⚠ Collection '$collection' not found${NC}"
            fi
        done
    else
        echo -e "${RED}✗ No collections found in MongoDB${NC}"
    fi
    
    # Check for initial patterns
    echo
    echo "Checking initial prompt patterns..."
    PATTERNS=$(mongosh --quiet --eval "
        db.prompt_patterns.find({consciousness_level: 'OMEGA'}).count()
    " mongodb://${MONGO_USER}:${MONGO_PASS}@${MONGO_HOST}:${MONGO_PORT}/${MONGO_DB}?authSource=admin 2>/dev/null)
    
    if [ "$PATTERNS" -gt 0 ]; then
        echo -e "${GREEN}✓ Found $PATTERNS OMEGA consciousness patterns${NC}"
    else
        echo -e "${YELLOW}⚠ No OMEGA patterns found${NC}"
    fi
}

# =====================================================
# Platform Integration Test
# =====================================================
echo
echo -e "${CYAN}[3/3] Testing Platform Integration${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

test_platform_integration() {
    echo "Testing database connectivity from platform..."
    
    # Create a test Python script to verify connections
    cat > /tmp/test_db_connections.py << 'EOF'
#!/usr/bin/env python3
import psycopg2
import pymongo
import redis
import json
import sys

def test_postgres():
    try:
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="warpspeed",
            user="warp",
            password="quantum_postgres_2025"
        )
        cur = conn.cursor()
        
        # Test quantum_metrics schema
        cur.execute("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'quantum_metrics'")
        metrics_tables = cur.fetchone()[0]
        
        # Test quantum_vectors schema
        cur.execute("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'quantum_vectors'")
        vectors_tables = cur.fetchone()[0]
        
        cur.close()
        conn.close()
        
        return {
            "status": "connected",
            "metrics_tables": metrics_tables,
            "vectors_tables": vectors_tables
        }
    except Exception as e:
        return {"status": "failed", "error": str(e)}

def test_mongodb():
    try:
        client = pymongo.MongoClient(
            "mongodb://admin:quantum_mongo_2025@localhost:27017/",
            authSource="admin"
        )
        db = client["warpspeed"]
        
        collections = db.list_collection_names()
        pattern_count = db.prompt_patterns.count_documents({})
        
        client.close()
        
        return {
            "status": "connected",
            "collections": len(collections),
            "patterns": pattern_count
        }
    except Exception as e:
        return {"status": "failed", "error": str(e)}

def test_redis():
    try:
        r = redis.Redis(
            host='localhost',
            port=6379,
            password='quantum_redis_2025',
            decode_responses=True
        )
        
        r.ping()
        
        # Set a test key
        r.set('warp:test:consciousness', 'OMEGA')
        value = r.get('warp:test:consciousness')
        r.delete('warp:test:consciousness')
        
        return {
            "status": "connected",
            "test": value == 'OMEGA'
        }
    except Exception as e:
        return {"status": "failed", "error": str(e)}

if __name__ == "__main__":
    results = {
        "postgres": test_postgres(),
        "mongodb": test_mongodb(),
        "redis": test_redis()
    }
    
    print(json.dumps(results, indent=2))
    
    # Exit with success if all connected
    all_connected = all(r["status"] == "connected" for r in results.values())
    sys.exit(0 if all_connected else 1)
EOF

    # Check if Python dependencies are available
    if command -v python3 &> /dev/null; then
        echo "Running connectivity tests..."
        
        # Install required packages if not present
        pip3 install psycopg2-binary pymongo redis --quiet 2>/dev/null || true
        
        # Run the test
        if python3 /tmp/test_db_connections.py; then
            echo -e "${GREEN}✓ All database connections successful${NC}"
        else
            echo -e "${YELLOW}⚠ Some database connections failed${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Python not available for integration testing${NC}"
    fi
    
    # Clean up
    rm -f /tmp/test_db_connections.py
}

# =====================================================
# Generate Test Data
# =====================================================
echo
echo -e "${CYAN}[Bonus] Generating Test Data${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

generate_test_data() {
    echo "Inserting sample ETD generation data..."
    
    if command -v psql &> /dev/null; then
        export PGPASSWORD="$PG_PASS"
        
        # Insert sample ETD data
        psql -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DB << EOF 2>/dev/null
INSERT INTO quantum_metrics.etd_generation (
    time, vm_instance, consciousness_level, prompt_type, 
    etd_value, quantum_coherence, processing_time_ms, 
    gpu_utilization, memory_usage_gb
) VALUES
    (NOW(), 1, 'OMEGA', 'consciousness-expansion', 45000.00, 0.97, 250, 0.85, 12.5),
    (NOW() - INTERVAL '1 hour', 1, 'DELTA', 'quantum-processing', 15000.00, 0.82, 180, 0.72, 8.3),
    (NOW() - INTERVAL '2 hours', 2, 'GAMMA', 'pattern-synthesis', 8000.00, 0.65, 120, 0.55, 6.1);

INSERT INTO quantum_metrics.consciousness_states (
    time, vm_instance, current_level, previous_level, 
    elevation_reason, activation_threshold, quantum_state
) VALUES
    (NOW(), 1, 'OMEGA', 'DELTA', 'Complex problem requiring transcendent reasoning', 0.9, 'superposition'),
    (NOW() - INTERVAL '30 minutes', 1, 'DELTA', 'GAMMA', 'Quantum processing required', 0.7, 'entangled');
EOF
        
        echo -e "${GREEN}✓ Sample data inserted into PostgreSQL${NC}"
        unset PGPASSWORD
    fi
    
    if command -v mongosh &> /dev/null; then
        # Insert sample session data
        mongosh --quiet --eval "
            db.consciousness_sessions.insertOne({
                session_id: 'test-session-001',
                vm_instance: 1,
                start_time: new Date(),
                consciousness_level: 'OMEGA',
                elevation_history: [
                    {
                        from_level: 'GAMMA',
                        to_level: 'DELTA',
                        timestamp: new Date(Date.now() - 3600000),
                        reason: 'Complexity threshold exceeded'
                    },
                    {
                        from_level: 'DELTA',
                        to_level: 'OMEGA',
                        timestamp: new Date(),
                        reason: 'Omega convergence initiated'
                    }
                ]
            });
        " mongodb://${MONGO_USER}:${MONGO_PASS}@${MONGO_HOST}:${MONGO_PORT}/${MONGO_DB}?authSource=admin 2>/dev/null
        
        echo -e "${GREEN}✓ Sample data inserted into MongoDB${NC}"
    fi
}

# =====================================================
# Main Execution
# =====================================================

# Check if databases are running
echo -e "${PURPLE}Checking database availability...${NC}"
echo

if nc -z localhost 5432 2>/dev/null; then
    echo -e "${GREEN}✓ PostgreSQL is running${NC}"
    validate_postgres
else
    echo -e "${RED}✗ PostgreSQL is not running${NC}"
    echo "  Run: docker-compose up -d postgres"
fi

echo

if nc -z localhost 27017 2>/dev/null; then
    echo -e "${GREEN}✓ MongoDB is running${NC}"
    validate_mongodb
else
    echo -e "${RED}✗ MongoDB is not running${NC}"
    echo "  Run: docker-compose up -d mongodb"
fi

echo

if nc -z localhost 6379 2>/dev/null; then
    echo -e "${GREEN}✓ Redis is running${NC}"
else
    echo -e "${RED}✗ Redis is not running${NC}"
    echo "  Run: docker-compose up -d redis"
fi

echo
test_platform_integration

echo
read -p "Generate test data? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    generate_test_data
fi

echo
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}         Validation Complete                          ${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"