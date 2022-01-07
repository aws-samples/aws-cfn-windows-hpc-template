<#
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0

DESCRIPTION
  This PowerShell script is the installation process of HPC Pack on a Head Node
#>


Write-Host "Installing the HPC Pack"
C:\cfn\install\InstallHead.ps1 $args[1]

Write-Host "Waiting for Installation"
do {
  $status = (Get-Service -Name HpcManagement -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Status)
} while (($status -ne "Running") -and (Start-Sleep 5))

Write-Host "Post installation configurations"
C:\cfn\install\PostInstallHead.ps1 $args[0] $args[1]

Add-PSSnapIn Microsoft.HPC
do {
  $status = (Get-HpcNode -Name $env:COMPUTERNAME -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty NodeState)
} while (($status -ne "Online") -and (Start-Sleep 5))
Write-Host "Done"

Write-Host "Downloading EnergyPlus"
C:\cfn\install\DownloadEnergyPlus.ps1 
