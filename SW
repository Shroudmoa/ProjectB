# HyperV-Switch-Creator_V2.ps1
# Vollständige Version 2
# GUI zur Auswahl eines Adapters, Erstellen eines externen Hyper-V Switches,
# Übertragen der IP-Konfiguration oder Aktivieren von DHCP
# Jetzt mit WLAN-Unterstützung & korrigierter ComboBox-Logik

[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

# --------- Hilfsfunktionen ----------
function Log-Info {
    param([string]$Message)
    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content $global:LogFile "$time [INFO] $Message"
}

function Log-Error {
    param([string]$Message)
    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content $global:LogFile "$time [ERROR] $Message"
}

function Show-MessageBox {
    param($text, $caption="Info", $icon=[System.Windows.Forms.MessageBoxIcon]::Information)
    [System.Windows.Forms.MessageBox]::Show($text, $caption, [System.Windows.Forms.MessageBoxButtons]::OK, $icon) | Out-Null
}

# --------- Admin-Rechte prüfen ----------
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Show-MessageBox "Bitte das Skript als Administrator starten!" "Fehlende Rechte" ([System.Windows.Forms.MessageBoxIcon]::Warning)
    exit
}

# --------- Logging vorbereiten ----------
$global:LogFile = "$env:TEMP\HyperV-Switch-Creator_V2_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss")
"Log gestartet: $(Get-Date)" | Out-File -FilePath $global:LogFile

# --------- GUI erstellen ----------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Hyper-V Switch Creator – Version 2"
$form.Size = New-Object System.Drawing.Size(650,300)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

# Adapter Label
$lblAdapter = New-Object System.Windows.Forms.Label
$lblAdapter.Location = "10,20"
$lblAdapter.AutoSize = $true
$lblAdapter.Text = "Netzwerkadapter auswählen:"
$form.Controls.Add($lblAdapter)

# ComboBox
$cbAdapter = New-Object System.Windows.Forms.ComboBox
$cbAdapter.Location = "10,45"
$cbAdapter.Width = 600
$form.Controls.Add($cbAdapter)

# Checkbox automatischer Adapter
$chkAuto = New-Object System.Windows.Forms.CheckBox
$chkAuto.Text = "Automatisch ersten aktiven Adapter wählen"
$chkAuto.Location = "10,80"
$chkAuto.AutoSize = $true
$chkAuto.Checked = $true
$form.Controls.Add($chkAuto)

# Switchname Label
$lblName = New-Object System.Windows.Forms.Label
$lblName.Location = "10,115"
$lblName.AutoSize = $true
$lblName.Text = "Name des neuen Switches:"
$form.Controls.Add($lblName)

# Textbox Switchname
$tbName = New-Object System.Windows.Forms.TextBox
$tbName.Location = "10,140"
$tbName.Width = 300
$form.Controls.Add($tbName)

# Radiobuttons
$rbStatic = New-Object System.Windows.Forms.RadioButton
$rbStatic.Text = "Statische IP (falls vorhanden) übernehmen"
$rbStatic.Location = "10,170"
$rbStatic.AutoSize = $true
$rbStatic.Checked = $true
$form.Controls.Add($rbStatic)

$rbDHCP = New-Object System.Windows.Forms.RadioButton
$rbDHCP.Text = "DHCP aktivieren"
$rbDHCP.Location = "10,190"
$rbDHCP.AutoSize = $true
$form.Controls.Add($rbDHCP)

# Button erstellen
$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "Switch erstellen"
$btnStart.Size = "150,35"
$btnStart.Location = "440,130"
$form.Controls.Add($btnStart)

# Button abbrechen
$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Abbrechen"
$btnCancel.Size = "150,30"
$btnCancel.Location = "440,175"
$btnCancel.Add_Click({ $form.Close() })
$form.Controls.Add($btnCancel)


# ---------- Adapterliste laden ----------
function Load-Adapters {

    $cbAdapter.Items.Clear()

    # PRIORITY 1 → physische Adapter
    $adapters = Get-NetAdapter -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.Status -eq "Up" -and
                    $_.Name -notmatch "vEthernet" -and
                    $_.Name -notmatch "Hyper-V"
                }

    foreach ($a in $adapters) {
        $cbAdapter.Items.Add($a.Name)
    }

    if ($cbAdapter.Items.Count -gt 0) { $cbAdapter.SelectedIndex = 0 }
}

Load-Adapters

# GUI Logik
$chkAuto.Add_CheckedChanged({
    $cbAdapter.Enabled = -not $chkAuto.Checked
})

$cbAdapter.Enabled = -not $chkAuto.Checked


# ============= Hauptfunktion =============
$btnStart.Add_Click({

    # Adapter ermitteln
    if ($chkAuto.Checked) {
        $adapter = Get-NetAdapter |
                   Where-Object { $_.Status -eq "Up" -and $_.Name -notmatch "vEthernet" } |
                   Select-Object -First 1
    } else {
        $adapter = Get-NetAdapter -Name $cbAdapter.SelectedItem
    }

    if (-not $adapter) {
        Show-MessageBox "Kein geeigneter Netzwerkadapter gefunden." "Fehler" ([System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    $switchName = $tbName.Text.Trim()
    if ($switchName -eq "") {
        Show-MessageBox "Bitte einen Switchnamen eingeben." "Fehler"
        return
    }

    Log-Info "Adapter ausgewählt: $($adapter.Name)"

    # IP-Konfig sichern
    $ip = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
          Where-Object { $_.IPAddress -ne "127.0.0.1" } |
          Select-Object -First 1

    $dns = (Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex).ServerAddresses

    if ($ip) {
        Log-Info "Gefundene IP: $($ip.IPAddress)/$($ip.PrefixLength) GW=$($ip.NextHop)"
    } else {
        Log-Info "Keine statische IP gefunden."
    }

    # Switch erstellen
    try {
        New-VMSwitch -Name $switchName -NetAdapterName $adapter.Name -AllowManagementOS $true -ErrorAction Stop
        Log-Info "Switch erstellt: $switchName"
    } catch {
        Log-Error "Fehler beim Erstellen des Switches: $_"
        Show-MessageBox "Fehler beim Erstellen des Switches." "Fehler"
        return
    }

    Start-Sleep -Seconds 2

    # neuen vEthernet Adapter suchen
    $vAdapter = Get-NetAdapter |
                Where-Object { $_.Name -like "vEthernet ($switchName)" } |
                Select-Object -First 1

    if (-not $vAdapter) {
        Log-Error "Neuer vEthernet Adapter wurde nicht gefunden."
        Show-MessageBox "vEthernet Adapter wurde nicht gefunden." "Fehler"
        return
    }

    Log-Info "Neuer Adapter: $($vAdapter.Name)"

    # IP übertragen
    try {
        if ($rbDHCP.Checked) {
            Set-NetIPInterface -InterfaceIndex $vAdapter.ifIndex -Dhcp Enabled -ErrorAction Stop
            Log-Info "DHCP aktiviert."
        } elseif ($ip) {
            New-NetIPAddress -InterfaceIndex $vAdapter.ifIndex -IPAddress $ip.IPAddress `
                             -PrefixLength $ip.PrefixLength -DefaultGateway $ip.NextHop -ErrorAction Stop

            if ($dns) {
                Set-DnsClientServerAddress -InterfaceIndex $vAdapter.ifIndex -ServerAddresses $dns -ErrorAction Stop
            }
            Log-Info "Statische IP übertragen."
        }
    } catch {
        Log-Error "Fehler beim Setzen der IP: $_"
        Show-MessageBox "Fehler beim Übertragen der IP." "Fehler"
        return
    }

    Show-MessageBox "Switch erfolgreich erstellt und IP übertragen!" "Fertig"
    Log-Info "Fertig."

})

# ---- GUI starten ----
$form.ShowDialog()
