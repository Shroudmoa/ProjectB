$UserName = $env:USERNAME

$TerminalSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$ProfilePath = "C:\Users\$UserName\Documents\WindowsPowerShell\profile.ps1"

$DefaultSettingsUrl = "https://raw.githubusercontent.com/Shroudmoa/ProjectB/refs/heads/main/CTRL%20%2B%20V/Powershell/Default.json"

Write-Host "Starting Fastfetch debloat..."

if (Test-Path $TerminalSettings) {
    Remove-Item $TerminalSettings -Force
    Write-Host "Windows Terminal settings.json deleted"
}

if (Test-Path $ProfilePath) {
    Remove-Item $ProfilePath -Force
    Write-Host "PowerShell profile deleted"
}

if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    winget uninstall fastfetch -e --accept-source-agreements --accept-package-agreements
    Write-Host "Fastfetch uninstalled"
}

$TerminalDir = Split-Path $TerminalSettings
if (-not (Test-Path $TerminalDir)) {
    New-Item -ItemType Directory -Path $TerminalDir -Force | Out-Null
}

$defaultSettings = Invoke-WebRequest -Uri $DefaultSettingsUrl -UseBasicParsing
$defaultSettings.Content | Out-File -FilePath $TerminalSettings -Encoding UTF8
winget uninstall fastfetch
Write-Host "Default Windows Terminal settings restored"
Write-Host "Debloat complete. Restart Windows Terminal."
