# Calculadora de estimaciones de tokens para Microsoft Foundry

Aplicación estática para estimar costos por proceso usando medidores oficiales de **Foundry Models** y servicios de IA publicados en Azure Retail Prices API.

La experiencia principal incluye estimadores rápidos para Document Intelligence, Azure Vision, Content Safety, Translator, Speech, Language y Azure AI Search. La sección de modelos Foundry queda como modo avanzado para cálculos de entrada, salida, cached input, embeddings y otros medidores tokenizados.

## Fuentes oficiales

- Azure Retail Prices API: https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices
- Azure OpenAI pricing: https://azure.microsoft.com/en-us/pricing/details/azure-openai/
- Microsoft Foundry: https://learn.microsoft.com/en-us/azure/foundry/what-is-foundry
- Foundry Models sold by Azure: https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure
- Foundry Models from partners and community: https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/models-from-partners
- Azure Document Intelligence in Foundry Tools: https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/overview?view=doc-intel-4.0.0
- Azure Vision in Foundry Tools: https://learn.microsoft.com/en-us/azure/ai-services/computer-vision/overview
- Azure AI Content Safety: https://learn.microsoft.com/en-us/azure/ai-services/content-safety/overview

## Actualizar precios

```powershell
.\scripts\refresh-prices.ps1
```

El script regenera `data/prices.json` desde Azure Retail Prices API con `serviceName eq 'Foundry Models' and priceType eq 'Consumption'`.

## Deploy en GitHub Pages

1. Cree un repositorio nuevo o use uno existente.
2. Copie estos archivos al repositorio.
3. Ejecute `.\scripts\refresh-prices.ps1`.
4. Haga push a la rama `main`.
5. En GitHub, configure Pages con **GitHub Actions** como fuente.

El workflow incluido publica el sitio y puede ejecutarse manualmente desde **Actions**.
