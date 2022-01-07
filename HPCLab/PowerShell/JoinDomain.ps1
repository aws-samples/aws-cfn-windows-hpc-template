<#
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0

DESCRIPTION
  This script joins this instance to a domain, using the specified hpc user
#>

Write-Host "Getting DNS IPs"

$secretId = $args[0]
$secret = Get-SECSecretValue -SecretId $secretId
$secrets = $secret.SecretString | ConvertFrom-Json 

$HPCIPs = $args[1]

$pattern="[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"
$dnsIPs = [regex]::Matches($HPCIPs,$pattern) |
  Select-Object -ExpandProperty Value
if (-not ($dnsIPs.Length -eq 2)) {
    Throw "Something wrong with DNS IPs, exiting script"
}

Write-Host "Getting instance DNS IPs"
$index=Get-NetIPConfiguration
$idx=$index.InterfaceIndex
Set-DNSClientServerAddress -Interfaceindex $idx -ServerAddresses `
    ($dnsIPs[0],$dnsIPs[1])

Write-Host "Building credentials"
$pass = ConvertTo-SecureString $secrets.HPCUserPassword -AsPlainText -Force
$domainCred = New-Object System.Management.Automation.PSCredential $secrets.HPCUserName, $pass

Write-Host "Joining instance to the domain"
Add-Computer -DomainName $secrets.HPCDNSName -Credential $domainCred -Restart
