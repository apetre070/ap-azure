function Get-APAzureVMInit {
    param([string]$Location
    )
    
    $locations = Get-AzureRmLocation
    
    $returnData = New-Object System.Collections.ArrayList
    $publisherCount = 1

    if ($Location -in $locations.displayName)
    {
        $Publishers = Get-AzureRmVMImagePublisher -Location $Location
        foreach ($publisher in $publishers)
        {
            $Offers = Get-AzureRmVMImageOffer -Location $Location -PublisherName $publisher.publishername

            foreach ($offer in $Offers)
            {
                $skus = Get-AzureRmVMImageSku -Location $Location -PublisherName $publisher.publishername -Offer $offer.offer
                
                $addObj = New-Object System.Management.Automation.PSObject

                $addObj | Add-Member NoteProperty -Name "PublisherName" -Value $publisher.publisherName
                $addObj | Add-Member NoteProperty -Name "OfferName" -Value $offer.offer
                $addObj | Add-Member NoteProperty -Name "Skus" -Value $skus.skus

                $returnData.add($addObj) | Out-Null

                if($skus){remove-variable skus}
                if($offer){Remove-Variable offer}
            }
            
            Write-Progress -Activity "Compiling VM Publisher, Offer, and Sku details" -Status "Publisher $publisherCount of $($publishers.count)" -PercentComplete (($publisherCount/$publishers.count)*100)
            
            $publisherCount++

            if($publisher){Remove-Variable publisher}
        }

        return $returnData
    }
    else {
        Write-Error "Invalid location"
    }
    
}