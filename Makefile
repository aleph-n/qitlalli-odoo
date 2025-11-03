# QiTlalli Healthcare Platform - Development Makefile
# Cross-platform development commands for QiTlalli Odoo

.PHONY: help setup start stop restart logs shell db-shell backup restore clean test lint deploy-dev deploy-prod status health

# Default target
.DEFAULT_GOAL := help

# Variables
DOCKER_COMPOSE := docker-compose
PROJECT_NAME := qitlalli-odoo
DB_CONTAINER := $(PROJECT_NAME)-db-1
WEB_CONTAINER := $(PROJECT_NAME)-web-1
BACKUP_DIR := ./backups
TIMESTAMP := $(shell date +%Y%m%d_%H%M%S)

# Colors for output (works in most terminals)
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Helper function to print colored output
define log_info
	@printf "$(BLUE)ℹ️  %s$(NC)\n" "$(1)"
endef

define log_success
	@printf "$(GREEN)✅ %s$(NC)\n" "$(1)"
endef

define log_warning
	@printf "$(YELLOW)⚠️  %s$(NC)\n" "$(1)"
endef

define log_error
	@printf "$(RED)❌ %s$(NC)\n" "$(1)"
endef

## Display this help message
help:
	@echo "QiTlalli Healthcare Platform - Development Commands"
	@echo ""
	@echo "🏥 Healthcare Platform Development:"
	@echo "  make setup          Initial project setup and dependency check"
	@echo "  make start          Start the development environment"
	@echo "  make stop           Stop all services"
	@echo "  make restart        Restart all services"
	@echo "  make logs           View application logs"
	@echo ""
	@echo "🐳 Container Management:"
	@echo "  make shell          Access Odoo container shell"
	@echo "  make db-shell       Access PostgreSQL database shell"
	@echo "  make status         Show container status"
	@echo "  make health         Check service health"
	@echo ""
	@echo "💾 Database Operations:"
	@echo "  make backup         Create database backup"
	@echo "  make restore FILE=<backup.sql>  Restore from backup"
	@echo ""
	@echo "🔧 Development Tools:"
	@echo "  make update         Update Odoo modules"
	@echo "  make install        Install custom modules"
	@echo "  make test           Run tests"
	@echo "  make lint           Run code linting"
	@echo ""
	@echo "☁️  Infrastructure (Terraform):"
	@echo "  make tf-init          Initialize Terraform"
	@echo "  make tf-plan          Plan infrastructure changes"
	@echo "  make tf-apply         Apply infrastructure changes"
	@echo "  make tf-destroy       Destroy infrastructure (use with caution)"
	@echo ""
	@echo "🚀 Deployment (Python-based):"
	@echo "  make gcp-setup        Complete GCP setup (IAM + secrets)"
	@echo "  make gcp-secrets      Manage Google Cloud secrets"
	@echo "  make deploy-prod      Complete production deployment"
	@echo "  make deploy-shell     Legacy shell deployment (deprecated)"
	@echo ""
	@echo "🔐 Secret Management:"
	@echo "  make secrets-create   Create all required GCP secrets"
	@echo "  make secrets-list     List all secrets"
	@echo "  make secrets-update   Update existing secrets"
	@echo "  make secrets-rotate   Rotate database password"
	@echo ""
	@echo "🧹 Maintenance:"
	@echo "  make clean          Clean up containers and volumes"
	@echo "  make clean-all      Remove everything including images"

## Initial project setup and dependency verification
setup:
	$(call log_info,"Setting up QiTlalli development environment...")
	@command -v docker >/dev/null 2>&1 || { $(call log_error,"Docker is required but not installed. Please install Docker first."); exit 1; }
	@command -v docker-compose >/dev/null 2>&1 || { $(call log_error,"Docker Compose is required but not installed."); exit 1; }
	$(call log_success,"Docker and Docker Compose are installed")
	@if [ ! -f .env ]; then \
		$(call log_info,"Creating .env file from template..."); \
		cp .env.example .env; \
		$(call log_warning,"Please review and update the .env file with your settings"); \
	fi
	@mkdir -p $(BACKUP_DIR)
	$(call log_info,"Creating necessary directories...")
	$(call log_success,"Setup completed! Run 'make start' to begin development")

## Start the development environment
start:
	$(call log_info,"Starting QiTlalli development environment...")
	$(DOCKER_COMPOSE) up -d
	$(call log_info,"Waiting for services to be ready...")
	@sleep 10
	$(call log_success,"Development environment is ready!")
	$(call log_info,"Access the application at: http://localhost:8069")
	$(call log_info,"Database admin at: http://localhost:8080")

## Stop all services
stop:
	$(call log_info,"Stopping QiTlalli services...")
	$(DOCKER_COMPOSE) down
	$(call log_success,"All services stopped")

## Restart all services
restart: stop start

## View application logs
logs:
	$(call log_info,"Showing application logs (Ctrl+C to exit)...")
	$(DOCKER_COMPOSE) logs -f

## Access Odoo container shell
shell:
	$(call log_info,"Accessing Odoo container shell...")
	$(DOCKER_COMPOSE) exec web bash

## Access PostgreSQL database shell
db-shell:
	$(call log_info,"Accessing PostgreSQL database...")
	$(DOCKER_COMPOSE) exec db psql -U odoo -d qitlalli_db

## Show container status
status:
	$(call log_info,"Container status:")
	$(DOCKER_COMPOSE) ps

## Check service health
health:
	$(call log_info,"Checking service health...")
	@echo "Web Service:"
	@curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:8069 || echo "Web service not accessible"
	@echo "Database Service:"
	@$(DOCKER_COMPOSE) exec -T db pg_isready -U odoo || echo "Database not ready"

## Create database backup
backup:
	$(call log_info,"Creating database backup...")
	@mkdir -p $(BACKUP_DIR)
	$(DOCKER_COMPOSE) exec -T db pg_dump -U odoo -h localhost qitlalli_db > $(BACKUP_DIR)/qitlalli_backup_$(TIMESTAMP).sql
	$(call log_success,"Backup created: $(BACKUP_DIR)/qitlalli_backup_$(TIMESTAMP).sql")

## Restore database from backup (usage: make restore FILE=backup.sql)
restore:
	@if [ -z "$(FILE)" ]; then \
		$(call log_error,"Please specify backup file: make restore FILE=backup.sql"); \
		exit 1; \
	fi
	$(call log_warning,"This will replace the current database. Are you sure? (Ctrl+C to cancel)")
	@read -p "Press Enter to continue..."
	$(call log_info,"Restoring database from $(FILE)...")
	$(DOCKER_COMPOSE) exec -T db psql -U odoo -d qitlalli_db < $(FILE)
	$(call log_success,"Database restored from $(FILE)")

## Update Odoo modules
update:
	$(call log_info,"Updating Odoo modules...")
	$(DOCKER_COMPOSE) exec web odoo -d qitlalli_db -u all --stop-after-init
	$(call log_success,"Modules updated")

## Install custom modules
install:
	$(call log_info,"Installing custom modules...")
	$(DOCKER_COMPOSE) exec web odoo -d qitlalli_db -i base --stop-after-init
	$(call log_success,"Modules installed")

## Run tests
test:
	$(call log_info,"Running tests...")
	$(DOCKER_COMPOSE) exec web python -m pytest tests/ -v
	$(call log_success,"Tests completed")

## Run code linting
lint:
	$(call log_info,"Running code linting...")
	@if command -v flake8 >/dev/null 2>&1; then \
		flake8 . --exclude=.git,__pycache__,migrations; \
	else \
		$(call log_warning,"flake8 not installed. Install with: pip install flake8"); \
	fi
	@if command -v black >/dev/null 2>&1; then \
		black --check .; \
	else \
		$(call log_warning,"black not installed. Install with: pip install black"); \
	fi

## Deploy to development environment
deploy-dev:
	$(call log_info,"Deploying to development environment...")
	$(call log_warning,"Development deployment not yet implemented")
	$(call log_info,"For local development, use 'make start'")

## Deploy to production (GCP)
deploy-prod:
	$(call log_info,"Deploying to GCP production environment...")
	@command -v gcloud >/dev/null 2>&1 || { $(call log_error,"Google Cloud CLI is required but not installed."); exit 1; }
	$(call log_info,"Verifying secrets exist...")
	@make secrets-verify
	$(call log_info,"Building and pushing Docker image...")
	@cd gcp && ./deploy.sh
	$(call log_success,"Production deployment completed!")

## Complete GCP setup with IAM and secrets (Python-based)
gcp-setup:
	$(call log_info,"Setting up complete GCP environment...")
	@command -v python3 >/dev/null 2>&1 || { $(call log_error,"Python 3 is required but not installed."); exit 1; }
	$(call log_info,"Installing Python GCP dependencies...")
	@pip install -r requirements.txt
	$(call log_info,"Running GCP setup...")
	@python3 deploy.py --project-id=${GCP_PROJECT_ID} --action=setup
	$(call log_success,"GCP environment setup completed!")

## Create all required secrets (Python-based)
gcp-secrets:
	$(call log_info,"Creating Google Cloud secrets...")
	@python3 deploy.py --project-id=${GCP_PROJECT_ID} --action=secrets
	$(call log_success,"Secrets management completed!")

## Initialize Terraform
tf-init:
	$(call log_info,"Initializing Terraform...")
	@command -v terraform >/dev/null 2>&1 || { $(call log_error,"Terraform is required but not installed. Install from https://terraform.io"); exit 1; }
	@cd terraform && terraform init
	$(call log_success,"Terraform initialized!")

## Plan infrastructure changes
tf-plan:
	$(call log_info,"Planning infrastructure changes...")
	@cd terraform && terraform plan -var="project_id=${GCP_PROJECT_ID}"
	$(call log_success,"Terraform plan completed!")

## Apply infrastructure changes
tf-apply:
	$(call log_info,"Applying infrastructure changes...")
	@cd terraform && terraform apply -var="project_id=${GCP_PROJECT_ID}" -auto-approve
	$(call log_success,"Infrastructure deployed successfully!")

## Destroy infrastructure (use with caution)
tf-destroy:
	$(call log_warning,"This will destroy ALL infrastructure resources!")
	@read -p "Are you absolutely sure? Type 'destroy' to confirm: " confirm && [ "$$confirm" = "destroy" ] || exit 1
	$(call log_info,"Destroying infrastructure...")
	@cd terraform && terraform destroy -var="project_id=${GCP_PROJECT_ID}" -auto-approve
	$(call log_success,"Infrastructure destroyed!")

## Complete infrastructure + application deployment
deploy-full: tf-apply deploy-app
	$(call log_success,"🎉 Full deployment completed!")

## Deploy application only (assumes infrastructure exists)
deploy-app:
	$(call log_info,"Deploying application to existing infrastructure...")
	@command -v python3 >/dev/null 2>&1 || { $(call log_error,"Python 3 is required but not installed."); exit 1; }
	$(call log_info,"Installing deployment dependencies...")
	@pip install -r requirements.txt
	$(call log_info,"Running application deployment...")
	@python3 deploy.py --project-id=${GCP_PROJECT_ID} --action=deploy
	$(call log_success,"Application deployment completed!")

## Complete production deployment (Python-based)
deploy-prod: deploy-full
	$(call log_success,"🎉 Production deployment completed!")

## Legacy shell script support (deprecated - use Terraform + Python instead)
deploy-shell:
	$(call log_warning,"Using legacy shell scripts (deprecated)")
	$(call log_info,"Consider using 'make deploy-full' for modern Terraform + Python deployment")
	@cd gcp && ./deploy.sh

## Create all required GCP secrets
secrets-create:
	$(call log_info,"Creating Google Cloud secrets...")
	@command -v gcloud >/dev/null 2>&1 || { $(call log_error,"Google Cloud CLI is required but not installed."); exit 1; }
	$(call log_info,"Creating database password secret...")
	@openssl rand -base64 32 | gcloud secrets create qitlalli-db-password --data-file=- || true
	$(call log_info,"Creating admin password secret...")
	@openssl rand -base64 24 | gcloud secrets create qitlalli-admin-password --data-file=- || true
	$(call log_info,"Creating JWT secret...")
	@openssl rand -base64 64 | gcloud secrets create qitlalli-jwt-secret --data-file=- || true
	$(call log_warning,"Please manually create email and WhatsApp secrets with your credentials:")
	@echo "  gcloud secrets create qitlalli-email-password --data-file=- <<< 'your-gmail-app-password'"
	@echo "  gcloud secrets create qitlalli-whatsapp-token --data-file=- <<< 'your-whatsapp-token'"
	$(call log_success,"Core secrets created successfully!")

## List all secrets
secrets-list:
	$(call log_info,"Listing all QiTlalli secrets...")
	@gcloud secrets list --filter="name:qitlalli-*" --format="table(name,created,labels)"

## Update existing secrets
secrets-update:
	$(call log_warning,"This will create new versions of existing secrets!")
	@read -p "Enter secret name to update: " secret_name; \
	read -s -p "Enter new secret value: " secret_value; \
	echo; \
	echo "$$secret_value" | gcloud secrets versions add $$secret_name --data-file=-
	$(call log_success,"Secret updated successfully!")

## Rotate database password
secrets-rotate:
	$(call log_warning,"This will rotate the database password and require service restart!")
	@read -p "Are you sure? [y/N]: " confirm && [ "$$confirm" = "y" ] || exit 1
	$(call log_info,"Generating new database password...")
	@openssl rand -base64 32 | gcloud secrets versions add qitlalli-db-password --data-file=-
	$(call log_success,"Database password rotated. Redeploy services to apply changes.")

## Verify all required secrets exist
secrets-verify:
	$(call log_info,"Verifying required secrets exist...")
	@for secret in qitlalli-db-password qitlalli-admin-password qitlalli-jwt-secret; do \
		gcloud secrets describe $$secret >/dev/null 2>&1 || { \
			$(call log_error,"Required secret $$secret not found. Run 'make secrets-create' first."); \
			exit 1; \
		}; \
	done
	$(call log_success,"All required secrets verified!")

## List all secrets
secrets-list:
	$(call log_info,"Listing all QiTlalli secrets...")
	@gcloud secrets list --filter="name:qitlalli-*" --format="table(name,created,labels)"

## Update existing secrets
secrets-update:
	$(call log_warning,"This will create new versions of existing secrets!")
	@read -p "Enter secret name to update: " secret_name; \
	read -s -p "Enter new secret value: " secret_value; \
	echo; \
	echo "$$secret_value" | gcloud secrets versions add $$secret_name --data-file=-
	$(call log_success,"Secret updated successfully!")

## Rotate database password
secrets-rotate:
	$(call log_warning,"This will rotate the database password and require service restart!")
	@read -p "Are you sure? [y/N]: " confirm && [ "$$confirm" = "y" ] || exit 1
	$(call log_info,"Generating new database password...")
	@openssl rand -base64 32 | gcloud secrets versions add qitlalli-db-password --data-file=-
	$(call log_success,"Database password rotated. Redeploy services to apply changes.")

## Verify all required secrets exist
secrets-verify:
	$(call log_info,"Verifying required secrets exist...")
	@for secret in qitlalli-db-password qitlalli-admin-password qitlalli-jwt-secret; do \
		gcloud secrets describe $$secret >/dev/null 2>&1 || { \
			$(call log_error,"Required secret $$secret not found. Run 'make secrets-create' first."); \
			exit 1; \
		}; \
	done
	$(call log_success,"All required secrets verified!")

## Clean up containers and volumes
clean:
	$(call log_info,"Cleaning up containers and volumes...")
	$(DOCKER_COMPOSE) down -v --remove-orphans
	$(call log_success,"Cleanup completed")

## Remove everything including images
clean-all:
	$(call log_warning,"This will remove all containers, volumes, and images!")
	@read -p "Are you sure? [y/N]: " confirm && [ "$$confirm" = "y" ] || exit 1
	$(call log_info,"Removing everything...")
	$(DOCKER_COMPOSE) down -v --remove-orphans --rmi all
	docker system prune -f
	$(call log_success,"Complete cleanup finished")

## Clean up containers and volumes
clean:
	$(call log_info,"Cleaning up containers and volumes...")
	$(DOCKER_COMPOSE) down -v
	$(call log_success,"Cleanup completed")

## Remove everything including images
clean-all:
	$(call log_warning,"This will remove all containers, volumes, and images")
	@read -p "Are you sure? Press Enter to continue..."
	$(DOCKER_COMPOSE) down -v --rmi all
	docker system prune -f
	$(call log_success,"Deep cleanup completed")

# Development shortcuts
dev-start: start
dev-stop: stop
dev-restart: restart
dev-logs: logs

# Database shortcuts
db-backup: backup
db-restore: restore

# Deployment shortcuts
dev: deploy-dev
prod: deploy-prod