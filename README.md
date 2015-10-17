# aws-cfn-windows-hpc-template
This sample AWS CloudFormation template will launch a Windows-based HPC cluster running Windows Server 2012 R2 and supporting core infrastructure including Amazon VPC, domain controllers and bastion servers.

This document presents the steps required to deploy and get the platform running.

## Prepare an Amazon EBS Snapshot for installation material

### Create the volume

Launch an Amazon EC2 instance, and in the wizard create a second Amazon EBS volume.

If you already have an instance running, create a new volume and attach it to your instance. Use Windows Server Manager (Local Server / Storage Services) to bring the volume online and format it (this step is done automatically for new instances).

The recommended settings for this volume are to use an Amazon EBS General Purpose SSD volume of 10 GiB in size.

### Get Microsoft HPC Pack 2012 R2 installation

Download the `HPCPack2012R2-Full.zip` file from `http://www.microsoft.com/en-us/download/details.aspx?id=41630`

Save it as `D:\HPCPack2012R2-Full.zip`.

Once the download has finished, extract the content to `D:\HPCPack2012R2-Full`

You can remove the `D:\HPCPack2012R2-Full.zip` file.

### Prepare SQL Server installation

When asking for Microsoft HPC Pack to install in unattended mode, the Microsoft SQL Server installation wizard is not fully unattended, it tries to open a window on the desktop and gets stuck. To overcome this limitation we need to ask it to pre-extract the installation media and run SQL Server setup before installing Microsoft HPC Pack 2012 R2.

Open a command prompt (or a PowerShell prompt), go to `D:\HPCPack2012R2-Full\amd64`

Run the following command `SQLEXPR_x64_ENU.exe /X:D:\SQLInstall`

This will create a folder called SQLInstall on your D drive

### Prepare for update AWS PV drivers (optional)

This step is optional, but you may want to check if you have the latest drivers.

Download the following file: `https://s3.amazonaws.com/ec2-downloads-windows/Drivers/AWSPVDriverSetup.zip` to D:\AWSPVDriverSetup.zip

Extract the content to `D:\AWSPVDriverSetup`

You can remove the `D:\AWSPVDriverSetup.zip` file.

### Prepare for update Intel SRV-IO drivers (optional)

This step is optional, but you may want to check if you have the latest drivers.

Download the following file: `https://downloadcenter.intel.com/download/23073/Network-Adapter-Driver-for-Windows-Server-2012-R2-` to `D:\PROWinx64.exe`

Rename the `D:\PROWinx64.exe` file as `D:\PROWinx64.zip`

Extract the content to `D:\PROWinx64`

You can remove the `D:\PROWinx64.zip` file.

### Make a Snapshot

Recommended: In Windows Server Manager (Local Server / Storage Services), select the disk associated with your Amazon EBS volume, and take it offline. This is recommended to ensure consistency os the data on the disk.

In the Amazon EC2 console, select the instance that you are using, in the *Description* tab, click on `xvdf` in the *Block devices* area, and click on the volume name beside the *EBS ID* value. Click on *Actions* / *Create Snapshot*, enter `HPC Pack 2012 Installation` as a Name and as a Description; click *Create*.

Wait for the snapshot to be created, and you are all set!

## Publish your content

This GitHub reposoroty contains multiple resources (AWS Lambda Functions, PowerShell scripts, configuration files, and AWS CloudFormation templates). To run the platform you will need to publish them to one of your existing Amazon S3 buckets.

Download or clone the content of this repository, and run:

* On Windows: `.\publish.ps1 -Bucket <bucket> -Prefix <prefix>`
* On Unix/Linux/Mac OS: `bash publish.sh <bucket> <prefix>`

Where:

* `<bucket>`: the Amazon S3 bucket that will store the AWS CloudFormation templates
* `<prefix>`: the prefix in this bucket that will be used to store the data

Make sure you have an AWS CLI (https://aws.amazon.com/cli/) configured for Unix environments, and an AWS Tools for Windows PowerShell (http://aws.amazon.com/powershell/) configured for Windows.

The script will give you the URL of the global AWS CloudFormation template to use for creating a full platform.

## Runing the template

In AWS CloudFormation, use the URL provided as an output of the publication script to start a new stack.

Choose a name, then fill te parameters.

*Passwords:* the template ask you for multiple passwords, that will be used in the platform. For security reasons we don't provide you with a default password.

* `BastionAdminPassword`: this password will be used to connect with the local administrator account to the bastion host
* `HPCUserPassword`: this password will be used to connect to the head-node, with the `AWSLAB\HPCUser` account
* `AdministratorPassword`: this password will be the domain administrator password (you should not have to use it)
* `RestoreModePassword`: this password will be the domain controller recovery mode (you should not have to use it)

*Networking:* you will have to enter multiple IP ranges for managing the platform.

* `VPCCIDR`: this is the internal IP range of the Amazon VPC that will be created for your instances.
* `RDPLocation`: this is the IP range that your network has when connecting to the internet, used to grant you connection to the Bastion host.

*Instances:* some details about the instances.

* `SnapshotName`: the name of the snapshot you have just created
* `HeadNodeInstanceType`: the instance type to use for the Head Node
* `ComputeNodeInstanceType`: the instance type to use for the Compute Nodes
* `ClusterPlacementGroup`: the name of an existing placement group for the cluster nodes (no placement group if empty)
* `ComputeNodeInstanceCount`: the number of compute nodes to start initially
* `ComputeNodeInstanceMaxCount`: the maximum number of compute nodes to start

Many more configuration options are available if you look at the details of the sub stacks (look in the cfn directory).

The template will get one single output:

* `Bastion`: the IP Address of the bastion host

## Connecting and using the platform

Use the output `Bastion` from the main template to connect in Remote Desktop Protocol to the bastion host. Use the `.\Administrator` account and the password you specified as the `BastionAdminPassword` parameter to connect.

Once on the bastion host, run `MSTSC.EXE` (Microsoft Remote Desktop Connection) to connect to the machine named `head-node`. As all cluster machines are in a domain, and the bastion host is configured to use the DNS servers of that domain, you will connect to the head node instance with the name `head-node.awslab.local`. Use `AWSLAB\HPCUser` as a user name, and the password you entered as the `HPCUserPassword` parameter to connect.

On the head node, you can interact with the Microsoft HPC Cluster Manager, or use `mpiexec` or PowerShell to start using the cluster..

## What does it do, how does it work, why should I use it?

This platform has been published as a companion to the (CMP306) Dynamic, On-Demand Windows HPC Clusters On AWS session at AWS re:Invent 2015.

This session is available on:

* [YouTube](https://www.youtube.com/watch?v=-LXUj4-cHxI)
* [SlideShare](http://www.slideshare.net/AmazonWebServices/cmp306-dynamic-ondemand-windows-hpc-clusters-on-aws)

Interesting tricks:

* [cfn-init/configure-hpc-network.ps1](cfn-init/configure-hpc-network.ps1) does the configuration for Jumbo Frames and interrupt moderation
* [cfn-init/post-install-hpc-pack-compute.ps1](cfn-init/post-install-hpc-pack-compute.ps1) manages physical core affinity for the compute nodes
* [cfn-init/compute-metrics.ps1](cfn-init/compute-metrics.ps1) queries the Microsoft HPC Pack APIs and publishes Amazon CloudWatch metrics based on the queue depth
