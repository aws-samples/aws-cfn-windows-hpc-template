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
# This script publishes the local AWS CloudFormation templates to an Amazon S3 bucket
#

[CmdletBinding()]
param(
  [Parameter(Mandatory=$True,Position=1)]
  [string]$Bucket,
  [Parameter(Mandatory=$False,Position=2)]
  [string]$Prefix=""
)

if ($Prefix -eq $null)
{
  $Prefix = ""
}
else
{
  $Prefix = $Prefix.Trim("/")
}

if ($Prefix -eq "")
{
  $FilesPrefix=""
  $Destination="${Bucket}"
  $HttpDestination="https://${Bucket}.s3.amazonaws.com"
}
else
{
  $FilesPrefix="${Prefix}/"
  $Destination="${Bucket}/${Prefix}"
  $HttpDestination="https://${Bucket}.s3.amazonaws.com/${Prefix}"
}

Write-Host "#####"
Write-Host "Publishing files to 's3://${DESTINATION}'"

Write-Host ""
Write-Host "Publishing AWS Lambda function sources"

Add-Type -assembly "System.IO.Compression"
Add-Type -assembly "System.IO.Compression.filesystem"

Get-ChildItem "lambda" -Filter *.js | Foreach-Object {
  $FullName = $_.FullName
  $FileName = $_.Name
  $BaseName = $_.BaseName
  $TmpName  = "${FullName}.tmp"

  $archive = [System.IO.Compression.ZipFile]::Open($TmpName, [IO.Compression.ZipArchiveMode]::Create)
  $entry = $archive.CreateEntry($FileName)
  $outputStream = $entry.Open()
  $inputStream = $_.OpenRead()
  $inputStream.CopyTo($outputStream)
  $inputStream.Close()
  $outputStream.Close()
  $archive.Dispose()

  Write-S3Object -BucketName $Bucket -Key "${FilesPrefix}lambda/${BaseName}.zip" -File $TmpName
  Remove-Item $TmpName
}

Write-Host ""
Write-Host "Publishing PowerShell Scripts"
Get-ChildItem "cfn-init" -Filter *.ps1 | Foreach-Object {
  $FullName = $_.FullName
  $FileName = $_.Name
  Write-S3Object -BucketName $Bucket -Key "${FilesPrefix}cfn-init/${FileName}" -File $FullName
}

Write-Host ""
Write-Host "Publishing Configuration Files"
Get-ChildItem "cfn-init" -Filter *.conf | Foreach-Object {
  $FullName = $_.FullName
  $FileName = $_.Name
  Write-S3Object -BucketName $Bucket -Key "${FilesPrefix}cfn-init/${FileName}" -File $FullName
}

Write-Host ""
Write-Host "Publishing AWS CloudFormation templates"
Get-ChildItem  -Filter *.json | Foreach-Object {
  $FullName = $_.FullName
  $FileName = $_.Name
  $TmpName = "${FullName}.tmp"
  Get-Content $FullName | `
    %{ $_.Replace("<SUBSTACKSOURCE>", "${HttpDestination}/").Replace("<BUCKETNAME>", $Bucket).Replace("<PREFIX>", $FilesPrefix).Replace("<DESTINATION>", $Destination) } | `
    Set-Content $TmpName
  Write-S3Object -BucketName $Bucket -Key "${FilesPrefix}${FileName}" -File $TmpName
  Remove-Item $TmpName
}

Write-Host ""
Write-Host "Publishing AWS CloudFormation sub stacks"
Get-ChildItem  -Filter cfn/*.json | Foreach-Object {
  $FullName = $_.FullName
  $FileName = $_.Name
  $TmpName = "${FullName}.tmp"
  Get-Content $FullName | `
    %{ $_.Replace("<SUBSTACKSOURCE>", "${HttpDestination}/").Replace("<BUCKETNAME>", $Bucket).Replace("<PREFIX>", $FilesPrefix).Replace("<DESTINATION>", $Destination) } | `
    Set-Content $TmpName
  Write-S3Object -BucketName $Bucket -Key "${FilesPrefix}cfn/${FileName}" -File $TmpName
  Remove-Item $TmpName
}

Write-Host "Start the cluster by using the '${HttpDestination}/0-all.json' AWS CloudFormation Stack"
