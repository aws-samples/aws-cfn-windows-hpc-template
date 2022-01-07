<#
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0

DESCRIPTION
  This PowerShell script manages the installation process of Microsoft HPC Pack on a Compute Node
#>

$secretId = $args[0]
$secret = Get-SECSecretValue -SecretId $secretId
$secrets = $secret.SecretString | ConvertFrom-Json

Write-Host "Building credentials"
$pass = ConvertTo-SecureString $secrets.HPCUserPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential $secrets.HPCUserName, $pass

# the installation using HPC cluster credentials
Register-PSSessionConfiguration -Name InstallComputeNode -RunAsCredential $credential -Force
Write-Host "Installing the HPC Pack on a Compute Node"
Invoke-Command -ComputerName . -Credential $credential -File "C:\cfn\install\InstallCompute.ps1" `
    -ConfigurationName InstallComputeNode -ArgumentList $args[1]

Write-Host "Post installation configurations on a Compute Node"
Invoke-Command -ComputerName . -Credential $credential -File "C:\cfn\install\PostInstallCompute.ps1" `
    -ConfigurationName InstallComputeNode

Write-Host "Compute Node setup finished"
