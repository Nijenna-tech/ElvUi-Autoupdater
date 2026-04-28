@echo off
:: Wechselt in den Ordner der Batch-Datei
cd /d "%~dp0"

:: --- HEADER (Wird nur einmal beim Start angezeigt) ---
echo ======================================================================
echo Nijenna ElvUI Updater: Wait for everything to be loaded...
echo Checks for Update will start in 5 seconds.

if not exist "Nijenna_Config.txt" (
    echo.
    echo  [!] [!] [!] [!] [!] [!] [!]  REMINDER [!] [!] [!] [!] [!] [!] [!]  
    echo.
    echo REMINDER: Addon path is needed because config file does not exist...
    echo.
    echo  [!] [!] [!] [!] [!] [!] [!] [!] [!] [!] [!] [!] [!] [!] [!] [!]  
    echo.
)
echo =======================================================================

:: Initialer Timeout
timeout /t 5 /nobreak

:START
echo Checking internet connection...
:: Ping an Google-DNS
ping 8.8.8.8 -n 1 -w 1000 >nul

if %errorlevel% neq 0 (
    echo.
    echo [!] [%time:~0,8%] No internet connection detected. 
    echo [!] Waiting 10 seconds before retrying...
    timeout /t 10 /nobreak
    echo.
    goto START
)

echo [+] Internet connection: OK!
echo [+] Starting update in 3 seconds...
timeout /t 3 /nobreak

:: Startet das PowerShell-Skript
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Nijenna_ElvUi_Updater.ps1"

:: FALL 1: Echtes Update wurde gemacht (exit 10 aus der PS1)
if %errorlevel% equ 10 (
    echo.
    echo [+] Das Update wurde erfolgreich installiert!
    timeout /t 5 /nobreak
    exit
)

:: FALL 2: Alles andere (Standard 0, oder dein exit 2)
:: Das deckt "schon aktuell" ab.
if %errorlevel% equ 0 (
    echo.
    echo [+] ElvUi ist aktuell, kein Update erforderlich!
    timeout /t 5 /nobreak
    exit
)

:: Falls ein unbekannter Fehler auftrat (Fenster zur Diagnose offen lassen)
echo.
echo [!] Der Updater wurde mit einem unerwarteten Status beendet (Code: %errorlevel%).
pause