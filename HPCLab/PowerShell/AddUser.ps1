<#
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0

DESCRIPTION
  This PowerShell script is adding the domain user to local administrators
#>

$secretId = $args[0]
$secret = Get-SECSecretValue -SecretId $secretId
$secrets = $secret.SecretString | ConvertFrom-Json
$HPCBIOSName = $secrets.HPCBIOSName

$ad = [ADSI]"WinNT://$env:ComputerName/Administrators,group"
$ad.Add("WinNT://$HPCBIOSName/admin")
