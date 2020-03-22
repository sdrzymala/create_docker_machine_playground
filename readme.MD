# Overview   
This is a simple script that will create a brand new VM with ubuntu with Docker and Samba configured in it. Should allow you to create a playground withing a couple of mimutes.

# Usage
* Azure Virtual Machine   
    Create VM in Azure, configure public static IP and SSH.
   * Prerequsite   
   `Install-Module -Name Az -AllowClobber`
   * Create VM   
   `.\azurevm\createvm.ps1`   
   `.\azurevm\createvm.ps1 -ResourceGroupName "rs-sd-ipython-sandbox"` 
   ![Azure create vm](misc/azure-crete-vm-printscreen1.png)
   * Remove VM   
   `.\azurevm\createvm.ps1 -Remove $true`
   `.\azurevm\createvm.ps1 -ResourceGroupName "rs-sd-ipython-sandbox" -Remove $true`
   ![Azure remove vm](misc/azure-crete-vm-printscreen1.png)
* VirtualBox   
    Create VM in local VirtualBOX, configure SSH and Samba
    * Create VM   
    `.\virtualbox\createvm.ps1`

# Known issues   
* Azure   
   * Verify SSH key
* VirtualBOX   
   * Samba configuration needs to be updated. Not working currently atm. Permission issue