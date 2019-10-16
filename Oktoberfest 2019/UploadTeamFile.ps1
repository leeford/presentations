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

# Upload Team Files
#######################################################################################################

$filePath = "C:\temp\ACC-1000 Pilot Program.pptx"
$destinationPath = "General/ACC-1000 Pilot Program.pptx"

try {

    Write-Host "    - Uploading file $filePath to $destinationPath... " -NoNewline

    # Get upload session
    while ([string]::IsNullOrEmpty($uploadSession.uploadUrl)) {

        $uploadSession = Invoke-GraphAPICall "https://graph.microsoft.com/v1.0/groups/$global:TeamId/drive/root:/$($destinationPath):/createUploadSession" -Method "POST"

    }

    # Solution inspired by https://stackoverflow.com/questions/57563160/sharepoint-large-upload-using-ms-graph-api-erroring-on-second-chunk
    $chunkSize = 8192000 # Roughly 8 MB chunks

    # File information
    $fileInfo = New-Object System.IO.FileInfo($filePath)

    # Load file in to memory
    $reader = [System.IO.File]::OpenRead($filePath)

    # Buffer Array
    $buffer = New-Object -TypeName Byte[] -ArgumentList $chunkSize

    # Start at beginning of file
    $position = 0

    # First upload, so data is required
    $moreData = $true
        
    while ($moreData) {

        # Progress
        Write-Progress -Activity "Uploading File:" -Status "$($fileInfo.Name)" -CurrentOperation "$position/$($fileInfo.Length) bytes" -PercentComplete (($position / $fileInfo.Length) * 100)

        # Read chunk of data using buffer as an offset
        $bytesRead = $reader.Read($buffer, 0, $buffer.Length)
        $output = $buffer

        # If chunk is smaller than buffer length - no more data is needed
        if ($bytesRead -ne $buffer.Length) {

            $moreData = $false

            # Shrink the output array to the number of bytes
            $output = New-Object -TypeName Byte[] -ArgumentList $bytesRead
            [Array]::Copy($buffer, $output, $bytesRead)

        }

        # Upload chunk
        $Headers = @{

            #"Content-Length" = $output.Length # Not required in PS Core - it is automatically added to Headers!
            "Content-Range" = "bytes $position-$($position + $output.Length - 1)/$($fileInfo.Length)"

        }

        Invoke-WebRequest -Uri $uploadSession.uploadUrl -Method "PUT" -Headers $Headers -Body $output -SkipHeaderValidation | Out-Null

        # Set new position
        $position = $position + $output.Length

    }

    $reader.Close()

    Write-Host "SUCCESS" -ForegroundColor Green

}
catch {

    Write-Host "FAILED" -ForegroundColor Red
    $_

}

#######################################################################################################