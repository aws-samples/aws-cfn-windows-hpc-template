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
# This PowerShell script joins the current computer to a domain, using the specified user
#
# It must be called with the name of the text file storing the user's information in the format (one value per line, no padding):
#   DOMAIN\HPCUser (Domain NetBIOS Name\User SAM Account Name)
#   Password
#   domain.local   (Domain DNS name)
#
[CmdletBinding()]
param(
  [Parameter(Mandatory=$True,Position=1)]
  [string]$DomainFile
)

if (-not (Test-Path $DomainFile))
{
    Throw "File '$DomainFile' does not exist, exiting script"
}

$content = Get-Content $DomainFile
$UserPS = $content[0]
$PassPS = ConvertTo-SecureString $content[1] -AsPlainText -Force
$DomainCred = New-Object System.Management.Automation.PSCredential $UserPS, $PassPS
Add-Computer -DomainName $content[2] -Credential $DomainCred -Restart
