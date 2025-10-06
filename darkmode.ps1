param([int]$ModeValue)

if (-not $ModeValue) {
    $ModeValue = 0
} 

# Set operating system to use dark mode
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name SystemUsesLightTheme -Value $ModeValue -ErrorAction Stop

# Set applications to use dark mode
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -Value $ModeValue -ErrorAction Stop
