#!/bin/bash

set -e

echo "Validating Blue/Green setup..."
echo ""

# Check docker-compose
if ! command -v docker-compose &> /dev/null; then
    echo "ERROR: docker-compose not found"
    exit 1
fi

# Check .env exists
if [ ! -f .env ]; then
    echo "ERROR: .env file not found"
    exit 1
fi

# Source .env
source .env

# Validate env vars
if [ -z "$BLUE_IMAGE" ] || [ -z "$GREEN_IMAGE" ]; then
    echo "ERROR: BLUE_IMAGE and GREEN_IMAGE must be set"
    exit 1
fi

echo "env vars ok"
echo "  BLUE_IMAGE: $BLUE_IMAGE"
echo "  GREEN_IMAGE: $GREEN_IMAGE"
echo "  ACTIVE_POOL: $ACTIVE_POOL"
echo ""

# Start services
echo "Starting services..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 10

# Test Nginx endpoint
echo ""
echo "Testing Nginx endpoint..."
for i in {1..5}; do
    response=$(curl -s -w "\n%{http_code}" http://localhost:8080/version)
    http_code=$(echo "$response" | tail -1)
    headers=$(echo "$response" | grep -E "X-App-Pool|X-Release-Id" || true)
    
    echo "Request $i: HTTP $http_code"
    echo "$headers"
    
    if [ "$http_code" != "200" ]; then
        echo "❌ Request $i failed with HTTP $http_code"
        docker-compose logs nginx
        exit 1
    fi
done

echo ""
echo "baseline tests passed"
echo ""
echo "Testing failover..."

curl -X POST http://localhost:8081/chaos/start?mode=error
sleep 2

success_count=0
for i in {1..20}; do
    response=$(curl -s -w "\n%{http_code}" http://localhost:8080/version)
    http_code=$(echo "$response" | tail -1)
    
    if [ "$http_code" == "200" ]; then
        success_count=$((success_count + 1))
    fi
    
    if [ "$http_code" != "200" ]; then
        echo "ERROR: Request $i failed with HTTP $http_code"
        echo "Response: $(echo "$response" | head -n -1)"
        docker-compose logs nginx
        curl -X POST http://localhost:8081/chaos/stop
        exit 1
    fi
done

echo "failover works: $success_count/20 successful requests"

curl -X POST http://localhost:8081/chaos/stop

echo ""
echo "All good!"

