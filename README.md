# Nijenna ElvUI Updater

A lightweight, automated one-click updater for the **ElvUI** World of Warcraft addon. This tool consists of a PowerShell script for the core logic and a Batch file for a user-friendly interface.

## Features
- **Auto-Detection:** Automatically finds your World of Warcraft installation path via Registry and standard directory checks.
- **Silent Update:** Checks the Tukui API for the latest version and updates only if a newer version is available.
- **Clean Installation:** Removes old folders and installs the new version cleanly.
- **Smart Feedback:** Provides clear status messages like "Already up to date" or "Successfully updated".
- **Automatic Cleanup:** Removes temporary zip files and extraction folders after the process.

## Requirements
- Windows 10/11
- PowerShell 5.1 or higher
- Internet Connection

## Installation & Usage
1. Download the `Nijenna_ElvUi_Updater.ps1` and `Nijenna_ElvUi_Updater.bat` files.
2. Place both files in a folder of your choice.
3. Run the **`Nijenna_ElvUi_Updater.bat`** to start the update process.
   - *Note: On the first run, the tool will create a `Nijenna_Config.txt` to store your WoW path.*
4. **For Automation:** Place a shortcut in the Autostart folder.
   - Press `Windows + R`, type `shell:startup` and press Enter. Place a shortcut to the `.bat` file there to never miss an update again.

## How it Works
The tool uses a two-tier communication system:
1. The **Batch File** acts as the wrapper for the console and final user feedback.
2. The **PowerShell Script** handles the core logic: API requests, downloading, and folder management.
3. Specific **Exit Codes** (0 for "Already Current", 10 for "Updated Successfully") ensure the Batch file displays the correct message.

## Credits
Developed by Nijenna.
