cls

[PSConstant]$DARK_MODE = 0
[PSConstant]$LIGHT_MODE = 1


function Show-Error {
    $ScriptName = Split-Path -Leaf $PSCommandPath
    Write-Host "Error: Unable to modify registry value." -ForegroundColor Red
    Write-Host "Details: $($_.Exception.Message)" -ForegroundColor DarkRed
    Write-Host "Try unblocking the $($ScriptName) (Right-click on file -> Properties -> Unblock)."
    Write-Host "Or try running $($ScriptName) as administrator."
}

function Execute-Deactivate-Watermark {
    try {
        # Turn off 'Activate Windows' watermark
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name PaintDesktopVersion -Value 0 -ErrorAction Stop

        Write-Host "'Activate Windows' watermark has been turned off." -ForegroundColor Green
    } catch {
        Show-Error
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
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name SystemUsesLightTheme -Value $ModeValue -ErrorAction Stop

        # Set applications to use dark/light mode
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -Value $ModeValue -ErrorAction Stop

        Write-Host "$($ModeName) mode has been successfully set." -ForegroundColor Green
    } catch {
        Show-Error
    }
}

function Toggle-Accent-Color-Prevalence {
    $accColorVal = Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name ColorPrevalence
    
    try {
        if ($accColorVal -eq 0) {
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name ColorPrevalence -Value 1
            Write-Host "Theme color prevalence has been successfully turned on." -ForegroundColor Green
        } else {
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name ColorPrevalence -Value 0
            Write-Host "Theme color prevalence has been successfully turned off." -ForegroundColor Green
        }
    } catch {
        Show-Error
    }
}

# Check if run as admin, if not, restart
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-Command `"cd '$pwd'; & '$PSCommandPath'`""
    exit;
}

$ModeValue = $DARK_MODE # Set dark mode as default

Write-Host ""
Write-Host "Welcome to Win11DarkMode. What would you like to do?"
Write-Host ""

Write-Host "[1] Set Dark mode"
Write-Host "[2] Set Light mode"
Write-Host "[3] Turn off 'Activate Windows' watermark"
Write-Host "[4] Toggle accent color prevalence in system"
Write-Host "[5] Exit"

Write-Host ""

$AnswerVal = Read-Host "Please choose an option (1,2,3,4,5)"

if ($AnswerVal -eq "1") {
    Deactivate-Watermark
    Set-Mode $DARK_MODE

} elseif ($AnswerVal -eq "2") {
    Deactivate-Watermark
    Set-Mode $LIGHT_MODE

} elseif ($AnswerVal -eq "3") {
    Execute-Deactivate-Watermark

} elseif ($AnswerVal -eq "4") {
    Toggle-Accent-Color-Prevalence    

} elseif ($AnswerVal -eq "5") {
    exit

} else {
    Write-Host "Invalid input." -ForegroundColor Red
    exit
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
