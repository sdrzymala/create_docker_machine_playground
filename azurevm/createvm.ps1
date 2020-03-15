param (
    [switch]$Remove = $false
)


$ResourceGroupName = "rs-sd-ipython-sandbox"
$VMName = "sd-vm-ipython"
$Location = "North Europe"
$VMImage = "UbuntuLTS"
$VMSize = "Standard_B2s"
$PortsToOpen = 22,80,3389,8888


$SSHPublicKeyFile = ".ssh/id_rsa.pub"
$ConfigScriptName = 'configurevm.sh'
$VMVirtualNetworkName = "myVnet"
$VMPublicIpAddressName = "myPublicIpAddress"
$VMSubnetName = "mySubnet"
$VMSecurityGroupName = "myNetworkSecurityGroup"
$VMIPAllocationMethod = "Static"


Write-Host "Create VM - start" -ForegroundColor Green


Write-Host "Login to Azure - start" -ForegroundColor Green
$currentAccountLog = Connect-AzAccount
Write-Host "Login to Azure - $($currentAccountLog.Context.Account)" -ForegroundColor Green


If ($Remove -eq $true)
{

    Write-Host "Removing resource group - start" -ForegroundColor Green
    Remove-AzResourceGroup -Name $ResourceGroupName
    Write-Host "Removing resource group - end" -ForegroundColor Green

}
elseif ($Remove -eq $false)
{


    Write-Host "Creating resource group - start" -ForegroundColor Green
    $currentRSGroupLog = New-AzResourceGroup `
        -Name $ResourceGroupName `
        -Location $Location
    Write-Host "Creating resource group - $($currentRSGroupLog.ProvisioningState)" -ForegroundColor Green


    Write-Host "Create virtual machine - start" -ForegroundColor Green
    $currentVMLog = New-AzVm `
        -ResourceGroupName $ResourceGroupName `
        -Name $VMName `
        -Location $Location `
        -Size $VMSize `
        -Image $VMImage `
        -VirtualNetworkName $VMVirtualNetworkName `
        -SubnetName $VMSubnetName `
        -SecurityGroupName $VMSecurityGroupName `
        -PublicIpAddressName $VMPublicIpAddressName `
        -AllocationMethod $VMIPAllocationMethod `
        -OpenPorts $PortsToOpen
    Write-Host "Create virtual machine - $($currentVMLog.ProvisioningState)" -ForegroundColor Green


    Write-Host "Get newly created virtual machine - start" -ForegroundColor Green
    $currentVirtualMachine = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
    Write-Host "Get newly created virtual machine - $($currentVirtualMachine.ProvisioningState)" -ForegroundColor Green


    Write-Host "Configure VM using script - start" -ForegroundColor Green
    $configurevmpath = Join-Path $PSScriptRoot $ConfigScriptName
    $currentConfigLog = Invoke-AzVMRunCommand `
        -VM $currentVirtualMachine `
        -CommandId 'RunShellScript' `
        -ScriptPath $configurevmpath
    Write-Host "Configure VM using script - $($currentConfigLog.Status)" -ForegroundColor Green


    Write-Host "Configure SSH key - start" -ForegroundColor Green
    $sshKeyFilePath = Join-Path $env:USERPROFILE $SSHPublicKeyFile
    $sshPublicKey = Get-Content $sshKeyFilePath
    $currentAddSSHKeyLog = Add-AzVMSshPublicKey `
        -VM $currentVirtualMachine `
        -KeyData $sshPublicKey `
        -Path "/home/azureuser/.ssh/authorized_keys"
    Write-Host "Configure SSH key - $($currentAddSSHKeyLog.ProvisioningState)" -ForegroundColor Green

    
    Write-Host "Obtaining IP address - start" -ForegroundColor Green
    $IPAddress = Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Name $VMPublicIpAddressName
    Write-Host "Obtaining IP address - $($IPAddress.IpAddress)" -ForegroundColor Green


}


Write-Host "Create VM - end" -ForegroundColor Green