A modular, enterprise-ready 3-Tier infrastructure provisioned on Microsoft Azure using Terraform with high-availability design, 
zero-trust network isolation, modern TLS enforcement, and OWASP WAF v2 security.

![Architecture Status](https://img.shields.io/badge/Status-Verified_Live-success?style=for-the-badge)

![Terraform](https://img.shields.io/badge/Terraform-1.x-623CE4?style=for-the-badge&logo=terraform)

![Azure](https://img.shields.io/badge/Microsoft_Azure-CentralIndia-0089D6?style=for-the-badge&logo=microsoftazure)


---

## Architecture Overview

[ Internet Traffic ]
                           │
                           ▼ (Port 80 / HTTP)
               [ Standard Public IP ]
                           │
                           ▼
    ┌────────────────────────────────────────────────────────┐
    │       Azure Application Gateway (WAF v2 Tier)          │
    │      • Subnet: 10.0.1.0/24                             │
    │      • OWASP 3.2 Ruleset (Detection Mode)              │
    │      • Predefined TLS 1.2+ Policy                      │
    └───────────────────────┬────────────────────────────────┘
                            │ (Port 3000 / Reverse Proxy)
                            ▼
    ┌────────────────────────────────────────────────────────┐
    │          Tier 1: Web Tier (VM Scale Set)               │
    │      • Subnets: 10.0.10.0/24 (Zone 1)                  │
    │      • Frontend Service (Port 3000)                    │
    │      • Inbound restricted strictly to App Gateway      │
    └───────────────────────┬────────────────────────────────┘
                            │ (Port 8080 / Private Network)
                            ▼
    ┌────────────────────────────────────────────────────────┐
    │          Internal Load Balancer (ILB Standard)         │
    │      • IP: 10.0.20.4                                   │
    │      • Port 8080 Routing & Health Probes               │
    └───────────────────────┬────────────────────────────────┘
                            │
                            ▼
    ┌────────────────────────────────────────────────────────┐
    │          Tier 2: App Tier (VM Scale Set)               │
    │      • Subnets: 10.0.20.0/24 (Zone 1)                  │
    │      • Backend API Service (Port 8080)                 │
    │      • Outbound egress routed via Azure NAT Gateway    │
    └───────────────────────┬────────────────────────────────┘
                            │ (Port 5432 / TLS Required)
                            ▼
    ┌────────────────────────────────────────────────────────┐
    │          Tier 3: Database Tier (Private Link)          │
    │      • Azure Database for PostgreSQL Flexible Server   │
    │      • Delegated Subnet: 10.0.30.0/24                  │
    │      • Private DNS Zone (privatelink.postgres...)      │
    │      • Credentials stored in Azure Key Vault           │
    └────────────────────────────────────────────────────────┘


    ---

## Key Engineering & SRE Highlights

- **Remote State Management:** Configured secure Terraform remote backend on Azure Blob Storage with automated state-locking via Azure Storage leases.
- **Strict Tier-to-Tier Network Security:** Isolated tiers using dedicated Network Security Groups (NSGs). Web tier only accepts App Gateway traffic, App tier only accepts Web tier traffic, and Database tier rejects all direct external access.
- **FinOps Optimization:** Managed regional quota constraints by tuning compute SKUs (`Standard_B2s_v2` single-instance baseline) and PostgreSQL Flexible Server (`B_Standard_B1ms`) without sacrificing multi-tier separation.
- **Dynamic Secrets Engine:** Azure Key Vault securely auto-generates database administrative credentials with Key Vault Access Policies and injects them directly during provisioning.
- **Zero-Downtime Health Probing:** End-to-end health check chain configured across App Gateway (Layer 7 Probe) and Internal Load Balancer (TCP/HTTP Probe).

---

## Directory Structure

azure-3tier-production-iac/
├── environments/
│   └── prod/
│       ├── backend.tf         # Remote backend on Azure Blob Storage
│       ├── main.tf            # Root orchestrator module
│       └── outputs.tf         # Endpoints, IPs and Gateway outputs
├── modules/
│   ├── appgw/                 # WAF v2 Gateway, Public IP, TLS policies
│   ├── compute/               # VMSS Web/App tiers, ILB, Cloud-Init
│   ├── database/              # PostgreSQL Flexible Server & Private DNS
│   ├── networking/            # VNet, Subnets, NAT Gateway
│   └── security/              # Azure Key Vault, Secrets, NSGs
├── .gitignore
└── README.md




---

## Deployment Instructions

### Prerequisites
1. Azure CLI (`az login`)
2. Terraform `>= 1.5.0`
3. Active Azure Subscription

### Steps
```bash
# 1. Clone repository
git clone [https://github.com/avinash-ingle-sre/azure-3tier-production-iac.git](https://github.com/avinash-ingle-sre/azure-3tier-production-iac.git)
cd azure-3tier-production-iac/environments/prod

# 2. Initialize remote state
terraform init

# 3. Review deployment plan
terraform plan

# 4. Provision infrastructure
terraform apply -auto-approve

# 5. Destroy infrastructure (Cost-saving)
terraform destroy -auto-approve

EOF

git add README.md
git commit -m "docs: add comprehensive production architecture documentation and diagrams"
git push origin main



