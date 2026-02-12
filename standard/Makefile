# Substrate Ecosystem - Docker Makefile
# Quick commands for building and managing the Docker setup

.PHONY: help build-base build up down restart logs clean test health

help: ## Show this help message
	@echo "Substrate Ecosystem Docker Commands"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

build-base: ## Build the base image with synapse
	@echo "Building base image with synapse..."
	docker build -f Dockerfile.base -t ghcr.io/hypermemetic/substrate-base:latest .

build: build-base ## Build all service images
	@echo "Building all services..."
	docker-compose build

up: ## Start all services
	@echo "Starting services..."
	docker-compose up -d
	@echo ""
	@echo "Services started. Access them at:"
	@echo "  Substrate: ws://localhost:4444"
	@echo "  Registry:  ws://localhost:4445"
	@echo "  Auth Hub:  ws://localhost:4446"

down: ## Stop all services
	@echo "Stopping services..."
	docker-compose down

restart: ## Restart all services
	@echo "Restarting services..."
	docker-compose restart

logs: ## Follow logs for all services
	docker-compose logs -f

logs-substrate: ## Follow logs for substrate only
	docker-compose logs -f substrate

logs-registry: ## Follow logs for registry only
	docker-compose logs -f registry

logs-auth: ## Follow logs for auth-hub only
	docker-compose logs -f auth-hub

clean: ## Stop services and remove volumes
	@echo "Cleaning up..."
	docker-compose down -v
	@echo "Removing images..."
	docker-compose down --rmi local

clean-all: ## Remove everything including base image
	@echo "Removing all containers, volumes, and images..."
	docker-compose down -v --rmi all
	docker rmi ghcr.io/hypermemetic/substrate-base:latest || true

health: ## Check health of all services
	@echo "Checking service health..."
	@docker-compose ps
	@echo ""
	@echo "Port checks:"
	@nc -zv localhost 4444 2>&1 | grep -q succeeded && echo "  ✓ Substrate (4444)" || echo "  ✗ Substrate (4444)"
	@nc -zv localhost 4445 2>&1 | grep -q succeeded && echo "  ✓ Registry (4445)" || echo "  ✗ Registry (4445)"
	@nc -zv localhost 4446 2>&1 | grep -q succeeded && echo "  ✓ Auth Hub (4446)" || echo "  ✗ Auth Hub (4446)"

test: ## Run test commands against services
	@echo "Testing substrate health..."
	@docker-compose exec -T substrate synapse -P 4444 substrate health check --raw || echo "Substrate not responding"
	@echo ""
	@echo "Testing auth-hub..."
	@docker-compose exec -T auth-hub synapse -P 4446 secrets auth list_secrets --prefix "" --raw || echo "Auth-hub not responding"

shell-substrate: ## Open shell in substrate container
	docker-compose exec substrate bash

shell-registry: ## Open shell in registry container
	docker-compose exec registry bash

shell-auth: ## Open shell in auth-hub container
	docker-compose exec auth-hub bash

secrets-backup: ## Backup secrets.yaml
	@mkdir -p backups
	@cp secrets/secrets.yaml backups/secrets.$(shell date +%Y%m%d_%H%M%S).yaml
	@echo "Secrets backed up to backups/"

secrets-restore: ## Restore latest secrets backup
	@cp $(shell ls -t backups/secrets.*.yaml | head -1) secrets/secrets.yaml
	@docker-compose restart auth-hub
	@echo "Secrets restored and auth-hub restarted"

dev: ## Start in development mode with live logs
	docker-compose up

rebuild: ## Rebuild and restart all services
	docker-compose build
	docker-compose up -d
	@echo "Services rebuilt and restarted"

ps: ## Show running containers
	docker-compose ps

top: ## Show resource usage
	docker-compose top
