Write-Host "Windows tool installer"

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$args
)
Write-Host "Windows tool installer with arguments: $args"

# Download the script content
$scriptContent = (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/vhuag/syna_install/master/test.ps1').Content

# Save the script content to a temporary file
$tempFile = [System.IO.Path]::GetTempFileName()
Set-Content -Path $tempFile -Value $scriptContent

# Run the downloaded script with the provided arguments
& $tempFile @args

# Optional: Remove the temporary file
Remove-Item -Path $tempFile