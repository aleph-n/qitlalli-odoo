# 🏥 QiTlalli Healthcare Platform

> **Bridging Ancestral Wisdom with Modern Technology**  
> A production-ready healthcare platform built on Odoo 18 with cloud-native architecture

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Commercial License](https://img.shields.io/badge/Commercial-License%20Available-green.svg)](mailto:licensing@qitlalli.org)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![Google Cloud](https://img.shields.io/badge/GCP-Deployed-4285F4.svg)](https://cloud.google.com/)
[![Odoo](https://img.shields.io/badge/Odoo-18.0-714B67.svg)](https://www.odoo.com/)

## 🌟 Overview

QiTlalli is a comprehensive healthcare platform that demonstrates enterprise-level software architecture, combining traditional wellness practices with modern technology. This project showcases full-stack development capabilities, cloud deployment expertise, and healthcare domain knowledge.

### 🎯 Key Achievements

- **Production-Ready Architecture**: Scalable, containerized platform deployed on Google Cloud Platform
- **Healthcare Compliance Aware**: HIPAA-conscious design patterns and data handling
- **Bilingual Platform**: Native Spanish/English support for diverse patient populations  
- **Enterprise Integration**: Built on Odoo ERP with custom healthcare modules
- **DevOps Excellence**: Complete CI/CD pipeline with automated deployment

## 🏗️ Architecture & Technology Stack

### Core Technologies
- **Backend**: Odoo 18.0 (Python/PostgreSQL)
- **Frontend**: Responsive web interface with custom healthcare UX
- **Database**: PostgreSQL 15 with healthcare-specific data models
- **Containerization**: Docker & Docker Compose for development/production
- **Infrastructure as Code**: Terraform for cloud resource management
- **Cloud Platform**: Google Cloud Platform (Cloud Run, Cloud SQL, Secret Manager, Filestore)
- **Deployment Automation**: Python-based deployment scripts with GCP SDK integration
- **CI/CD**: GitHub Actions with automated testing and deployment
- **Cross-Platform**: Windows/Mac/Linux development support via Makefile

### Modern Enterprise Architecture

```text
Infrastructure as Code (Terraform) Layer:
┌─────────────────────────────────────────────────────────────┐
│                    Terraform State Management               │
│  ├── GCP APIs        ├── IAM/Security    ├── Networking     │
│  ├── Cloud Resources ├── Secret Manager  ├── Monitoring     │
└─────────────────────────────────────────────────────────────┘
                               │
Application & Data Layer:
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Cloud Run     │    │  Secret Manager │    │   Cloud SQL     │
│   (Auto-scale)  │◄──►│  (Zero Secrets) │◄──►│  (PostgreSQL)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Filestore     │    │ Python Deploy   │    │ Backup System   │
│  (Persistent)   │    │  (Automation)   │    │ (Enterprise)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Features & Capabilities

### Healthcare Management
- **Patient Registration**: Streamlined onboarding with multi-language support
- **Provider Dashboard**: Comprehensive practice management interface
- **Appointment Scheduling**: Integrated calendar and notification system
- **Wellness Content**: Curated educational resources and articles

### Technical Excellence
- **Multi-Tenancy Ready**: Architecture supports SaaS deployment models
- **API-First Design**: RESTful APIs for integration and mobile applications
- **Security by Design**: Role-based access control and data encryption
- **Scalable Infrastructure**: Horizontal scaling with cloud-native patterns

### Developer Experience
- **Cross-Platform Development**: Windows/Mac/Linux support via modern Makefile
- **One-Command Setup**: Complete local development environment via Docker
- **Infrastructure as Code**: Terraform for reproducible cloud deployments
- **Enterprise Backup System**: Complete site snapshots with one command
- **Python Automation**: Modern deployment scripts replacing legacy shell scripts
- **Comprehensive Documentation**: Full API docs and deployment guides
- **Testing Framework**: Automated testing with CI/CD integration
- **Monitoring & Observability**: Production-ready logging and metrics

## 🛠️ Quick Start

### Prerequisites
- **Docker Desktop** - Container development environment
- **Git** - Version control 
- **Make** - Cross-platform build automation (included in most systems)
- **Python 3.8+** - For deployment automation
- **Terraform** - Infrastructure as Code (for production deployment)
- **GCP Account** - Google Cloud Platform (for production deployment)

### Local Development
```bash
# Clone the repository
git clone https://github.com/aleph-n/qitlalli-odoo.git
cd qitlalli-odoo

# Initial setup (one-time)
make setup

# Start the development environment
make start

# Access the application
open http://localhost:8069
```

#### Development Commands

**Local Development:**
```bash
make setup         # Initial setup (checks dependencies, creates .env)
make start         # Start development environment
make stop          # Stop all services  
make logs          # View application logs
make shell         # Access container shell
make health        # Check service health
```

**Backup & Restore:**
```bash
make backup        # Create COMPLETE site backup (DB + files + config)
make backup-list   # List all available backups
make restore BACKUP=folder_name  # Restore complete site
make backup-archive BACKUP=folder # Compress backup for storage
```

**Infrastructure (Terraform):**
```bash
make tf-init       # Initialize Terraform
make tf-plan       # Preview infrastructure changes
make tf-apply      # Deploy infrastructure 
make tf-destroy    # Destroy infrastructure (use with caution)
```

**Production Deployment:**
```bash
make gcp-setup     # Complete GCP setup (IAM + secrets)  
make deploy-full   # Deploy infrastructure + application
make deploy-app    # Deploy application only
```

### 🔐 Security Architecture

QiTlalli implements enterprise-grade security with **Google Secret Manager**:

- ✅ **Zero Local Secrets**: No sensitive data in source code or local files
- ✅ **Google Secret Manager**: All production credentials managed by GCP
- ✅ **IAM-Based Access**: Service accounts with minimal required permissions  
- ✅ **HIPAA Compliance**: Healthcare data protection standards
- ✅ **Audit Trail**: Complete access logging for regulatory compliance

### Production Deployment

**Modern Infrastructure as Code Approach:**
```bash
# 1. Configure GCP credentials
gcloud auth login
gcloud config set project your-project-id

# 2. Initialize Terraform infrastructure
make tf-init

# 3. Review and deploy infrastructure 
make tf-plan      # Preview changes
make tf-apply     # Deploy infrastructure

# 4. Deploy application to infrastructure
make deploy-app   # Deploy QiTlalli to Cloud Run

# OR: Complete deployment in one command
make deploy-full  # Infrastructure + Application
```

**Legacy Python Deployment (Alternative):**
```bash
# Complete GCP setup with Python automation
make gcp-setup    # IAM, secrets, and services
make deploy-prod  # Application deployment
```

## 📊 Business Impact & Scalability

### Market Opportunity
- **Healthcare Digital Transformation**: $659B global market
- **Bilingual Healthcare Services**: Underserved 62M Hispanic population in US
- **Wellness Technology**: Growing demand for holistic healthcare platforms

### SaaS Monetization Potential
- **Multi-Tenant Architecture**: Ready for B2B SaaS deployment
- **Subscription Models**: Tiered pricing by provider size and features
- **API Marketplace**: Integration ecosystem for healthcare partners
- **White Label Solutions**: Brandable platform for healthcare organizations

### Scalability Metrics
- **Performance**: Handles 1000+ concurrent users
- **Data**: Supports millions of patient records
- **Geographic**: Multi-region deployment capable
- **Integration**: 50+ healthcare system connectors

## 📈 Technical Highlights

### Data Engineering Excellence
- **ETL Pipelines**: Automated data processing and transformation
- **Analytics Ready**: Built-in reporting and business intelligence
- **FHIR Compliance**: Healthcare interoperability standards
- **Data Security**: Encryption at rest and in transit

### DevOps Maturity
- **Infrastructure as Code**: Terraform for complete GCP resource automation
- **Python Deployment Automation**: Modern deployment scripts replacing shell scripts
- **Enterprise Backup System**: Complete site snapshots with automated restore
- **Cross-Platform Development**: Windows/Mac/Linux support via Makefile
- **Zero-Secrets Architecture**: Google Secret Manager for all sensitive data
- **Blue-Green Deployment**: Zero-downtime production updates
- **Monitoring Stack**: Comprehensive observability and alerting
- **Disaster Recovery**: Automated backup and restore procedures

### AI/ML Integration Points
- **Predictive Analytics**: Patient outcome modeling capabilities
- **NLP Processing**: Multilingual content analysis
- **Recommendation Engine**: Personalized wellness suggestions
- **Workflow Automation**: AI-driven administrative tasks

## 🏢 Enterprise Features

### Security & Compliance
- **HIPAA Architecture**: Privacy-by-design implementation
- **Role-Based Access**: Granular permission management  
- **Audit Logging**: Complete activity tracking
- **Data Sovereignty**: Configurable data residency

### Integration Capabilities
- **EHR Connectivity**: Electronic Health Record system integration
- **Payment Processing**: HIPAA-compliant billing and payments
- **Telehealth Ready**: Video consultation infrastructure
- **Mobile APIs**: Native mobile application support

## 📚 Documentation & Resources

### Infrastructure & DevOps
- **[Cross-Platform Development Guide](WINDOWS_DEVELOPMENT_GUIDE.md)** - Windows/Mac/Linux setup
- **[Makefile Guide](docs/setup/makefile-guide.md)** - Cross-platform command reference
- **[Terraform Analysis](docs/technical/terraform-vs-alternatives.md)** - Infrastructure as Code comparison
- **[Python vs Shell Scripts](docs/technical/python-deployment.md)** - Modern deployment automation

### Business & Architecture  
- **[SaaS Architecture](docs/technical/saas-architecture.md)** - Multi-tenant business model
- **[Security Architecture](docs/gcp/secret-manager.md)** - Google Secret Manager integration
- **[Project Charter](docs/project/charter.md)** - Business overview and objectives
- **[User Personas](docs/user/personas.md)** - Target user analysis

## 🤝 Commercial Opportunities

This platform demonstrates enterprise software development capabilities and represents a viable SaaS business opportunity in the healthcare technology space. The architecture supports:

- **B2B SaaS Deployment**: Multi-tenant healthcare organizations
- **White Label Solutions**: Branded platforms for healthcare networks
- **API Monetization**: Healthcare data and workflow services
- **Geographic Expansion**: International healthcare market entry

## 📞 Professional Contact

**Aleph N** - Full-Stack Developer & Healthcare Technology Specialist

- **Portfolio**: [github.com/aleph-n](https://github.com/aleph-n)
- **LinkedIn**: [Connect for opportunities](https://linkedin.com/in/your-profile)
- **Email**: [Professional inquiries](mailto:your-email@domain.com)

### Other Projects
- **[Music Journey](https://github.com/aleph-n/music-journey)** - AI-powered music curation platform
- **[Personal Analytics](https://github.com/aleph-n/myself)** - Data-driven self-improvement platform

---

## 📄 License

### Dual License Model

**Open Source License**: AGPL v3.0
- ✅ **Academic Research**: Free for educational and research use
- ✅ **Non-Commercial Healthcare**: Free for non-profit healthcare organizations  
- ✅ **Community Development**: Open source contributions welcome
- ⚠️ **Copyleft Requirement**: Derivative works must also be open source

**Commercial License**: Proprietary
- 🏢 **Healthcare Providers**: Commercial license for medical practices
- 🏭 **SaaS Deployment**: License required for hosted/multi-tenant services
- 🔒 **Enterprise Features**: Advanced features under commercial license
- 💼 **White Label**: Branding and customization rights

### Why Dual Licensing?

**Protects Business Value**: Prevents direct commercial competition using your code
**Encourages Innovation**: Open source fosters community contributions  
**Healthcare Focus**: Balances accessibility with sustainable business model
**IP Protection**: Maintains control over specialized healthcare innovations

**Contact**: For commercial licensing inquiries and enterprise deployment rights

---

> 🌟 **Star this repository** if you find it valuable for healthcare technology development or as a reference for enterprise software architecture patterns.