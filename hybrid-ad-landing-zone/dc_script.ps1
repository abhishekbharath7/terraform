<powershell>
$ErrorActionPreference = "Stop"

# 1. Force local admin password immediately
$adminPassword = "${admin_password}"
$admin = [adsi]"WinNT://localhost/Administrator,user"
$admin.SetPassword($adminPassword)

# 2. System setup and Active Directory installation
#Rename-Computer -NewName "CORP-DC01" -Force
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Import-Module ADDSDeployment

# 3. Create the password object needed ONLY for Directory Services Restore Mode (DSRM)
$SafeModePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force

# 4. Forest Provisioning with automated post-reboot enforcement
Install-ADDSForest `
  -DomainName "corp.local" `
  -SafeModeAdministratorPassword $SafeModePassword `
  -InstallDns:$true `
  -Force:$true
</powershell>