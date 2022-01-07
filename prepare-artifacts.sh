cd ./HPCLab/PowerShell/

zip ../../ScriptsForHeadNode2019.zip AddUser.ps1 JoinDomain.ps1 PreInstall.ps1 InstallHead.ps1 PostInstallHead.ps1 SetupProcessHead.ps1 DownloadEnergyPlus.ps1 sql-config.conf 
zip ../../ScriptsForComputeNode2019.zip AddUser.ps1 JoinDomain.ps1 PreInstall.ps1 InstallCompute.ps1 PostInstallCompute.ps1 SetupProcessCompute.ps1 install-packages.ps1 run-simulation-prod.ps1 WaitForScaling.ps1
cd ..
cd HPCJobs 
zip ../../ScriptsForHeadNode2019.zip Parametric-Job-Prod.xml  