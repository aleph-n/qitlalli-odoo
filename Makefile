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
	@echo "💾 Backup & Restore Operations:"
	@echo "  make backup         Create COMPLETE site backup (DB + files + config)"
	@echo "  make backup-db      Create database backup only"
	@echo "  make backup-prod    Create production cloud backup"
	@echo "  make backup-list    List all available backups"
	@echo "  make restore BACKUP=<folder>  Restore complete site from backup"
	@echo "  make restore-db FILE=<file>   Restore database only"
	@echo "  make backup-archive BACKUP=<folder>  Compress backup for storage"
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

## Create database backup only
backup-db:
	$(call log_info,"Creating database backup...")
	@mkdir -p $(BACKUP_DIR)
	$(DOCKER_COMPOSE) exec -T db pg_dump -U odoo -h localhost qitlalli_db > $(BACKUP_DIR)/qitlalli_db_$(TIMESTAMP).sql
	$(call log_success,"Database backup created: $(BACKUP_DIR)/qitlalli_db_$(TIMESTAMP).sql")

## Create complete site backup (database + filestore + configuration)
backup:
	$(call log_info,"Creating complete QiTlalli site backup...")
	@mkdir -p $(BACKUP_DIR)/qitlalli_full_$(TIMESTAMP)
	$(call log_info,"1/4 Backing up database...")
	$(DOCKER_COMPOSE) exec -T db pg_dump -U odoo -h localhost qitlalli_db > $(BACKUP_DIR)/qitlalli_full_$(TIMESTAMP)/database.sql
	$(call log_info,"2/4 Backing up filestore...")
	$(DOCKER_COMPOSE) exec -T web tar -czf - /var/lib/odoo/filestore > $(BACKUP_DIR)/qitlalli_full_$(TIMESTAMP)/filestore.tar.gz
	$(call log_info,"3/4 Backing up configuration...")
	cp -r config/ $(BACKUP_DIR)/qitlalli_full_$(TIMESTAMP)/config/
	cp .env $(BACKUP_DIR)/qitlalli_full_$(TIMESTAMP)/.env 2>/dev/null || cp .env.example $(BACKUP_DIR)/qitlalli_full_$(TIMESTAMP)/.env.example
	$(call log_info,"4/4 Creating backup manifest...")
	@echo "QiTlalli Complete Site Backup" > $(BACKUP_DIR)/qitlalli_full_$(TIMESTAMP)/BACKUP_INFO.txt
	@echo "Created: $(shell date)" >> $(BACKUP_DIR)/qitlalli_full_$(TIMESTAMP)/BACKUP_INFO.txt
	@echo "Database: database.sql" >> $(BACKUP_DIR)/qitlalli_full_$(TIMESTAMP)/BACKUP_INFO.txt
	@echo "Filestore: filestore.tar.gz" >> $(BACKUP_DIR)/qitlalli_full_$(TIMESTAMP)/BACKUP_INFO.txt
	@echo "Configuration: config/ and .env files" >> $(BACKUP_DIR)/qitlalli_full_$(TIMESTAMP)/BACKUP_INFO.txt
	@echo "Docker Compose Version: $(shell $(DOCKER_COMPOSE) version --short 2>/dev/null || echo 'unknown')" >> $(BACKUP_DIR)/qitlalli_full_$(TIMESTAMP)/BACKUP_INFO.txt
	@echo "Git Commit: $(shell git rev-parse HEAD 2>/dev/null || echo 'not-a-git-repo')" >> $(BACKUP_DIR)/qitlalli_full_$(TIMESTAMP)/BACKUP_INFO.txt
	$(call log_success,"Complete backup created: $(BACKUP_DIR)/qitlalli_full_$(TIMESTAMP)/")
	$(call log_info,"Backup size: $(shell du -sh $(BACKUP_DIR)/qitlalli_full_$(TIMESTAMP) | cut -f1)")

## Create production cloud backup (for deployed sites)
backup-prod:
	$(call log_info,"Creating production site backup...")
	@mkdir -p $(BACKUP_DIR)/qitlalli_prod_$(TIMESTAMP)
	@command -v gcloud >/dev/null 2>&1 || { $(call log_error,"Google Cloud CLI is required for production backup."); exit 1; }
	$(call log_info,"1/3 Backing up Cloud SQL database...")
	gcloud sql export sql qitlalli-db gs://$(GCP_PROJECT_ID)-backups/database_$(TIMESTAMP).sql --database=qitlalli --project=$(GCP_PROJECT_ID)
	$(call log_info,"2/3 Backing up secrets...")
	@mkdir -p $(BACKUP_DIR)/qitlalli_prod_$(TIMESTAMP)/secrets
	@for secret in qitlalli-db-password qitlalli-admin-password qitlalli-jwt-secret; do \
		echo "Backing up $$secret..."; \
		gcloud secrets versions access latest --secret=$$secret --project=$(GCP_PROJECT_ID) > $(BACKUP_DIR)/qitlalli_prod_$(TIMESTAMP)/secrets/$$secret.txt; \
	done
	$(call log_info,"3/3 Backing up infrastructure state...")
	@if [ -d terraform ]; then cp -r terraform/ $(BACKUP_DIR)/qitlalli_prod_$(TIMESTAMP)/terraform/; fi
	cp deploy.py $(BACKUP_DIR)/qitlalli_prod_$(TIMESTAMP)/ 2>/dev/null || true
	$(call log_success,"Production backup created: $(BACKUP_DIR)/qitlalli_prod_$(TIMESTAMP)/")

## Archive backup (compress for long-term storage)
backup-archive:
	@if [ -z "$(BACKUP)" ]; then \
		$(call log_error,"Please specify backup directory: make backup-archive BACKUP=qitlalli_full_20251102_143000"); \
		exit 1; \
	fi
	$(call log_info,"Archiving backup: $(BACKUP)")
	@cd $(BACKUP_DIR) && tar -czf $(BACKUP).tar.gz $(BACKUP)
	$(call log_success,"Archive created: $(BACKUP_DIR)/$(BACKUP).tar.gz")
	$(call log_info,"Archive size: $(shell du -sh $(BACKUP_DIR)/$(BACKUP).tar.gz | cut -f1)")
	$(call log_warning,"You can safely delete the uncompressed backup: rm -rf $(BACKUP_DIR)/$(BACKUP)")

## List available backups
backup-list:
	$(call log_info,"Available backups in $(BACKUP_DIR):")
	@echo ""
	@echo "📁 Complete Site Backups:"
	@ls -la $(BACKUP_DIR)/ | grep qitlalli_full || echo "   No full site backups found"
	@echo ""
	@echo "🏭 Production Backups:"
	@ls -la $(BACKUP_DIR)/ | grep qitlalli_prod || echo "   No production backups found"
	@echo ""
	@echo "💾 Database Only Backups:"
	@ls -la $(BACKUP_DIR)/ | grep "\.sql$$" || echo "   No database backups found"
	@echo ""
	@echo "📦 Archived Backups:"
	@ls -la $(BACKUP_DIR)/ | grep "\.tar\.gz$$" || echo "   No archived backups found"
	@echo ""
	@echo "💡 Usage examples:"
	@echo "   make restore BACKUP=qitlalli_full_20251102_143000"
	@echo "   make restore-db FILE=qitlalli_db_20251102_143000.sql"
	@echo "   make restore-archive ARCHIVE=qitlalli_full_20251102_143000.tar.gz"

## Restore database only (usage: make restore-db FILE=backup.sql)
restore-db:
	@if [ -z "$(FILE)" ]; then \
		$(call log_error,"Please specify backup file: make restore-db FILE=backup.sql"); \
		exit 1; \
	fi
	$(call log_warning,"This will replace the current database. Are you sure? (Ctrl+C to cancel)")
	@read -p "Press Enter to continue..."
	$(call log_info,"Restoring database from $(FILE)...")
	$(DOCKER_COMPOSE) exec -T db psql -U odoo -d qitlalli_db < $(FILE)
	$(call log_success,"Database restored from $(FILE)")

## Restore complete site from backup (usage: make restore BACKUP=qitlalli_full_20251102_143000)
restore:
	@if [ -z "$(BACKUP)" ]; then \
		$(call log_error,"Please specify backup directory: make restore BACKUP=qitlalli_full_20251102_143000"); \
		exit 1; \
	fi
	@if [ ! -d "$(BACKUP_DIR)/$(BACKUP)" ]; then \
		$(call log_error,"Backup directory not found: $(BACKUP_DIR)/$(BACKUP)"); \
		$(call log_info,"Available backups:"); \
		ls -la $(BACKUP_DIR)/ | grep qitlalli_full || echo "No full backups found"; \
		exit 1; \
	fi
	$(call log_warning,"This will replace the entire site (database + filestore + config). Are you sure? (Ctrl+C to cancel)")
	@read -p "Press Enter to continue..."
	$(call log_info,"Stopping services...")
	$(DOCKER_COMPOSE) down
	$(call log_info,"1/4 Restoring database...")
	$(DOCKER_COMPOSE) up -d db
	@sleep 5
	$(DOCKER_COMPOSE) exec -T db psql -U odoo -d qitlalli_db < $(BACKUP_DIR)/$(BACKUP)/database.sql
	$(call log_info,"2/4 Restoring filestore...")
	$(DOCKER_COMPOSE) up -d web
	@sleep 5
	$(DOCKER_COMPOSE) exec -T web rm -rf /var/lib/odoo/filestore/* 2>/dev/null || true
	$(DOCKER_COMPOSE) exec -T web tar -xzf - -C / < $(BACKUP_DIR)/$(BACKUP)/filestore.tar.gz
	$(call log_info,"3/4 Restoring configuration...")
	@if [ -d "$(BACKUP_DIR)/$(BACKUP)/config" ]; then \
		cp -r $(BACKUP_DIR)/$(BACKUP)/config/* config/ 2>/dev/null || true; \
	fi
	@if [ -f "$(BACKUP_DIR)/$(BACKUP)/.env" ]; then \
		cp $(BACKUP_DIR)/$(BACKUP)/.env .env; \
	fi
	$(call log_info,"4/4 Restarting services...")
	$(DOCKER_COMPOSE) restart
	@sleep 10
	$(call log_success,"Site restored from backup: $(BACKUP)")
	$(call log_info,"Site should be available at: http://localhost:8069")

## Extract and restore from archive (usage: make restore-archive ARCHIVE=qitlalli_full_20251102_143000.tar.gz)
restore-archive:
	@if [ -z "$(ARCHIVE)" ]; then \
		$(call log_error,"Please specify archive file: make restore-archive ARCHIVE=backup.tar.gz"); \
		exit 1; \
	fi
	@if [ ! -f "$(BACKUP_DIR)/$(ARCHIVE)" ]; then \
		$(call log_error,"Archive file not found: $(BACKUP_DIR)/$(ARCHIVE)"); \
		exit 1; \
	fi
	$(call log_info,"Extracting archive: $(ARCHIVE)")
	@cd $(BACKUP_DIR) && tar -xzf $(ARCHIVE)
	@BACKUP_NAME=$$(basename $(ARCHIVE) .tar.gz) && \
	$(MAKE) restore BACKUP=$$BACKUP_NAME

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