$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$dataDir = Join-Path $root "data"
$outFile = Join-Path $dataDir "prices.json"

if (-not (Test-Path $dataDir)) {
    New-Item -ItemType Directory -Path $dataDir | Out-Null
}

function Get-RetailItems {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Filter,
        [int]$MaxPages = 200
    )

    $items = New-Object System.Collections.Generic.List[object]
    $url = "https://prices.azure.com/api/retail/prices?api-version=2023-01-01-preview&`$filter=$([uri]::EscapeDataString($Filter))"
    $next = $url
    $pages = 0

    while ($next -and $pages -lt $MaxPages) {
        $response = Invoke-RestMethod -Uri $next
        foreach ($item in $response.Items) {
            $items.Add($item)
        }
        $next = $response.NextPageLink
        $pages++
    }

    return [pscustomobject]@{
        Url = $url
        Pages = $pages
        Items = $items
    }
}

function Select-PricingFields {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$InputItems
    )

    $selected = New-Object System.Collections.Generic.List[object]
    foreach ($item in $InputItems) {
        if ($item.unitOfMeasure -match "Token|1M|1K|Second|Hour|Transaction|Image|Character") {
            $selected.Add([pscustomobject]@{
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
    return $selected
}

$foundryFilter = "serviceName eq 'Foundry Models' and priceType eq 'Consumption'"
$serviceFilter = "priceType eq 'Consumption' and (contains(productName,'Document Intelligence') or contains(productName,'Vision') or contains(productName,'Content Safety') or contains(productName,'Speech') or contains(productName,'Language') or contains(productName,'Translator') or contains(productName,'Azure AI Search'))"

$foundryResult = Get-RetailItems -Filter $foundryFilter
$serviceResult = Get-RetailItems -Filter $serviceFilter
$items = Select-PricingFields -InputItems $foundryResult.Items
$serviceItems = Select-PricingFields -InputItems $serviceResult.Items

$payload = [pscustomobject]@{
    metadata = [pscustomobject]@{
        generatedAt = (Get-Date).ToUniversalTime().ToString("o")
        source = "Azure Retail Prices API"
        sourceDocumentation = "https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices"
        sourceQuery = $foundryResult.Url
        filter = $foundryFilter
        pages = $foundryResult.Pages
        itemCount = $items.Count
        serviceSourceQuery = $serviceResult.Url
        serviceFilter = $serviceFilter
        servicePages = $serviceResult.Pages
        serviceItemCount = $serviceItems.Count
        notes = "Retail USD public consumption prices for serviceName 'Foundry Models'. Discounts, private agreements, reservations, taxes, and Azure Marketplace subscription constraints are not applied."
    }
    documentation = [pscustomobject]@{
        foundry = "https://learn.microsoft.com/en-us/azure/foundry/what-is-foundry"
        foundryModelsSoldByAzure = "https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure"
        foundryModelsPartners = "https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/models-from-partners"
        azureOpenAiPricing = "https://azure.microsoft.com/en-us/pricing/details/azure-openai/"
        documentIntelligence = "https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/overview?view=doc-intel-4.0.0"
        documentIntelligencePricing = "https://azure.microsoft.com/en-us/pricing/details/document-intelligence/"
        vision = "https://learn.microsoft.com/en-us/azure/ai-services/computer-vision/overview"
        visionPricing = "https://azure.microsoft.com/en-us/pricing/details/computer-vision/"
        contentSafety = "https://learn.microsoft.com/en-us/azure/ai-services/content-safety/overview"
        contentSafetyPricing = "https://azure.microsoft.com/en-us/pricing/details/content-safety/"
        speechPricing = "https://azure.microsoft.com/en-us/pricing/details/cognitive-services/speech-services/"
        languagePricing = "https://azure.microsoft.com/en-us/pricing/details/cognitive-services/language-service/"
        translatorPricing = "https://azure.microsoft.com/en-us/pricing/details/cognitive-services/translator/"
        searchPricing = "https://azure.microsoft.com/en-us/pricing/details/search/"
    }
    items = $items
    serviceItems = $serviceItems
}

$payload | ConvertTo-Json -Depth 8 | Set-Content -Path $outFile -Encoding utf8
Write-Host "Wrote $($items.Count) Foundry model meters and $($serviceItems.Count) AI service meters to $outFile"
