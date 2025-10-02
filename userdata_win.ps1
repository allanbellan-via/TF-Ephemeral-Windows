#ps1_sysnative

$ViaAdminUsername = "${ViaAdminUsername}"
$ViaAdminPassword = "${ViaAdminPassword}" | ConvertTo-SecureString -AsPlainText -Force
$TestUsername = "${$TestUsername}"
$TestPassword = "${$TestUsername}" | ConvertTo-SecureString -AsPlainText -Force

if (-not (Get-LocalUser -Name $ViaAdminUsername -ErrorAction SilentlyContinue)) {
  New-LocalUser -Name $ViaAdminUsername -Password $ViaAdminPassword -AccountNeverExpires:$true
} else {
  Set-LocalUser -Name $ViaAdminUsername -Password $ViaAdminPassword
}
Add-LocalGroupMember -Group "Administrators" -Member $ViaAdminUsername

WMIC USERACCOUNT WHERE "Name='$ViaAdminUsername'" SET PasswordExpires=FALSE | Out-Null

if (-not (Get-LocalUser -Name $TestUsername -ErrorAction SilentlyContinue)) {
  New-LocalUser -Name $TestUsername -Password $TestPassword -AccountNeverExpires:$true
} else {
  Set-LocalUser -Name $TestUsername -Password $TestPassword
}
Add-LocalGroupMember -Group "Administrators" -Member $TestUsername

WMIC USERACCOUNT WHERE "Name='$TestUsername'" SET PasswordExpires=FALSE | Out-Null

Write-Host "Usuários administrativos configurados. Bootstrap finalizado."
