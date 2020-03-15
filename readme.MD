# Overview   
This is a simple script that will create a brand new VM with ubuntu with Docker and Samba configured in it. Should allow you to create a playground withing a couple of mimutes.

# Usage
* Azure Virtual Machine   
    Create VM in Azure, configure public static IP and SSH.
   * Create VM   
   `azurevm\createvm.ps1` 
   * Remove VM   
   `azurevm\createvm.ps1 -Remove $true`
* VirtualBox   
    Create VM in local VirtualBOX, configure SSH and Samba
    * Create VM   
    `.\createvm.ps1`

# Known issues   
Samba configuration needs to be updated Not working currently...