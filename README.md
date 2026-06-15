# Win11DarkMode
Simple PowerShell utility for changing Windows 11 personalization settings — even on machines without an active Windows license.

## Features
- Enable Dark mode system-wide
- Enable Light mode system-wide
- Set accent color from wallpaper
- Toggle accent color prevalence in the Start menu and taskbar
- Toggle transparency effects
- Experimental option for hiding the "Activate Windows" watermark
- Automatically requests administrator privileges when needed

## Enabling script execution
- PowerShell by default blocks running scripts for security reasons
- If you cannot execute the script, you need to **allow script execution**
- In PowerShell, type:
    ```powershell
    Set-ExecutionPolicy RemoteSigned
    ```
  and confirm with `y`
- This change is permanent! If you want to revert the change, type:
    ```powershell
    Set-ExecutionPolicy Restricted
    ```

## Usage
1. Open **PowerShell as Administrator**  
2. Navigate to the folder containing `darkmode.ps1` in File Explorer
3. Click the address bar at the top, right-click → **Copy**  
4. In PowerShell, type:  
    ```powershell
    cd <paste-your-path-here>
    ```
    and press **Enter**
5. Then type:
    ```powershell
    Unblock-File .\darkmode.ps1
    ```
6. Run the script:
    ```powershell
    .\darkmode.ps1
    ```
7. Follow the on-screen instructions

## Requirements
- Windows 11
- PowerShell 5.1 or newer
- Administrator privileges

## Disclaimer
The watermark removal option is experimental and may not work on all Windows versions.
