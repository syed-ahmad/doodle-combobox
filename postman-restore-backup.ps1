<#
.SYNOPSIS
    Restores Postman's IndexedDB from backup to %APPDATA%\Postman\IndexedDB.
    Before overwriting, it backs up the current roaming IndexedDB to a timestamped folder.

.DESCRIPTION
    - Backs up current:
        From: %APPDATA%\Postman\IndexedDB
        To:   C:\Users\<username>\dev\postman-indexeddb\roaming-backups\YYYYMMDD_HHMMSS
    - Restores backup:
        From: C:\Users\<username>\dev\postman-indexeddb
        To:   %APPDATA%\Postman\IndexedDB (force overwrite)
    - Uses robocopy for robust, incremental copy with retries.
    - Ensures Postman is NOT running before restoring.

.NOTES
    Run this after closing Postman.
    Adjust $BackupRoot if your backup location differs.
#>

param(
    # Max seconds to wait for Postman to close if it's running
    [int]$MaxWaitSeconds = 120,

    # Seconds between checks while waiting for Postman to close
    [int]$PollIntervalSeconds = 2
)

# --- CONFIGURATION ---

# Backup root (where your watcher script copies IndexedDB to)
$BackupRoot = "C:\Users\$env:USERNAME\dev\postman-indexeddb"

# Folder to store timestamped roaming backups
$RoamingBackupsRoot = Join-Path $BackupRoot "roaming-backups"

# Source for restore (your chosen backup to restore FROM)
$RestoreSource = $BackupRoot

# Destination: Postman's IndexedDB folder in roaming profile
$DestinationPath = Join-Path $env:APPDATA "Postman\IndexedDB"

# Current roaming IndexedDB (to back up before overwrite)
$CurrentRoamingPath = $DestinationPath

# Log file
$LogDir = Join-Path $BackupRoot "logs"
$LogFile = Join-Path $LogDir ("PostmanIndexedDB-Restore-{0}.log" -f (Get-Date -Format "yyyyMMdd"))

# ---------------------

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"

    # Write to host
    switch ($Level) {
        "ERROR" { Write-Host $line -ForegroundColor Red }
        "WARN"  { Write-Host $line -ForegroundColor Yellow }
        default { Write-Host $line }
    }

    # Write to log file
    try {
        if (-not (Test-Path -Path $LogDir -PathType Container)) {
            New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
        }
        Add-Content -Path $LogFile -Value $line -Encoding UTF8
    } catch {
        # If logging fails, just continue
    }
}

function Wait-ForPostmanToClose {
    param(
        [int]$MaxWaitSeconds,
        [int]$PollIntervalSeconds
    )

    $processName = "Postman"
    $elapsed = 0

    while ($true) {
        $procs = Get-Process -Name $processName -ErrorAction SilentlyContinue
        if (-not $procs) {
            Write-Log "Postman is not running."
            return $true
        }

        if ($elapsed -ge $MaxWaitSeconds) {
            Write-Log "Postman is still running after $MaxWaitSeconds seconds. Aborting restore." -Level ERROR
            return $false
        }

        Write-Log "Postman is still running. Waiting $PollIntervalSeconds seconds... ($elapsed/$MaxWaitSeconds)"
        Start-Sleep -Seconds $PollIntervalSeconds
        $elapsed += $PollIntervalSeconds
    }
}

function Backup-CurrentRoamingIndexedDB {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path -Path $Source -PathType Container)) {
        Write-Log "Current roaming IndexedDB does not exist; nothing to back up: $Source" -Level WARN
        return $true
    }

    # Ensure destination parent exists
    if (-not (Test-Path -Path $Destination -PathType Container)) {
        Write-Log "Creating backup directory: $Destination"
        New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    }

    # Use robocopy for robust copy:
    # /E        - copy subdirs including empty
    # /Z        - restartable mode
    # /R:2 /W:2 - retry 2 times, wait 2 seconds
    # /NFL /NDL - no file/dir list in output (cleaner)
    # /NJH /NJS - no job header/summary
    $robocopyArgs = @(
        $Source
        $Destination
        "/E"
        "/Z"
        "/R:2"
        "/W:2"
        "/NFL"
        "/NDL"
        "/NJH"
        "/NJS"
    )

    Write-Log "Backing up current roaming IndexedDB from:"
    Write-Log "  $Source"
    Write-Log "To:"
    Write-Log "  $Destination"

    $result = robocopy @robocopyArgs

    if ($result -ge 8) {
        Write-Log "robocopy failed while backing up roaming IndexedDB (exit code $result)" -Level ERROR
        return $false
    }

    Write-Log "Backup of current roaming IndexedDB completed successfully."
    return $true
}

function Restore-PostmanIndexedDB {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path -Path $Source -PathType Container)) {
        Write-Log "Restore source folder does not exist: $Source" -Level ERROR
        return $false
    }

    # Ensure destination parent exists (%APPDATA%\Postman)
    $destParent = Split-Path -Path $Destination -Parent
    if (-not (Test-Path -Path $destParent -PathType Container)) {
        Write-Log "Creating destination directory: $destParent"
        New-Item -ItemType Directory -Force -Path $destParent | Out-Null
    }

    # Use robocopy for robust, force-overwrite copy:
    # /E        - copy subdirs including empty
    # /Z        - restartable mode
    # /R:2 /W:2 - retry 2 times, wait 2 seconds
    # /NFL /NDL - no file/dir list in output (cleaner)
    # /NJH /NJS - no job header/summary
    # Note: robocopy overwrites by default when destination files exist
    $robocopyArgs = @(
        $Source
        $Destination
        "/E"
        "/Z"
        "/R:2"
        "/W:2"
        "/NFL"
        "/NDL"
        "/NJH"
        "/NJS"
    )

    Write-Log "Restoring IndexedDB from:"
    Write-Log "  $Source"
    Write-Log "To:"
    Write-Log "  $Destination"

    $result = robocopy @robocopyArgs

    if ($result -ge 8) {
        Write-Log "robocopy failed while restoring IndexedDB (exit code $result)" -Level ERROR
        return $false
    }

    Write-Log "Restore completed successfully."
    return $true
}

# --- MAIN ---

Write-Log "=== Postman IndexedDB Restore (with backup) Started ==="

# 1. Ensure Postman is closed
$ok = Wait-ForPostmanToClose -MaxWaitSeconds $MaxWaitSeconds -PollIntervalSeconds $PollIntervalSeconds
if (-not $ok) {
    Write-Log "Aborting restore because Postman is still running." -Level ERROR
    exit 1
}

# 2. Create timestamped backup folder for current roaming IndexedDB
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$RoamingBackupFolder = Join-Path $RoamingBackupsRoot $timestamp

# 3. Backup current roaming IndexedDB
$backupOk = Backup-CurrentRoamingIndexedDB -Source $CurrentRoamingPath -Destination $RoamingBackupFolder
if (-not $backupOk) {
    Write-Log "Backup of current roaming IndexedDB failed; aborting restore." -Level ERROR
    exit 1
}

# 4. Restore chosen backup over roaming IndexedDB (force overwrite)
$restoreOk = Restore-PostmanIndexedDB -Source $RestoreSource -Destination $DestinationPath
if (-not $restoreOk) {
    Write-Log "Restore completed with errors." -Level WARN
    exit 1
}

Write-Log "=== Postman IndexedDB Restore (with backup) Finished ==="
Write-Log "Current roaming IndexedDB backed up to: $RoamingBackupFolder"
exit 0
