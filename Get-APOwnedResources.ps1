function Get-APAzureOwnedResources{
    param([string]$UserEmail)

    $resourceGroups = Find-AzureRmResourceGroup -Tag @{'email'="$UserEmail"}

    $resources = Get-AzureRmResource | Where-Object {$_.resourceGroupName -in $resourceGroups.Name}
    
    return $resources
}