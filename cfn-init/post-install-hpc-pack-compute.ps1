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
# This PowerShell script configures Microsoft HPC Pack on a Compute Node 
#
Add-PSSnapIn Microsoft.HPC

# This node will be a compute node
Assign-HpcNodeTemplate -NodeName $env:COMPUTERNAME -Name "ComputeNode Template" -Confirm:$false

# Only use physical cores, and leave the OS assign the processes on the machine
$cores = (Get-WmiObject Win32_Processor | Measure-Object -Property NumberOfCores -Sum | Select-Object -ExpandProperty Sum)
Set-HpcNode -Name $env:COMPUTERNAME -SubscribedCores $cores -Affinity:$false

# Bring the node online
Set-HpcNodeState -Name $env:COMPUTERNAME -State online

# Set processor affinity to only use the physical cores for MPI processes
[long]$affinity = 0
for($i = 0; $i -lt $cores; $i++)
{
   $affinity = $affinity + (([long] 1) -shl ($i * 2))
}
(Get-Process msmpisvc).ProcessorAffinity = $affinity
