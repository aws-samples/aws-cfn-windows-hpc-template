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
# This PowerShell script initializes the D drive of the computer by bringing the volume online and giving write access to the Domain Users of the specified domain
#
# It must be called with the NetBIOS name of the domain
#
[CmdletBinding()]
param(
  [Parameter(Mandatory=$True,Position=1)]
  [string]$DomainNetBIOSName
)

Get-Disk | Where-Object -Property OperationalStatus -EQ -Value "Offline" | Set-Disk -IsOffline:$false 
Get-Disk | Where-Object -Property IsReadOnly -EQ -Value $true | Set-Disk -IsReadOnly:$false

$Acl = Get-Acl "D:"
$Ar = New-Object  system.security.accesscontrol.filesystemaccessrule("$DomainNetBIOSName\Domain Users", ([System.Security.AccessControl.FileSystemRights]::Write -bor [System.Security.AccessControl.FileSystemRights]::Modify -bor [System.Security.AccessControl.FileSystemRights]::Traverse -bor [System.Security.AccessControl.FileSystemRights]::ReadAndExecute -bor [System.Security.AccessControl.FileSystemRights]::ListDirectory), ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit), [System.Security.AccessControl.PropagationFlags]::None, [System.Security.AccessControl.AccessControlType]::Allow)
$Acl.SetAccessRule($Ar)
Set-Acl "D:" $Acl
