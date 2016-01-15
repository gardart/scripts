# vmware-hyperv-migration-script.ps1
#
# Description: This script uses MVMC v3.1 Powershell cmdlets to migrate vm's from VSphere to HyperV
#               This script should be run from a host that can run the vmm console and can connect with hyperv manager.
# Dependencies: MVMC v3.1 Powershell cmdlets and VMM console
# Author: Gardar Thorsteinsson: gardart@gmail.com
# version 1.1

# Added high-availability support

#
#-------------------------- Configuration to Change ---------------------------------------------------#
# Virtual Machine to migrate from vmware to Hyper-V
$vmName="ts-mig-2008"

# source vSphere cluster
$sourceServer= "vcenter"

# Destination Hyper-V host and path to store the vm
$hyperVServer = "hyperv-01"
$tempVolume = "\\hyperv-01\C$\Migration\Hosts" # Or local storage if possible

# SC VMM Server
$VMM = "vmmserver"

# Destination Cluster Storage Volume (CSV)
$CSVVolume = "Volume5"

#
#-------------------------- Dont change anything below ------------------------------------------------#
#
#Start-Transcript

# Import Modules
Import-Module "C:\Program Files\Microsoft Virtual Machine Converter\MvmcCmdlet.psd1"
Import-Module "C:\Program Files\Microsoft System Center 2012 R2\Virtual Machine Manager\bin\psModules\virtualmachinemanager\virtualmachinemanager.psd1"

# Connect to vSphere cluster
$sourceCredential = Get-Credential
$sourceConnection = New-MvmcSourceConnection -Server $sourceServer -SourceCredential $sourceCredential -verbose


# select the the virtual machine to convert
$sourceVM = Get-MvmcSourceVirtualMachine -SourceConnection $sourceConnection -verbose | where {$_.Name -match $vmName}

# convert the source virtual machine
$destinationLiteralPath = $tempVolume
$machineDriveCollection = ConvertTo-MvmcVirtualHardDiskOvf -SourceConnection $sourceConnection -DestinationLiteralPath $destinationLiteralPath -GuestVmId $sourceVM.GuestVmId -verbose

# provision a Hyper-V virtual machine from ovf file
$convertedVM = New-MvmcVirtualMachineFromOvf -DestinationLiteralPath $machineDriveCollection.Ovf.DirectoryName -DestinationServer $hyperVServer

#
# Move machine to cluster (make it high available)
#

# Refresh VMM
Get-SCVMHost -ComputerName $hyperVServer | Read-SCVMHost
Read-SCVirtualMachine $vmName
 
# Add the migrated VM to the Hyper-V Cluster (H/A)
$CSVPath = "C:\Clusterstorage\" + $CSVVolume
Move-SCVirtualMachine -VM $vmName -VMHost $hyperVServer -HighlyAvailable $true -Path $CSVPath -UseLAN

#Stop-Transcript  
