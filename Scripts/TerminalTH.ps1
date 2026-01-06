$url = 'https://raw.githubusercontent.com/Shroudmoa/ProjectB/main/CTRL%20%2B%20V/Powershell/Setting.json'
$localFile = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$folder = Split-Path $localFile
if (-not (Test-Path $folder)) { New-Item -ItemType Directory -Path $folder -Force | Out-Null }
if (Test-Path $localFile) { Copy-Item -Path $localFile -Destination "$localFile.bak" -Force }
$response = Invoke-WebRequest -Uri $url -UseBasicParsing
if ($response.StatusCode -eq 200) { $response.Content | Out-File -FilePath $localFile -Encoding UTF8 }
