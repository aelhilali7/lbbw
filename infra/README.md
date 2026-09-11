# infra — IaC-Ausschnitt (Terraform, azurerm ~> 4.0)

Exemplarische Umsetzung des **AI-Spoke** aus Teil 1. Der Hub (ExpressRoute, Azure Firewall, DNS-Zonen, DNS Private Resolver, Policies) gehört dem Plattformteam der Landing Zone und wird nur referenziert. Ausführliche Doku: [README.md, Teil 2](../README.md#teil-2-infrastructure-as-code-iac).

## Was hier liegt

| Datei | Teil 1 | Inhalt |
|---|---|---|
| `versions.tf` | 1.4 | Provider, Backend, OIDC-Auth (kein Secret) |
| `variables.tf` | – | Hub-Referenzen (IDs, IPs), Adressräume, Modelle |
| `main.tf` | – | Resource Group |
| `network.tf` | 1.1, 1.3 | VNet (DNS = Hub-Resolver), Subnetze, Peering, UDR → Firewall, NSGs |
| `ai-services.tf` | 1.2 | Azure OpenAI ohne öffentlichen Zugriff und ohne Keys, Deployments, Private Endpoint, Logs |
| `search.tf` | 1.2 | AI Search, Private Endpoint, Shared Private Links zu Storage und OpenAI |
| `storage-keyvault.tf` | 1.2 | Storage und Key Vault, je ein Private Endpoint |
| `identity.tf` | 1.4 | Managed Identities (App, Indexer), Rollenzuweisungen |
| `outputs.tf` | – | Endpunkt, private IP, Client-ID |

## Vom Plattformteam vorausgesetzt (nicht im Code)

- Hub-VNet mit ExpressRoute Gateway und Azure Firewall (Default Deny → Internet)
- Zentrale Private DNS Zones (`privatelink.openai.azure.com`, `privatelink.cognitiveservices.azure.com`, `privatelink.services.ai.azure.com`, `privatelink.search.windows.net`, `privatelink.blob.core.windows.net`, `privatelink.vaultcore.azure.net`), gelinkt an den Hub
- DNS Private Resolver im Hub; Inbound-IP wird als `hub_dns_inbound_ip` übergeben
- `DeployIfNotExists`-Policy, die Private Endpoints automatisch in den Zonen registriert
- `Deny`-Policies: keine Public IPs, kein öffentlicher AI-Zugriff, keine API-Keys, keine `privatelink.*`-Zonen in Spokes

## Prüfen (ohne Azure-Zugang)

```bash
terraform init -backend=false && terraform validate && terraform fmt -check
```

`plan`/`apply` benötigen Azure-Zugang und die Hub-Werte aus `terraform.tfvars.example`.
