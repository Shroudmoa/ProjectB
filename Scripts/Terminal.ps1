Write-Host "Installing fastfetch configuration..."
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$UserName = $env:USERNAME
$UserPath = "C:/Users/$UserName"

$FastfetchDir = "$UserPath/.config/fastfetch"
$AsciiPath    = "$FastfetchDir/ascii.txt"
$ConfigPath   = "$FastfetchDir/config.jsonc"

$ProfilePath = $profile.CurrentUserAllHosts
$ProfileDir  = Split-Path $ProfilePath


$ProfileURL = "https://raw.githubusercontent.com/Shroudmoa/ProjectB/refs/heads/main/CTRL%20%2B%20V/Powershell/Microsoft.PowerShell_profile.ps1"
$AsciiURL   = "https://raw.githubusercontent.com/Shroudmoa/ProjectB/refs/heads/main/CTRL%20%2B%20V/Fastdetch/ascii.txt"
$ConfigURL  = "https://raw.githubusercontent.com/Shroudmoa/ProjectB/refs/heads/main/CTRL%20%2B%20V/Fastdetch/config.jsonc"


if (-not (Get-Command fastfetch -ErrorAction SilentlyContinue)) {
    winget install fastfetch -e --accept-source-agreements --accept-package-agreements
}

New-Item -ItemType Directory -Path $FastfetchDir -Force | Out-Null
New-Item -ItemType Directory -Path $ProfileDir  -Force | Out-Null


attrib +h "$UserPath/.config"


Invoke-WebRequest $AsciiURL  -OutFile $AsciiPath  -UseBasicParsing
Invoke-WebRequest $ConfigURL -OutFile $ConfigPath -UseBasicParsing
Invoke-WebRequest $ProfileURL -OutFile $ProfilePath -UseBasicParsing


$ConfigContent = Get-Content $ConfigPath -Raw

$ConfigContent = $ConfigContent -replace 'C:/Users/%USERPROFILE%', $UserPath
$ConfigContent = $ConfigContent -replace '"source":\s*".*ascii.txt"', '"source": "' + $UserPath + '/.config/fastfetch/ascii.txt"'

[System.IO.File]::WriteAllText(
    $ConfigPath,
    $ConfigContent,
    $Utf8NoBom
)

New-Item -Path $ProfilePath -ItemType File -Force | Out-Null

$ProfileContent = Get-Content $ProfilePath -Raw

$ProfileContent = $ProfileContent -replace 'C:/Users/%USERPROFILE%', $UserPath
$ProfileContent = $ProfileContent -replace 'fastfetch\s+-c\s+".*config.jsonc"', 'fastfetch -c "' + $UserPath + '/.config/fastfetch/config.jsonc"'

[System.IO.File]::WriteAllText(
    $ProfilePath,
    $ProfileContent,
    $Utf8NoBom
)

Write-Host "Installation completed. Restart PowerShell."
