# PowerShell Multitool

do {
    Clear-Host
    $choice = Read-Host "help?"

    switch ($choice) {
		"install" {
    iex (Invoke-WebRequest "https://raw.githubusercontent.com/Shroudmoa/ProjectB/refs/heads/main/Scripts/Terminal.ps1").Content
    iex (Invoke-WebRequest "https://raw.githubusercontent.com/Shroudmoa/ProjectB/refs/heads/main/Scripts/TerminalTH.ps1").Content
	iex (Invoke-WebRequest "https://raw.githubusercontent.com/Shroudmoa/ProjectB/refs/heads/main/Scripts/JetFont.ps1").Content
}
		"delete"{
		 iex (Invoke-WebRequest "https://raw.githubusercontent.com/Shroudmoa/ProjectB/refs/heads/main/Scripts/Default.ps1").Content
		}

        "1" {
            Write-Host "Running ASCII.ps1..." -ForegroundColor Green
            iex (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Shroudmoa/ProjectB/refs/heads/main/Scripts/ASCII.ps1").Content
        }
        
        "2" {
            Write-Host "Running JetFont.ps1..." -ForegroundColor Green
            iex (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Shroudmoa/ProjectB/refs/heads/main/Scripts/JetFont.ps1").Content
        }
        "3" {
            Write-Host "Running Terminal.ps1..." -ForegroundColor Green
           Write-Host "V2 : Installing fastfetch configuration..."

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


if (-not (Test-Path $ProfilePath)) {
    New-Item -Path $ProfilePath -ItemType File -Force | Out-Null
}

$AsciiContent = (Invoke-WebRequest $AsciiURL -UseBasicParsing).Content
[System.IO.File]::WriteAllText($AsciiPath, $AsciiContent, $Utf8NoBom)


$ConfigContent = (Invoke-WebRequest $ConfigURL -UseBasicParsing).Content
$ConfigContent = $ConfigContent -replace 'C:/Users/%USERPROFILE%', $UserPath
$ConfigContent = $ConfigContent -replace '"source":\s*".*ascii.txt"', '"source": "' + $UserPath + '/.config/fastfetch/ascii.txt"'
[System.IO.File]::WriteAllText($ConfigPath, $ConfigContent, $Utf8NoBom)


$ProfileContent = (Invoke-WebRequest $ProfileURL -UseBasicParsing).Content
$ProfileContent = $ProfileContent -replace 'C:/Users/%USERPROFILE%', $UserPath
$ProfileContent = $ProfileContent -replace 'fastfetch\s+-c\s+".*config.jsonc"', 'fastfetch -c "' + $UserPath + '/.config/fastfetch/config.jsonc"'
[System.IO.File]::WriteAllText($ProfilePath, $ProfileContent, $Utf8NoBom)

Clear-Host
Write-Host "Installation completed. Restart PowerShell^^"

        }
        "4" {
            Write-Host "Running TerminalTH.ps1..." -ForegroundColor Green
            iex (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Shroudmoa/ProjectB/refs/heads/main/Scripts/TerminalTH.ps1").Content
        }
		"help" {
            Write-Host "Install = 2,3,4" -ForegroundColor Green
            Write-Host "1. ASCII -> C:/Users/$UserName/.config/fastfetch"
			Write-Host "2. install Jetbrains Font"
			Write-Host "3. Fastfetch install + default ASCII"
			Write-Host "4. Config -> C:\Users\%USERPROFILE%\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
			Write-Host "5. New Fastfetch Config -> $env:USERPROFILE\.config\fastfetch\config.jsonc"
			Write-Host "5+. Open $env:USERPROFILE\.config\fastfetch"
			Write-Host "6. Delete Fastfetch"
        }
		
				"5" {
					$randomNumber = Get-Random -Minimum 2 -Maximum 32
					$url = "https://raw.githubusercontent.com/fastfetch-cli/fastfetch/refs/heads/dev/presets/examples/$randomNumber.jsonc"
					$targetPath = "$env:USERPROFILE\.config\fastfetch\config.jsonc"

					$dir = Split-Path $targetPath
					if (-not (Test-Path $dir)) {
						New-Item -ItemType Directory -Path $dir -Force | Out-Null
					}

					Invoke-WebRequest -Uri $url -OutFile $targetPath
					Write-Host "$randomNumber.jsonc -> $targetPath"


					$openPath = Read-Host "Do you want to open the folder? (yes/no)"
					if ($openPath -eq "yes") {
						Invoke-Item $dir
					}

					$copyConfig = Read-Host "Do you want to copy the default Shroudmoa config to clipboard? (yes/no)"
					if ($copyConfig -eq "yes") {
						$defaultUrl = "https://raw.githubusercontent.com/Shroudmoa/ProjectB/refs/heads/main/Arcive/config.jsonc"
						$defaultConfig = Invoke-WebRequest -Uri $defaultUrl -UseBasicParsing
						$defaultConfig.Content | Set-Clipboard
						Write-Host "Default Shroudmoa config copied to clipboard."
						}

						}
			
		"5+"{
			$targetPath = "$env:USERPROFILE\.config\fastfetch\config.jsonc"

			$dir = Split-Path $targetPath
			
			Invoke-Item $dir
			$copyConfig = Read-Host "Do you want to copy the default Shroudmoa config to clipboard? (yes/no)"
					if ($copyConfig -eq "yes") {
						$defaultUrl = "https://raw.githubusercontent.com/Shroudmoa/ProjectB/refs/heads/main/Arcive/config.jsonc"
						$defaultConfig = Invoke-WebRequest -Uri $defaultUrl -UseBasicParsing
						$defaultConfig.Content | Set-Clipboard
						Write-Host "Default Shroudmoa config copied to clipboard."
						}
		}
		
        "e" {
           exit
        }
        default {
            Write-Host "Invalid option" -ForegroundColor Red
        }
    }

    Write-Host ""
    Read-Host "Press Enter to return to the menu"
} while ($true)



