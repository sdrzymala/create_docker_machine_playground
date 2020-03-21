param (
    [Parameter(Mandatory=$false)][switch]$Remove=$false,

    [Parameter(Mandatory=$false)][String]$ResourceGroupName = "rs-sd-ipython-sandbox",
    [Parameter(Mandatory=$false)][String]$VMName = "sd-vm-ipython",
    [Parameter(Mandatory=$false)][String]$Location = "North Europe",
    [Parameter(Mandatory=$false)][String]$VMImage = "UbuntuLTS",
    [Parameter(Mandatory=$false)][String]$VMSize = "Standard_B2s",
    [Parameter(Mandatory=$false)][String]$PortsToOpen = "22,80,3389,8888",

    [Parameter(Mandatory=$false)][String]$SSHPublicKeyFile = ".ssh/id_rsa.pub",
    [Parameter(Mandatory=$false)][String]$ConfigScriptName = 'configurevm.sh',
    [Parameter(Mandatory=$false)][String]$VMVirtualNetworkName = "myVnet",
    [Parameter(Mandatory=$false)][String]$VMPublicIpAddressName = "myPublicIpAddress",
    [Parameter(Mandatory=$false)][String]$VMSubnetName = "mySubnet",
    [Parameter(Mandatory=$false)][String]$VMSecurityGroupName = "myNetworkSecurityGroup",
    [Parameter(Mandatory=$false)][String]$VMIPAllocationMethod = "Static"
)


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
        -OpenPorts $PortsToOpen.Split(",")
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