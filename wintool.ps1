

# Prompt user for Python folder path
$pythonFolderPath = Read-Host -Prompt 'Enter the Python folder path'

# Check if pythonFolderPath exists and python.exe is in this folder
if (-Not (Test-Path $pythonFolderPath)) {
    Write-Host "Python folder path does not exist: $pythonFolderPath"
    exit 1
}
if (-Not (Test-Path "$pythonFolderPath\python.exe")) {
    Write-Host "Python executable does not exist in folder: $pythonFolderPath"
    exit 1
}



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


# Ensure the directory structure exists
$dirPath = "$spmFolderPath\package\log_uploader"
if (-Not (Test-Path $dirPath)) {
    New-Item -Path $dirPath -ItemType Directory
}


Invoke-WebRequest -Uri "https://api.github.com/repos/$owner/$repo/contents/package/log_uploader/log_uploader.py" -Headers $headers -OutFile "$spmFolderPath\package\log_uploader\log_uploader.py"

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
Invoke-Expression "& '$pythonFolderPath\python.exe' -m pip install pymongo"
Invoke-Expression "& '$pythonFolderPath\python.exe' -m pip install pyserial"
Invoke-Expression "& '$pythonFolderPath\python.exe' -m pip install pynput"

