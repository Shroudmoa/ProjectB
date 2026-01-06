#monoinstaller
$ErrorActionPreference = "Stop"

Write-Host "...Installing JetBrainsMono Nerd Font Mono..."

$ZipUrl  = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"
$TempZip = "$env:TEMP\JetBrainsMono.zip"
$TempDir = "$env:TEMP\JetBrainsMono"

Import-Module BitsTransfer
Write-Host "...Downloading..."
Start-BitsTransfer -Source $ZipUrl -Destination $TempZip

if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
Expand-Archive $TempZip $TempDir -Force

Write-Host "...Installing JetBrainsMono Nerd Font Mono..."

$FontsShell = (New-Object -ComObject Shell.Application).Namespace(0x14)

Get-ChildItem $TempDir -Recurse -Filter "*.ttf" | Where-Object { $_.Name -like "JetBrainsMono*Nerd*Mono*.ttf" } | ForEach-Object {
    $FontName = $_.Name
    $Target  = "C:\Windows\Fonts\$FontName"

    if (-not (Test-Path $Target)) {
        Write-Host "   -> $FontName"
        $FontsShell.CopyHere($_.FullName)
    }
}

Write-Host "\ (^_^) /JetBrainsMono Nerd Font Mono installed."
Write-Host "Restart apps"
