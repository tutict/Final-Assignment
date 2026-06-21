#!/bin/bash

# k6 Performance Test Suite Runner
# Run all performance tests in sequence

set -e  # Exit on error

# Configuration
BASE_URL=${BASE_URL:-http://localhost:8080}
RESULTS_DIR="k6-tests/results"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "=========================================="
echo "k6 Performance Test Suite"
echo "=========================================="
echo "Base URL: $BASE_URL"
echo "Results Directory: $RESULTS_DIR"
echo ""

# Create results directory
mkdir -p "$RESULTS_DIR"

# Check if services are running
echo "Checking if services are accessible..."
if ! curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/actuator/health" | grep -q "200\|404"; then
    echo -e "${RED}❌ Services are not accessible at $BASE_URL${NC}"
    echo "Please start all microservices before running tests."
    exit 1
fi
echo -e "${GREEN}✅ Services are accessible${NC}"
echo ""

# Test 1: Smoke Test (Quick validation - 30 seconds)
echo -e "${YELLOW}[1/4] Running Smoke Test (30s)...${NC}"
if k6 run --out json="$RESULTS_DIR/smoke-test.json" k6-tests/01-smoke-test.js; then
    echo -e "${GREEN}✅ Smoke Test PASSED${NC}"
else
    echo -e "${RED}❌ Smoke Test FAILED - Critical endpoints not responding${NC}"
    echo "Fix critical issues before proceeding with other tests."
    exit 1
fi
echo ""

# Test 2: Load Test (Normal operations - 9 minutes)
echo -e "${YELLOW}[2/4] Running Load Test (9 min)...${NC}"
if k6 run --out json="$RESULTS_DIR/load-test.json" k6-tests/02-load-test.js; then
    echo -e "${GREEN}✅ Load Test PASSED${NC}"
else
    echo -e "${RED}⚠️  Load Test had issues - Check results${NC}"
fi
echo ""

# Test 3: Stress Test (Peak load - 15 minutes)
echo -e "${YELLOW}[3/4] Running Stress Test (15 min)...${NC}"
if k6 run --out json="$RESULTS_DIR/stress-test.json" k6-tests/03-stress-test.js; then
    echo -e "${GREEN}✅ Stress Test PASSED${NC}"
else
    echo -e "${RED}⚠️  Stress Test had issues - System may struggle under peak load${NC}"
fi
echo ""

# Test 4: Critical Flows (Business workflows)
echo -e "${YELLOW}[4/4] Running Critical Flow Test...${NC}"
if k6 run --out json="$RESULTS_DIR/critical-flows.json" k6-tests/06-critical-flows.js; then
    echo -e "${GREEN}✅ Critical Flow Test PASSED${NC}"
else
    echo -e "${RED}⚠️  Critical Flow Test had issues - Check workflow integrity${NC}"
fi
echo ""

echo "=========================================="
echo -e "${GREEN}✅ All tests completed!${NC}"
echo "=========================================="
echo ""
echo "Results saved in: $RESULTS_DIR/"
echo ""
echo "Quick Summary:"
echo "  - Smoke Test: Basic endpoint validation"
echo "  - Load Test: 50-100 concurrent users"
echo "  - Stress Test: Up to 300 concurrent users"
echo "  - Critical Flows: End-to-end workflows"
echo ""
echo "To view detailed results:"
echo "  cat $RESULTS_DIR/*.json | jq '.metrics'"
echo ""
echo "Next steps:"
echo "  1. Review test results in $RESULTS_DIR/"
echo "  2. Check application logs for errors"
echo "  3. Monitor database and cache metrics"
echo "  4. Address any performance bottlenecks"
echo ""
