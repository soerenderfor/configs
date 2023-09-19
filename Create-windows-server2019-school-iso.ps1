#!/usr/bin/env pwsh
<#PSScriptInfo

.VERSION 1.0

.GUID 871f8fa6-d46c-4b91-936a-d1d3692aebd2

.AUTHOR S.Kahr

.COMPANYNAME

.LICENSEURI https://github.com/soerenderfor?tab=repositories/LICENSE

.PROJECTURI GitHub: https://github.com/soerenderfor?tab=repositories

.RELEASENOTES

#>

<#

.DESCRIPTION
The purpose of this script is to build a customized Windows unattended istallation ISO.
The installation will inject VMware paravirtual SCSI driver and VMware VMXNET3 network driver.
VMware paravirtual SCSI drivers are included in the VMware Guest Tool ISO.
VMware VMXNET3 network drivers downloads from own personal github.
Remove the prompt "Press any key to boot from CD/DVD" message, allowing fully automate install.

#>

# Scirpt requirements
#Requires -PSEdition Core
#Requires -RunAsAdministrator

### MODIFIY THESE VARIABLES AS NEEDED ###

$SourceIsoPath = 'C:\Temp\img\windows_server2019.iso'
$AutoUnattendXmlPath = 'C:\Temp\img\UNATTENDS\autounattend.xml'
$VMwareToolsUrl = 'https://packages.vmware.com/tools/esx/latest/windows/VMware-tools-windows-12.2.5-21855600.iso'
$VmxnetUrl = "https://github.com/soerenderfor/configs/raw/main/vmxnet3.inf"
$LCU = "http://download.windowsupdate.com/d/msdownload/update/software/secu/2023/09/windows10.0-kb5030214-x64_a3cdc7fa59462aa30cbead2831d25bfa79155be6.msu"
$SSU = "http://download.windowsupdate.com/d/msdownload/update/software/secu/2021/08/windows10.0-kb5005112-x64_81d09dc6978520e1a6d44b3b15567667f83eba2c.msu"

#########################################

New-Item -ItemType Directory -Path C:\Custom_ISO
New-Item -ItemType Directory -Path C:\Custom_ISO\Final
New-Item -ItemType Directory -Path C:\Custom_ISO\UnattendXML

# Clean DISM mount point if any. Linked to the PVSCSI drivers injection
Clear-WindowsCorruptMountPoint
Dismount-WindowsImage -path 'C:\Custom_ISO\Temp\MountDISM' -discard

# Delete Temp folder if it exists from previous run
Remove-Item -Recurse -Force 'C:\Custom_ISO\Temp'

New-Item -ItemType Directory -Path C:\Custom_ISO\Temp
New-Item -ItemType Directory -Path C:\Custom_ISO\Temp\WorkingFolder
New-Item -ItemType Directory -Path C:\Custom_ISO\Temp\VMwareTools
New-Item -ItemType Directory -Path C:\Custom_ISO\Temp\SSU
New-Item -ItemType Directory -Path C:\Custom_ISO\Temp\LCU
New-Item -ItemType Directory -Path C:\Custom_ISO\Temp\Drivers
New-Item -ItemType Directory -Path C:\Custom_ISO\Temp\MountDISM

# Prepare path for the Windows ISO destination file
$SourceIsoName = $SourceIsoPath.split("\")[-1]
$DestinationIsoPath = 'C:\Custom_ISO\Final\' +  ($SourceIsoName -replace ".iso","") + '_custom.iso'

# Download VMware Tools ISO from (https://packages.vmware.com)
$VMwareToolsIsoName = $VMwareToolsUrl.split("/")[-1]
$VMwareToolsIsoPath =  "C:\Custom_ISO\Temp\VMwareTools\" + $VMwareToolsIsoName 
(New-Object System.Net.WebClient).DownloadFile($VMwareToolsUrl, $VMwareToolsIsoPath)

# Download SSU Update from (http://www.catalog.update.microsoft.com)
$SSUName = $SSU.split("/")[-1]
$SSUPath =  "C:\Custom_ISO\Temp\SSU\" + $SSUName 
(New-Object System.Net.WebClient).DownloadFile($SSU, $SSUPath)

# Download LCU Update from (http://www.catalog.update.microsoft.com)
$LCUName = $LCU.split("/")[-1]
$LCUPath =  "C:\Custom_ISO\Temp\LCU\" + $LCUName 
(New-Object System.Net.WebClient).DownloadFile($LCU, $LCUPath)

# Mount Source Windows ISO and get the assigned drive letter
$MountSourceWindowsIso = Mount-DiskImage -imagepath $SourceIsoPath -passthru
$DriveSourceWindowsIso = ($MountSourceWindowsIso | Get-Volume).driveletter + ':'

# Mount VMware tools ISO and get the assigned drive letter
$MountVMwareToolsIso = Mount-DiskImage -imagepath $VMwareToolsIsoPath -passthru
$DriveVMwareToolsIso = ($MountVMwareToolsIso  | Get-Volume).driveletter + ':'

# Copy content of the Source Windows ISO to the working folder and remove the read-only attribtues and remove bootfix files
Copy-Item $DriveSourceWindowsIso\* -Destination 'C:\Custom_ISO\Temp\WorkingFolder' -force -recurse
Get-ChildItem 'C:\Custom_ISO\Temp\WorkingFolder' -recurse | %{ if (! $_.psiscontainer) { $_.isreadonly = $false } }
if (Test-Path -Path "C:\Custom_ISO\Temp\WorkingFolder\boot\bootfix.bin" -PathType Leaf) {
	Remove-Item -Path "C:\Custom_ISO\Temp\WorkingFolder\boot\bootfix.bin" -Force -Confirm:$false
	}

# Copy VMware Tools setup executable (for 64-bit) to tools folder on the finished ISO
New-Item -ItemType Directory -Path 'C:\Custom_ISO\Temp\WorkingFolder\tools'
Copy-Item "$DriveVMwareToolsIso\setup64.exe" -Destination 'C:\Custom_ISO\Temp\WorkingFolder\tools'

# Inject PVSCSI Drivers (VMware paravirtual SCSI controller) in boot.wim and install.wim
$pvcsciPath = $DriveVMwareToolsIso + '\Program Files\VMware\VMware Tools\Drivers\pvscsi\Win8\amd64\pvscsi.inf'

# Download and inject VMXNET3 Drivers (VMware VMXNET3 network driver) from github (Soeren) in boot.wim and install.wim
$Vmxnet = $VmxnetUrl.split("/")[-1]
$VmxnetPath =  "C:\Custom_ISO\Temp\Drivers\" + $Vmxnet 
(New-Object System.Net.WebClient).DownloadFile($VmxnetUrl, $VmxnetPath)

# Modify all images in boot.wim (ImageIndex 1 = Microsoft WIndows PE (amd64), ImageIndex 2 = Microsoft Windows Setup)
Get-WindowsImage -ImagePath 'C:\Custom_ISO\Temp\WorkingFolder\sources\boot.wim' | ForEach-Object {
	Mount-WindowsImage -ImagePath 'C:\Custom_ISO\Temp\WorkingFolder\sources\boot.wim' -Index ($_.ImageIndex) -Path 'C:\Custom_ISO\Temp\MountDISM'
	Add-WindowsDriver -path 'C:\Custom_ISO\Temp\MountDISM' -driver $pvcsciPath -ForceUnsigned
	Add-WindowsDriver -path 'C:\Custom_ISO\Temp\MountDISM' -driver $VmxnetPath -ForceUnsigned
	Dismount-WindowsImage -path 'C:\Custom_ISO\Temp\MountDISM' -save
}

# Modify all images in install.wim (This operation will take a long time if there are lots of indexed images)
Get-WindowsImage -ImagePath 'C:\Custom_ISO\Temp\WorkingFolder\sources\install.wim' | ForEach-Object {
	Mount-WindowsImage -ImagePath 'C:\Custom_ISO\Temp\WorkingFolder\sources\install.wim' -Index ($_.ImageIndex) -Path 'C:\Custom_ISO\Temp\MountDISM'
	Add-WindowsPackage -PackagePath $SSUPath -Path 'C:\Custom_ISO\Temp\MountDISM'
	Add-WindowsPackage -PackagePath $LCUPath -Path 'C:\Custom_ISO\Temp\MountDISM'
	Add-WindowsCapability -Name NetFx3~~~~ -Source $DriveSourceWindowsIso\sources\sxs\ -Path 'C:\Custom_ISO\Temp\MountDISM'
	Add-WindowsPackage -PackagePath $LCUPath -Path 'C:\Custom_ISO\Temp\MountDISM'
	Add-WindowsDriver -path 'C:\Custom_ISO\Temp\MountDISM' -driver $pvcsciPath -ForceUnsigned
	Add-WindowsDriver -path 'C:\Custom_ISO\Temp\MountDISM' -driver $VmxnetPath -ForceUnsigned
	Dismount-WindowsImage -path 'C:\Custom_ISO\Temp\MountDISM' -save
}

# Add the customized autaunattend.xml answer file
Copy-Item $AutoUnattendXmlPath -Destination 'C:\Custom_ISO\Temp\WorkingFolder\autounattend.xml'

# Use the contents of the working folder to build the custom windows ISO using Oscdimg
$OcsdimgPath = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg'
$oscdimg  = "$OcsdimgPath\oscdimg.exe"
$etfsboot = "$OcsdimgPath\etfsboot.com"
$efisys_noprompt = "$OcsdimgPath\efisys_noprompt.bin"

$data = '2#p0,e,b"{0}"#pEF,e,b"{1}"' -f $etfsboot, $efisys_noprompt
Start-Process $oscdimg -args @("-bootdata:$data",'-u2','-m','-udfver102','-o','C:\Custom_ISO\Temp\WorkingFolder', $DestinationIsoPath) -wait -nonewwindow

# Optional Clean-up tasks
Dismount-DiskImage -ImagePath $SourceIsoPath
Dismount-DiskImage -ImagePath $VMwareToolsIsoPath
Remove-Item -Recurse -Force 'C:\Custom_ISO\Temp'

# Finished! Customized ISO located in C:\Custom_ISO\Final