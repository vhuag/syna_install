# Define parameters at the top of the script
param(
    [Parameter(Position=0)]
    [string]$pythonFolderPath,

    [Parameter(Position=1, ValueFromRemainingArguments = $true)]
    [string[]]$args
)

Write-Host "Windows tool installer"

# Read GitHub token from file
$githubToken = Get-Content "\\SJC1WVP-HISDW01\SynarpShare\driver1\spm\spm_token.txt"

# Create C:\spm directory if it doesn't exist
$spmFolderPath = "C:\spm"
if (-Not (Test-Path $spmFolderPath)) {
    New-Item -Path $spmFolderPath -ItemType Directory
}

# GitHub API parameters
$owner = "vhuag"
$repo = "spm"

# Authorization headers
$headers = @{
    Authorization = "Bearer $githubToken"
    Accept = 'application/vnd.github.v3.raw'
}

# Download spm from private GitHub repo
Invoke-WebRequest -Uri "https://api.github.com/repos/$owner/$repo/contents/spm" -Headers $headers -OutFile "$spmFolderPath\spm"

# Download spm.json from private GitHub repo
Invoke-WebRequest -Uri "https://api.github.com/repos/$owner/$repo/contents/spm.json" -Headers $headers -OutFile "$spmFolderPath\spm.json"

# Check if C:\spm is already in the PATH
if ($env:Path -notmatch [regex]::Escape($spmFolderPath)) {
    # If not, add it
    $env:Path += ";$spmFolderPath"
    [Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
}

# Create batch file to run Python script
$batContent = @"
@echo off
"$pythonFolderPath\python.exe" "C:\spm\spm" %*
"@
Set-Content -Path "$spmFolderPath\spm.bat" -Value $batContent

Invoke-Expression "& '$pythonFolderPath\python.exe' -m pip install requests"

# Process the remaining provided arguments
foreach ($arg in $args) {
    Write-Host "Processing argument: $arg"
}
