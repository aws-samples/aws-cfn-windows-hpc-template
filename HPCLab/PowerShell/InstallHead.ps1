<#
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0

DESCRIPTION
  This PowerShell script installs Microsoft HPC Pack on a Head Node and prepare
  the HPC certificates
#>
 
$certSecret =  (Get-SECSecretValue -SecretId $args[0]).SecretString | ConvertFrom-Json
$CertPassword = $certSecret.certPassword

$installPath = "C:\cfn\install\HPCPack"

Write-Host "Starting head node Installation"

Write-Host "Preparing installation materials"

if (!(Test-Path "C:\cfn\install\HPCPack.zip")) {
  Throw "Not able to find HPC Pack package, exiting script"
}

Write-Host "Unzipping HPCPack"
Expand-Archive "C:\cfn\install\HPCPack.zip" `
     -DestinationPath $installPath


Write-Host "Preparing SQL installation"
$extractionSQLresult = Start-Process -Wait -PassThru `
    -WorkingDirectory "$installPath\amd64" `
    -FilePath 'SQLEXPR_x64_ENU.exe' `
    -ArgumentList @(
        '/Q',
        '/X:C:\cfn\Install\SQLInstall'
    )
if ($extractionSQLresult.ExitCode -ne 0) {
  Throw "Not able to Extract SQL to SQLInstall, exiting script"
}
$instalSQLresult = Start-Process -Wait -PassThru `
    -WorkingDirectory 'C:\cfn\Install\SQLInstall' `
    -FilePath 'setup.exe' `
    -ArgumentList @(
        '/ConfigurationFile="C:\cfn\install\sql-config.conf"'
    )
if ($instalSQLresult.ExitCode -ne 0) {
  Throw "Not able to install SQL Server express, exiting script"
}
Write-Host "Finish SQL Installation"

Write-Host "Create HPC Certificates"
# using CreateHpcCertificate.ps1 which is in installation package /setup folder to
# create two certificates, one for head node and one for the compute nodes
# see more on https://tiny.amazon.com/xj7fo3zx/wamazbinviewEC2EnteOSTEFA


$password= ConvertTo-SecureString $CertPassword  -AsPlainText -Force
& "$installPath\setup\CreateHpcCertificate.ps1" `
    -Password $password `
    -Path "$installPath\Setup\HpcHeadNode.pfx"
& "$installPath\setup\CreateHpcCertificate.ps1" `
    -Password $password `
    -Path "$installPath\Setup\HpcComputeNode.pfx"

Write-Host "Installing HPC Pack"
Start-Process -Wait -WindowStyle Hidden `
    -WorkingDirectory "$installPath" `
    -FilePath 'Setup.exe' `
    -ArgumentList @(
      '-Unattend',
      '-HeadNode',
      "-SSLPfxFilePath:`"$installPath\Setup\HpcHeadNode.pfx`"",
      "-SSLPfxFilePassword:`"$CertPassword`"",
      "-installdir:`"$installPath`"",
      "-datadir:`"$installPath\Data`"",
      "-MgmtDbDir:`"$installPath\Database\Data\ManagementDB`"",
      "-MgmtDbLogDir:`"$installPath\Database\Log\ManagementDB`"",
      "-SchdDbDir:`"$installPath\Database\Data\SchedulerDB`"",
      "-SchdDbLogDir:`"$installPath\Database\Log\SchedulerDB`"",
      "-ReportingDbDir:`"$installPath\Database\Data\ReportingDB`"",
      "-ReportingDbLogDir:`"$installPath\Database\Log\ReportingDB`"",
      "-DiagDbDir:`"$installPath\Database\Data\DiagnosticsDB`"",
      "-DiagDbLogDir:`"$installPath\Database\Log\DiagnosticsDB`"",
      "-MonDbDir:`"$installPath\Database\Data\MonitoringDB`"",
      "-MonDbLogDir:`"$installPath\Database\Log\MonitoringDB`""
    )

Write-Host "Waiting for Installation"
do {
  $status = (Get-Service -Name HpcManagement -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Status)
} while (($status -ne "Running") -and (Start-Sleep 5))

Write-Host "Installation finished"
