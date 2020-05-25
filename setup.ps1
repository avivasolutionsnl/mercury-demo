#Requires -RunAsAdministrator
Param(
    [string]
    $currentFolder = "$PSScriptRoot",
    [string]
    $licenseFile = "c:/license/license.xml",
    [string]
    $composeFile = "$PSScriptRoot/docker-compose.yml"
)
Function Test-CommandExists {
    Param ($command)

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'

    try {
        if (Get-Command $command) {
            return $true
        }
    } catch {
        Write-Host "$command does not exist"; 
        return $false
    } finally {
        $ErrorActionPreference = $oldPreference
    }
}

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

If (-Not (Test-Path($licenseFile))) {
    throw "license.xml file at $licenseFile not found"
}

If (-Not (Test-Path("$composeFile"))) {
    throw "docker-compose.yml file at $composeFile not found"
}

Write-Host "Setting the file permissions...."
takeown.exe /R /F $currentFolder
icacls.exe $currentFolder /t /c /GRANT 'Users:F'
icacls.exe $currentFolder /t /c /GRANT 'Authenticated Users:F'
Write-Host "Setting file permissions finished!" -ForegroundColor Green

$dockerIsInstalled = ((Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall") |  Where-Object { $_.GetValue( "DisplayName" ) -like "*docker*" } ).Length;

if ($dockerIsInstalled -eq 0) {
    $dockerInstalexe = "$currentFolder/dockerInstal.exe"

    If (-Not (Test-Path($dockerInstalexe))) {
        $dockerInstalDownload = "$currentFolder/dockerInstal.exe"
        Write-Host "Downloading docker...."
        Invoke-WebRequest -Uri https://download.docker.com/win/stable/Docker%20for%20Windows%20Installer.exe -OutFile $dockerInstalDownload
        Move-Item -Path $dockerInstalDownload -Destination $dockerInstalexe
        Write-Host "Download of docker finished!" -ForegroundColor Green
    }
    else {
        Write-Host "Docker already downloaded!" -ForegroundColor Green
    }
    Write-Host "Installing docker...."
    start-process -wait $dockerInstalexe " install --quiet"
    Write-Host "Docker installed!" -ForegroundColor Green

    Write-Host "Starting docker...."
    start-process "$env:ProgramFiles\docker\Docker\Docker for Windows.exe"
    Write-Host "Docker started!" -ForegroundColor Green
}else{
    Write-Host "Docker already installed!" -ForegroundColor Green
}

If (!(Test-CommandExists "az")) {
    $azureclimsi = "$currentFolder/azurecli.msi"
    If (-Not (Test-Path($azureclimsi))) {
        Write-Host "Downloading the azure cli...."
        Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile $azureclimsi
        Write-Host "Download of azure cli finished!" -ForegroundColor Green
    }
    else {
        Write-Host "Azure cli already downloaded!" -ForegroundColor Green
    }
    Write-Host "Installing the azure cli...."
    Start-Process msiexec.exe -Wait -ArgumentList '/I $azureclimsi /quiet'
    Write-Host "Installation of azure cli finished!" -ForegroundColor Green
}
else {
    Write-Host "Azure cli already installed!" -ForegroundColor Green
}
Write-Host "Setup finished! Please restart for changes to take effect" -ForegroundColor Green
