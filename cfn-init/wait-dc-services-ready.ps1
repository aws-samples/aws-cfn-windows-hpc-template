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
# This PowerShell script waits for the NTDS (NT Domain Services) and DNS services to be Running on a Domain Controller
#

Import-Module ServerManager

$status = (Get-Service -Name NTDS -ErrorAction SilentlyContinue | Select -ExpandProperty Status)
while ($status -ne "Running")
{
  Start-Sleep 10
  $status = (Get-Service -Name NTDS -ErrorAction SilentlyContinue | Select -ExpandProperty Status)
}

$status = (Get-Service -Name dns -ErrorAction SilentlyContinue | Select -ExpandProperty Status)
while ($status -ne "Running")
{
  Start-Sleep 10
  $status = (Get-Service -Name dns -ErrorAction SilentlyContinue | Select -ExpandProperty Status)
}
