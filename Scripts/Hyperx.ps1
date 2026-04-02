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
        @{ Id = "1";  Label = "Start VM" }
        @{ Id = "2";  Label = "Shutdown VM" }
        @{ Id = "3";  Label = "Force Stop VM" }
        @{ Id = "4";  Label = "Delete VM" }
        @{ Id = "5";  Label = "Create VM" }
        @{ Id = "6";  Label = "Export VM" }
        @{ Id = "7";  Label = "Import VM" }
        @{ Id = "8";  Label = "List vSwitches" }
        @{ Id = "9";  Label = "Live Dashboard" }
        @{ Id = "10"; Label = "Change Switch" }
        @{ Id = "11"; Label = "Create vSwitch" }
        @{ Id = "12"; Label = "Delete vSwitch" }
        @{ Id = "15"; Label = "Open VM Console" }
        @{ Id = "e";  Label = "Exit" }
    )

    $index = 0

    while ($true) {
        Clear-Host
        Write-Host "(//_^)" -ForegroundColor DarkCyan
        Write-Host "=== Hyper-X Menu ===`n"

        for ($i = 0; $i -lt $menuItems.Count; $i++) {
            $item = $menuItems[$i]

            if ($i -eq $index) {
                Write-Host "> [$($item.Id)] $($item.Label)" -ForegroundColor Green
            } else {
                Write-Host "  [$($item.Id)] $($item.Label)"
            }
        }

        $key = [System.Console]::ReadKey($true)

        switch ($key.Key) {
            "UpArrow"   { if ($index -gt 0) { $index-- } }
            "DownArrow" { if ($index -lt $menuItems.Count - 1) { $index++ } }
            "Enter"     { return $menuItems[$index].Id }

            default {
                if ($key.KeyChar -match '[0-9e]') {
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

            New-VM -Name $name `
                -Generation $gen `
                -MemoryStartupBytes ($ram * 1MB) `
                -NewVHDPath "C:\VMs\$name\$name.vhdx" `
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
            while ($true) {
                Clear-Host
                Get-VM | Select Name, State, CPUUsage,
                @{N="RAM(MB)";E={[math]::Round($_.MemoryAssigned/1MB)}} |
                Format-Table
                Start-Sleep 3
            }
        }

        "10" {
            Write-Host "Switch change not implemented here (use your function)"
            Pause
        }

        "11" {
            $name = Read-Host "Switch Name"
            New-VMSwitch -Name $name -SwitchType Internal
            Write-Host "Switch created."
            Pause
        }

        "12" {
            $sw = Get-VMSwitch | Select -First 1
            if ($sw) {
                Remove-VMSwitch -Name $sw.Name -Force
                Write-Host "Deleted."
            }
            Pause
        }

        "15" {
            Open-VMConsole
        }

        "e" { break }
    }

} while ($true)
