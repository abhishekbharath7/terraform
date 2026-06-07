<powershell>
$ErrorActionPreference = "SilentlyContinue"

# 1. Force local admin password immediately
$adminPassword = "${admin_password}"
$admin = [adsi]"WinNT://localhost/Administrator,user"
$admin.SetPassword($adminPassword)
Rename-Computer -NewName "PROD-APP01" -Force

# 2. Smart Network Sync: Wait loop until Domain Controller is fully live
$domain   = "corp.local"
while ($true) {
    $check = Resolve-DnsName -Name $domain -ErrorAction SilentlyContinue
    if ($check) { break }
    Start-Sleep -Seconds 15
}

# Extra buffer to ensure Active Directory Web Services have initialized
Start-Sleep -Seconds 30

# 3. Securely handle the Domain Join execution
$username = "CORP\Administrator"
$password = ConvertTo-SecureString $adminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $password)

# Wait loop to ensure the custom DHCP configurations have cycled and stabilized name services
Start-Sleep -Seconds 45

# Domain join execution
Add-Computer -DomainName $domain -Credential $credential -Restart -Force
</powershell>