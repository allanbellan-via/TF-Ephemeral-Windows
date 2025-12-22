#ps1_sysnative
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

Write-Output "=== Configurando Windows Server 2022 FULL pt-BR ==="

# 1. Timezone Brasilia
tzutil /s "E. South America Standard Time"

# 2. Instalar idioma pt-BR
Install-Language pt-BR -CopyToSettings

# 3. Definir idioma e cultura
Set-WinSystemLocale pt-BR
Set-WinUILanguageOverride pt-BR
Set-Culture pt-BR

# 4. Teclado ABNT2
$LangList = New-WinUserLanguageList pt-BR
$LangList[0].InputMethodTips.Clear()
$LangList[0].InputMethodTips.Add("0416:00000416")
Set-WinUserLanguageList $LangList -Force

# 5. Localizacao Brasil
Set-WinHomeLocation -GeoId 32

# 6. COPIAR CONFIGURACOES PARA TELA DE LOGIN E NOVOS USUARIOS
Write-Output "Copiando configuracoes para System e Default User..."

Copy-UserInternationalSettingsToSystem -WelcomeScreen $true -NewUser $true

Write-Output "Configuracao de Idioma concluida."

# Variáveis vindas do Terraform (mantenha exatamente assim)
$ViaAdminUsername    = "${ViaAdminUsername}"
$ViaAdminPasswordRaw = "${ViaAdminPassword}"
$TestUsername        = "${TestUsername}"
$TestPasswordRaw     = "${TestPassword}"

# Converte para SecureString para os cmdlets de conta local
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

winrm quickconfig -q
Enable-PSRemoting -Force
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true
Restart-Service WinRM

Write-Host "Usuarios administrativos configurados. Bootstrap finalizado."
