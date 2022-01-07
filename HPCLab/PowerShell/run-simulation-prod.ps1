<#
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0

This sample, non-production-ready PowerShell script performs EnergyPlus simulations for HPC workloads on HPC Pack cluster worker nodes.  
© 2021 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.  
This AWS Content is provided subject to the terms of the AWS Customer Agreement available at  
http://aws.amazon.com/agreement or other written agreement between Customer and either
Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both. #>

#set case variable that pulls from parametric job * iteration
param([Int32]$case=1) 

#set instance id from metadata
$instanceId = (New-Object System.Net.WebClient).DownloadString("http://169.254.169.254/latest/meta-data/instance-id")
$stackName = Get-EC2Tag | ` Where-Object {$_.ResourceId -eq $instanceId -and $_.Key -eq 'aws:cloudformation:stack-name'} | Select-Object -ExpandProperty Value

#Returns a Stack instance describing the specified stack
#$S3BucketName = (Get-CFNStack -StackName $stackName).Parameters | where {$_.ParameterKey -eq 'S3BucketName'}
#$S3BucketName | ForEach-Object {$_.ParameterValue}

$S3BucketName = ((get-cfnstack $stackName).Parameters | where {$_.ParameterKey -eq 'S3BucketName'}).ParameterValue
$S3OutputBucketName = ((get-cfnstack $stackName).Parameters | where {$_.ParameterKey -eq 'S3OutputBucketName'}).ParameterValue
$HPCPackUrl = ((Get-CFNStack -StackName $stackName).Outputs | where {$_.OutputKey -eq 'URL'}).OutputValue

Write-Host $S3BucketName
Write-Host $S3OutputBucketName
#starting script - make sure it's working with the correct case number passed from HPC Pack
Write-Host "running EnergyPlus simulation for case $case..."

#make output directory
mkdir C:\output\$case\
cd C:\output\$case\

#read idf and epw inputs from s3
#Read-S3Object -BucketName $s3BucketName -KeyPrefix input/$case/idf -Folder C:\input\$case\idf
#Read-S3Object -BucketName $s3BucketName -KeyPrefix input/$case/epw -Folder C:\input\$case\epw

#if idf folder exists, delete
Get-ChildItem C:\input\$case\idf\ -Recurse | Remove-Item
#create idf input folder
New-Item -Path "C:\input\$case\idf\" -ItemType Directory
#get input files from examplefiles folder to a staging folder
New-Item -Path "C:\EnergyPlus\EnergyPlus-9.5.0-de239b2e5f-Windows-x86_64\ExampleFiles\idf\" -ItemType Directory
Get-ChildItem C:\EnergyPlus\EnergyPlus-9.5.0-de239b2e5f-Windows-x86_64\ExampleFiles\ -Filter *.idf | Copy-Item -Destination C:\EnergyPlus\EnergyPlus-9.5.0-de239b2e5f-Windows-x86_64\ExampleFiles\idf\ -Force -PassThru

#get random idf input file
$idfinputfile = gci "C:\EnergyPlus\EnergyPlus-9.5.0-de239b2e5f-Windows-x86_64\ExampleFiles\idf\5ZoneAirCooled_*.idf" | resolve-path  |  get-random -count 1
#copy to idf folder
Copy-Item $idfinputfile  -destination C:\input\$case\idf\

#create epw folder and copy input epw
New-Item -Path "C:\input\$case\epw\" -ItemType Directory
Copy-Item "C:\EnergyPlus\EnergyPlus-9.5.0-de239b2e5f-Windows-x86_64\WeatherData\USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw" -Destination "C:\input\$case\epw\"

#find idf input
Write-Host "finding idf input file.."
cd C:\input\$case\idf

#set idf file name as idf ps variable
$idf = dir | Where-Object {$_.extension -eq ".idf"}
Write-Host "idf input: "$idf

#input epw input
Write-Host "finding epw weather input file"
cd C:\input\$case\epw

#set epw file name as epw ps variable
$epw = dir | Where-Object {$_.extension -eq ".epw"}
Write-Host "epw input file: "$epw

#change to output directory
cd C:\output\$case\

#run simulation
C:\EnergyPlus\EnergyPlus-9.5.0-de239b2e5f-Windows-x86_64\energyplus -i \Energy+.idd -w C:\input\$case\epw\$epw C:\input\$case\idf\$idf

#delete input files from worker node
#Remove-Item 'C:\Users\$case\admin\input\epw' -Recurse
#Remove-Item 'C:\Users\$case\admin\input\idf' -Recurse

#write output files to s3
Write-S3Object -BucketName $S3OutputBucketName -Folder C:\output\$case\ -KeyPrefix output\$case\

#remove idf files
Remove-Item 'C:\EnergyPlus\EnergyPlus-9.5.0-de239b2e5f-Windows-x86_64\ExampleFiles\idf\' -Recurse

#simulation completed
Write-Host "Finished simulation for case $case"
Write-Host "Removed idf and epw inputs for case $case"
Write-Host "Instance that performed simulation: $instanceId"
Write-Host "S3Bucket: $S3BucketName"
Write-Host "S3 Output Bucket: $S3OutputBucketName"
Write-Host "HPC Pack Portal: $HPCPackUrl"
Write-Host "Done"
