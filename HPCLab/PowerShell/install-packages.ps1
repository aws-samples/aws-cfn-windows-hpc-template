<#
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0

This sample, non-production-ready PowerShell script installs EnergyPlus HPC software on HPC Pack cluster worker nodes.
© 2021 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
http://aws.amazon.com/agreement or other written agreement between Customer and either
Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both. #>

#set instance id from metadata
$instanceId = (New-Object System.Net.WebClient).DownloadString("http://169.254.169.254/latest/meta-data/instance-id")
$stackName = Get-EC2Tag | ` Where-Object {$_.ResourceId -eq $instanceId -and $_.Key -eq 'aws:cloudformation:stack-name'} | Select-Object -ExpandProperty Value

#Returns a Stack instance describing the specified stack - alternative way; can delete
#$S3BucketName = (Get-CFNStack -StackName $stackName).Parameters | where {$_.ParameterKey -eq 'S3BucketName'}
#$S3BucketName | ForEach-Object {$_.ParameterValue}

#Returns a Stack instance describing the specified stack
$S3BucketName = ((get-cfnstack $stackName).Parameters | where {$_.ParameterKey -eq 'S3BucketName'}).ParameterValue
$S3BucketRegion = ((get-cfnstack $stackName).Parameters | where {$_.ParameterKey -eq 'S3Region'}).ParameterValue

Write-Host "Installing EnergyPlus"
cd C:\

#use this if you're downloading EnergyPlus from S3
Read-S3Object -BucketName $s3BucketName -Key EnergyPlus.zip -File C:\EnergyPlus.zip -Region $S3BucketRegion

#make directory and unzip energyplus contents on local
mkdir EnergyPlus
Expand-Archive C:\EnergyPlus.zip -DestinationPath c:\EnergyPlus

Write-Host "Installed EnergyPlus"
