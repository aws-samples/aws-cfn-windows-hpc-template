 <#
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0

This sample, non-production-ready PowerShell script performs EnergyPlus simulations for HPC workloads on HPC Pack cluster worker nodes.
©¿½ 2021 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
http://aws.amazon.com/agreement or other written agreement between Customer and either
Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both. #>

#set case variable that pulls from parametric job * iteration
param([Int32]$case=1)

#set instance id from metadata
$instanceId = (New-Object System.Net.WebClient).DownloadString("http://169.254.169.254/latest/meta-data/instance-id")
$stackName = Get-EC2Tag | ` Where-Object {$_.ResourceId -eq $instanceId -and $_.Key -eq 'aws:cloudformation:stack-name'} | Select-Object -ExpandProperty Value

$S3BucketName = ((get-cfnstack $stackName).Parameters | where {$_.ParameterKey -eq 'S3BucketName'}).ParameterValue
$S3BucketRegion = ((get-cfnstack $stackName).Parameters | where {$_.ParameterKey -eq 'S3Region'}).ParameterValue
$S3OutputBucketName = ((get-cfnstack $stackName).Parameters | where {$_.ParameterKey -eq 'S3OutputBucketName'}).ParameterValue
$HPCPackUrl = ((Get-CFNStack -StackName $stackName).Outputs | where {$_.OutputKey -eq 'URL'}).OutputValue

Write-Host $S3BucketName
Write-Host $S3OutputBucketName

Write-Host "running EnergyPlus simulation for case $case..."

#make output directory
mkdir C:\output\$case\
cd C:\output\$case\

#get idf end epw input files
$idfinputfile = Get-ChildItem "C:\EnergyPlus\EnergyPlus-9.5.0-de239b2e5f-Windows-x86_64\ExampleFiles\5ZoneAirCooled_*.idf" | get-random -count 1 | % { $_.FullName }
$epwinputfile = "C:\EnergyPlus\EnergyPlus-9.5.0-de239b2e5f-Windows-x86_64\WeatherData\USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw"

#run simulation
C:\EnergyPlus\EnergyPlus-9.5.0-de239b2e5f-Windows-x86_64\energyplus -i \Energy+.idd -w $epwinputfile $idfinputfile

#write output files to s3
Write-S3Object -BucketName $S3OutputBucketName -Folder C:\output\$case\ -KeyPrefix output\$case\ -Region $S3BucketRegion

#simulation completed
Write-Host "Finished simulation for case $case"
Write-Host "Removed idf and epw inputs for case $case"
Write-Host "Instance that performed simulation: $instanceId"
Write-Host "S3Bucket: $S3BucketName"
Write-Host "S3 Output Bucket: $S3OutputBucketName"
Write-Host "HPC Pack Portal: $HPCPackUrl"
Write-Host "Done"