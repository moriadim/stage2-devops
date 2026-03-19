.PHONY: up down logs restart test validate clean chaos status config

help: ## help
	@echo 'make [target]'
	@echo ''
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

up: ## 🚀 Build and start all services in detached mode
	docker-compose up -d --build

down: ## 🛑 Stop all running services
	docker-compose down

logs: ## 📊 Monitor Nginx routing and Watcher analysis simultaneously
	docker-compose logs -f nginx_proxy alert_watcher

restart: ## 🔄 Restart all services
	docker-compose restart

test: ## 🧪 Run a basic validation test on the active pool
	@echo "Testing baseline traffic..."
	@curl -s http://localhost:8080/version | grep "X-App-Pool"
	@echo "Injecting chaos for 1 second..."
	@curl -s -X POST http://localhost:8081/chaos/start?mode=error > /dev/null && sleep 1
	@curl -s http://localhost:8080/version | grep "X-App-Pool"
	@echo "Stopping chaos..."
	@curl -s -X POST http://localhost:8081/chaos/stop > /dev/null

validate: ## ✅ Run full external validation script
	bash validate_setup.sh

chaos: ## 😈 Instantly trigger Chaos Testing to simulate a crash!
	@echo "Starting Chaos... Watch your Slack alerts!"
	curl -s -X POST http://localhost:8081/chaos/start

clean: ## 🧹 Pure reset: remove containers, volumes, and wipe old logs
	docker-compose down -v
	rm -rf logs/
	@echo "Environment perfectly cleaned!"

status: ## ℹ️ Show container status
	docker-compose ps

config: ## ⚙️ Display current Nginx upstream configuration
	docker-compose exec nginx cat /etc/nginx/nginx.conf | grep -A 10 "upstream"
