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

# Most Popular Tabs (Apps)
#######################################################################################################

$groups = Invoke-GraphAPICall -URI "https://graph.microsoft.com/v1.0/groups" -Method "GET"

$allTabs = @()

# Loop through groups
$groups.value | ForEach-Object {

    # Check if it's a Team
    if ($_.ResourceProvisioningOptions -contains "Team") {

        $TeamId = $_.id
        $TeamDisplayName = $_.DisplayName

        Write-Host "Checking $TeamDisplayName"

        # Query Channels
        $channels = Invoke-GraphAPICall -URI "https://graph.microsoft.com/v1.0/teams/$TeamId/channels" -Method "GET"

        $channels.value | ForEach-Object {

            $ChannelId = $_.id
            $ChannelDisplayName = $_.DisplayName

            Write-Host "    - Checking $ChannelDisplayName"

            # Query Tabs
            $tabs = Invoke-GraphAPICall -URI "https://graph.microsoft.com/v1.0/teams/$TeamId/channels/$ChannelId/tabs?`$expand=teamsApp" -Method "GET"

            $allTabs += $tabs.value

        }

    }

}

$allTabs.teamsApp | Group-Object -Property id -NoElement | Sort-Object -Property Count -Descending | Format-Table -AutoSize

#######################################################################################################