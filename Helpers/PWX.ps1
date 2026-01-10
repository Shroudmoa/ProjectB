# PowerShell Multitool

do {
    Clear-Host
    $choice = Read-Host "help?"

    switch ($choice) {
		"install" {
    iex (Invoke-WebRequest "https://raw.githubusercontent.com/Shroudmoa/ProjectB/refs/heads/main/Scripts/JetFont.ps1").Content
    iex (Invoke-WebRequest "https://raw.githubusercontent.com/Shroudmoa/ProjectB/refs/heads/main/Scripts/Terminal.ps1").Content
    iex (Invoke-WebRequest "https://raw.githubusercontent.com/Shroudmoa/ProjectB/refs/heads/main/Scripts/TerminalTH.ps1").Content
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
            iex (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Shroudmoa/ProjectB/refs/heads/main/Scripts/Terminal.ps1").Content
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
