cls

New-Variable -Name "DARK_MODE" -Value ([int]0) -Option Constant
New-Variable -Name "LIGHT_MODE" -Value ([int]1) -Option Constant

[String]$PERSONALIZE_PATH = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
[String]$DWM_PATH = "HKCU:\SOFTWARE\Microsoft\Windows\DWM"
[String]$DESKTOP_PATH = "HKCU:\Control Panel\Desktop"

New-Variable -Name "SET_DARK_MODE" -Value "1" -Option Constant
New-Variable -Name "SET_LIGHT_MODE" -Value "2" -Option Constant
New-Variable -Name "SET_WALLPAPER" -Value "3" -Option Constant
New-Variable -Name "ACCENT_COLOR" -Value "4" -Option Constant
New-Variable -Name "ACCENT_WALLPAPER" -Value "5" -Option Constant
New-Variable -Name "COLOR_PREVALENCE" -Value "6" -Option Constant
New-Variable -Name "SYSTEM_TRANSPARENCY" -Value "7" -Option Constant
New-Variable -Name "DISABLE_WIN_WATERMARK" -Value "8" -Option Constant
New-Variable -Name "EXIT" -Value "9" -Option Constant

function Show-Error {
    param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ErrorRecord]$ErrorObject
    )

    $ScriptName = Split-Path -Leaf $PSCommandPath
    Write-Host "An error has occurred." -ForegroundColor Red
    Write-Host "Details: $($ErrorObject.Exception.Message)" -ForegroundColor DarkRed
    Write-Host "Try unblocking the $($ScriptName) file (Right-click on file -> Properties -> Unblock)."
    Write-Host "Or try running $($ScriptName) as administrator."
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

function Ensure-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)

    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Start-Process -FilePath "powershell.exe" `
            -Verb RunAs `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""

        exit
    }
}

function Deactivate-Watermark {
    Ensure-Administrator

    Write-Host ""
    Write-Host "Deactivating Activate Windows watermark..."  -ForegroundColor Yellow

    $svsvcPath = "HKLM:\System\CurrentControlSet\Services\svsvc"
    $activationPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform\Activation"

    try {
        if (-not (Test-Path $svsvcPath)) {
            New-Item -Path (Split-Path $svsvcPath -Parent) -Name "svsvc" -Force -ErrorAction Stop | Out-Null
        }
        
        try {
            $null = Get-ItemProperty -Path $svsvcPath -Name Start -ErrorAction Stop
        } catch [Microsoft.PowerShell.Commands.WriteErrorException], [System.Management.Automation.ItemNotFoundException] {
            New-ItemProperty -Path $svsvcPath -Name Start -Value 4 -PropertyType DWORD -Force -ErrorAction Stop | Out-Null
        }

        if (-not (Test-Path $activationPath)) {
            $parentPath = Split-Path $activationPath -Parent
            if (-not (Test-Path $parentPath)) {
                New-Item -Path (Split-Path $parentPath -Parent) -Name "SoftwareProtectionPlatform" -Force -ErrorAction Stop | Out-Null
            }
            New-Item -Path $parentPath -Name "Activation" -Force -ErrorAction Stop | Out-Null
        }

        try {
            $null = Get-ItemProperty -Path $activationPath -Name NotificationDisabled -ErrorAction Stop
        } catch [Microsoft.PowerShell.Commands.WriteErrorException], [System.Management.Automation.ItemNotFoundException] {
            New-ItemProperty -Path $activationPath -Name NotificationDisabled -Value 1 -PropertyType DWORD -Force -ErrorAction Stop | Out-Null
        }

        Set-ItemProperty -Path $svsvcPath -Name Start -Value 4 -ErrorAction Stop
        Set-ItemProperty -Path $activationPath -Name NotificationDisabled -Value 1 -ErrorAction Stop

        Write-Host "'Activate Windows' watermark related settings have been modified." -ForegroundColor Green
    } catch {
        Show-Error $_
    }
}

function Set-Mode {
    param (
        [Parameter(Mandatory=$true)]
        [int]$ModeValue
    )

    # Printing mode name according to ModeValue
    $ModeName = if ($ModeValue -eq 0) {"Dark"} else {"Light"}

    Write-Host ""
    Write-Host "Applying $($ModeName) mode to your system..." -ForegroundColor Yellow

    try {
        try {
            $null = Get-ItemProperty -Path $PERSONALIZE_PATH -Name SystemUsesLightTheme -ErrorAction Stop
        } catch [Microsoft.PowerShell.Commands.WriteErrorException], [System.Management.Automation.ItemNotFoundException] {
            New-ItemProperty -Path $PERSONALIZE_PATH -Name SystemUsesLightTheme -Value $ModeValue -PropertyType DWORD -Force -ErrorAction Stop | Out-Null
        }

        try {
            $null = Get-ItemProperty -Path $PERSONALIZE_PATH -Name AppsUseLightTheme -ErrorAction Stop
        } catch [Microsoft.PowerShell.Commands.WriteErrorException], [System.Management.Automation.ItemNotFoundException] {
            New-ItemProperty -Path $PERSONALIZE_PATH -Name AppsUseLightTheme -Value $ModeValue -PropertyType DWORD -Force -ErrorAction Stop | Out-Null
        }

        # Set operating system to use dark/light mode
        Set-ItemProperty -Path $PERSONALIZE_PATH -Name SystemUsesLightTheme -Value $ModeValue -ErrorAction Stop

        # Set applications to use dark/light mode
        Set-ItemProperty -Path $PERSONALIZE_PATH -Name AppsUseLightTheme -Value $ModeValue -ErrorAction Stop

        Write-Host "$($ModeName) mode has been successfully set." -ForegroundColor Green
    } catch {
        Show-Error $_
    }
}

function Toggle-Accent-Color-Prevalence {
    Write-Host ""
    Write-Host "Toggling Accent color prevalence..."  -ForegroundColor Yellow

    try {
        try {
            $accColorVal = (Get-ItemProperty -Path $PERSONALIZE_PATH -Name ColorPrevalence -ErrorAction Stop).ColorPrevalence
        } catch [Microsoft.PowerShell.Commands.WriteErrorException], [System.Management.Automation.ItemNotFoundException] {
            # Create the property if it does not exist, default to 0 to trigger the "turn on" logic below
            New-ItemProperty -Path $PERSONALIZE_PATH -Name ColorPrevalence -Value 0 -PropertyType DWORD -Force -ErrorAction Stop | Out-Null
            $accColorVal = 0
        }

        try {
            $null = Get-ItemProperty -Path $DWM_PATH -Name ColorPrevalence -ErrorAction Stop
        } catch {
            New-ItemProperty -Path $DWM_PATH -Name ColorPrevalence -Value 0 -PropertyType DWORD -Force -ErrorAction Stop | Out-Null
        }

        if ($accColorVal -eq 0) {
            Set-ItemProperty -Path $PERSONALIZE_PATH -Name ColorPrevalence -Value 1 -ErrorAction Stop
            Set-ItemProperty -Path $DWM_PATH -Name ColorPrevalence -Value 1 -ErrorAction Stop
            Write-Host "Theme color prevalence has been successfully turned on." -ForegroundColor Green
        } else {
            Set-ItemProperty -Path $PERSONALIZE_PATH -Name ColorPrevalence -Value 0 -ErrorAction Stop
            Set-ItemProperty -Path $DWM_PATH -Name ColorPrevalence -Value 0 -ErrorAction Stop
            Write-Host "Theme color prevalence has been successfully turned off." -ForegroundColor Green
        }
    } catch {
        Show-Error $_
    }
}

function Toggle-Window-Transparency {
    Write-Host ""
    Write-Host "Toggling Window transparency..."  -ForegroundColor Yellow

    try {
        try {
            $transparencyVal = (Get-ItemProperty -Path $PERSONALIZE_PATH -Name EnableTransparency -ErrorAction Stop).EnableTransparency
        } catch [Microsoft.PowerShell.Commands.WriteErrorException], [System.Management.Automation.ItemNotFoundException] {
            # Create the property if it does not exist, default to 0 to trigger the "turn on" logic below
            New-ItemProperty -Path $PERSONALIZE_PATH -Name EnableTransparency -Value 0 -PropertyType DWORD -Force -ErrorAction Stop | Out-Null
            $transparencyVal = 0
        }

        if ($transparencyVal -eq 0) {
            Set-ItemProperty -Path $PERSONALIZE_PATH -Name EnableTransparency -Value 1 -ErrorAction Stop
            Write-Host "Theme transparency has been successfully turned on." -ForegroundColor Green
        } else {
            Set-ItemProperty -Path $PERSONALIZE_PATH -Name EnableTransparency -Value 0 -ErrorAction Stop
            Write-Host "Theme transparency has been successfully turned off." -ForegroundColor Green
        }
    } catch {
        Show-Error $_
    }
}

function Toggle-Accent-Color-From-Wallpaper {
    Write-Host ""
    Write-Host "Toggling Accent color from wallpaper..."  -ForegroundColor Yellow

    try {
        try {
            $autoColorizationVal = (Get-ItemProperty -Path $DESKTOP_PATH -Name AutoColorization -ErrorAction Stop).AutoColorization
        } catch [Microsoft.PowerShell.Commands.WriteErrorException], [System.Management.Automation.ItemNotFoundException] {
            # Create the property if it does not exist, default to 0 to trigger the "turn on" logic below
            New-ItemProperty -Path $DESKTOP_PATH -Name AutoColorization -Value 0 -PropertyType DWORD -Force -ErrorAction Stop | Out-Null
            $autoColorizationVal = 0
        }

        if ($autoColorizationVal -eq 0) {
            Set-ItemProperty -Path $DESKTOP_PATH -Name AutoColorization -Value 1 -ErrorAction Stop
            Write-Host "Accent color from wallpaper has been successfully turned on." -ForegroundColor Green
        } else {
            Set-ItemProperty -Path $DESKTOP_PATH -Name AutoColorization -Value 0 -ErrorAction Stop
            Write-Host "Accent color from wallpaper has been successfully turned off." -ForegroundColor Green
        }
    } catch {
        Show-Error $_
    }
}

function Set-Accent-Color {
    cls

    Write-Host ""
    Write-Host "Please select a color:"
    Write-Host ""

    # List all colors

    $AnswerVal = Read-Host "Please choose an option [1..32]"

    # Change the accent color
}

function Set-Wallpaper {
    Write-Host ""
    Write-Host "Please find the image you want as a wallpaper in file explorer" -ForegroundColor Yellow
    Write-Host "Right click on the image and select 'Copy as path'" -ForegroundColor Yellow
    Write-Host "Then paste the path below" -ForegroundColor Yellow
    Write-Host "Pasting invalid path will result in a solid black wallpaper" -ForegroundColor Red
    Write-Host ""

    $PathToImage = (Read-Host).Replace('"', '')

    if (-not (Test-Path $PathToImage)) {
        Write-Host "File does not exist." -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "Setting a new wallpaper..."  -ForegroundColor Yellow

    try {
        try {
            $null = Get-ItemProperty -Path $DESKTOP_PATH -Name WallPaper -ErrorAction Stop
        } catch [Microsoft.PowerShell.Commands.WriteErrorException], [System.Management.Automation.ItemNotFoundException] {
            New-ItemProperty -Path $DESKTOP_PATH -Name WallPaper -Value $PathToImage -PropertyType String -Force -ErrorAction Stop | Out-Null
        }

        Set-ItemProperty -Path $DESKTOP_PATH -Name WallPaper -Value $PathToImage -ErrorAction Stop

        Write-Host "New wallpaper has been successfully set." -ForegroundColor Green

    } catch {
        Show-Error $_
    }
}

Write-Host ""
Write-Host "Welcome to Win11DarkMode. What would you like to do?"
Write-Host ""

Write-Host "[1] Set Dark mode"
Write-Host "[2] Set Light mode"
Write-Host "[3] Set Wallpaper"
Write-Host "[4] Set Accent Color (Not working)"
Write-Host "[5] Toggle Accent color from wallpaper"
Write-Host "[6] Toggle Accent color prevalence in system"
Write-Host "[7] Toggle Window transparency in system"
Write-Host "[8] Deactivate 'Activate Windows' watermark (experimental, might not work, requires admin privileges)"
Write-Host "[9] Exit"

Write-Host ""

$AnswerVal = Read-Host "Please choose an option (1,2,3,4,5,6,7,8,9)"

switch ($AnswerVal) {
    $SET_DARK_MODE {
        Set-Mode $DARK_MODE
    }

    $SET_LIGHT_MODE {
        Set-Mode $LIGHT_MODE
    }

    $SET_WALLPAPER {
        Set-Wallpaper
    }

    $ACCENT_COLOR {
        Set-Accent-Color
    }

    $ACCENT_WALLPAPER {
        Toggle-Accent-Color-From-Wallpaper
    }

    $COLOR_PREVALENCE {
        Toggle-Accent-Color-Prevalence
    }

    $SYSTEM_TRANSPARENCY {
        Toggle-Window-Transparency
    }


    $DISABLE_WIN_WATERMARK {
        Deactivate-Watermark
    }

    $EXIT {
        exit
    }

    default {
        Write-Host "Invalid input." -ForegroundColor Red
        exit
    }
}

Write-Host ""
Write-Host "For changes to take an effect, please restart the computer." -ForegroundColor Yellow
$RestartComputer = Read-Host "Would you like to restart your computer NOW? (y/n)"

Write-Host ""

if ($RestartComputer -eq "y") {
    Write-Host "Restarting your computer in 5 seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    Restart-Computer
} else {
    Write-Host "OK. Don't forget to restart your computer manually later." -ForegroundColor Yellow
}

Write-Host ""
