Connect-MgGraph -Scopes "Application.ReadWrite.All", "Directory.ReadWrite.All", "DelegatedPermissionGrant.ReadWrite.All", "AppRoleAssignment.ReadWrite.All" -NoWelcome
$folder = "$PWD/azure-sp-permissions/" # Assign folderpath to $folder
$data = "$folder/azure_service_principals.txt" # Assign filepath to $data
If (-Not(Test-Path -Path $folder)) { # Test if $folder exists
    New-Item $folder -Type Directory # Create $folder if false
}
Get-MgServicePrincipal | Format-Wide Id -Column 1 > $data # Get list of IDs then write to $data
Get-Content $data | ? {$_.trim() -ne "" } | Set-Content $data # Strip empty lines from $data
[System.IO.File]::ReadLines($data) | ForEach-Object { # Read IDs from $data then enter loop
    $sp = Get-MgServicePrincipal -ServicePrincipalID $_ # Assign current service principal to $sp
    $outFile = "$path/$($sp.displayName)_$($sp.Id).txt" # Assign filepath to $outFile
    Write-Output "Service principal: $($sp.displayName)" > $outFile # Write text to $outFile
    Write-Output "Client ID: $($sp.Id)" >> $outFile # Write text to $outFile
    Write-Output "++ Delegated permissions ++" >> $outFile # Write text to $outFile
    Get-MgOauth2PermissionGrant -All| Where-Object { $_.clientId -eq $sp.Id } | ft ConsentType, PrincipalId, ResourceId, Scope >> $outFile # Get delegated permissions for $sp then write table to $outFile
    Write-Output "++ Application permissions ++" >> $outFile # Write text to $outFile
    Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -All | Where-Object { $_.PrincipalType -eq "ServicePrincipal" } | ft PrincipalType, ResourceDisplayName, CreatedDateTime, DeletedDateTime >> $outFile # Get application permissions for $sp then write table to $outFile
    Write-Output "++ Azure AD app role assignments ++" >> $outFile # Write text to $outFile
    Get-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalID $sp.Id -All | Where-Object { $_.PrincipalType -eq "ServicePrincipal" } | ft PrincipalType, PrincipalDisplayName, CreatedDateTime, DeletedDateTime >> $outFile # Get Azure AD app role assignments for $sp then write table to $outFile
}