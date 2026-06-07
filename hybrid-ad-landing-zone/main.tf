provider "aws" {
  region = var.aws_region
}

# ==========================================
# 0. NETWORKING VARIABLES & LOCALS
# ==========================================
locals {
  onprem_cidr        = "10.100.1.0/24"
  prod_cidr          = "10.0.10.0/24"
  dc_static_private_ip = "10.100.1.10" # Fixes the DHCP dependency loop cleanly
}

# ==========================================
# 1. THE SIMULATED ON-PREM CORPORATE HQ VPC
# ==========================================
resource "aws_vpc" "onprem_vpc" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "Simulated-OnPrem-HQ" }
}

resource "aws_subnet" "onprem_subnet" {
  vpc_id            = aws_vpc.onprem_vpc.id
  cidr_block        = local.onprem_cidr
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "onprem-private-subnet" }
}

# Internet Access for On-Prem (To download updates/Active Directory components)
resource "aws_internet_gateway" "onprem_igw" {
  vpc_id = aws_vpc.onprem_vpc.id
  tags   = { Name = "onprem-igw" }
}

resource "aws_route_table" "onprem_rt" {
  vpc_id = aws_vpc.onprem_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.onprem_igw.id
  }
  tags = { Name = "onprem-route-table" }
}

resource "aws_route_table_association" "onprem_assoc" {
  subnet_id      = aws_subnet.onprem_subnet.id
  route_table_id = aws_route_table.onprem_rt.id
}


# ==========================================
# 2. THE AWS PRODUCTION CLOUD LANDING ZONE
# ==========================================
resource "aws_vpc" "prod_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "AWS-Production-Cloud" }
}

resource "aws_subnet" "prod_subnet" {
  vpc_id            = aws_vpc.prod_vpc.id
  cidr_block        = local.prod_cidr
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "prod-private-subnet" }
}

resource "aws_internet_gateway" "prod_igw" {
  vpc_id = aws_vpc.prod_vpc.id
  tags   = { Name = "prod-igw" }
}

resource "aws_route_table" "prod_rt" {
  vpc_id = aws_vpc.prod_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod_igw.id
  }
  tags = { Name = "prod-route-table" }
}

resource "aws_route_table_association" "prod_assoc" {
  subnet_id      = aws_subnet.prod_subnet.id
  route_table_id = aws_route_table.prod_rt.id
}


# ==========================================
# 3. THE HYBRID BRIDGE (VPC PEERING)
# ==========================================
resource "aws_vpc_peering_connection" "hybrid_link" {
  peer_vpc_id = aws_vpc.prod_vpc.id
  vpc_id      = aws_vpc.onprem_vpc.id
  auto_accept = true
  tags        = { Name = "OnPrem-to-Cloud-Peering" }
}

# Cross-Network Routing Rules
resource "aws_route" "route_onprem_to_cloud" {
  route_table_id            = aws_route_table.onprem_rt.id
  destination_cidr_block    = local.prod_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.hybrid_link.id
  depends_on = [aws_vpc_peering_connection.hybrid_link]
}

resource "aws_route" "route_cloud_to_onprem" {
  route_table_id            = aws_route_table.prod_rt.id
  destination_cidr_block    = local.onprem_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.hybrid_link.id
  depends_on = [aws_vpc_peering_connection.hybrid_link]
}


# ==========================================
# 4. SECURITY GROUPS
# ==========================================
# Active Directory Domain Controller Security Group
resource "aws_security_group" "ad_dc_sg" {
  name        = "corporate-dc-sg"
  description = "Allow inbound traffic to Domain Controller"
  vpc_id      = aws_vpc.onprem_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.prod_cidr]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change to specific public IP for production security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "corporate-dc-sg" }
} 

# Production Cloud Security Group
resource "aws_security_group" "prod_sg" {
  name        = "production-workload-sg"
  description = "Allow inbound traffic to App Server"
  vpc_id      = aws_vpc.prod_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.onprem_cidr] 
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "production-workload-sg" }
}


# ==========================================================
# 5. HYBRID DNS ROUTING (AWS DHCP OPTIONS SET)
# ==========================================================
resource "aws_vpc_dhcp_options" "dns_resolver" {
  domain_name         = "corp.local"
  domain_name_servers = [local.dc_static_private_ip, "169.254.169.253"] # DC Private IP is now known instantly

  tags = {
    Name = "hybrid-dhcp-options"
  }
}

resource "aws_vpc_dhcp_options_association" "prod_dhcp_assoc" {
  vpc_id          = aws_vpc.prod_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.dns_resolver.id
}


# ==========================================================
# 6. WINDOWS SERVER ACTIVE DIRECTORY DOMAIN CONTROLLER (DC)
# ==========================================================
data "aws_ami" "windows_2022" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
}

resource "aws_instance" "onprem_dc" {
  ami                         = data.aws_ami.windows_2022.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.onprem_subnet.id
  vpc_security_group_ids      = [aws_security_group.ad_dc_sg.id]
  associate_public_ip_address = true
  private_ip                  = local.dc_static_private_ip

  user_data = templatefile("${path.module}/dc_script.ps1", {
    admin_password = var.admin_password
  })

  tags = {
    Name = "Corporate-Domain-Controller"
  }
}


# ==========================================================
# 7. PRODUCTION WORKLOAD (AUTOMATED DOMAIN-JOIN INSTANCE)
# ==========================================================
resource "aws_instance" "prod_server" {
  ami                         = data.aws_ami.windows_2022.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.prod_subnet.id
  vpc_security_group_ids      = [aws_security_group.prod_sg.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/app_script.ps1", {
    admin_password = var.admin_password
  })

  tags = {
    Name = "Production-App-Server"
  }

  depends_on = [
    aws_vpc_peering_connection.hybrid_link,
    aws_vpc_dhcp_options_association.prod_dhcp_assoc,
    aws_instance.onprem_dc
  ]
}