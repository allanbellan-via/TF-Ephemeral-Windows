#ps1_sysnative
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

$ViaAdminUsername    = "${ViaAdminUsername}"
$ViaAdminPasswordRaw = "${ViaAdminPassword}"
$TestUsername        = "${TestUsername}"
$TestPasswordRaw     = "${TestPassword}"

$ViaAdminPassword = $ViaAdminPasswordRaw | ConvertTo-SecureString -AsPlainText -Force
$TestPassword     = $TestPasswordRaw     | ConvertTo-SecureString -AsPlainText -Force

# --- ViaAdmin (admin principal) ---
if (-not (Get-LocalUser -Name $ViaAdminUsername -ErrorAction SilentlyContinue)) {
  New-LocalUser -Name $ViaAdminUsername -Password $ViaAdminPassword -AccountNeverExpires:$true
} else {
  Set-LocalUser -Name $ViaAdminUsername -Password $ViaAdminPassword
}
Add-LocalGroupMember -Group "Administrators" -Member $ViaAdminUsername
WMIC USERACCOUNT WHERE "Name='$ViaAdminUsername'" SET PasswordExpires=FALSE | Out-Null

# --- Usuário de teste (opcional) ---
if ($TestUsername -and $TestUsername -ne "") {
  if (-not (Get-LocalUser -Name $TestUsername -ErrorAction SilentlyContinue)) {
    New-LocalUser -Name $TestUsername -Password $TestPassword -AccountNeverExpires:$true
  } else {
    Set-LocalUser -Name $TestUsername -Password $TestPassword
  }
  Add-LocalGroupMember -Group "Administrators" -Member $TestUsername
  WMIC USERACCOUNT WHERE "Name='$TestUsername'" SET PasswordExpires=FALSE | Out-Null
}

Write-Host "Usuarios administrativos configurados. Bootstrap finalizado."
