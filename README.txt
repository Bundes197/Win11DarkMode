Win11DarkMode
Simple PowerShell script that enables dark mode across the entire Windows 11 system — even on machines without an active Windows license.

Features
- Enables dark or light mode system-wide  
- Optionally disables the 'Activate Windows' watermark  
- Automatically requests admin privileges if needed

Enabling script execution
- PowerShell by default blocks running scripts for security reasons
- If you cannot execute the script, you need to allow script execution
- In PowerShell, type:

    Set-ExecutionPolicy RemoteSigned

  and confirm with 'y'
- This change is permanent! If you want to revert the change, type:

    Set-ExecutionPolicy Restricted

Usage
1. Open PowerShell as Administrator  
2. Navigate to the folder containing darkmode.ps1  
3. Click the address bar at the top, right-click → Copy  
4. In PowerShell, type:  

    cd <paste-your-path-here>

    and press Enter
5. Run the script:

    .\darkmode.ps1

6. Follow the on-screen instructions

Requirements
- Windows 11
- PowerShell 5.1 or newer
- Administrator privileges
