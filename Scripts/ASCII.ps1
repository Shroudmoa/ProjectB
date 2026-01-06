Write-Host "Paste ASCII art:"
Write-Host "(Press Enter on an empty line to finish input)"
$Lines = @()

while ($true) {
    $Line = Read-Host
    if ([string]::IsNullOrWhiteSpace($Line)) {
        break
    }
    $Lines += $Line
}

if ($Lines.Count -lt 2) {
    Write-Host "At least 2 lines of ASCII are required."
    return
}

$Total = $Lines.Count
$Result = @()

for ($i = 0; $i -lt $Total; $i++) {
    $Color = [math]::Round(($i * 8) / ($Total - 1)) + 1
    $Result += ('$' + $Color + $Lines[$i])
}

$Final = $Result -join "`n"
$UserName = $env:USERNAME
$FastfetchDir = "C:/Users/$UserName/.config/fastfetch"
$AsciiPath = "$FastfetchDir/ascii.txt"
New-Item -ItemType Directory -Path $FastfetchDir -Force | Out-Null


attrib +h "C:/Users/$UserName/.config" 2>$null


$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

[System.IO.File]::WriteAllText(
    $AsciiPath,
    $Final,
    $Utf8NoBom
)


Write-Host ""
Write-Host "ASCII processed and saved to:"
Write-Host $AsciiPath
Write-Host ""
Write-Host "Preview:"
Write-Host $Final
