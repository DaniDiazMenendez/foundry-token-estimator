$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$dataDir = Join-Path $root "data"
$outFile = Join-Path $dataDir "prices.json"

if (-not (Test-Path $dataDir)) {
    New-Item -ItemType Directory -Path $dataDir | Out-Null
}

$filter = "serviceName eq 'Foundry Models' and priceType eq 'Consumption'"
$baseUrl = "https://prices.azure.com/api/retail/prices?api-version=2023-01-01-preview&`$filter=$([uri]::EscapeDataString($filter))"

$items = New-Object System.Collections.Generic.List[object]
$next = $baseUrl
$pages = 0

while ($next) {
    $response = Invoke-RestMethod -Uri $next
    foreach ($item in $response.Items) {
        if ($item.unitOfMeasure -match "Token|1M|1K|Second|Hour|Transaction|Image|Character") {
            $items.Add([pscustomobject]@{
                currencyCode = $item.currencyCode
                serviceName = $item.serviceName
                productName = $item.productName
                skuName = $item.skuName
                meterName = $item.meterName
                meterId = $item.meterId
                unitOfMeasure = $item.unitOfMeasure
                retailPrice = [double]$item.retailPrice
                unitPrice = [double]$item.unitPrice
                armRegionName = $item.armRegionName
                location = $item.location
                effectiveStartDate = $item.effectiveStartDate
                type = $item.type
                isPrimaryMeterRegion = $item.isPrimaryMeterRegion
            })
        }
    }
    $next = $response.NextPageLink
    $pages++
}

$payload = [pscustomobject]@{
    metadata = [pscustomobject]@{
        generatedAt = (Get-Date).ToUniversalTime().ToString("o")
        source = "Azure Retail Prices API"
        sourceDocumentation = "https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices"
        sourceQuery = $baseUrl
        filter = $filter
        pages = $pages
        itemCount = $items.Count
        notes = "Retail USD public consumption prices for serviceName 'Foundry Models'. Discounts, private agreements, reservations, taxes, and Azure Marketplace subscription constraints are not applied."
    }
    documentation = [pscustomobject]@{
        foundry = "https://learn.microsoft.com/en-us/azure/foundry/what-is-foundry"
        foundryModelsSoldByAzure = "https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure"
        foundryModelsPartners = "https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/models-from-partners"
        azureOpenAiPricing = "https://azure.microsoft.com/en-us/pricing/details/azure-openai/"
    }
    items = $items
}

$payload | ConvertTo-Json -Depth 8 | Set-Content -Path $outFile -Encoding utf8
Write-Host "Wrote $($items.Count) official price meters from $pages API pages to $outFile"
