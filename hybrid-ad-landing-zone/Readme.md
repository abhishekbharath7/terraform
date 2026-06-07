# Automated Hybrid Cloud Identity Hub: Cross-VPC Active Directory Integration

An enterprise-grade infrastructure-as-code (IaC) deployment that automatically provisions an isolated, multi-VPC hybrid network architecture on Amazon Web Services (AWS). This architecture sets up a simulated on-premises corporate office containing a core Windows Server Active Directory Domain Controller (DC) and securely bridges it to an independent AWS Production VPC Landing Zone via a private VPC Peering connection.

The entire environment features dynamic bootstrap lifecycle configuration via PowerShell scripts (`user_data`), automated DHCP options routing for directory name services, explicit inter-subnet security boundaries, and automated domain joining.

---

## 🏗️ Architecture Design Overview

The architecture implements a dual-network sandbox designed to accurately simulate an enterprise hybrid migration or workload expansion:

1. **Simulated On-Premises HQ (`10.100.0.0/16`)**: An isolated corporate perimeter hosting the primary namespace authority (`corp.local`) on a statically assigned network interface (`10.100.1.10`) to eliminate race conditions and graph cycles during compilation.
2. **AWS Production Cloud Landing Zone (`10.0.0.0/16`)**: A separate staging environment running enterprise business applications.
3. **The Hybrid Bridge**: Bi-directional cross-network traffic travels exclusively across an `aws_vpc_peering_connection` using precise static routes (`/24` to `/24`) following the Principle of Least Privilege.
4. **Automated Identity Sync**: Workloads in the AWS Production zone auto-discover the on-premises directory services natively using a customized AWS DHCP Options Set that injects the DC private IP as the primary DNS resolver.



---

## 📂 Repository File Footprint

Ensure your local directory structure is organized as follows:

```text
├── main.tf                 # Core AWS infrastructure resources & networking fabric
├── variables.tf            # Strict type and validation boundaries for parameters
├── outputs.tf              # Informational endpoints (Public IPs, Subnets, VPC IDs)
├── terraform.tfvars        # LOCAL ONLY (Untracked) - Runtime variable values
├── dc_script.ps1           # Windows Bootstrap User Data for Forest Promotion
└── app_script.ps1          # Windows Bootstrap User Data for App Domain-Join
```


## 🛠️ Configuration & Runtime Variables

To deploy this project successfully, you must explicitly populate your environment parameters.

### 1. The Deployment File: `terraform.tfvars`

Create a file named `terraform.tfvars` in your root directory. This file contains private runtime configuration parameters and must **never** be committed to source control.

```hcl
# The target AWS region where all resources will be provisioned
aws_region     = "us-east-1"

# The hardware profile utilized for the EC2 compute workloads
instance_type  = "t3.medium"

# The master password deployed for the Windows Administrator and DSRM safe mode
# MUST meet Windows Server complexity requirements (Upper, Lower, Number, Special)
admin_password = "SecureEnterprisePass123!"
```
### 2. Version Control Safety (`.gitignore`)

Ensure your workspace includes a `.gitignore` file to prevent accidental exposures of authentication tokens, states, or passwords:

```plaintext
# Local variable definitions containing credentials
*.tfvars
*.tfvars.json

# Local terraform execution states and backups
.terraform/
*.tfstate
*.tfstate.backup
.terraform.lock.hcl
```


## 🚀 Execution & Deployment Lifecycle

Follow these steps sequentially to provision the hybrid identity hub hands-free:

### Step 1: Initialize Workspace Environment

Download required cloud API provider plug-ins, compile internal registry schemas, and initialize the system backend:

```bash
terraform init
```

### Step 2: Validate Schema Consistency

Verify that the unified configuration exhibits no syntax errors, attribute mismatches, or unreferenced variable paths:

```bash
terraform validate
```

### Step 3: Compile Execution Blueprint

Generate a deterministic plan to preview the resource modifications, hardware assignments, and routing changes before applying updates:

```bash
terraform plan
```

### Step 4: Provision Infrastructure

Execute the cloud orchestration phase to spin up the architecture. Hardware virtualization and the initial OS boot sequence take roughly 2 to 3 minutes:

```bash
terraform apply --auto-approve
```



## 🔍 Validation & Verification Matrix

Once Terraform reports a successful apply phase, the automated configuration scripts run in the background. Complete the following verification steps:

### Phase 1: Automated Identity Sync Loop (Background Check)

Active Directory promotions force a system reboot. Monitor the installation status using the AWS Console:

1. Navigate to **AWS Console** ➔ **EC2** ➔ **Instances**.
2. Select `Corporate-Domain-Controller` ➔ **Actions** ➔ **Monitor and troubleshoot** ➔ **Get instance screenshot**.
3. The Domain Controller will show a blue "Restarting" loop between minute 2 and 4 as it builds the active directory database.
4. Once the DC is fully live, check the screenshot for the `Production-App-Server`. It will automatically trigger its own reboot sequence once its internal PowerShell sync loop discovers the domain authority across the peering bridge.

### Phase 2: Command-Line Domain Validation

Log into the `Production-App-Server` via RDP using the Domain Administrator credentials:

* **Username:** `CORP\Administrator`
* **Password:** `[Your assigned admin_password value]`

Open an administrative PowerShell prompt and execute the following commands to verify identity integration:
#### 1. Confirm Domain Trust Assignment

```powershell
Get-ComputerInfo | Select-Object OsName, CsDomain, CsName, CsNetworkServer
```
**Expected Output Validation:**
* **CsName** displays `PROD-APP01`
* **CsDomain** reports `corp.local`
* **CsNetworkServer** lists `CORP-DC01`

#### 2. Confirm Private Peering Network Connectivity

```powershell
Test-Connection -ComputerName 10.100.1.10 -Count 4
```
**Expected Output Validation:**
* Low-latency, bi-directional ICMP echo responses directly from the Domain Controller's private IP (`10.100.1.10`) traversing the established VPC peering route table paths.

#### 3. Confirm DHCP Namespace Allocation

```powershell
Get-NetIPConfiguration | Select-Object InterfaceAlias, IPv4Address, DNSServer
```
**Expected Output Validation:**
* The infrastructure network interface card shows its active primary `DNSServer` mapped directly to the on-premises Domain Controller at `10.100.1.10`.



## 🧼 Workspace Cleanup & Destruction

To prevent unexpected consumption of your cloud billing quotas, tear down the architecture completely once validation testing is finalized:

```bash
terraform destroy --auto-approve
```
