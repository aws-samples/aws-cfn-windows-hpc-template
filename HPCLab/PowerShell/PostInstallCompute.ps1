<#  
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0

DESCRIPTION
  This script configures Microsoft HPC Pack Cluster on a compute Node 
  after the installation
#>
Add-PSSnapIn Microsoft.HPC
Write-Host "Assigning HPC node template" 
Assign-HpcNodeTemplate -NodeName $env:COMPUTERNAME -Name "ComputeNode Template" `
    -Confirm:$false

Write-Host "Assigning the compute node and bringing it online" 
Set-HpcNode -Name $env:COMPUTERNAME 
Set-HpcNodeState -Name $env:COMPUTERNAME -State online
 
do {
  $status = (Get-HpcNode -Name $env:COMPUTERNAME -ErrorAction SilentlyContinue | 
    Select-Object -ExpandProperty NodeState)
} while (($status -ne "Online") -and (Start-Sleep 5))

Write-Host "Done"
