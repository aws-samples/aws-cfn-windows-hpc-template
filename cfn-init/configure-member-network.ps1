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
# This PowerShell script confgures the network adapter for a domain member computer
#
# It must be called with the domain DNS name, and with the name of the network adapter
#
[CmdletBinding()]
param(
  [Parameter(Mandatory=$True,Position=1)]
  [string]$DomainDNSName,
  [Parameter(Mandatory=$True,Position=2)]
  [string]$InterfaceNewName
)

Import-Module ServerManager

Write-Host "Renaming network adapter"
$adapterName = (Get-NetAdapter | Select -ExpandProperty Name -First 1)
Rename-NetAdapter -Name $adapterName -NewName $InterfaceNewName

Write-Host "Disabling IPv6"
Disable-NetAdapterBinding  -InterfaceAlias $InterfaceNewName -ComponentID ms_tcpip6 -Confirm:$false

Write-Host "Changing DNS Client"
Set-DnsClient -InterfaceAlias "Public" -ConnectionSpecificSuffix $DomainDNSName -UseSuffixWhenRegistering:$false -RegisterThisConnectionsAddress:$false -Confirm:$false

Write-Host "Changing DNS configuration on hosts"
$nics = (Get-WmiObject "Win32_NetworkAdapterConfiguration where IPEnabled='TRUE'")
foreach($nic in $nics)
{
  $nic.SetDnsDomain($DomainDNSName)
}

Write-Host "Changing DNS Search Order"
$class = [wmiclass]'Win32_NetworkAdapterConfiguration'
$class.SetDNSSuffixSearchOrder(@($DomainDNSName))

Write-Host "Done"
