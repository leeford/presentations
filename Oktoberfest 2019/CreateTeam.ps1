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

# Create Team 
#######################################################################################################

$body = @{

    "template@odata.bind" = "https://graph.microsoft.com/beta/teamsTemplates('standard')"
    displayName           = "Oktoberfest"
    description           = "A Team created specifically for Oktoberfest"

} | ConvertTo-Json

Invoke-GraphAPICall -URI "https://graph.microsoft.com/beta/teams" -Method "POST" -Body $body

# Get created Team ID
$matches = $null
"$($script:responseHeaders.Location)" -match "\/teams\('([a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12})'\)\/operations\('([a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12})'\)" | Out-Null

# If new Team ID exists
if ($matches[1]) {
        
    $global:TeamId = $matches[1]

    Write-Host "Team created with ID: $($global:TeamId)"

}

#######################################################################################################