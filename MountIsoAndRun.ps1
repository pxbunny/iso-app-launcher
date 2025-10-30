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

if (-not (Test-Path $IsoPath -PathType Leaf)) {
    throw "ISO file not found: $IsoPath"
}

$diskImage = $null

try {
    Write-Host "Mounting ISO: $IsoPath"

    $diskImage = Mount-DiskImage -ImagePath $IsoPath -PassThru -ErrorAction Stop
    $volume = Get-Volume -DiskImage $diskImage -ErrorAction Stop

    if (-not $volume) { throw "Could not read the ISO volume." }

    $driveLetterUpper = $DriveLetter.ToUpper()

    if ($driveLetterUpper -ne $volume.DriveLetter) {
        if (Test-Path "$driveLetterUpper`:\") {
            throw "Drive letter $driveLetterUpper`: is already in use."
        }

        $partition = Get-Partition -DriveLetter $originalLetter -ErrorAction Stop
        Set-Partition -InputObject $partition -NewDriveLetter $driveLetterUpper -ErrorAction Stop
    }

    if (-not (Test-Path $ExePath -PathType Leaf)) {
        throw "EXE file not found: $ExePath"
    }

    Write-Host "Launching: $ExePath"
    Write-Host "Waiting for the application to exit..."

    $process = Start-Process -FilePath $ExePath -PassThru -Wait

    Write-Host "Process finished with exit code: $($process.ExitCode)"
}
catch {
    Write-Error "Error: $($_.Exception.Message)"
    cmd /c "pause"
}
finally {
    if (-not ($diskImage)) { Exit }

    try {
        Write-Host "Unmounting ISO..."
        Dismount-DiskImage -ImagePath $IsoPath -ErrorAction Stop -Confirm:$false | Out-Null
        Write-Host "Done!"
    } catch {
        Write-Warning "Could not unmount the ISO: $($_.Exception.Message)"
    }
}
