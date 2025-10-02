#ps1_sysnative

$ViaAdminUsername = "${ViaAdminUsername}"
$ViaAdminPassword = "${ViaAdminPassword}" | ConvertTo-SecureString -AsPlainText -Force

if (-not (Get-LocalUser -Name $ViaAdminUsername -ErrorAction SilentlyContinue)) {
  New-LocalUser -Name $ViaAdminUsername -Password $ViaAdminPassword -AccountNeverExpires:$true
} else {
  Set-LocalUser -Name $ViaAdminUsername -Password $ViaAdminPassword
}
Add-LocalGroupMember -Group "Administrators" -Member $ViaAdminUsername

# Evita “password must be changed at next logon”
WMIC USERACCOUNT WHERE "Name='$ViaAdminUsername'" SET PasswordExpires=FALSE | Out-Null



$TestUsername = "${ViaAdminUsername}"
$TestPassword = "${ViaAdminPassword}" | ConvertTo-SecureString -AsPlainText -Force

if (-not (Get-LocalUser -Name $TestUsername -ErrorAction SilentlyContinue)) {
  New-LocalUser -Name $TestUsername -Password $TestPassword -AccountNeverExpires:$true
} else {
  Set-LocalUser -Name $TestUsername -Password $TestPassword
}
Add-LocalGroupMember -Group "Administrators" -Member $TestUsername

# Evita “password must be changed at next logon”
WMIC USERACCOUNT WHERE "Name='$TestUsername'" SET PasswordExpires=FALSE | Out-Null


Write-Host "Usuários administrativos configurados. Bootstrap finalizado."
