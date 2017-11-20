function New-APAzureSimpleVM{
    param([string]$ResourceGroupName,
    [string]$VNetName,
    [string]$SubnetName,
    [ValidateSet("W2012R2","Ubuntu","RedHat")] 
    [string]$OS,
    [string]$VMName,
    [string]$VMSize = "Standard_A2",
    [ValidateSet("STANDARD_ZRS","STANDARD_RAGRS","STANDARD_GRS","STANDARD_LRS")]
    [string]$StorageType = "STANDARD_LRS"
    )

    $resourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName 

    $availVmSizes = Get-AzureRmVMSize -Location $resourceGroup.location
    if($VMSize -notin $availVmSizes.Name)
    {
        Write-Error "Specified VM size not found in this region."
    }
    else
    {
        switch ($OS) {

            "W2012R2"{
                $publisherName = "MicrosoftWindowsServer"
                $offer = "WindowsServer"
                $sku = "2012-R2-Datacenter"
            }
            "Ubuntu"{
                $publisherName = "Canonical"
                $offer = "Ubuntu_Core"
                $sku = "16"
            }
            "Ubuntu"{
                $publisherName = "Canonical"
                $offer = "Ubuntu_Core"
                $sku = "16"
            }
            default{
                $publisherName = "MicrosoftWindowsServer"
                $offer = "WindowsServer"
                $sku = "2012-R2-Datacenter"
            }
        }
        $pattern = '[^a-zA-Z]'
        $StorageName = "$($resourcegroup.resourceGroupName -Replace $pattern,'')storage"
        
        #check to see that storage account exists, if not - create. 
        $storageAccountTest = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup.resourceGroupName | ?{$_.storageAccountName -like "$StorageName"}
        if($storageAccountTest.count -eq 0)
        {
            $StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $resourceGroup.resourceGroupName -Name $StorageName -Type $StorageType -Location $resourceGroup.location
        }
        else
        {
            $StorageAccount = $storageAccountTest
        }

        $interfaceName = "$($VMname)Interface"
        $OSDiskName = $VMName + "OSDisk"
        
        $Vnet = Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $resourceGroup.resourceGroupName 

        if ($Vnet){
            $subnet = $vnet.Subnets | Where-Object {$_.name -like "$SubnetName"}
            
            $PIp = New-AzureRmPublicIpAddress -Name $InterfaceName -ResourceGroupName $resourceGroup.resourceGroupName -Location $resourceGroup.location -AllocationMethod Dynamic
            
            $interfaceCheck = Get-AzureRmNetworkInterface -Name $interfaceName -ResourceGroupName $resourceGroup.resourceGroupName
            if ($interfaceCheck.count -eq 0)
            {
                $Interface = New-AzureRmNetworkInterface -Name $InterfaceName -ResourceGroupName $resourceGroup.resourceGroupName -Location $resourceGroup.location -SubnetId $subnet.id -PublicIpAddressId $PIp.Id
            }
            else
            {
                $interface = $interfaceCheck    
            }
            
            $Credential = Get-Credential
            $VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
            $VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
            $VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName $publisherName -Offer $offer -Skus $sku -Version "latest"
            $VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface.Id
            $OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
            $VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption FromImage
            
            $VMCreate = New-AzureRmVM -ResourceGroupName $resourceGroup.resourceGroupName -Location $resourceGroup.location -VM $VirtualMachine

            return $VMCreate
        }
        else 
        {
            Write-Error "VNet not found."
        }
    }
}