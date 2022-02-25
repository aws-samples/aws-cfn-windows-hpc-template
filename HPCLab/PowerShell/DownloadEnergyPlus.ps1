 <#
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0

This sample, non-production-ready PowerShell script downloads EnergyPlus HPC software on HPC Pack cluster head node and uploads to S3.
©¿½ 2021 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
http://aws.amazon.com/agreement or other written agreement between Customer and either
Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

#>

#set instance id from metadata
$instanceId = (New-Object System.Net.WebClient).DownloadString("http://169.254.169.254/latest/meta-data/instance-id")
$stackName = Get-EC2Tag | ` Where-Object {$_.ResourceId -eq $instanceId -and $_.Key -eq 'aws:cloudformation:stack-name'} | Select-Object -ExpandProperty Value

#Returns a Stack instance describing the specified stack
$s3BucketName = ((get-cfnstack $stackName).Parameters | where {$_.ParameterKey -eq 'S3BucketName'}).ParameterValue
$s3BucketRegion = ((get-cfnstack $stackName).Parameters | where {$_.ParameterKey -eq 'S3Region'}).ParameterValue

Write-Host "Installing EnergyPlus"
cd C:\

#use this if you're downloading from github
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest https://github.com/NREL/EnergyPlus/releases/download/v9.5.0/EnergyPlus-9.5.0-de239b2e5f-Windows-x86_64.zip -OutFile "EnergyPlus.zip"


#sha256 hash checksum for EnergyPlus
#0fbdebef1223c4d9ddc3560dbd7042995097e9e668f68b8510302952d3d8ffb6
#https://github.com/NREL/EnergyPlus/releases/tag/v9.5.0 has a txt file called sha256sums.txt
$energyPlusHash = "0fbdebef1223c4d9ddc3560dbd7042995097e9e668f68b8510302952d3d8ffb6"

#use SHA256 Algorithm and get Checksum/hash from downloaded EnergyPlus File
Set-Location -Path C:\
$downloadedHash = Get-FileHash -Path .\EnergyPlus.zip -Algorithm SHA256

Write-Host $downloadedHash.hash
Write-Host $energyPlusHash

#validate if checksums from downloaded zip hash and EnergyPlus hash match
if ($downloadedHash.hash -ne $energyPlusHash){
    Write-Host "The hash values do not match" -ForegroundColor Red
    Remove-Item 'C:\EnergyPlus.zip' -Force -Recurse

    Write-Host "Deleting EnergyPlus.zip - possible security threat detected" -ForegroundColor Red
    Write-Host "Exiting script" -ForegroundColor Red
    exit
} else {
    Write-Host "The hash values match" -ForegroundColor Green
}

#write EnergyPlus to S3
Write-S3Object -BucketName $s3BucketName -Key EnergyPlus.zip -File C:\EnergyPlus.zip -Region $s3BucketRegion

Write-Host "EnergyPlus has successfully uploaded to S3"