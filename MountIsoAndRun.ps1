[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$IsoPath,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ExePath,

    [string]$DriveLetter
)

$ErrorActionPreference = 'Stop'
$launchExitCode        = $null

if (-not (Test-Path $IsoPath -PathType Leaf)) {
    throw "ISO file not found: $IsoPath"
}

if ($DriveLetter -and $DriveLetter -notmatch '^[A-Za-z]$') {
    throw "DriveLetter must be a single letter (A-Z)."
}

$diskImage = $null
$mountedDriveLetter = $null

try {
    Write-Host "Mounting ISO: $IsoPath"

    $diskImage = Mount-DiskImage -ImagePath $IsoPath -PassThru -ErrorAction Stop
    $volume    = Get-Volume -DiskImage $diskImage -ErrorAction Stop | Select-Object -First 1

    if (-not $volume) { throw "Could not read the ISO volume." }

    $mountedDriveLetter = $volume.DriveLetter

    if (-not $mountedDriveLetter) { throw "Mounted ISO has no assigned drive letter." }

    $targetDriveLetter = if ($DriveLetter) {
        $DriveLetter.ToUpper()
    } else {
        $mountedDriveLetter
    }

    Start-Sleep -Milliseconds 500

    if ($DriveLetter -and $targetDriveLetter -ne $mountedDriveLetter) {
        if (Test-Path "$targetDriveLetter`:\") {
            throw "Drive letter $targetDriveLetter`: is already in use."
        }

        $partition = Get-Partition -DriveLetter $mountedDriveLetter -ErrorAction Stop
        Set-Partition -InputObject $partition -NewDriveLetter $targetDriveLetter -ErrorAction Stop | Out-Null
        $mountedDriveLetter = $targetDriveLetter
    } else {
        $mountedDriveLetter = $targetDriveLetter
    }

    Write-Host "Using drive letter: $mountedDriveLetter`:"

    $resolvedExePath = if ([System.IO.Path]::IsPathRooted($ExePath)) {
        $ExePath
    } else {
        Join-Path "$mountedDriveLetter`:\" $ExePath
    }

    if (-not (Test-Path $resolvedExePath -PathType Leaf)) {
        throw "EXE file not found: $resolvedExePath"
    }

    Write-Host "Launching executable: $resolvedExePath"
    Write-Host "Waiting for the application to exit..."

    $process = Start-Process -FilePath $resolvedExePath -PassThru -Wait -ErrorAction Stop

    $launchExitCode = $process.ExitCode
    Write-Host "Application finished with exit code: $launchExitCode"
}
catch {
    Write-Error "Failure: $($_.Exception.Message)"
    $launchExitCode = 1
}
finally {
    if ($diskImage) {
        try {
            Write-Host "Unmounting ISO..."
            Dismount-DiskImage -ImagePath $IsoPath -ErrorAction Stop -Confirm:$false | Out-Null
            Write-Host "ISO unmounted."
        } catch {
            Write-Warning "Could not unmount the ISO: $($_.Exception.Message)"
        }
    }
}

if ($null -eq $launchExitCode) { $launchExitCode = 0 }

exit $launchExitCode
