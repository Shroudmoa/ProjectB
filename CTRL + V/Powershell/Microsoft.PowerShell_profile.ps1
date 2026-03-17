# Minimal profile: UTF‑8 + Oh My Posh (if installed) + Fastfetch with explicit config path
#C:\Users\User\Documents\WindowsPowerShell - 
try {
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    chcp 65001 > $null
} catch {}

Clear-Host
#Import-Module posh-git

#oh-my-posh init pwsh --config 'C:\Users\moa\.config\ohmyposh\tokyo.omp.json' | Invoke-Expression


# Force Fastfetch to use YOUR config every time (bypass path confusion)
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch -c "C:/Users/%USERPROFILE%/.config/fastfetch/config.jsonc"
}
