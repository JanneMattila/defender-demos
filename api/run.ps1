# https://learn.microsoft.com/en-us/defender-endpoint/api/exposed-apis-create-app-nativeapp#get-an-access-token

$clientId = "..."
$tenantId = "..."

$resourceId = "https://api.securitycenter.microsoft.com" # "fc780465-2017-40d4-a0c5-307022471b92" # WindowsDefenderATP
$authPayload = "scope=$resourceId/.default&client_id=$clientId"

$authEndpoint = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/devicecode"
$tokenEndpoint = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

$authResponse = Invoke-RestMethod -Uri $authEndpoint -Method Post -Body $authPayload
try {
    # Windows only for now.
    $authResponse.user_code | clip
}
catch {}
Write-Host $authResponse.message

$tokenPayload = "client_id=$clientId&grant_type=urn:ietf:params:oauth:grant-type:device_code&device_code=$($authResponse.device_code)"
while ($true) {
    try {
        Start-Sleep -Seconds $authResponse.interval
        $tokenEndpointResponse = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $tokenPayload
        if ($null -ne $tokenEndpointResponse.access_token) {
            break
        }
    }
    catch {}
}

$accessToken = $tokenEndpointResponse.access_token
$accessToken | clip
$bearerToken = ConvertTo-SecureString -String $accessToken -AsPlainText

$url = "https://api.securitycenter.microsoft.com/api/machines"

$response = Invoke-RestMethod -Method Get -Uri $url -Authentication Bearer -Token $bearerToken
$response.value

$response.value | ForEach-Object {
    Write-Host $_.computerDnsName $_.ipAddresses.ipAddress
}
