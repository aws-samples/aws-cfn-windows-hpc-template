$ComputeNodes = Get-HpcNode -HealthState OK -GroupName ComputeNodes
Write-Host "Waiting for scaling"
While ($ComputeNodes.Count -ne 2)
{
    Start-Sleep -Seconds 15
    $ComputeNodes = Get-HpcNode -HealthState OK -GroupName ComputeNodes
}
Write-Host "Scaling Complete" 
