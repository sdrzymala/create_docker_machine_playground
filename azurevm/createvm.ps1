param (
    [switch]$Remove = $false
)

$ResourceGroupName = "rs-sd-ipython-sandbox"
$VMName = "sd-vm-ipython"
$Location = "North Europe"
$VMImage = "UbuntuLTS"
$VMSize = "Standard_B2s"
$PortsToOpen = 22,80,3389,8888


Write-Output "Begin"


Write-Output "Login to Azure"
$currentAccount = Connect-AzAccount
Write-Output "  * Logged as $($currentAccount.Context.Account)"


If ($Remove -eq $true)
{

    Write-Output "Removing resource group"
    Remove-AzResourceGroup -Name $ResourceGroupName

}
elseif ($Remove -eq $false)
{


    Write-Output "Creating resource group"
    New-AzResourceGroup `
        -Name $ResourceGroupName `
        -Location $Location


    Write-Output "Create virtual machine"
    New-AzVm `
        -ResourceGroupName $ResourceGroupName `
        -Name $VMName `
        -Location $Location `
        -Size $VMSize `
        -Image $VMImage `
        -VirtualNetworkName "myVnet" `
        -SubnetName "mySubnet" `
        -SecurityGroupName "myNetworkSecurityGroup" `
        -PublicIpAddressName "myPublicIpAddress" `
        -AllocationMethod "Static" `
        -OpenPorts $PortsToOpen


    Write-Output "Configure VM using script"
    Invoke-AzVMRunCommand `
        -ResourceGroupName $ResourceGroupName `
        -Name $VMName `
        -CommandId 'RunShellScript' `
        -ScriptPath 'configurevm.sh'

    
    Write-Output "Obtaining IP address"
    $IPAddress = Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Name "myPublicIpAddress"
    Write-Output "  * IP address: $($IPAddress.IpAddress)" 


}


Write-Output "End"