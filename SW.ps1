Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Msg($t,$c="Info",$i=[System.Windows.Forms.MessageBoxIcon]::Information){
    [System.Windows.Forms.MessageBox]::Show($t,$c,[System.Windows.Forms.MessageBoxButtons]::OK,$i) | Out-Null
}

function Log($m){
    Add-Content $global:LogFile "$(Get-Date -f 'yyyy-MM-dd HH:mm:ss') $m"
}

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
    Msg "Bitte PowerShell als Administrator starten!" "Admin erforderlich" ([System.Windows.Forms.MessageBoxIcon]::Error)
    exit
}

$global:LogFile="$env:TEMP\SW_V3_$(Get-Date -f yyyyMMdd_HHmmss).log"
Log "SW Tool Version 3 gestartet"

$form=New-Object System.Windows.Forms.Form
$form.Text="Hyper-V Switch Tool – Version 3 (DNS Safe)"
$form.Size=New-Object System.Drawing.Size(620,260)
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
$btn.Size=New-Object System.Drawing.Size(150,35)
$form.Controls.Add($btn)

function Load-Adapters{
    $cb.Items.Clear()
    Get-NetAdapter | Where-Object {
        $_.Status -eq "Up" -and
        $_.Name -notmatch "vEthernet"
    } | For
