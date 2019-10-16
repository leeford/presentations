$global:token = $null

# Tenant ID, Client ID
$tenantId = "346e50a9-e410-4af6-b468-bf406fad043e"
$clientId = "85b3dc2c-a2c3-47bd-9293-d2b665f7029d"

$codeBody = @{ 

    resource  = "https://graph.microsoft.com/"
    client_id = $clientId
    scope     = "Group.ReadWrite.All, User.ReadBasic.All Notes.ReadWrite.All"

}

# Get OAuth Code
$codeRequest = Invoke-RestMethod -Method POST -Uri "https://login.microsoftonline.com/$tenantId/oauth2/devicecode" -Body $codeBody

# Print Code to host
Write-Host "`n$($codeRequest.message)"

$tokenBody = @{

    grant_type = "urn:ietf:params:oauth:grant-type:device_code"
    code       = $codeRequest.device_code
    client_id  = $clientId

}

# Get OAuth Token
while ([string]::IsNullOrEmpty($tokenRequest.access_token)) {

    $tokenRequest = try {

        Invoke-RestMethod -Method POST -Uri "https://login.microsoftonline.com/$tenantId/oauth2/token" -Body $tokenBody

    }
    catch {

        $errorMessage = $_.ErrorDetails.Message | ConvertFrom-Json

        # If not waiting for auth, throw error
        if ($errorMessage.error -ne "authorization_pending") {

            Throw

        }

    }

}

$tokenRequest

$global:token = $tokenRequest