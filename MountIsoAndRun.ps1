[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$IsoPath,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ExePath,

    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z]$')]
    [string]$DriveLetter
)

$ErrorActionPreference = 'Stop'
$launchExitCode        = $null

if (-not (Test-Path $IsoPath -PathType Leaf)) {
    throw "ISO file not found: $IsoPath"
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

    $driveLetterUpper = $DriveLetter.ToUpper()
    Start-Sleep -Milliseconds 500

    if ($driveLetterUpper -ne $mountedDriveLetter) {
        if (Test-Path "$driveLetterUpper`:\") {
            throw "Drive letter $driveLetterUpper`: is already in use."
        }

        $partition = Get-Partition -DriveLetter $mountedDriveLetter -ErrorAction Stop
        Set-Partition -InputObject $partition -NewDriveLetter $driveLetterUpper -ErrorAction Stop | Out-Null
        $mountedDriveLetter = $driveLetterUpper
    }

    $resolvedExePath = if ([System.IO.Path]::IsPathRooted($ExePath)) {
        $ExePath
    } else {
        Join-Path "$mountedDriveLetter`:\" $ExePath
    }

    if (-not (Test-Path $resolvedExePath -PathType Leaf)) {
        throw "EXE file not found: $resolvedExePath"
    }

    Write-Host "Launching: $resolvedExePath"
    Write-Host "Waiting for the application to exit..."

    $process = Start-Process -FilePath $resolvedExePath -PassThru -Wait -ErrorAction Stop

    $launchExitCode = $process.ExitCode
    Write-Host "Process finished with exit code: $launchExitCode"
}
catch {
    Write-Error "Error: $($_.Exception.Message)"
    $launchExitCode = 1
}
finally {
    if ($diskImage) {
        try {
            Write-Host "Unmounting ISO..."
            Dismount-DiskImage -ImagePath $IsoPath -ErrorAction Stop -Confirm:$false | Out-Null
            Write-Host "Done!"
        } catch {
            Write-Warning "Could not unmount the ISO: $($_.Exception.Message)"
        }
    }
}

if ($null -eq $launchExitCode) { $launchExitCode = 0 }

exit $launchExitCode
