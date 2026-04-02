Add-Type -AssemblyName System.Windows.Forms
function Select-Folder {
	$d = New-Object System.Windows.Forms.FolderBrowserDialog
	if ($d.ShowDialog() -eq "OK") { return $d.SelectedPath }
}
function Select-ISO {
	$d = New-Object System.Windows.Forms.OpenFileDialog
	$d.Filter = "ISO (*.iso)|*.iso"
	if ($d.ShowDialog() -eq "OK") { return $d.FileName }
}
function Change-VM-Switch {

    $vm = Select-VM
    if (-not $vm) { return }

    $switches = Get-VMSwitch
    if ($switches.Count -eq 0) {
        Write-Host "No virtual switches found!" -ForegroundColor Red
        Pause
        return
    }

    Write-Host "`nAvailable virtual switches:`n"

    for ($i = 0; $i -lt $switches.Count; $i++) {
        Write-Host "$($i+1). $($switches[$i].Name) [$($switches[$i].SwitchType)]"
    }

    $choice = Read-Host "`nSelect switch number"
    if ($choice -notmatch '^\d+$' -or $choice -lt 1 -or $choice -gt $switches.Count) {
        Write-Host "Invalid selection!" -ForegroundColor Red
        Pause
        return
    }

    $newSwitch = $switches[$choice - 1]

    $adapters = Get-VMNetworkAdapter -VMName $vm.Name
    if ($adapters.Count -eq 0) {
        Write-Host "VM has no network adapters!" -ForegroundColor Red
        Pause
        return
    }

    foreach ($adapter in $adapters) {
        try {
            Connect-VMNetworkAdapter `
                -VMNetworkAdapter $adapter `
                -SwitchName $newSwitch.Name `
                -ErrorAction Stop

            Write-Host "Adapter '$($adapter.Name)' → '$($newSwitch.Name)'" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Pause
}
function Pause {
    Write-Host ""
    Read-Host "Press ENTER to continue"
}

function Select-VM {
    $vms = Get-VM
    if (!$vms) { return $null }

    for ($i=0; $i -lt $vms.Count; $i++) {
        Write-Host "$($i+1). $($vms[$i].Name) [$($vms[$i].State)]"
    }

    $sel = Read-Host "Select VM number"
    if ($sel -match '^\d+$' -and $sel -le $vms.Count) {
        return $vms[$sel-1]
    }
    return $null
}

function Show-VMList {
    
    Write-Host "Current Virtual Machines:"
    Write-Host "-----------------------------------------------------------"

    Get-VM | ForEach-Object {
        $net = Get-VMNetworkAdapter -VMName $_.Name -ErrorAction SilentlyContinue
        "{0,-15} {1,-10} {2,-18} {3}" -f `
            $_.Name,
            $_.State,
            ($net.IPAddresses -join ","),
            $net.SwitchName
    }

    Write-Host "-----------------------------------------------------------`n"
}

function Open-VMConsole {
    $vm = Select-VM
    if ($vm) {
        if ($vm.State -eq "Off") {
            Start-VM -Name $vm.Name
        }
        vmconnect.exe localhost $vm.Name
    }
}

function Show-Menu {
    $menuItems = @(
        @{ Id = "0"; Label = "Show VMs" }
        @{ Id = "1"; Label = "Start VM" }
        @{ Id = "2"; Label = "Shutdown VM" }
        @{ Id = "3"; Label = "Force Stop VM" }
        @{ Id = "4"; Label = "Delete VM" }
        @{ Id = "5"; Label = "Create VM" }
        @{ Id = "6"; Label = "Export VM" }
        @{ Id = "7"; Label = "Import VM" }
        @{ Id = "8"; Label = "List vSwitches" }
        @{ Id = "9"; Label = "Live Dashboard" }
        @{ Id = "10"; Label = "Change Switch" }
        @{ Id = "11"; Label = "Create vSwitch" }
        @{ Id = "12"; Label = "Delete vSwitch" }
        @{ Id = "15"; Label = "Open VM Console" }
        @{ Id = "e"; Label = "Exit" }
    )

    $cols = 3  
    $index = 0

    while ($true) {
        Clear-Host

        Write-Host "(//_^)" -ForegroundColor DarkCyan
        Write-Host "=== Hyper-X Menu ===`n"

        for ($i = 0; $i -lt $menuItems.Count; $i += $cols) {

            $row = $menuItems[$i..([math]::Min($i+$cols-1, $menuItems.Count-1))]

            for ($j = 0; $j -lt $row.Count; $j++) {
                $itemIndex = $i + $j
                $item = $row[$j]

                $text = "[{0}] {1}" -f $item.Id, $item.Label

                if ($itemIndex -eq $index) {
                    Write-Host ("{0,-30}" -f ("> " + $text)) -ForegroundColor Green -NoNewline
                } else {
                    Write-Host ("{0,-30}" -f ("  " + $text)) -NoNewline
                }
            }
            Write-Host ""
            Write-Host ""
        }

        $key = [System.Console]::ReadKey($true)

        switch ($key.Key) {
            "LeftArrow"  { if ($index -gt 0) { $index-- } }
            "RightArrow" { if ($index -lt $menuItems.Count - 1) { $index++ } }

            "UpArrow" {
                if ($index -ge $cols) { $index -= $cols }
            }

            "DownArrow" {
                if ($index + $cols -lt $menuItems.Count) { $index += $cols }
            }

            "Enter" { return $menuItems[$index].Id }

            default {
                if ($key.KeyChar) {
                    return "$($key.KeyChar)"
                }
            }
        }
    }
}

do {
    
    $choice = Show-Menu

    switch ($choice) {
         "6" {
			$vm = Select-VM
			if ($vm) {
				$path = Select-Folder
				if ($path) {
					Export-VM -Name $vm.Name -Path $path
				}
			}
			Pause
		}
        "7" {
			$path = Select-Folder
			if (!$path) { break }
			$vmConfig = Get-ChildItem $path -Recurse -Include *.vmcx,*.xml | Select-Object -First 1
			if (!$vmConfig) {
				Write-Host "No VM config found!" -ForegroundColor Red
				Pause
				break
			}
			Import-VM -Path $vmConfig.FullName -Copy -GenerateNewId
			Pause
		}

        "1" {
            $vm = Select-VM
            if ($vm -and $vm.State -eq "Off") {
                Start-VM -Name $vm.Name
            }
            Pause
        }

        "2" {
            $vm = Select-VM
            if ($vm -and $vm.State -eq "Running") {
                Stop-VM -Name $vm.Name
            }
            Pause
        }

        "3" {
            $vm = Select-VM
            if ($vm -and $vm.State -ne "Off") {
                Stop-VM -Name $vm.Name -TurnOff -Force
            }
            Pause
        }

      		"4" {
			$vm = Select-VM
			if ($vm) {
				$confirm = Read-Host "Delete VM '$($vm.Name)'? (y/n)"
				if ($confirm -ne "y") { break }
				
				if ($vm.State -ne "Off") {
					Stop-VM -Name $vm.Name -TurnOff -Force
				}
				
				Get-VMSnapshot -VMName $vm.Name -ErrorAction SilentlyContinue |
					Remove-VMSnapshot -ErrorAction Stop
				
				$vhdPaths = Get-VMHardDiskDrive -VMName $vm.Name |
					Select-Object -ExpandProperty Path
				
				Remove-VM -Name $vm.Name -Force
				
				$del = Read-Host "Delete VHD files too? (y/n)"
				if ($del -eq "y") {
					foreach ($vhd in $vhdPaths) {
						Remove-Item $vhd -Force -ErrorAction SilentlyContinue
					}
				}
				Write-Host "VM deleted successfully." -ForegroundColor Green
				Pause
			}
		}

        "5" {
			$name = Read-Host "VM Name"
			$ram  = [int] (Read-Host "Startup RAM (MB)")
			$cpu  = [int] (Read-Host "CPU Count")
			$vhd  = [int] (Read-Host "VHD Size (GB)")
			$iso = Select-ISO
			if (!$iso) { break }
			$switches = Get-VMSwitch
			for ($i=0;$i -lt $switches.Count;$i++){
				Write-Host "$($i+1). $($switches[$i].Name)"
			}
			$sw = Read-Host "Select switch number"
			$switch = $switches[$sw-1].Name
			$path = "C:\VMs\$name"
			New-Item -ItemType Directory -Path $path -Force | Out-Null
			New-VM `
				-Name $name `
				-Generation 1 `
				-MemoryStartupBytes ([UInt64]$ram * 1MB) `
				-NewVHDPath "$path\$name.vhdx" `
				-NewVHDSizeBytes ([UInt64]$vhd * 1GB) `
				-SwitchName $switch
			Set-VM -Name $name -ProcessorCount $cpu
			Set-VMFirmware -VMName $name -EnableSecureBoot Off
			Add-VMDvdDrive -VMName $name -Path $iso
			Write-Host "VM created successfully." -ForegroundColor Green
			Pause
        }

        "8" {
           	Get-VMSwitch | ForEach-Object {
				[PSCustomObject]@{
					SwitchName = $_.Name
					Type	   = $_.SwitchType
					NIC		   = $_.NetAdapterInterfaceDescription
				}
			} | Format-Table -AutoSize
			Pause
		}
        

        "9" {
            Write-Host "LIVE DASHBOARD (CTRL+C to exit)" -ForegroundColor Yellow
            Start-Sleep 2
            while ($true) {
                Clear-Host
                Get-VM | Select Name, State, CPUUsage,
                @{N="RAM(MB)";E={[math]::Round($_.MemoryAssigned/1MB)}} |
                Format-Table
                Start-Sleep 3
            }
        }

        "10" {
            Change-VM-Switch
            Pause
        }

        "11" {
            pause
        }

        "12" {
            $switches = Get-VMSwitch
            for ($i=0;$i -lt $switches.Count;$i++){
                Write-Host "$($i+1). $($switches[$i].Name)"
            }
            $sel = Read-Host "Select switch"
            $sw = $switches[$sel-1]

            if ($sw) {
                Remove-VMSwitch -Name $sw.Name -Force
                Write-Host "Deleted." -ForegroundColor Green
            }
            Pause
        }
        "0"{
            Show-VMList
            Pause
            
        }

        "15" {
            Open-VMConsole
        }

        "e" {
            Write-Host "Roses are red, violets are blue" -ForegroundColor Cyan
            exit
        }
    }

} while ($true)
