# 
# AWS CloudFormation Windows HPC Template
# 
# Copyright 2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# 
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
# 
#  http://aws.amazon.com/apache2.0
# 
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.
# 

# 
# This PowerShell script manages the installation process of Microsoft HPC Pack on a Head Node
#
# It must be called with the name of the text file storing the user's information, the current region, and the stack name. Text file in the format (one value per line, no padding):
#   DOMAIN\HPCUser (Domain NetBIOS Name\User SAM Account Name)
#   Password
#
[CmdletBinding()]
param(
  [Parameter(Mandatory=$True,Position=1)]
  [string]$UserFile,
  [Parameter(Mandatory=$True,Position=2)]
  [string]$Region,
  [Parameter(Mandatory=$True,Position=3)]
  [string]$Stack
)

if (-not (Test-Path $UserFile))
{
    Throw "File '$UserFile' does not exist, exiting script"
}

$content = Get-Content $UserFile
$UserPS = $content[0]
$PassPS = $content[1]

# Write-Host "Registering Installation Scheduled Task"
# schtasks.exe /Create /SC ONSTART /RU "$UserPS" /RP "$PassPS" /TN InstallHPCPack /TR "powershell.exe -ExecutionPolicy Unrestricted C:\cfn\install\install-hpc-pack.ps1 >> C:\cfn\log\hpc-install.log 2>&1"

# Write-Host "Running Installation Scheduled Task"
# schtasks.exe /Run /I /TN InstallHPCPack

Write-Host "Waiting for Installation"
$status = (Get-Service -Name HpcManagement -ErrorAction SilentlyContinue | Select -ExpandProperty Status)
while ($status -ne "Running")
{
  Start-Sleep 10
  $status = (Get-Service -Name HpcManagement -ErrorAction SilentlyContinue | Select -ExpandProperty Status)
}

& ${env:SystemRoot}\Microsoft.NET\Framework64\v4.0.30319\installutil.exe "D:\HPCPack2012\Bin\ccppsh.dll"

Write-Host "Deleting Installation Scheduled Task"
schtasks.exe /Delete /F /TN InstallHPCPack

Start-Sleep 300

Write-Host "Registering Post-Installation Scheduled Task"
schtasks.exe /Create /SC ONSTART /RU "$UserPS" /RP "$PassPS" /TN PostInstallHPCPack /TR "powershell.exe -ExecutionPolicy Unrestricted C:\cfn\install\post-install-hpc-pack.ps1 -UserFile $UserFile >> C:\cfn\log\hpc-install2.log 2>&1"

Write-Host "Running Post-Installation Scheduled Task"
schtasks.exe /Run /I /TN PostInstallHPCPack

Write-Host "Waiting for Post-Installation"
Add-PSSnapIn Microsoft.HPC

$state = (Get-HpcNode -Name $env:COMPUTERNAME -ErrorAction SilentlyContinue | Select -ExpandProperty NodeState)
while ($state -ne "Online")
{
  Start-Sleep 10
  $state = (Get-HpcNode -Name $env:COMPUTERNAME -ErrorAction SilentlyContinue | Select -ExpandProperty NodeState)
}

Write-Host "Deleting Post-Installation Scheduled Task"
schtasks.exe /Delete /F /TN PostInstallHPCPack

Write-Host "Registering Metrics Publication Scheduled Task"
schtasks.exe /Create /SC MINUTE /MO 1 /RU "$UserPS" /RP "$PassPS" /TN ComputeMetrics /TR "powershell.exe -ExecutionPolicy Unrestricted C:\cfn\install\compute-metrics.ps1 -Region $Region -Stack $Stack >> C:\cfn\log\metrics-publish.log 2>&1"

Write-Host "Done"