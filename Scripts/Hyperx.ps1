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

    $cols = 3   # 🔥 Anzahl Spalten (ändern wie du willst)
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

                Remove-VM -Name $vm.Name -Force
                Write-Host "VM deleted." -ForegroundColor Green
                Pause
            }
        }

        "5" {
            $name = Read-Host "VM Name"
            $ram  = [int](Read-Host "RAM (MB)")
            $cpu  = [int](Read-Host "CPU Count")
            $vhd  = [int](Read-Host "VHD Size (GB)")

            Write-Host "Generation: 1=BIOS | 2=UEFI"
            $gen = Read-Host "Choice"
            if ($gen -ne "1") { $gen = 2 }

            $path = "C:\VMs\$name"
            New-Item -ItemType Directory -Path $path -Force | Out-Null

            New-VM -Name $name `
                -Generation $gen `
                -MemoryStartupBytes ($ram * 1MB) `
                -NewVHDPath "$path\$name.vhdx" `
                -NewVHDSizeBytes ($vhd * 1GB)

            if ($gen -eq 2) {
                Set-VMFirmware -VMName $name -EnableSecureBoot Off
            }

            Set-VM -Name $name -ProcessorCount $cpu

            Write-Host "VM created." -ForegroundColor Green
            Pause
        }

        "8" {
            Get-VMSwitch | Format-Table Name, SwitchType
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
            Write-Host "Use your existing Change-VM-Switch function here"
            Pause
        }

        "11" {
            $name = Read-Host "Switch Name"
            New-VMSwitch -Name $name -SwitchType Internal
            Write-Host "Switch created." -ForegroundColor Green
            Pause
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
            Write-Host "Bye!" -ForegroundColor Cyan
            exit
        }
    }

} while ($true)
