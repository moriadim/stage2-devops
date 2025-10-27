#!/bin/bash

echo "Testing Blue/Green setup..."
echo ""

# Check if services are running
echo "1. Checking service status..."
docker-compose ps

echo ""
echo "2. Testing Nginx endpoint (expecting Blue active)..."
for i in {1..5}; do
    echo "Request $i:"
    curl -s -i http://localhost:8080/version | grep -E "HTTP|X-App-Pool|X-Release-Id"
    echo ""
done

echo ""
echo "3. Starting chaos on Blue..."
curl -X POST http://localhost:8081/chaos/start?mode=error

echo ""
echo "4. Testing Nginx endpoint after chaos (should failover to Green)..."
for i in {1..10}; do
    echo "Request $i:"
    curl -s -i http://localhost:8080/version | grep -E "HTTP|X-App-Pool|X-Release-Id"
    echo ""
done

echo ""
echo "5. Stopping chaos on Blue..."
curl -X POST http://localhost:8081/chaos/stop

echo ""
echo "Done!"

