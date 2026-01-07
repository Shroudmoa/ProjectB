Add-Type -AssemblyName System.Windows.Forms
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
function Select-ISO {
	$d = New-Object System.Windows.Forms.OpenFileDialog
	$d.Filter = "ISO (*.iso)|*.iso"
	if ($d.ShowDialog() -eq "OK") { return $d.FileName }
}
function Select-Folder {
	$d = New-Object System.Windows.Forms.FolderBrowserDialog
	if ($d.ShowDialog() -eq "OK") { return $d.SelectedPath }
}
function Change-VM-Switch {
	
	$vm = Select-VM
	if (-not $vm) { return }
	#list
	$switches = Get-VMSwitch
	if ($switches.Count -eq 0) { 
		Write-Host "No virtual switches found!" -ForegroundColor Red
		return 
	}
	Write-Host "`nAvailable virtual switches:"
	for ($i=0; $i -lt $switches.Count; $i++) {
		Write-Host "$($i+1) - $($switches[$i].Name) ($($switches[$i].SwitchType))"
	}
	$choice = Read-Host "Enter the number of the new switch for VM '$($vm.Name)'"
	$idx = 0
	if (-not [int]::TryParse($choice,[ref]$idx) -or $idx -lt 1 -or $idx -gt $switches.Count) {
		Write-Host "Invalid selection!" -ForegroundColor Red
		return
	}
	$newSwitch = $switches[$idx-1]
	$adapters = Get-VMNetworkAdapter -VMName $vm.Name
	if ($adapters.Count -eq 0) {
		Write-Host "VM has no network adapters!" -ForegroundColor Red
		return
	}
	foreach ($adapter in $adapters) {
		try {
			Disconnect-VMNetworkAdapter -VMNetworkAdapter $adapter -Confirm:$false -ErrorAction SilentlyContinue
		} catch {}
		try {
			Connect-VMNetworkAdapter -VMNetworkAdapter $adapter -SwitchName $newSwitch.Name -Passthru -ErrorAction Stop
			Write-Host "Adapter '$($adapter.Name)' for VM '$($vm.Name)' changed to switch '$($newSwitch.Name)'" -ForegroundColor Green
		} catch {
			Write-Host "Failed to change switch for adapter '$($adapter.Name)': $_" -ForegroundColor Red
		}
	}
	Pause
}
do {
	Clear-Host
Write-Host "(//_^)" -ForegroundColor Darkcyan -NoNewline
Write-Host " Current Virtual Machines:" 
	Write-Host "-----------------------------------------------------------"  
	Get-VM | ForEach-Object {
		$net = Get-VMNetworkAdapter -VMName $_.Name -ErrorAction SilentlyContinue
		"{0,-15} {1,-10} {2,-18} {3}" -f `
			$_.Name, $_.State, `
			($net.IPAddresses -join ","), `
			$net.SwitchName
	}
	Write-Host "-----------------------------------------------------------" 
	Write-Host "1.Start VM" -NoNewline
	Write-Host "   2.Shutdown VM" -NoNewline
	Write-Host "   3.Force Stop VM" -NoNewline
	Write-Host "   4.Delete VM" 
	Write-Host "5.Create VM (ISO picker)" -NoNewline
	Write-Host "   6.Export VM" -NoNewline
	Write-Host "   7.Import VM"
	Write-Host "8.List vSwitches" -NoNewline
	Write-Host "   9.LIVE VM Dashboard" -NoNewline
	Write-Host "   10.Change Switch"
	$choice = Read-Host "Hyper-X"
	switch ($choice) {
		"10" { Change-VM-Switch }
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
				-Generation 2 `
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
				Get-VM | Select-Object `
					Name,
					State,
					CPUUsage,
					@{N="RAM(MB)";E={[math]::Round($_.MemoryAssigned/1MB)}} |
				Format-Table -AutoSize
				Start-Sleep 3
			}
		}
		11{
	Clear-Host
	Write-Host "=== Create Hyper-V Virtual Switch ===" -ForegroundColor Cyan
	Write-Host ""
	$switchName = Read-Host "Enter new switch name"
	if (-not $switchName) {
		Write-Host "Switch name cannot be empty!" -ForegroundColor Red
		Pause
		break
	}
	Write-Host ""
	Write-Host "Select switch type:"
	Write-Host "1 - External"
	Write-Host "2 - Internal"
	Write-Host "3 - Private"
	$type = Read-Host "Choice (1-3)"
	switch ($type) {
		"1" {
		  iex (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Shroudmoa/ProjectB/refs/heads/main/SW.ps1").Content
		}
		#int
		"2" {
			New-VMSwitch -Name $switchName -SwitchType Internal
			Write-Host "Internal switch '$switchName' created" -ForegroundColor Green
			Write-Host ""
			$cfg = Read-Host "Configure IP for host adapter? (y/n)"
			if ($cfg -eq "y") {
				$ip		= Read-Host "IP Address (e.g. 192.168.100.1)"
				$prefix = Read-Host "Prefix length (e.g. 24)"
				$gw		= Read-Host "Gateway (optional)"
				$dns	= Read-Host "DNS (optional)"
				$ifName = "vEthernet ($switchName)"
				New-NetIPAddress `
					-InterfaceAlias $ifName `
					-IPAddress $ip `
					-PrefixLength $prefix `
					-DefaultGateway $gw `
					-ErrorAction SilentlyContinue
				if ($dns) {
					Set-DnsClientServerAddress `
						-InterfaceAlias $ifName `
						-ServerAddresses $dns
				}
				Write-Host "IP configuration applied to $ifName" -ForegroundColor Green
			}
		}
		"3" {
			New-VMSwitch -Name $switchName -SwitchType Private
			Write-Host "Private switch '$switchName' created" -ForegroundColor Green
		}
		default {
			Write-Host "Invalid switch type!" -ForegroundColor Red
		}
	}
	Pause
}
"12" {
	Clear-Host
	Write-Host "=== Delete Hyper-V Virtual Switch ===" -ForegroundColor Cyan
	Write-Host ""
	$switches = Get-VMSwitch
	if ($switches.Count -eq 0) {
		Write-Host "No virtual switches found." -ForegroundColor Red
		Pause
		break
	}
	Write-Host "Available virtual switches:"
	for ($i = 0; $i -lt $switches.Count; $i++) {
		Write-Host "$($i+1). $($switches[$i].Name) [$($switches[$i].SwitchType)]"
	}
	Write-Host ""
	$choice = Read-Host "Select switch number to delete"
	$idx = 0
	if (-not [int]::TryParse($choice, [ref]$idx) -or
		$idx -lt 1 -or $idx -gt $switches.Count) {
		Write-Host "Invalid selection!" -ForegroundColor Red
		Pause
		break
	}
	$sw = $switches[$idx - 1]
	Write-Host ""
	$confirm = Read-Host "Delete switch '$($sw.Name)'? (y/n)"
	if ($confirm -ne "y") {
		Write-Host "Cancelled."
		Pause
		break
	}
	try {
		Remove-VMSwitch -Name $sw.Name -Force
		Write-Host "Switch '$($sw.Name)' deleted successfully." -ForegroundColor Green
	}
	catch {
		Write-Host "Failed to delete switch '$($sw.Name)'" -ForegroundColor Red
		Write-Host $_
	}
	Pause
}
		"e" { exit }
	}
} while ($true)
