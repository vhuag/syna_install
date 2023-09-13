
# Initialize an empty dictionary
$synaluDict = @{}

# Scan for all environment variables with "SYNALU" prefix
$envVariables = Get-ChildItem Env: | Where-Object { $_.Name -match "^SYNALU_" }

# List all environment variables with "SYNALU" prefix and populate the dictionary
if ($envVariables.Count -eq 0) {
    Write-Host "No environment variables with 'SYNALU_' prefix found."
} else {
    Write-Host "Populating dictionary with environment variables having 'SYNALU' prefix:"
    foreach ($var in $envVariables) {
      #  Write-Host ("{0} = {1}" -f $var.Name, $var.Value)
        
        # Removing 'SYNALU_' prefix and populating the dictionary
        $key = $var.Name -replace '^SYNALU_', ''
        $synaluDict[$key] = $var.Value
        Write-Host ("{0} = {1}" -f $key, $synaluDict[$key])
    }
}

$pythonFolderPath = $synaluDict["pythonpath"]
#if the dict doesn't contain the key, it will return null
#if ($pythonFolderPath -eq $null) {
#    Write-Host "Python folder path does not exist"
#}

if ($pythonFolderPath -eq $null) {
    # Prompt user for Python folder path
    $pythonFolderPath = Read-Host -Prompt 'Enter the Python folder path'
}
Write-Host "python path: $pythonFolderPath"

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

# List of modules to check
$modules = @("requests", "pymongo", "pyserial", "pynput")

# Get the list of installed modules
$moduleList = Invoke-Expression "& '$pythonFolderPath\python.exe' -m pip list"

foreach ($module in $modules) {
    $moduleFound = $false

    foreach ($line in $moduleList) {
        if ($line -match $module) {
            $moduleFound = $true
            break
        }
    }

    if (-Not $moduleFound) {
        Write-Host "Installing Python module: $module"
        Invoke-Expression "& '$pythonFolderPath\python.exe' -m pip install $module"
    }
}

# Initialize a variable to store the command-line parameters
$spmParameters = ""

# Convert each key-value pair in the dictionary to a command-line parameter
# Convert each key-value pair in the dictionary to a command-line parameter
foreach ($entry in $synaluDict.GetEnumerator()) {
    $key = $entry.Name
    $value = $entry.Value
    # Skip pythonFolderPath
    if ($key -eq "pythonPath") {
        continue
    }
    $spmParameters += "$key=$value "
}

# Run spm with the collected command-line parameters
$spmCommand = "$pythonFolderPath\python.exe C:\spm\spm run log_uploader upload_from_com $spmParameters"
Write-Host "Running: $spmCommand"
Invoke-Expression "& $spmCommand"
#Start-Process -FilePath "$pythonFolderPath\python.exe" -ArgumentList "C:\spm\spm $spmParameters" -NoNewWindow -Wait