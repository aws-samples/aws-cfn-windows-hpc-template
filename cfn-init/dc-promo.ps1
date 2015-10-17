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
# This PowerShell script promotes the current computer as a Domain Controller in a new Domain
#
# It must be called with the name of the text file storing the domain's information in the format (one value per line, no padding):
#   domain.local   (Domain DNS name)
#   DOMAIN         (Domain NetBIOS Name)
#   RestorePasword (Recovery mode password for the domain)
#
[CmdletBinding()]
param(
  [Parameter(Mandatory=$True,Position=1)]
  [string]$ConfigFile
)

if (-not (Test-Path $ConfigFile))
{
    Throw "File '$ConfigFile' does not exist, exiting script"
}

$content = Get-Content $ConfigFile
dcpromo /unattend /ReplicaOrNewDomain:Domain /NewDomain:Forest /NewDomainDNSName:"$($content[0])" /ForestLevel:4 /DomainNetbiosName:"$($content[1])" /DomainLevel:4  /InstallDNS:Yes  /ConfirmGc:Yes  /CreateDNSDelegation:No  /DatabasePath:"C:\Windows\NTDS"  /LogPath:"C:\Windows\NTDS"  /SYSVOLPath:"C:\Windows\SYSVOL" /SafeModeAdminPassword="$($content[2])" /RebootOnCompletion:Yes
