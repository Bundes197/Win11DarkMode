cls

New-Variable -Name "DARK_MODE" -Value ([int]0) -Option Constant
New-Variable -Name "LIGHT_MODE" -Value ([int]1) -Option Constant

[String]$PERSONALIZE_PATH = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
[String]$ACCENT_PATH = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Accent" #AGBR
[String]$DWM_PATH = "HKCU:\SOFTWARE\Microsoft\Windows\DWM"
[String]$DESKTOP_PATH = "HKCU:\Control Panel\Desktop"

New-Variable -Name "SET_DARK_MODE" -Value "1" -Option Constant
New-Variable -Name "SET_LIGHT_MODE" -Value "2" -Option Constant
New-Variable -Name "ACCENT_COLOR" -Value "3" -Option Constant
New-Variable -Name "ACCENT_WALLPAPER" -Value "4" -Option Constant
New-Variable -Name "COLOR_PREVALENCE" -Value "5" -Option Constant
New-Variable -Name "SYSTEM_TRANSPARENCY" -Value "6" -Option Constant
New-Variable -Name "DISABLE_WIN_WATERMARK" -Value "7" -Option Constant
New-Variable -Name "EXIT" -Value "8" -Option Constant

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
    exit
}

function Execute-Deactivate-Watermark {
    try {
        # Turn off 'Activate Windows' watermark
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\svsvc" -Name Start -Value 4 -ErrorAction Stop
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform\Activation" -Name NotificationDisabled -Value 1 -ErrorAction Stop

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

    Write-Host ""

    # Printing mode name according to ModeValue
    $ModeName = if ($ModeValue -eq 0) {"Dark"} else {"Light"}
    Write-Host "Applying $($ModeName) mode to your system..." -ForegroundColor Yellow

    try {
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
        $accColorVal = (Get-ItemProperty -Path $PERSONALIZE_PATH -Name ColorPrevalence -ErrorAction Stop).ColorPrevalence

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
        $transparencyVal = (Get-ItemProperty -Path $PERSONALIZE_PATH -Name EnableTransparency -ErrorAction Stop).EnableTransparency

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
        $autoColorizationVal = (Get-ItemProperty -Path $DESKTOP_PATH -Name AutoColorization -ErrorAction Stop).AutoColorization

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
}

# Check if run as admin, if not, restart
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-Command `"cd '$pwd'; & '$PSCommandPath'`""
    exit;
}

Write-Host ""
Write-Host "Welcome to Win11DarkMode. What would you like to do?"
Write-Host ""

Write-Host "[1] Set Dark mode"
Write-Host "[2] Set Light mode"
Write-Host "[3] Set Accent color"
Write-Host "[4] Toggle Accent color from wallpaper"
Write-Host "[5] Toggle Accent color prevalence in system"
Write-Host "[6] Toggle Window transparency in system"
Write-Host "[7] Turn off 'Activate Windows' watermark (experimental, might not work)"
Write-Host "[8] Exit"

Write-Host ""

$AnswerVal = Read-Host "Please choose an option (1,2,3,4,5,6,7,8)"

switch ($AnswerVal) {
    $SET_DARK_MODE {
        Set-Mode $DARK_MODE
    }

    $SET_LIGHT_MODE {
        Set-Mode $LIGHT_MODE
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
        Execute-Deactivate-Watermark
    }

    $EXIT {
        exit
    }

    default {
        Write-Host "Invalid input." -ForegroundColor Red
        Start-Sleep -Seconds 3
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
