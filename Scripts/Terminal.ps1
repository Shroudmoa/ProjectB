

Write-Host "Installing fastfetch configuration..."
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$UserName   = $env:USERNAME
$UserPath   = "C:/Users/$UserName"

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


$AsciiRaw   = Invoke-WebRequest $AsciiURL   -UseBasicParsing
$ConfigRaw  = Invoke-WebRequest $ConfigURL  -UseBasicParsing
$ProfileRaw = Invoke-WebRequest $ProfileURL -UseBasicParsing


[System.IO.File]::WriteAllText(
    $AsciiPath,
    $AsciiRaw.Content,
    $Utf8NoBom
)


$FixedConfig = $ConfigRaw.Content
$FixedConfig = $FixedConfig -replace 'C:/Users/%USERPROFILE%', $UserPath
$FixedConfig = $FixedConfig -replace '"source":\s*".*ascii.txt"', '"source": "' + $UserPath + '/.config/fastfetch/ascii.txt"'

[System.IO.File]::WriteAllText(
    $ConfigPath,
    $FixedConfig,
    $Utf8NoBom
)


New-Item -Path $ProfilePath -ItemType File -Force | Out-Null


$FixedProfile = $ProfileRaw.Content
$FixedProfile = $FixedProfile -replace 'C:/Users/%USERPROFILE%', $UserPath
$FixedProfile = $FixedProfile -replace 'fastfetch\s+-c\s+".*config.jsonc"', 'fastfetch -c "' + $UserPath + '/.config/fastfetch/config.jsonc"'

[System.IO.File]::WriteAllText(
    $ProfilePath,
    $FixedProfile,
    $Utf8NoBom
)

Write-Host "Installation completed. Restart PowerShell."
