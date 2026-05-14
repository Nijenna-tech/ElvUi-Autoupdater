# NCC ElvUI One-Click Updater (Silent Optimized)
$scriptPath = $PSScriptRoot
Set-Location $scriptPath

$configFile = Join-Path $scriptPath "Nijenna_Config.txt"
$tempZip = Join-Path $scriptPath "elvui_latest.zip"
$tempExtract = Join-Path $scriptPath "ElvUI_Temp"
$targetFolders = @("ElvUI", "ElvUI_Libraries", "ElvUI_Options")

# 1. Config laden oder automatisch suchen
if (Test-Path $configFile) {
    $configContent = Get-Content $configFile
    $wowPath = $configContent[0]
    $lastVersion = if ($configContent.Count -gt 1) { $configContent[1] } else { "0" }
} else {
    Write-Host "=== NCC ElvUI Updater Erstkonfiguration ===" -ForegroundColor Cyan
    $wowPath = "" # Initialisierung als leerer String zur Fehlervermeidung

    # STUFE A: Registry-Suche an beiden bekannten Orten
    $registryPaths = @(
        "HKLM:\SOFTWARE\WOW6432Node\Blizzard Entertainment\World of Warcraft",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\World of Warcraft"
    )

    foreach ($regPath in $registryPaths) {
        if (Test-Path $regPath) {
            $regValue = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
            $potentialPath = if ($regValue.InstallPath) { $regValue.InstallPath } else { $regValue.InstallLocation }
            
            if ($potentialPath) {
                # Wir prüfen direkt auf den _retail_ Ordner
                $checkPath = Join-Path $potentialPath "_retail_\Interface\AddOns"
                if (Test-Path $checkPath) { 
                    $wowPath = $checkPath
                    break 
                }
            }
        }
    }

    # STUFE B: Wenn Registry nichts liefert -> Suche in Standardpfaden
    if ([string]::IsNullOrWhiteSpace($wowPath)) {
        $defaultPaths = @(
            "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns",
            "C:\Users\Public\Games\World of Warcraft\_retail_\Interface\AddOns"
        )
        foreach ($p in $defaultPaths) {
            if (Test-Path $p) { 
                $wowPath = $p
                break 
            }
        }
    }

    # STUFE C: Wenn immer noch nichts gefunden -> Tiefensuche auf C: und D:
    if ([string]::IsNullOrWhiteSpace($wowPath)) {
        Write-Host "[!] Automatische Suche läuft (das kann einen Moment dauern)..." -ForegroundColor Yellow
        $foundFolder = Get-ChildItem -Path "C:\", "D:\" -Filter "_retail_" -Directory -Recurse -ErrorAction SilentlyContinue | 
                       Where-Object { $_.FullName -like "*World of Warcraft*_retail_*" } | 
                       Select-Object -First 1

        if ($foundFolder) {
            $wowPath = Join-Path $foundFolder.FullName "Interface\AddOns"
        }
    }

    # STUFE D: Letzter Ausweg - Manuelle Eingabe
    if ([string]::IsNullOrWhiteSpace($wowPath) -or -not (Test-Path $wowPath)) {
        Write-Host "[!] WoW konnte nicht automatisch gefunden werden." -ForegroundColor Red
        $wowPath = Read-Host "Bitte WoW AddOns-Pfad manuell eingeben (z.B. C:\Games\WoW\_retail_\Interface\AddOns)"
        if ($wowPath) { $wowPath = $wowPath.Trim('"') }
    } else {
        Write-Host "[V] WoW-Pfad erfolgreich gefunden: $wowPath" -ForegroundColor Green
    }

    # Speichern der gefundenen Konfiguration
    if (-not [string]::IsNullOrWhiteSpace($wowPath)) {
        $wowPath, "0" | Out-File $configFile -Encoding utf8
    }
    $lastVersion = "0"
}

# SICHERHEITS-CHECK: Falls kein Pfad vorhanden ist, hier abbrechen
if ([string]::IsNullOrWhiteSpace($wowPath) -or -not (Test-Path $wowPath)) {
    Write-Host "[!] KRITISCHER FEHLER: Kein gültiger Zielpfad. Update abgebrochen." -ForegroundColor Red
    if ([Environment]::UserInteractive) { Read-Host "Drücke Enter zum Beenden..." }
    exit
}

# 2. API Check
try {
    $apiResponse = Invoke-RestMethod -Uri "https://api.tukui.org/v1/addon/elvui" -UserAgent "Mozilla/5.0"
    $currentVersion = $apiResponse.version 
    
    if ($lastVersion -eq $currentVersion) { 
        # Ausgabe für die Konsole
        Write-Host "Aktuelle Version:" -ForegroundColor Gray
        Write-Host $currentVersion -ForegroundColor White
        
        # Aufräumen
        if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
        if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
        
        [System.Environment]::Exit(0) 
    }
    $realDownloadUrl = $apiResponse.url
} catch { 
    Write-Host "[!] Fehler beim Abrufen der API-Daten." -ForegroundColor Red
    exit 1
}

# 3. Download & Installation
try {
    Write-Host "[...] Lade ElvUI $currentVersion herunter..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $realDownloadUrl -OutFile $tempZip -UserAgent "Mozilla/5.0"
    
    if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
    Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force
    
    foreach ($folder in $targetFolders) {
        $src = Join-Path $tempExtract $folder
        $dst = Join-Path $wowPath $folder
        if (Test-Path $src) {
            if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
            Move-Item -Path $src -Destination $dst -Force
            Write-Host "[+] Ordner aktualisiert: $folder" -ForegroundColor Gray
        }
    }
    
    # Update der Config-Datei mit neuer Version
    $wowPath, $currentVersion | Out-File $configFile -Encoding utf8
    #Write-Host "[V] Update auf Version $currentVersion erfolgreich abgeschlossen!" -ForegroundColor Green
    if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
    if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
    
    [System.Environment]::Exit(10) # <--- Das signalisiert der Batch: "Update wirklich durchgeführt!"

} catch {
    Write-Host "[!] Fehler während der Installation: $($_.Exception.Message)" -ForegroundColor Red
    if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
    if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
    [System.Environment]::Exit(1) # <--- Optional: Signalisiert der Batch einen Fehler
}
