# Fetch Prisma Access service IP data and export as CSV, JSON, or TXT.
param (
    [ValidateSet("Worldwide", "China", "US", "CN", "Global")]
    [string]$region = $null,

    [string]$api_key = $null,

    [ValidateSet("prod", "prod2", "prod3", "prod4", "prod5", "prod6", "prod7")]
    [string]$environment = $null,

    [ValidateSet(
        "EgressIPs",
        "ActiveReservedOnboardedMobileUserLocations",
        "ActiveIPOnboardedMobileUserLocations",
        "ActiveMobileUserAddresses",
        "RemoteNetworkAddresses",
        "CleanPipeAddresses",
        "ExplicitProxyAddresses",
        "loopback_ip"
    )]
    [string]$dataType = $null,

    [string]$outputFile = $null
)

$ErrorActionPreference = "Stop"

$validEnvironments = @("prod", "prod2", "prod3", "prod4", "prod5", "prod6", "prod7")
$validDataTypes = @(
    "EgressIPs",
    "ActiveReservedOnboardedMobileUserLocations",
    "ActiveIPOnboardedMobileUserLocations",
    "ActiveMobileUserAddresses",
    "RemoteNetworkAddresses",
    "CleanPipeAddresses",
    "ExplicitProxyAddresses",
    "loopback_ip"
)

$dataPayloads = @{
    "EgressIPs" = '{"serviceType":"all","addrType":"all","location":"all"}'
    "ActiveReservedOnboardedMobileUserLocations" = '{"serviceType":"gp_gateway","addrType":"all","location":"deployed"}'
    "ActiveIPOnboardedMobileUserLocations" = '{"serviceType":"gp_gateway","addrType":"active","location":"deployed"}'
    "ActiveMobileUserAddresses" = '{"serviceType":"gp_gateway","addrType":"all","location":"all"}'
    "RemoteNetworkAddresses" = '{"serviceType":"remote_network","addrType":"all","location":"all"}'
    "CleanPipeAddresses" = '{"serviceType":"clean_pipe","addrType":"all","location":"all"}'
    "ExplicitProxyAddresses" = '{"serviceType":"swg_proxy","location":"deployed","addrType":"auth_cache_service"}'
}

function Read-RequiredValue {
    param ([string]$Prompt, [string]$DefaultValue = $null)

    if ([string]::IsNullOrWhiteSpace($DefaultValue)) {
        return Read-Host $Prompt
    }

    $value = Read-Host "$Prompt [$DefaultValue]"
    if ([string]::IsNullOrWhiteSpace($value)) { return $DefaultValue }
    return $value
}

function Normalize-Region {
    param ([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        $Value = Read-RequiredValue -Prompt "Enter region: Worldwide or China" -DefaultValue "Worldwide"
    }

    switch -Regex ($Value.Trim()) {
        "^(Worldwide|Global|US)$" { return "Worldwide" }
        "^(China|CN)$" { return "China" }
        default {
            Write-Error "Invalid region. Use 'Worldwide' or 'China'."
            exit 1
        }
    }
}

function Select-DataType {
    param ([string]$Value)

    if (![string]::IsNullOrWhiteSpace($Value)) { return $Value }

    Write-Host "Available datasets:"
    for ($i = 0; $i -lt $validDataTypes.Count; $i++) {
        Write-Host ("  {0}. {1}" -f ($i + 1), $validDataTypes[$i])
    }

    $selection = Read-RequiredValue -Prompt "Enter dataset/dataType" -DefaultValue "EgressIPs"

    if ($selection -match "^\d+$") {
        $index = [int]$selection - 1
        if ($index -ge 0 -and $index -lt $validDataTypes.Count) { return $validDataTypes[$index] }
    }

    return $selection
}

function Send-ApiRequest {
    param (
        [string]$Uri,
        [ValidateSet("GET", "POST")]
        [string]$Method,
        [hashtable]$Headers,
        [string]$Body = $null
    )

    try {
        if ($Method -eq "GET") {
            return Invoke-RestMethod -Uri $Uri -Method Get -Headers $Headers
        }
        return Invoke-RestMethod -Uri $Uri -Method Post -Body $Body -Headers $Headers -ContentType "application/json"
    } catch {
        Write-Error "Failed to fetch data from $Uri. Error: $_"
        exit 1
    }
}

function Format-AddressResults {
    param ($Result)

    $outputTable = @()
    foreach ($item in $Result) {
        foreach ($detail in $item.address_details) {
            $outputTable += [PSCustomObject]@{
                Zone        = $item.zone
                ServiceType = $detail.serviceType
                Address     = $detail.address
                AddressType = $detail.addressType
            }
        }
    }
    return $outputTable
}

function Format-LoopbackResults {
    param ($Result)

    $outputTable = @()
    foreach ($item in $Result) {
        $fwType = $item.result.fwType
        foreach ($addr in $item.result.addrList) {
            $splitAddr = $addr -split ":", 2
            $outputTable += [PSCustomObject]@{
                Type          = $fwType
                Location      = $splitAddr[0]
                "Loopback IP" = $splitAddr[1]
            }
        }
    }
    return $outputTable
}

function Export-Results {
    param ($RawData, $DisplayData, [string]$FilePath, [string]$SelectedDataType)

    $ext = [System.IO.Path]::GetExtension($FilePath).ToLowerInvariant()
    switch ($ext) {
        ".json" {
            $RawData | ConvertTo-Json -Depth 20 | Out-File -FilePath $FilePath -Encoding utf8
            Write-Host "Raw JSON data saved to '$FilePath'." -ForegroundColor Green
        }
        ".csv" {
            $DisplayData | Export-Csv -Path $FilePath -NoTypeInformation
            Write-Host "CSV data saved to '$FilePath'." -ForegroundColor Green
        }
        ".txt" {
            if ($SelectedDataType -eq "loopback_ip") {
                $RawData | ForEach-Object { $_.result.addrList | ForEach-Object { ($_ -split ":", 2)[1] } } | Out-File -FilePath $FilePath -Encoding utf8
            } else {
                $RawData | ForEach-Object { $_.address_details | ForEach-Object { $_.address } } | Out-File -FilePath $FilePath -Encoding utf8
            }
            Write-Host "IP addresses saved to '$FilePath'." -ForegroundColor Green
        }
        default {
            Write-Error "Unsupported file extension: $ext. Use .csv, .json, or .txt."
            exit 1
        }
    }
}

if ([string]::IsNullOrWhiteSpace($api_key)) { $api_key = Read-Host "Enter API Key" }
if ([string]::IsNullOrWhiteSpace($api_key)) {
    Write-Error "Please enter a valid API key."
    exit 1
}

$region = Normalize-Region -Value $region

if ([string]::IsNullOrWhiteSpace($environment)) {
    $environment = Read-RequiredValue -Prompt "Enter environment" -DefaultValue "prod"
}
if ($validEnvironments -notcontains $environment) {
    Write-Error "Invalid environment. Use one of: $($validEnvironments -join ', ')."
    exit 1
}

$dataType = Select-DataType -Value $dataType
if ($validDataTypes -notcontains $dataType) {
    Write-Error "Unsupported data type: $dataType. Use one of: $($validDataTypes -join ', ')."
    exit 1
}

$domainSuffix = if ($region -eq "China") { "cn" } else { "com" }
$uriBase = "https://api.$environment.datapath.prismaaccess.$domainSuffix"
$headers = @{ "header-api-key" = $api_key }

$rawData = $null
$displayData = @()

if ($dataType -eq "loopback_ip") {
    $loopbackResults = @()
    foreach ($fwType in @("gpcs_gp_gw", "gpcs_gp_portal", "gpcs_remote_network")) {
        $loopbackUri = "$uriBase/getAddrList/latest?fwType=$fwType&addrType=loopback_ip"
        Write-Host "Fetching loopback data for $fwType..."
        $loopbackResults += Send-ApiRequest -Uri $loopbackUri -Method "GET" -Headers $headers
    }
    $rawData = $loopbackResults
    $displayData = Format-LoopbackResults -Result $loopbackResults
} else {
    $apiUri = "$uriBase/getPrismaAccessIP/v2"
    Write-Host "Fetching data for $dataType from $uriBase..."
    $response = Send-ApiRequest -Uri $apiUri -Method "POST" -Headers $headers -Body $dataPayloads[$dataType]
    $rawData = $response.result
    $displayData = Format-AddressResults -Result $rawData
}

if (!$displayData -or $displayData.Count -eq 0) {
    Write-Error "No data returned or processed."
    exit 1
}

if ($outputFile) {
    Export-Results -RawData $rawData -DisplayData $displayData -FilePath $outputFile -SelectedDataType $dataType
} else {
    $displayData | Format-Table -AutoSize
    $createCsv = Read-Host "Do you want to export the results to a CSV file? (Y/N)"
    if ($createCsv -match "^[Yy]$") {
        $csvFileName = Read-Host "Enter the full file name for the CSV (e.g., output.csv)"
        if (![string]::IsNullOrWhiteSpace($csvFileName)) {
            $displayData | Export-Csv -Path $csvFileName -NoTypeInformation
            Write-Host "Results exported successfully to '$csvFileName'." -ForegroundColor Green
        } else {
            Write-Host "Invalid file name. Skipping export." -ForegroundColor Yellow
        }
    }
}
