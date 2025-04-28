# Parameter definitions
param (
    [string]$region = "US",  # Default to US
    [string]$api_key = $null,
    [string]$environment = $null, # Prompt if not provided
    [string]$dataType = "EgressIPs",
    [string]$outputFile = $null
)

# Prompt for API Key if not provided
if ([string]::IsNullOrEmpty($api_key)) {
    $api_key = Read-Host "Enter API Key"
    if ([string]::IsNullOrWhiteSpace($api_key)) {
        Write-Host "Please enter a valid API key."
        exit
    }
}

# Prompt for Environment if not provided
if ([string]::IsNullOrEmpty($environment)) {
    $environment = Read-Host "Enter environment (e.g., prod, prod2 to prod7)"
}

# Validate environment format
if ($environment -notmatch "^prod([0-7])?$") {
    Write-Host "Invalid environment. Use 'prod' or 'prod2' through 'prod7'."
    exit
}

# Define the base API URI based on region and environment
if ($region -eq "CN") {
    $uriBase = "https://api.$environment.datapath.prismaaccess.cn"
} else {
    $uriBase = "https://api.$environment.datapath.prismaaccess.com"
}

# Define headers for API requests
$headers = @{
    "header-api-key" = $api_key
}

# Define data payloads
$dataPayloads = @{
    "EgressIPs" = '{"serviceType": "all", "addrType": "all", "location": "all"}'
    "ActiveReservedOnboardedMobileUserLocations" = '{"serviceType": "gp_gateway", "addrType": "all", "location": "deployed"}'
    "ActiveIPOnboardedMobileUserLocations" = '{"serviceType": "gp_gateway", "addrType": "active", "location": "deployed"}'
    "ActiveMobileUserAddresses" = '{"serviceType": "gp_gateway", "addrType": "all", "location": "all"}'
    "RemoteNetworkAddresses" = '{"serviceType": "remote_network", "addrType": "all", "location": "all"}'
    "CleanPipeAddresses" = '{"serviceType": "clean_pipe", "addrType": "all", "location": "all"}'
    "ExplicitProxyAddresses" = '{"serviceType": "swg_proxy", "location": "deployed", "addrType": "auth_cache_service"}'
}

# Function to send API requests
function Send-APIRequest {
    param (
        [string]$uri,
        [string]$method,
        $body = $null,
        $headers
    )
    try {
        $response = Invoke-RestMethod -Uri $uri -Method $method -Body $body -Headers $headers -ContentType "application/json"
        return $response
    } catch {
        Write-Error "Failed to fetch data from $uri. Error: $_"
        exit
    }
}

# Function to display formatted results
function Display-FormattedResult {
    param ($result)
    $outputTable = @()
    foreach ($item in $result) {
        foreach ($detail in $item.address_details) {
            $row = [PSCustomObject]@{
                Zone        = $item.zone
                ServiceType = $detail.serviceType
                Address     = $detail.address
                AddressType = $detail.addressType
            }
            $outputTable += $row
        }
    }
    return $outputTable
}

# Function to display loopback IPs
function Display-LoopbackIps {
    param ($result)
    $outputTable = @()
    foreach ($item in $result) {
        $fwType = $item.result.fwType
        foreach ($addr in $item.result.addrList) {
            $splitAddr = $addr -split ':'
            $row = [PSCustomObject]@{
                Type         = $fwType
                Location     = $splitAddr[0]
                "Loopback IP" = $splitAddr[1]
            }
            $outputTable += $row
        }
    }
    return $outputTable
}

# Function to handle CSV prompt
function Handle-CSVExport {
    param (
        $data
    )
    $createCSV = Read-Host "Do you want to export the results to a CSV file? (Y/N)"
    if ($createCSV -match "^[Yy]$") {
        $csvFileName = Read-Host "Enter the full file name for the CSV (e.g., output.csv)"
        if (![string]::IsNullOrWhiteSpace($csvFileName)) {
            $data | Export-Csv -Path $csvFileName -NoTypeInformation
            Write-Host "Results exported successfully to '$csvFileName'." -ForegroundColor Green
        } else {
            Write-Host "Invalid file name. Skipping export." -ForegroundColor Yellow
        }
    }
}

# Main logic based on $dataType
if ($dataType -eq "loopback_ip") {
    $loopbackResults = @()
    foreach ($fwType in @('gpcs_gp_gw', 'gpcs_gp_portal', 'gpcs_remote_network')) {
        $loopbackUri = "$uriBase/getAddrList/latest?fwType=$fwType&addrType=loopback_ip"
        $result = Send-APIRequest -uri $loopbackUri -method 'GET' -headers $headers
        $loopbackResults += $result
    }

    $displayData = Display-LoopbackIps -result $loopbackResults

    if ($outputFile) {
        $ext = [System.IO.Path]::GetExtension($outputFile).ToLower()
        switch ($ext) {
            ".json" { $loopbackResults | ConvertTo-Json -Depth 10 | Out-File $outputFile }
            ".csv"  { $displayData | Export-Csv -Path $outputFile -NoTypeInformation }
            ".txt"  { $loopbackResults | ForEach-Object { $_.result.addrList | ForEach-Object { ($_ -split ':')[1] } } | Out-File $outputFile }
            default { Write-Error "Unsupported file extension: $ext" }
        }
    } else {
        $displayData | Format-Table -AutoSize
        Handle-CSVExport -data $displayData
    }
} else {
    $apiUri = "$uriBase/getPrismaAccessIP/v2"
    if ($dataPayloads.ContainsKey($dataType)) {
        $body = $dataPayloads[$dataType]
        $result = Send-APIRequest -uri $apiUri -method 'POST' -body $body -headers $headers
        $resultData = $result.result

        $displayData = Display-FormattedResult -result $resultData

        if ($outputFile) {
            $ext = [System.IO.Path]::GetExtension($outputFile).ToLower()
            switch ($ext) {
                ".json" { $resultData | ConvertTo-Json -Depth 10 | Out-File $outputFile }
                ".csv"  { $displayData | Export-Csv -Path $outputFile -NoTypeInformation }
                ".txt"  { $resultData | ForEach-Object { $_.address_details | ForEach-Object { $_.address } } | Out-File $outputFile }
                default { Write-Error "Unsupported file extension: $ext" }
            }
        } else {
            $displayData | Format-Table -AutoSize
            Handle-CSVExport -data $displayData
        }
    } else {
        Write-Error "Unsupported data type: $dataType"
    }
}
