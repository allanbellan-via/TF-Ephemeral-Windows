#ps1
$ErrorActionPreference = "Stop"

# Ajusta execução de scripts
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force

# Parâmetros do Terraform (templatefile)
$ViaAdminUsername = "${ViaAdminUsername}"
$ViaAdminPassword = "${ViaAdminPassword}"
$TestUsername     = "${TestUsername}"
$TestPassword     = "${TestPassword}"

if ([string]::IsNullOrWhiteSpace($ViaAdminPassword)) {
  Write-Error "ViaAdminPassword vazio. Defina TF_VAR_viaadmin_password no n8n antes de criar a VM."
}
if ([string]::IsNullOrWhiteSpace($TestPassword)) {
  Write-Error "TestPassword vazio. Defina TF_VAR_test_password no n8n antes de criar a VM."
}

function Ensure-LocalAdmin($UserName, $PlainPassword, $FullName, $Description) {
  $sec = ConvertTo-SecureString $PlainPassword -AsPlainText -Force
  if (Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue) {
    Write-Host "Usuário $UserName já existe; atualizando senha e grupos..."
    Set-LocalUser -Name $UserName -Password $sec
  } else {
    New-LocalUser -Name $UserName -Password $sec -AccountNeverExpires:$true -PasswordNeverExpires:$true -FullName $FullName -Description $Description
  }
  if (-not (Get-LocalGroupMember -Group "Administrators" -Member $UserName -ErrorAction SilentlyContinue)) {
    Add-LocalGroupMember -Group "Administrators" -Member $UserName
  }
}

# Cria/garante viaadmin e usuário de testes como Administrators
Ensure-LocalAdmin -UserName $ViaAdminUsername -PlainPassword $ViaAdminPassword -FullName "Viasoft Admin" -Description "Conta administrativa criada via Cloudbase-Init"
Ensure-LocalAdmin -UserName $TestUsername     -PlainPassword $TestPassword     -FullName "Viasoft QA"    -Description "Usuário de testes (QA) criado via Cloudbase-Init"

# Habilitar RDP e liberar firewall de RDP
try {
  Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
  Enable-NetFirewallRule -DisplayGroup "Remote Desktop" | Out-Null
} catch { Write-Warning "Falha ao ajustar RDP: $_" }

Write-Host "Usuários administrativos configurados. Bootstrap finalizado."
