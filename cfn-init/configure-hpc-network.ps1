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
# This PowerShell script confgures the network adapter for a member of a compute cluster
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

Write-Host "Firewall deactivation"
Set-NetFirewallProfile -All -Enabled False

Write-Host "Renaming network card"
$adapterName = (Get-NetAdapter | Select -ExpandProperty Name -First 1)
Rename-NetAdapter -Name $adapterName -NewName $InterfaceNewName

Write-Host "Reading adapter configuration"
$private    = (Get-NetIPAddress -InterfaceAlias $InterfaceNewName -AddressFamily IPv4)
$privateIp  = $private.IPAddress
$privatePl  = $private.PrefixLength
$privateGw  = (Get-NetIPConfiguration -InterfaceAlias $InterfaceNewName).IPv4DefaultGateway.NextHop
$privateDns = (Get-DnsClientServerAddress -InterfaceAlias $InterfaceNewName -AddressFamily IPv4).ServerAddresses

Write-Host "Deactivating IPv6"
Disable-NetAdapterBinding  -InterfaceAlias $InterfaceNewName -ComponentID ms_tcpip6 -Confirm:$false

Write-Host "Using Static IP"
Remove-NetIPAddress -InterfaceAlias $InterfaceNewName -IPAddress $privateIp -Confirm:$false
New-NetIPAddress    -InterfaceAlias $InterfaceNewName -IPAddress $privateIp -PrefixLength $privatePl -DefaultGateway $privateGw -Confirm:$false

Write-Host "Setting DNS parameters"
Set-DnsClient -InterfaceAlias $InterfaceNewName -ConnectionSpecificSuffix $DomainDNSName -UseSuffixWhenRegistering:$true -RegisterThisConnectionsAddress:$true -Confirm:$false
Set-DnsClientServerAddress -InterfaceAlias $InterfaceNewName -ServerAddresses $privateDns
$class = [wmiclass]'Win32_NetworkAdapterConfiguration'
$class.SetDNSSuffixSearchOrder(@($DomainDNSName))

Write-Host "Flushing DNS cache"
& ipconfig /flushdns

if (Test-Path "D:\PROWinx64\PROXGB\Winx64\NDIS64\vxn64x64.inf")
{
  Write-Host "Installing Intel Updated Network driver (SR-IOV)"
  pnputil -i -a D:\PROWinx64\PROXGB\Winx64\NDIS64\vxn64x64.inf > "D:\PROWinx64\setup.log" 2>&1
}

if (Test-Path "D:\AWSPVDriverSetup\AWSPVDriverSetup.msi")
{
  Write-Host "Install AWS Updated Drivers"
  & msiexec.exe /log "D:\AWSPVDriverSetup\install.log" /i "D:\AWSPVDriverSetup\AWSPVDriverSetup.msi" /quiet > "D:\AWSPVDriverSetup\setup.log" 2>&1
}

# Error occured
# Write-Host "Activating Jumbo Frames and deactivating Interrupt Moderation"
# netsh int ip set subinterface "$InterfaceNewName" mtu=9001 store=persistent
# Set-NetAdapterAdvancedProperty -Name $InterfaceNewName -RegistryKeyword "*JumboPacket" -RegistryValue 9014
# Set-NetAdapterAdvancedProperty -Name $InterfaceNewName -RegistryKeyword "*InterruptModeration" -RegistryValue 0

Write-Host "Deactivating Windows Update"
$AUSettings = (New-Object -com "Microsoft.Update.AutoUpdate").Settings
$AUSettings.NotificationLevel         = 1      # Disabled
$AUSettings.ScheduledInstallationDay  = 1      # Every Sunday
$AUSettings.ScheduledInstallationTime = 3      # 3AM
$AUSettings.IncludeRecommendedUpdates = $false # Disabled
$AUSettings.FeaturedUpdatesEnabled    = $false # Disabled
$AUSettings.Save()
