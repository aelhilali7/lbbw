#############################################
# AI-Spoke-VNet (Teil 1.1, Baustein 3)
#############################################

resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-${local.name}"
  location            = azurerm_resource_group.ai.location
  resource_group_name = azurerm_resource_group.ai.name
  address_space       = [var.spoke_address_space]
  tags                = var.tags

  # CAF: "All Azure virtual networks use the DNS private resolver that's hosted
  # in the hub virtual network." Der Spoke braucht dadurch keine eigenen
  # Zonen-Links; die zentralen Zonen sind am Hub gelinkt (Teil 1.3).
  dns_servers = [var.hub_dns_inbound_ip]
}

resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.ai.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.subnet_app_prefix]
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.ai.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.subnet_private_endpoints_prefix]

  # Damit NSG-Regeln auf Private Endpoints wirken (Teil 1.2, Segmentierung).
  private_endpoint_network_policies = "Enabled"
}

#############################################
# VNet-Peering Spoke <-> Hub (nur zum Hub, kein Spoke-zu-Spoke)
#############################################

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-spoke-to-hub"
  resource_group_name       = azurerm_resource_group.ai.name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = var.hub_vnet_id

  allow_forwarded_traffic = true
  use_remote_gateways     = true # ExpressRoute Gateway im Hub nutzen
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-${local.name}"
  resource_group_name       = var.hub_resource_group_name
  virtual_network_name      = var.hub_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id

  allow_forwarded_traffic = true
  allow_gateway_transit   = true
}

#############################################
# Route Table: Default-Route auf die Firewall (Teil 1.1, "kein Egress")
#############################################

resource "azurerm_route_table" "app" {
  name                          = "rt-${local.name}-app"
  location                      = azurerm_resource_group.ai.location
  resource_group_name           = azurerm_resource_group.ai.name
  bgp_route_propagation_enabled = false # keine unerwartete Route aus BGP
  tags                          = var.tags

  route {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_private_ip
  }
}

resource "azurerm_subnet_route_table_association" "app" {
  subnet_id      = azurerm_subnet.app.id
  route_table_id = azurerm_route_table.app.id
}

#############################################
# NSG auf dem Private-Endpoint-Subnetz (Teil 1.2, Segmentierung):
# Port 443 nur aus snet-app, alles andere aus dem VNet explizit verweigern.
#############################################

resource "azurerm_network_security_group" "private_endpoints" {
  name                = "nsg-${local.name}-pe"
  location            = azurerm_resource_group.ai.location
  resource_group_name = azurerm_resource_group.ai.name
  tags                = var.tags

  security_rule {
    name                       = "allow-https-from-app-subnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.subnet_app_prefix
    destination_address_prefix = var.subnet_private_endpoints_prefix
  }

  security_rule {
    name                       = "allow-https-from-onprem"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = var.onprem_address_prefixes
    destination_address_prefix = var.subnet_private_endpoints_prefix
  }

  security_rule {
    name                       = "deny-all-other-inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints.id
}

#############################################
# NSG auf dem App-Subnetz: eingehend nur 443 aus dem Bank-RZ
#############################################

resource "azurerm_network_security_group" "app" {
  name                = "nsg-${local.name}-app"
  location            = azurerm_resource_group.ai.location
  resource_group_name = azurerm_resource_group.ai.name
  tags                = var.tags

  security_rule {
    name                       = "allow-https-from-onprem"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = var.onprem_address_prefixes
    destination_address_prefix = var.subnet_app_prefix
  }

  security_rule {
    name                       = "deny-all-other-inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}
