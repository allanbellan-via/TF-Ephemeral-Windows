#ps1_sysnative

$user = "${ViaAdminUsername}"
$pass = "${ViaAdminPassword}" | ConvertTo-SecureString -AsPlainText -Force

if (-not (Get-LocalUser -Name $user -ErrorAction SilentlyContinue)) {
  New-LocalUser -Name $user -Password $pass -AccountNeverExpires:$true
} else {
  Set-LocalUser -Name $user -Password $pass
}
Add-LocalGroupMember -Group "Administrators" -Member $user

WMIC USERACCOUNT WHERE "Name='$user'" SET PasswordExpires=FALSE | Out-Null

Write-Host "Usuários administrativos configurados. Bootstrap finalizado."
