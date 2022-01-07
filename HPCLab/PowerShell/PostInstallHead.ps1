<#
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0

DESCRIPTION
  This script configures Microsoft HPC Pack Cluster on a Head Node after the installation
#>

$secretId = $args[0]
$secrets = (Get-SECSecretValue -SecretId $secretId).SecretString | ConvertFrom-Json

$pass = ConvertTo-SecureString $secrets.HPCUserPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential $secrets.HPCUserName, $pass


$certSecret =  (Get-SECSecretValue -SecretId $args[1]).SecretString | ConvertFrom-Json 

Add-PSSnapIn Microsoft.HPC
Write-Host "Configuring HPC network" 
Set-HPCNetwork -Topology Enterprise -EnterpriseDnsRegistrationType FullDnsNameOnly `
    -EnterpriseFirewall $True

# Compute node would use this credential to execute cluster
Write-Host "Configuring HPC credentials" 
Set-HpcJobCredential -Credential $credential 
Set-HpcClusterProperty -InstallCredential $credential

# set up cluster property and Node template for adding compute nodes
Write-Host "Configuring HPC cluster naming series" 
Set-HpcClusterProperty -NodeNamingSeries "Compute%100%"

Write-Host "Creating HPC node template" 
New-HpcNodeTemplate -Name "ComputeNode Template" -Description "Custom compute node template" `
     -Type ComputeNode -UpdateCategory None

# set up the HeadNode and bringing it online, the HeadNode needs to be online, else it will not
# accept any ComputeNode connections Broker node won't participate in computing, change into
# -Role BrokerNode, ComputeNode if computing is needed
Write-Host "Assigning Broker role to head node and bringing it online" 
Set-HpcNode -Name $env:COMPUTERNAME -Role BrokerNode > $null 
Set-HpcNodeState -Name $env:COMPUTERNAME -State online > $null

Write-Host "Installing the certificate for the compute nodes deployment"
$secPsw = ConvertTo-SecureString $certSecret.certPassword -AsPlainText -Force;
$pfxFilePath = "c:\cfn\install\HPCPack\Setup\HpcComputeNode.pfx"

Set-HpcInstallCertificate -PfxFilePath $pfxFilePath -Password $secPsw
