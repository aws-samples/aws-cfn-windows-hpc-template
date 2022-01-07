<#
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0

DESCRIPTION
  This PowerShell script configures the network on the instance
#>

$secretId = $args[0]
$secret = Get-SECSecretValue -SecretId $secretId
$secrets = $secret.SecretString | ConvertFrom-Json

$interfaceNewName = "Enterprise"
$adapterName = (Get-NetAdapter | Select-Object -ExpandProperty Name -First 1)
Write-Host "Renaming adapter"
Rename-NetAdapter -Name $adapterName -NewName $interfaceNewName

Write-Host "Reading adapter configuration"
$privateDns = (Get-DnsClientServerAddress -InterfaceAlias $interfaceNewName `
    -AddressFamily IPv4).ServerAddresses

Write-Host "Setting DNS parameters"
Set-DnsClient -InterfaceAlias $interfaceNewName -ConnectionSpecificSuffix $secrets.HPCDNSName `
    -UseSuffixWhenRegistering:$true -RegisterThisConnectionsAddress:$true -Confirm:$false
Set-DnsClientServerAddress -InterfaceAlias $interfaceNewName -ServerAddresses $privateDns
$class = [wmiclass]'Win32_NetworkAdapterConfiguration'
$class.SetDNSSuffixSearchOrder(@($secrets.HPCDNSName))

Write-Host "Flushing DNS cache"
& ipconfig /flushdns

Write-Host "Deactivating Windows Update"
$AUSettings = (New-Object -com "Microsoft.Update.AutoUpdate").Settings
$AUSettings.NotificationLevel         = 1      # Disabled
$AUSettings.ScheduledInstallationDay  = 1      # Every Sunday
$AUSettings.ScheduledInstallationTime = 3      # 3AM
$AUSettings.IncludeRecommendedUpdates = $false # Disabled
$AUSettings.FeaturedUpdatesEnabled    = $false # Disabled
$AUSettings.Save()
