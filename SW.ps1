# ===============================
# SW.ps1 – Hyper-V Switch Tool
# Version 3 – DNS SAFE EDITION
# ===============================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# -------------------------------
# Helpers
# -------------------------------
function Msg($t,$c="Info",$i=[System.Windows.Forms.MessageBoxIcon]::Information){
    [System.Windows.Forms.MessageBox]::Show($t,$c,[System.Windows.Forms.MessageBoxButtons]::OK,$i) | Out-Null
}

function Log($m){
    Add-Content $global:LogFile "$(Get-Date -f 'yyyy-MM-dd HH:mm:ss') $m"
}

# -------------------------------
# Admin check
# -------------------------------
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
    Msg "Bitte PowerShell als Administrator starten!" "Admin erforderlich" ([System.Windows.Forms.MessageBoxIcon]::Error)
    exit
}

# -------------------------------
# Log
# -------------------------------
$global:LogFile="$env:TEMP\SW_V3_$(Get-Date -f yyyyMMdd_HHmmss).log"
Log "SW Tool Version 3 gestartet"

# -------------------------------
# GUI
# -------------------------------
$form=New-Object System.Windows.Forms.Form
$form.Text="Hyper-V Switch Tool – Version 3 (DNS Safe)"
$form.Size="620,260"
$form.StartPosition="CenterScreen"
$form.FormBorderStyle="FixedDialog"

$cb=New-Object System.Windows.Forms.ComboBox
$cb.Location="10,30"
$cb.Width=580
$form.Controls.Add($cb)

$chk=New-Object System.Windows.Forms.CheckBox
$chk.Text="Automatisch ersten aktiven Adapter verwenden"
$chk.Location="10,60"
$chk.Checked=$true
$form.Controls.Add($chk)

$tb=New-Object System.Windows.Forms.TextBox
$tb.Location="10,100"
$tb.Width=300
$form.Controls.Add($tb)

$lbl=New-Object System.Windows.Forms.Label
$lbl.Text="Neuer Switchname"
$lbl.Location="10,80"
$form.Controls.Add($lbl)

$btn=New-Object System.Windows.Forms.Button
$btn.Text="Switch erstellen"
$btn.Location="420,120"
$btn.Size="150,35"
$form.Controls.Add($btn)

# -------------------------------
# Adapter laden (inkl WLAN)
# -------------------------------
function Load-Adapters{
    $cb.Items.Clear()
    Get-NetAdapter | Where-Object {
        $_.Status -eq "Up" -and
        $_.Name -notmatch "vEthernet"
    } | ForEach-Object{
        $cb.Items.Add($_.Name)
    }
    if($cb.Items.Count -gt 0){$cb.SelectedIndex=0}
}
Load-Adapters
$cb.Enabled=-not $chk.Checked
$chk.Add_CheckedChanged({$cb.Enabled=-not $chk.Checked})

# -------------------------------
# MAIN
# -------------------------------
$btn.Add_Click({

    # Adapter bestimmen
    if($chk.Checked){
        $adapter=Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.Name -notmatch "vEthernet"} | Select -First 1
    } else {
        $adapter=Get-NetAdapter -Name $cb.SelectedItem
    }

    if(-not $adapter){
        Msg "Kein Adapter gefunden" "Fehler" ([System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    $sw=$tb.Text.Trim()
    if(!$sw){
        Msg "Bitte Switchnamen eingeben"
        return
    }

    Log "Adapter: $($adapter.Name)"

    # IP & DNS sichern
    $ip=Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 |
        Where {$_.IPAddress -ne "127.0.0.1"} | Select -First 1

    $dns=(Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex).ServerAddresses |
         Where {$_ -match '\.'}

    Log "IP=$($ip.IPAddress) DNS=$($dns -join ',')"

    # Switch erstellen
    try{
        New-VMSwitch -Name $sw -NetAdapterName $adapter.Name -AllowManagementOS $true -ErrorAction Stop
    }catch{
        Msg "Switch konnte nicht erstellt werden"
        return
    }

    # Warten bis vEthernet READY
    $vNic=$null
    for($i=0;$i -lt 10;$i++){
        Start-Sleep 1
        $vNic=Get-NetAdapter -Name "vEthernet ($sw)" -ErrorAction SilentlyContinue
        if($vNic){break}
    }

    if(-not $vNic){
        Msg "vEthernet Adapter nicht gefunden" "Fehler"
        return
    }

    # IP setzen
    if($ip){
        New-NetIPAddress -InterfaceIndex $vNic.ifIndex `
            -IPAddress $ip.IPAddress `
            -PrefixLength $ip.PrefixLength `
            -DefaultGateway $ip.NextHop -ErrorAction SilentlyContinue
    }

    # DNS setzen + Fallback
    if($dns){
        Set-DnsClientServerAddress -InterfaceIndex $vNic.ifIndex -ServerAddresses $dns
        Log "DNS gesetzt"
    } else {
        Log "DNS leer → Fallback"
        Set-DnsClientServerAddress -InterfaceIndex $vNic.ifIndex -ServerAddresses @("8.8.8.8","1.1.1.1")
    }

    # Verifikation
    Start-Sleep 2
    $finalDns=(Get-DnsClientServerAddress -InterfaceIndex $vNic.ifIndex).ServerAddresses
    if(-not $finalDns){
        Msg "WARNUNG: DNS leer! Bitte prüfen." "Warnung" ([System.Windows.Forms.MessageBoxIcon]::Warning)
    }

    Msg "Switch erstellt & Netzwerk stabil gesetzt ✅"
    Log "Fertig"
})

$form.ShowDialog()
Msg "Log: $global:LogFile"
