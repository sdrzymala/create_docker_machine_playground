Param 
    (
        [Parameter(Mandatory=$false)][String]$name="mydockermachine",
        [Parameter(Mandatory=$false)][int]$RAMGB=4,
        [Parameter(Mandatory=$false)][int]$vcpu=2,
        [Parameter(Mandatory=$false)][int]$diskGB=40,
        [Parameter(Mandatory=$false)][String]$timezone="UTC",
        [Parameter(Mandatory=$false)][String]$diskPath="E:\VM\",
        [Parameter(Mandatory=$false)][String]$sharedFolderPath="C:\narnia\data\",
        [Parameter(Mandatory=$false)][String]$sharedFolderName="create_docker_machine",
        [Parameter(Mandatory=$false)][String]$configScriptName="configurevm.sh",
        [Parameter(Mandatory=$false)][String]$isoPath="E:\Tools\ubuntu-18.04-desktop-amd64.iso",
        [Parameter(Mandatory=$false)][String]$vBoxManagePath="C:\Program Files\Oracle\VirtualBox\"
)


# Copy file to shared folder
$currentDirectory = (Split-Path -parent $PSCommandPath) 
$currentConfigScriptPath = $currentDirectory + "\" + $configScriptName
Copy-Item $currentConfigScriptPath -Destination $sharedFolderPath -force
Write-Host $currentDirectory
Write-Host $currentConfigScriptPath


# Convert GB to MB
$disksize = $diskGB * 1024
$memory = $RAMGB * 1024


# Set up other parameters 
$mediumPath = $diskPath + $name + ".vdi"
$sharedFolderPathOnGuest = "/media/sf_" + $sharedFolderName + "/" + $configScriptName


Write-Host (get-date).ToString('y/M/d HH:mm:ss:ms') "Specify machine user and pass" -ForegroundColor Green
$user= read-host "enter username "
$passsecure= read-host "enter password " -assecurestring
$sambapasssecure= read-host "enter samba password " -assecurestring


# convert secure pass to string
$pass = [System.Net.NetworkCredential]::new("", $passsecure).Password
$sambapass = [System.Net.NetworkCredential]::new("", $sambapasssecure).Password


Write-Host (get-date).ToString('y/M/d HH:mm:ss:ms') "Begin virtual machine configuration" -ForegroundColor Green
$startTime = $(get-date)


# Step one create VM
Set-Location $vBoxManagePath


# Register VM
.\VBoxManage createvm --name "$name" --register


# modify the vm ram and network
.\VBoxManage modifyvm "$name" --memory $memory --acpi on --boot1 dvd --cpus $vcpu
.\VBoxManage modifyvm "$name" --nic1 natnetwork --nat-network1 NatNetwork
./VBoxManage modifyvm "$name" --nic2 hostonly --hostonlyadapter2 'VirtualBox Host-Only Ethernet Adapter #3'
.\VBoxManage modifyvm "$name" --ostype Ubuntu_64
.\VBoxManage sharedfolder add "$name" --name $sharedFolderName --hostpath $sharedFolderPath --automount


# create storage
.\VBoxManage createhd --filename $mediumPath --size $disksize --format VDI
.\VBoxManage storagectl "$name" --name "IDE Controller" --add ide


# attach storage
.\VBoxManage storagectl "$name" --add sata --controller IntelAHCI --name "SATA Controller"
.\VBoxManage storageattach "$name" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $mediumPath


# unattending install aka user name and computer name
$unattendedConfigLog = .\VBoxManage unattended install "$name" --iso="$isoPath" --user="$user" --password="$pass" --full-user-name="$user" --time-zone="$timezone" --hostname=$name.lab.local --install-additions


Write-Host (get-date).ToString('y/M/d HH:mm:ss') "Finish virtual machine configuration" -ForegroundColor Green


# start VM
Write-Host (get-date).ToString('y/M/d HH:mm:ss') "Start machine" -ForegroundColor Green
#.\VBoxManage startvm "$name" --type headless
$startVMLog = .\VBoxManage startvm "$name"


Write-Host (get-date).ToString('y/M/d HH:mm:ss') "Check installation status" -ForegroundColor Green
# check if install is complete
$currentstatus = ""
while($currentstatus -notlike "*Value: *")
{
    Write-Host (get-date).ToString('y/M/d HH:mm:ss') "Still installing" -ForegroundColor Green
    Start-Sleep 120
    $currentstatus = .\VBoxManage guestproperty get $name "/VirtualBox/GuestInfo/OS/LoggedInUsers"
}


# wait additional minute so boot is complete
Write-Host (get-date).ToString('y/M/d HH:mm:ss') "Wait additional 60 seconds to finish reboot" -ForegroundColor Green
Start-Sleep 60


# reset / reboot
Write-Host (get-date).ToString('y/M/d HH:mm:ss') "Reboot" -ForegroundColor Green
.\VBoxManage controlvm $name reset


# wait till machine will boot again
$currentstatus = ""
while($currentstatus -notlike "*Value: *")
{
    Write-Host (get-date).ToString('y/M/d HH:mm:ss') "Still rebooting" -ForegroundColor Green
    Start-Sleep 60
    $currentstatus = .\VBoxManage guestproperty get $name "/VirtualBox/GuestInfo/OS/LoggedInUsers"
}


# wait additional minute so boot is complete
Write-Host (get-date).ToString('y/M/d HH:mm:ss') "Wait additional 60 seconds to finish reboot" -ForegroundColor Green
Start-Sleep 60


Write-Host (get-date).ToString('y/M/d HH:mm:ss') "Install complete" -ForegroundColor Green


Write-Host (get-date).ToString('y/M/d HH:mm:ss') "Run post installation script" -ForegroundColor Green
#.\VBoxManage guestcontrol $name run --verbose --username root --password $pass --wait-stdout --wait-stderr --quiet --exe "/bin/bash" -- ls/arg0 $sharedFolderPathOnGuest $user $sambapass | Tee-Object -Variable ConfigScriptOutput
$ConfigScriptOutput = .\VBoxManage guestcontrol $name run --verbose --username root --password $pass --wait-stdout --wait-stderr --quiet --exe "/bin/bash" -- ls/arg0 $sharedFolderPathOnGuest $user $sambapass
if ([string]($ConfigScriptOutput) -match 'Finish config script$')
{
    Write-Host "Config script fully completed" -ForegroundColor Green
}
else 
{
    throw "System installed correctly, but there was an error while executing the config script. 
            Check the logs carefully
            Terminating"
}
Write-Host (get-date).ToString('y/M/d HH:mm:ss') "Run post installation script completed" -ForegroundColor Green

# wait additional minute so boot is complete
Write-Host (get-date).ToString('y/M/d HH:mm:ss') "Wait additional 60 seconds to finish reboot" -ForegroundColor Green
Start-Sleep 60

# reset / reboot
Write-Host (get-date).ToString('y/M/d HH:mm:ss') "Reboot" -ForegroundColor Green
.\VBoxManage controlvm $name reset

# wait till machine will boot again
$currentstatus = ""
while($currentstatus -notlike "*Value: *")
{
    Write-Host (get-date).ToString('y/M/d HH:mm:ss') "Still rebooting" -ForegroundColor Green
    Start-Sleep 60
    $currentstatus = .\VBoxManage guestproperty get $name "/VirtualBox/GuestInfo/OS/LoggedInUsers"
}

# wait additional minute so boot is complete
Write-Host (get-date).ToString('y/M/d HH:mm:ss') "Wait additional 60 seconds to finish reboot" -ForegroundColor Green
Start-Sleep 60


Write-Host (get-date).ToString('y/M/d HH:mm:ss') "Installation and configuration done" -ForegroundColor Green


# set location back to the script directory
Set-Location (Split-Path (Split-Path $currentConfigScriptPath -Parent) -Parent)


# Report finish and execution time 
$elapsedTime = $(get-date) - $StartTime
Write-Host (get-date).ToString('y/M/d HH:mm:ss') "Execution time: " $elapsedTime -ForegroundColor Green

