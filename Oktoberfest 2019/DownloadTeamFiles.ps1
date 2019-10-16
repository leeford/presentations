function Invoke-GraphAPICall {

    param (

        [Parameter(mandatory = $true)][uri]$URI,
        [Parameter(mandatory = $false)][string]$method,
        [Parameter(mandatory = $false)][string]$body

    )

    # Is method speficied (if not assume GET)
    if ([string]::IsNullOrEmpty($method)) { $method = 'GET' }

    $Headers = @{"Authorization" = "Bearer $($global:token.access_token)" }

    # Paging
    $currentUri = $URI
    $content = while (-not [string]::IsNullOrEmpty($currentUri)) {

        # API Call
        $apiCall = try {
            
            Invoke-RestMethod -Method $method -Uri $currentUri -ContentType "application/json" -Headers $Headers -Body $body -ResponseHeadersVariable script:responseHeaders

        }
        catch {
            
            $errorMessage = $_.ErrorDetails.Message | ConvertFrom-Json

        }
        
        $currentUri = $null
    
        if ($apiCall) {
    
            # Check if any data is left
            $currentUri = $apiCall.'@odata.nextLink'
    
            $apiCall
    
        }
    
    }

    return $content
    
}

# Download Team Files
#######################################################################################################

$Path = "c:/temp/Oktoberfest"
            
Write-Host " - Backing up Files..."

# List all items in drive
$itemList = Invoke-GraphAPICall -URI "https://graph.microsoft.com/v1.0/groups/$global:TeamId/drive/list/items?`$expand=DriveItem"

# Loop through items
$itemList.value | ForEach-Object {

    $item = Invoke-GraphAPICall -URI "https://graph.microsoft.com/v1.0/groups/$global:TeamId/drive/items/$($_.DriveItem.id)"

    # If item can be downloaded
    if ($item."@microsoft.graph.downloadUrl") {

        # Get path in relation to drive

        $itemPath = $item.parentReference.path -replace "/drive/root:", ""
        $fullFolderPath = "$Path/Files/$itemPath" -replace "//", "/"
        $fullPath = "$Path/Files/$itemPath/$($item.name)" -replace "//", "/"

        # Create folder to maintain structure
        New-Item -ItemType Directory -Force -Path $fullFolderPath | Out-Null

        # Download file
        Write-Host "    - Saving $($item.name)... " -NoNewline
        try {

            Invoke-WebRequest -Uri $item."@microsoft.graph.downloadUrl" -OutFile $fullPath
            Write-Host "SUCCESS" -ForegroundColor Green

        }
        catch {

            Write-Host "FAILED" -ForegroundColor Red

        }
            
    }

}

#######################################################################################################