
$baseUrl = "https://raw.githubusercontent.com/Shroudmoa/ProjectB/main/Wallpapers"


$rand = Get-Random -Minimum 1 -Maximum 24 
$randomImage = "$rand.jpg"


$downloadUrl = "$baseUrl/$randomImage"


$tempPath = "$env:TEMP\$randomImage"


Invoke-WebRequest -Uri $downloadUrl -OutFile $tempPath


Add-Type @"
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@


[Wallpaper]::SystemParametersInfo(24, 0, $tempPath, 3)

Write-Output "Wallpaper gesetzt: $randomImage"
