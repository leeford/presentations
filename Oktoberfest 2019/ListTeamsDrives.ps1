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

# List Teams Drive Usage
#######################################################################################################

$groups = Invoke-GraphAPICall -URI "https://graph.microsoft.com/v1.0/groups" -Method "GET"

$allDrives = @()

# Loop through groups
$groups.value | ForEach-Object {

    # Check if it's a Team
    if ($_.ResourceProvisioningOptions -contains "Team") {

        $TeamId = $_.id
        $TeamDisplayName = $_.DisplayName

        Write-Host "Checking $TeamDisplayName"

        $driveInfo = Invoke-GraphAPICall -URI "https://graph.microsoft.com/v1.0/groups/$TeamId/drive/"

        if ($driveInfo.quota.used) {

            $drive = @{

                Team_Name = $TeamDisplayName
                Used_MB     = ($driveInfo.quota.used / 1000000)

            }

            $allDrives += New-Object PSObject -Property $drive

        }
    }

}

$allDrives | Sort-Object -Property Used_MB -Descending

#######################################################################################################