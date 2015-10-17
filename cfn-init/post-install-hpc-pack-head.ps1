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
# This PowerShell script configures Microsoft HPC Pack on a Head Node
#
# It must be called with the name of the text file storing the user's information in the format (one value per line, no padding):
#   DOMAIN\HPCUser (Domain NetBIOS Name\User SAM Account Name)
#   Password
#
[CmdletBinding()]
param(
  [Parameter(Mandatory=$True,Position=1)]
  [string]$UserFile
)

if (-not (Test-Path $UserFile))
{
    Throw "File '$UserFile' does not exist, exiting script"
}

$content = Get-Content $UserFile
$UserPS = $content[0]
$PassPS = ConvertTo-SecureString $content[1] -AsPlainText -Force
$DomainCred = New-Object System.Management.Automation.PSCredential $UserPS, $PassPS

Add-PSSnapIn Microsoft.HPC

Set-HPCNetwork -Topology Enterprise -EnterpriseDnsRegistrationType FullDnsNameOnly -EnterpriseFirewall $null

Set-HpcJobCredential -Credential $DomainCred
Set-HpcClusterProperty -InstallCredential $DomainCred

Set-HpcClusterProperty -NodeNamingSeries "Compute%1000%"
New-HpcNodeTemplate -Name "ComputeNode Template" -Description "Custom compute node template" -Type ComputeNode -UpdateCategory None 
Set-HpcNode -Name $env:COMPUTERNAME -Role BrokerNode
Set-HpcNodeState -Name $env:COMPUTERNAME -State online
