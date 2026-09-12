<#
.SYNOPSIS
    Watches for Postman shutdowns and backs up Postman's IndexedDB every 30 minutes.

.DESCRIPTION
    - Designed to run at Windows startup and stay running until shutdown.
    - Every 30 minutes:
        * Waits for Postman to be closed.
        * Copies %APPDATA%\Postman\IndexedDB to C:\Users\<username>\dev\postman-indexeddb.
    - Uses robocopy for robust, incremental copies with retries.

.NOTES
    Adjust $DestinationRoot if you want a different base folder.
    Configure this script to run at startup via Task Scheduler or Startup folder.
#>

param(
    # Interval between backup attempts (in minutes)
    [int]$BackupIntervalMinutes = 30,

    # Max seconds to wait for Postman to close if it's running
    [int]$MaxWaitSeconds = 120,

    # Seconds between checks while waiting for Postman to close
    [int]$PollIntervalSeconds = 2
)

# --- CONFIGURATION ---

# Destination root: change if you want a different base path
$DestinationRoot = "C:\Users\$env:USERNAME\dev\postman-indexeddb"

# Source: Postman IndexedDB folder
$SourcePath = Join-Path $env:APPDATA "Postman\IndexedDB"

# Destination: we'll copy into $DestinationRoot directly
$DestinationPath = $DestinationRoot

# Log file (optional, useful for startup scripts)
$LogDir = Join-Path $DestinationRoot "logs"
$LogFile = Join-Path $LogDir ("PostmanIndexedDB-Backup-{0}.log" -f (Get-Date -Format "yyyyMMdd"))

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
            Write-Log "Postman is still running after $MaxWaitSeconds seconds. Skipping backup this cycle." -Level WARN
            return $false
        }

        Write-Log "Postman is still running. Waiting $PollIntervalSeconds seconds... ($elapsed/$MaxWaitSeconds)"
        Start-Sleep -Seconds $PollIntervalSeconds
        $elapsed += $PollIntervalSeconds
    }
}

function Backup-PostmanIndexedDB {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path -Path $Source -PathType Container)) {
        Write-Log "Source folder does not exist: $Source" -Level WARN
        return $false
    }

    # Ensure destination root exists
    $destDir = Split-Path -Path $Destination -Parent
    if (-not (Test-Path -Path $destDir -PathType Container)) {
        Write-Log "Creating destination directory: $destDir"
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
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

    Write-Log "Copying IndexedDB from:"
    Write-Log "  $Source"
    Write-Log "To:"
    Write-Log "  $Destination"

    $result = robocopy @robocopyArgs

    # robocopy exit codes: 0-7 = success with varying details, >=8 = errors
    if ($result -ge 8) {
        Write-Log "robocopy failed with exit code $result" -Level ERROR
        return $false
    }

    Write-Log "Backup completed successfully."
    return $true
}

# --- MAIN LOOP ---

Write-Log "=== Postman IndexedDB Watcher Started ==="
Write-Log "Backup interval: $BackupIntervalMinutes minutes"
Write-Log "Destination: $DestinationPath"

while ($true) {
    try {
        Write-Log "Starting backup cycle."

        # 1. Ensure Postman is closed
        $ok = Wait-ForPostmanToClose -MaxWaitSeconds $MaxWaitSeconds -PollIntervalSeconds $PollIntervalSeconds
        if (-not $ok) {
            Write-Log "Skipping backup this cycle because Postman is still running." -Level WARN
        } else {
            # 2. Perform backup
            $success = Backup-PostmanIndexedDB -Source $SourcePath -Destination $DestinationPath
            if ($success) {
                Write-Log "Backup cycle completed successfully."
            } else {
                Write-Log "Backup cycle completed with errors." -Level WARN
            }
        }
    } catch {
        Write-Log "Unexpected error in backup cycle: $_" -Level ERROR
    }

    Write-Log "Sleeping for $BackupIntervalMinutes minutes before next cycle."
    Start-Sleep -Seconds ($BackupIntervalMinutes * 60)
}
