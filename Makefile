.PHONY: up down logs restart test validate clean

help: ## help
	@echo 'make [target]'
	@echo ''
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

up: ## start services
	docker-compose up -d

down: ## stop services
	docker-compose down

logs: ## view logs
	docker-compose logs -f

restart: ## restart services
	docker-compose restart

test: ## run basic test
	@echo "testing..."
	@curl -s http://localhost:8080/version | grep "X-App-Pool"
	@curl -s -X POST http://localhost:8081/chaos/start?mode=error > /dev/null && sleep 1
	@curl -s http://localhost:8080/version | grep "X-App-Pool"
	@curl -s -X POST http://localhost:8081/chaos/stop > /dev/null

validate: ## run full validation
	bash validate_setup.sh

clean: ## remove containers
	docker-compose down -v

status: ## show status
	docker-compose ps

config: ## show nginx config
	docker-compose exec nginx cat /etc/nginx/nginx.conf | grep -A 10 "upstream"

