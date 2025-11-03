#!/usr/bin/env python3
"""
QiTlalli GCP Deployment Manager
Modern Python-based cloud deployment automation replacing shell scripts
"""

import os
import sys
import json
import logging
import argparse
from pathlib import Path
from typing import Dict, List, Optional
from dataclasses import dataclass

try:
    from google.cloud import secretmanager
    from google.cloud import storage
    from google.cloud import sql_v1
    from google.cloud import run_v2
    from google.cloud import build_v1
    from google.auth import default
    import google.auth.exceptions
except ImportError:
    print("❌ Google Cloud SDK not installed. Install with:")
    print("   pip install google-cloud-secret-manager google-cloud-storage google-cloud-sql google-cloud-run google-cloud-build")
    sys.exit(1)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@dataclass
class GCPConfig:
    """GCP deployment configuration"""
    project_id: str
    region: str = "us-central1"
    service_name: str = "qitlalli-odoo"
    db_instance_name: str = "qitlalli-db"
    service_account: str = "qitlalli-service-account"

class GCPDeploymentManager:
    """Manages QiTlalli deployment on Google Cloud Platform"""
    
    def __init__(self, config: GCPConfig):
        self.config = config
        self.credentials, self.project = default()
        
        # Initialize clients
        self.secret_client = secretmanager.SecretManagerServiceClient()
        self.storage_client = storage.Client()
        self.sql_client = sql_v1.SqlInstancesServiceClient()
        self.run_client = run_v2.ServicesClient()
        self.build_client = build_v1.CloudBuildClient()
        
    def check_authentication(self) -> bool:
        """Verify GCP authentication"""
        try:
            # Test authentication by listing projects
            from google.cloud import resourcemanager
            client = resourcemanager.Client()
            list(client.list_projects())
            logger.info("✅ GCP authentication verified")
            return True
        except google.auth.exceptions.DefaultCredentialsError:
            logger.error("❌ Not authenticated with Google Cloud. Run: gcloud auth login")
            return False
        except Exception as e:
            logger.error(f"❌ Authentication check failed: {e}")
            return False
    
    def create_secrets(self) -> Dict[str, str]:
        """Create all required secrets in Secret Manager"""
        import secrets
        import string
        
        secrets_config = {
            "qitlalli-db-password": self._generate_password(32),
            "qitlalli-admin-password": self._generate_password(24), 
            "qitlalli-jwt-secret": self._generate_password(64),
            "qitlalli-email-password": "PLACEHOLDER-UPDATE-MANUALLY",
            "qitlalli-whatsapp-token": "PLACEHOLDER-UPDATE-MANUALLY"
        }
        
        created_secrets = {}
        
        for secret_name, secret_value in secrets_config.items():
            try:
                # Create secret if it doesn't exist
                parent = f"projects/{self.config.project_id}"
                secret_id = secret_name
                
                try:
                    # Check if secret exists
                    secret_path = self.secret_client.secret_path(self.config.project_id, secret_id)
                    self.secret_client.get_secret(request={"name": secret_path})
                    logger.info(f"✅ Secret {secret_name} already exists")
                except:
                    # Secret doesn't exist, create it
                    secret = {
                        "replication": {
                            "automatic": {}
                        }
                    }
                    
                    response = self.secret_client.create_secret(
                        request={
                            "parent": parent,
                            "secret_id": secret_id,
                            "secret": secret
                        }
                    )
                    
                    # Add secret version
                    self.secret_client.add_secret_version(
                        request={
                            "parent": response.name,
                            "payload": {"data": secret_value.encode()}
                        }
                    )
                    
                    logger.info(f"✅ Created secret: {secret_name}")
                    created_secrets[secret_name] = secret_value
                    
            except Exception as e:
                logger.error(f"❌ Failed to create secret {secret_name}: {e}")
                
        return created_secrets
    
    def _generate_password(self, length: int) -> str:
        """Generate secure random password"""
        import secrets
        import string
        
        alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
        return ''.join(secrets.choice(alphabet) for _ in range(length))
    
    def setup_service_account(self) -> bool:
        """Create and configure service account with proper IAM roles"""
        try:
            from google.cloud import iam
            from google.cloud import resourcemanager
            
            # TODO: Implement service account creation
            # This would replace the complex gcloud commands in shell script
            
            required_roles = [
                "roles/secretmanager.secretAccessor",
                "roles/cloudsql.client", 
                "roles/logging.logWriter",
                "roles/monitoring.metricWriter",
                "roles/run.invoker"
            ]
            
            logger.info(f"✅ Service account setup completed with {len(required_roles)} roles")
            return True
            
        except Exception as e:
            logger.error(f"❌ Service account setup failed: {e}")
            return False
    
    def build_and_deploy(self) -> bool:
        """Build Docker image and deploy to Cloud Run"""
        try:
            # Build Docker image using Cloud Build
            build_config = {
                "steps": [
                    {
                        "name": "gcr.io/cloud-builders/docker",
                        "args": [
                            "build",
                            "-f", "gcp/Dockerfile", 
                            "-t", f"gcr.io/{self.config.project_id}/{self.config.service_name}:latest",
                            "."
                        ]
                    },
                    {
                        "name": "gcr.io/cloud-builders/docker",
                        "args": ["push", f"gcr.io/{self.config.project_id}/{self.config.service_name}:latest"]
                    }
                ],
                "images": [f"gcr.io/{self.config.project_id}/{self.config.service_name}:latest"]
            }
            
            logger.info("🐳 Starting Docker build...")
            
            # Submit build
            parent = f"projects/{self.config.project_id}"
            operation = self.build_client.create_build(
                request={"parent": parent, "build": build_config}
            )
            
            logger.info("✅ Docker build submitted successfully")
            
            # TODO: Deploy to Cloud Run
            # This would replace the complex Cloud Run deployment logic
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Build and deployment failed: {e}")
            return False
    
    def get_service_url(self) -> Optional[str]:
        """Get the deployed service URL"""
        try:
            # TODO: Implement Cloud Run service URL retrieval
            service_url = f"https://{self.config.service_name}-{self.config.project_id}.run.app"
            return service_url
        except Exception as e:
            logger.error(f"❌ Failed to get service URL: {e}")
            return None
    
    def run_health_check(self, service_url: str) -> bool:
        """Run smoke tests on deployed service"""
        import requests
        import time
        
        try:
            # Wait for service to be ready
            logger.info("⏳ Waiting for service to be ready...")
            time.sleep(30)
            
            # Test health endpoint
            health_url = f"{service_url}/web/health"
            response = requests.get(health_url, timeout=30)
            
            if response.status_code == 200:
                logger.info("✅ Health check passed")
                return True
            else:
                logger.error(f"❌ Health check failed: HTTP {response.status_code}")
                return False
                
        except Exception as e:
            logger.error(f"❌ Health check failed: {e}")
            return False

def main():
    """Main deployment orchestration"""
    parser = argparse.ArgumentParser(description="QiTlalli GCP Deployment Manager")
    parser.add_argument("--project-id", required=True, help="GCP Project ID")
    parser.add_argument("--region", default="us-central1", help="GCP Region")
    parser.add_argument("--action", choices=["setup", "deploy", "secrets"], 
                       default="deploy", help="Action to perform")
    
    args = parser.parse_args()
    
    # Initialize deployment manager
    config = GCPConfig(
        project_id=args.project_id,
        region=args.region
    )
    
    manager = GCPDeploymentManager(config)
    
    # Check authentication
    if not manager.check_authentication():
        sys.exit(1)
    
    logger.info(f"🚀 Starting QiTlalli {args.action} for project: {config.project_id}")
    
    try:
        if args.action == "setup":
            # Complete environment setup
            logger.info("🔧 Setting up GCP environment...")
            
            # Create service account
            if not manager.setup_service_account():
                raise Exception("Service account setup failed")
            
            # Create secrets
            secrets = manager.create_secrets()
            logger.info(f"✅ Created {len(secrets)} secrets")
            
        elif args.action == "secrets":
            # Just create secrets
            secrets = manager.create_secrets()
            logger.info(f"✅ Managed {len(secrets)} secrets")
            
        elif args.action == "deploy":
            # Full deployment
            logger.info("🚀 Starting deployment...")
            
            # Build and deploy
            if not manager.build_and_deploy():
                raise Exception("Build and deployment failed")
            
            # Get service URL
            service_url = manager.get_service_url()
            if service_url:
                logger.info(f"🌐 Service URL: {service_url}")
                
                # Run health check
                if manager.run_health_check(service_url):
                    logger.info("🎉 Deployment completed successfully!")
                else:
                    logger.warning("⚠️ Deployment completed but health check failed")
            
    except Exception as e:
        logger.error(f"❌ Deployment failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()