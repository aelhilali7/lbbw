#############################################
# Workload-Team (Application Landing Zone: AI-Spoke)
#############################################

variable "location" {
  description = "Azure-Region. Annahme aus Teil 1: Germany West Central."
  type        = string
  default     = "germanywestcentral"
}

variable "environment" {
  description = "Umgebungskürzel (dev, test, prod). Fließt in Ressourcennamen ein."
  type        = string
  default     = "prod"
}

variable "name_prefix" {
  description = "Präfix für alle Ressourcennamen."
  type        = string
  default     = "lbbw-ai"
}

variable "tags" {
  description = "Tags für alle Ressourcen."
  type        = map(string)
  default = {
    workload   = "ai-platform"
    owner      = "cloud-ai-engineering"
    data-class = "confidential"
  }
}

#############################################
# Werte vom Plattformteam (Hub, Connectivity Subscription)
# Der Spoke erzeugt nichts davon, er referenziert nur.
#############################################

variable "hub_vnet_id" {
  description = "Resource-ID des bestehenden Hub-VNets."
  type        = string
}

variable "hub_resource_group_name" {
  description = "Resource Group des Hub-VNets (für das Rück-Peering)."
  type        = string
}

variable "hub_vnet_name" {
  description = "Name des Hub-VNets (für das Rück-Peering)."
  type        = string
}

variable "firewall_private_ip" {
  description = "Private IP der Azure Firewall im Hub. Ziel der Default-Route 0.0.0.0/0."
  type        = string
  default     = "10.10.2.4"
}

variable "hub_dns_inbound_ip" {
  description = "IP des Inbound Endpoints des DNS Private Resolvers im Hub. Wird DNS-Server des Spoke-VNets (CAF: alle VNets nutzen den Resolver im Hub)."
  type        = string
  default     = "10.10.0.4"
}

variable "onprem_address_prefixes" {
  description = "Adressbereiche des Bank-RZ, die über ExpressRoute erreichbar sind (für NSG-Regeln)."
  type        = list(string)
  default     = ["10.100.0.0/16"]
}

variable "log_analytics_workspace_id" {
  description = "Resource-ID des zentralen Log Analytics Workspace (angebunden über AMPLS)."
  type        = string
}

#############################################
# AI-Spoke-VNet
#############################################

variable "spoke_address_space" {
  description = "Adressraum des AI-Spoke-VNets. Darf sich nicht mit Hub oder RZ überschneiden."
  type        = string
  default     = "10.20.0.0/16"
}

variable "subnet_app_prefix" {
  description = "Subnetz für die RAG-Anwendung (Container Apps / App Service)."
  type        = string
  default     = "10.20.0.0/24"
}

variable "subnet_private_endpoints_prefix" {
  description = "Subnetz für alle Private Endpoints."
  type        = string
  default     = "10.20.1.0/24"
}

#############################################
# Azure OpenAI
#############################################

variable "openai_model_deployments" {
  description = "Modell-Deployments auf der Azure-OpenAI-Ressource."
  type = map(object({
    model_name    = string
    model_version = string
    capacity      = number
  }))
  default = {
    "gpt-4o" = {
      model_name    = "gpt-4o"
      model_version = "2024-11-20"
      capacity      = 30
    }
    "text-embedding-3-large" = {
      model_name    = "text-embedding-3-large"
      model_version = "1"
      capacity      = 60
    }
  }
}
