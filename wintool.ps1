Write-Host "Windows tool installer"

param(
    [Parameter(Position=0)]
    [string]$pythonFolderPath,

    [Parameter(Position=1, ValueFromRemainingArguments = $true)]
    [string[]]$args
)

#print out the arguments
Write-Host "Python folder path: $pythonFolderPath"
Write-Host "Remaining arguments: $args"
# Add Python folder path to PATH environment variable for this session
$env:Path = "$env:Path;$pythonFolderPath"

# Create C:\spm directory if it doesn't exist
$spmFolderPath = "C:\spm"
if (-Not (Test-Path $spmFolderPath)) {
    New-Item -Path $spmFolderPath -ItemType Directory
}

# Add C:\spm to PATH environment variable for this session
$env:Path = "$env:Path;$spmFolderPath"

# Download spm and spm.json from GitHub to C:\spm
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/vhuag/syna_install/master/spm' -OutFile "$spmFolderPath\spm"
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/vhuag/syna_install/master/spm.json' -OutFile "$spmFolderPath\spm.json"

# Download the main script content
$scriptContent = (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/vhuag/syna_install/master/test.ps1').Content

# Save the script content to a temporary file
$tempFile = [System.IO.Path]::GetTempFileName()
Set-Content -Path $tempFile -Value $scriptContent

# Run the downloaded script with the remaining provided arguments
& $tempFile @args

# Optional: Remove the temporary file
Remove-Item -Path $tempFile