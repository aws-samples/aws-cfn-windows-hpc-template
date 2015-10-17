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
# This PowerShell script adds the specified domain user as an administrator to this computer
#
# It must be called with the name of the user in the format DOMAIN/HPCUser (note the forard slash '/')
#
[CmdletBinding()]
param(
  [Parameter(Mandatory=$True,Position=1)]
  [string]$LogonName
)

$de = [ADSI]"WinNT://$env:ComputerName/Administrators,group"
$de.psbase.Invoke("Add",([ADSI]"WinNT://$LogonName").path)
