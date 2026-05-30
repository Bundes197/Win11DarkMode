cls

New-Variable -Name "DARK_MODE" -Value ([int]0) -Option Constant
New-Variable -Name "LIGHT_MODE" -Value ([int]1) -Option Constant
[String]$PERSONALIZE_PATH = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
[String]$ACCENT_PATH = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Accent" # AccentColorMenu, StartColorMenu
[String]$DWM_PATH = "HKCU:\SOFTWARE\Microsoft\Windows\DWM" # AccentColor, EnableWindowColorization, ColorizationAfterglow, ColorizationColor

New-Variable -Name "SET_DARK_MODE" -Value "1" -Option Constant
New-Variable -Name "SET_LIGHT_MODE" -Value "2" -Option Constant
New-Variable -Name "DISABLE_WIN_WATERMARK" -Value "3" -Option Constant
New-Variable -Name "COLOR_PREVALENCE" -Value "4" -Option Constant
New-Variable -Name "SYSTEM_TRANSPARENCY" -Value "5" -Option Constant
New-Variable -Name "EXIT" -Value "6" -Option Constant

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
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsNT\CurrentVersion\SoftwareProtectionPlatform\Activation" -Name NotificationDisabled -Value 1 -ErrorAction Stop

        Write-Host "'Activate Windows' watermark related settings have been modified." -ForegroundColor Green
    } catch {
        Show-Error $_
    }
    
}

function Deactivate-Watermark {
    Write-Host ""
    $AnswerWatermark = Read-Host "Would you also like to turn off 'Activate Windows' watermark? (y/n)"

    if ($AnswerWatermark -eq "y") {
        Execute-Deactivate-Watermark
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
    try {
        $accColorVal = (Get-ItemProperty -Path $PERSONALIZE_PATH -Name ColorPrevalence).ColorPrevalence

        if ($accColorVal -eq 0) {
            Set-ItemProperty -Path $PERSONALIZE_PATH -Name ColorPrevalence -Value 1
            Set-ItemProperty -Path $DWM_PATH -Name ColorPrevalence -Value 1
            Write-Host "Theme color prevalence has been successfully turned on." -ForegroundColor Green
        } else {
            Set-ItemProperty -Path $PERSONALIZE_PATH -Name ColorPrevalence -Value 0
            Set-ItemProperty -Path $DWM_PATH -Name ColorPrevalence -Value 0
            Write-Host "Theme color prevalence has been successfully turned off." -ForegroundColor Green
        }
    } catch {
        Show-Error $_
    }
}

function Toggle-Theme-Transparency {
    try {
        $transparencyVal = (Get-ItemProperty -Path $PERSONALIZE_PATH -Name EnableTransparency).EnableTransparency

        if ($transparencyVal -eq 0) {
            Set-ItemProperty -Path $PERSONALIZE_PATH -Name EnableTransparency -Value 1
            Write-Host "Theme transparency has been successfully turned on." -ForegroundColor Green
        } else {
            Set-ItemProperty -Path $PERSONALIZE_PATH -Name EnableTransparency -Value 0
            Write-Host "Theme transparency has been successfully turned off." -ForegroundColor Green
        }
    } catch {
        Show-Error $_
    }
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
Write-Host "[3] Turn off 'Activate Windows' watermark (experimental, might not work)"
Write-Host "[4] Toggle accent color prevalence in system"
Write-Host "[5] Toggle window transparency in system"
Write-Host "[6] Exit"

Write-Host ""

$AnswerVal = Read-Host "Please choose an option (1,2,3,4,5,6)"

switch ($AnswerVal) {
    $SET_DARK_MODE {
        Set-Mode $DARK_MODE
    }

    $SET_LIGHT_MODE {
        Set-Mode $LIGHT_MODE
    }

    $DISABLE_WIN_WATERMARK {
        Execute-Deactivate-Watermark
    }

    $COLOR_PREVALENCE {
        Toggle-Accent-Color-Prevalence
    }

    $SYSTEM_TRANSPARENCY {
        Toggle-Theme-Transparency
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
