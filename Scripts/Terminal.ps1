Write-Host "Installing fastfetch configuration..."

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)


$UserName = $env:USERNAME
$UserPath = "C:/Users/$UserName"

$FastfetchDir = "$UserPath/.config/fastfetch"
$AsciiPath    = "$FastfetchDir/ascii.txt"
$ConfigPath   = "$FastfetchDir/config.jsonc"

$ProfilePath = $profile.CurrentUserAllHosts
$ProfileDir  = Split-Path $ProfilePath

$AsciiURL = "https://raw.githubusercontent.com/Shroudmoa/ProjectB/refs/heads/main/CTRL%20%2B%20V/Fastdetch/ascii.txt"

if (-not (Get-Command fastfetch -ErrorAction SilentlyContinue)) {
    winget install fastfetch -e --accept-source-agreements --accept-package-agreements
}

New-Item -ItemType Directory -Path $FastfetchDir -Force | Out-Null
New-Item -ItemType Directory -Path $ProfileDir  -Force | Out-Null


attrib +h "$UserPath/.config"

Invoke-WebRequest $AsciiURL -OutFile $AsciiPath -UseBasicParsing


$ConfigContent = @"
{
  "\$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "type": "file",
    "source": "C:/Users/$UserName/.config/fastfetch/ascii.txt"
  }
}
"@

[System.IO.File]::WriteAllText(
    $ConfigPath,
    $ConfigContent,
    $Utf8NoBom
)

New-Item -Path $ProfilePath -ItemType File -Force | Out-Null

$ProfileContent = @"
Clear-Host

if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch -c "C:/Users/$UserName/.config/fastfetch/config.jsonc"
}
"@

[System.IO.File]::WriteAllText(
    $ProfilePath,
    $ProfileContent,
    $Utf8NoBom
)
Write-Host "Installation completed. Restart PowerShell^^"
