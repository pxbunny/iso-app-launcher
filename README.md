# ISO App Launcher

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A PowerShell script that mounts an ISO, launches an application, and unmounts the ISO when the app exits. Can be used for apps that require a CD to be present while running.


## Requirements

- Windows 10/11
- PowerShell version 5.1+
- Permission to mount/unmount disk images and change drive letters


## Installation

Just copy it anywhere, e.g.: `C:\Scripts\MountIsoAndRun.ps1`


## Usage Example

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File "C:\Scripts\MountIsoAndRun.ps1" `
  -IsoPath "C:\ISO\mydisc.iso" `
  -ExePath "C:\Program Files\MyApp\MyApp.exe" `
  -DriveLetter "I"
```


## One-click launch (shortcut)

1. Right-click the Desktop → **New** → **Shortcut**
2. In the **Type the location of the item**, paste (and update parameters):
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\MountIsoAndRun.ps1" -IsoPath "D:\ISOs\mydisc.iso" -ExePath "C:\Program Files\MyApp\MyApp.exe" -DriveLetter "I"
```
4. Click **Next**, name the shortcut file, and **Finish**.
5. (Optional) Change icon (**Properties** → **Shortcut** → **Change Icon...**)
