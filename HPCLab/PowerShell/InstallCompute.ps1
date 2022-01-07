<#
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0

DESCRIPTION
  This PowerShell script installs Microsoft HPC Pack on a Compute Node
#>

$certSecret =  (Get-SECSecretValue -SecretId $args[0]).SecretString | ConvertFrom-Json
$CertPassword = $certSecret.certPassword 

Write-Host "Starting Installation"

$installPath = "C:\cfn\install\HPCPack"

Write-Host "Installing HPC Pack"
Start-Process -Wait -WindowStyle Hidden -Verb RunAs `
    -WorkingDirectory '\\head-node\REMINST\' `
    -FilePath 'Setup.exe' `
    -ArgumentList @(
      '-Unattend',
      '-ComputeNode:"head-node"',
      '-SSLPfxFilePath:"\\head-node\REMINST\Certificates\HpcCnCommunication.pfx"',
      "-SSLPfxFilePassword:`"$CertPassword`"",
      '-CACertificate:"\\head-node\REMINST\Certificates\HpcHnPublicCert.cer"',
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
