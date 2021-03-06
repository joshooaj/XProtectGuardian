
$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"

# Prepare PowerShell environment and install MilestonePSTools
Write-Host 'Setting SecurityProtocol to TLS 1.2, Execution Policy to RemoteSigned' -ForegroundColor Green
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
#Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Confirm:$false -Force -ErrorAction SilentlyContinue

Write-Host 'Registering the NuGet package source if necessary' -ForegroundColor Green
if ($null -eq (Get-PackageSource -Name NuGet -ErrorAction Ignore)) {
    $null = Register-PackageSource -Name NuGet -Location https://www.nuget.org/api/v2 -ProviderName NuGet -Trusted -Force
}

Write-Host 'Installing the NuGet package provider' -ForegroundColor Green
$nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction Ignore
$requiredVersion = [Microsoft.PackageManagement.Internal.Utility.Versions.FourPartVersion]::Parse('2.8.5.201')
if ($null -eq $nugetProvider -or $nugetProvider.Version -lt $requiredVersion) {
    $null = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
}

Write-Host 'Installing PowerShellGet 2.2.5 or greater if necessary' -ForegroundColor Green
if ($null -eq (Get-Module -ListAvailable PowerShellGet | Where-Object Version -ge 2.2.5)) {
    $null = Install-Module PowerShellGet -MinimumVersion 2.2.5 -Force
}

Write-Host 'Installing MilestonePSTools' -ForegroundColor Green
if ($null -eq (Get-InstalledModule -Name MilestonePSTools -ErrorAction Ignore)) {
    Install-Module MilestonePSTools -Force
}

# Install Pester
Install-Module Pester -MinimumVersion 5.3.3 -Scope AllUsers -Confirm:$false -SkipPublisherCheck -Force

# Create a folder under the drive root
mkdir actions-runner; cd actions-runner
# Download the latest runner package
Invoke-WebRequest -Uri 'https://github.com/actions/runner/releases/download/v2.293.0/actions-runner-win-x64-2.293.0.zip' -OutFile 'actions-runner-win-x64-2.293.0.zip'
# Optional: Validate the hash
$hash = (Get-FileHash -Path actions-runner-win-x64-2.293.0.zip -Algorithm SHA256).Hash
if($hash -ne 'AE421F582B08CD7F8521C46991FC80685B643402FE3822EAE2DA23430819FB8B'){
    throw 'Computed checksum did not match'
}
# Extract the installer
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD/actions-runner-win-x64-2.293.0.zip", $PWD)

# Install Python + mkdocs
Write-Host "Downloading and installing Python and MkDocs"
Invoke-WebRequest 'https://www.python.org/ftp/python/3.10.5/python-3.10.5-amd64.exe' -OutFile .\python3.10.5.exe
Start-Process .\python3.10.5.exe -ArgumentList '/quiet', 'InstallAllUsers=1', 'PrependPath=1' -Wait
Remove-Item .\python3.10.5.exe
$env:Path += ';C:\Program Files\Python310'
$env:Path += ';C:\Program Files\Python310\scripts'
& pip install mkdocs

# Download portable git
Write-Host "Downloading and installing git"
Invoke-WebRequest 'https://github.com/git-for-windows/git/releases/download/v2.36.1.windows.1/PortableGit-2.36.1-64-bit.7z.exe' -OutFile '.\portablegit.exe'
Start-Process .\portablegit.exe -ArgumentList '-o"C:\git\"', '-y' -Wait
Remove-Item .\portablegit.exe
$path = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).path
$path = "$path;C:\git\bin"
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $path