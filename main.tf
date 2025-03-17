
data "azurerm_subscription" "currentSubscription" {
}



# Create a resource group
resource "azurerm_resource_group" "rg_compute" {
  name     = "rg-compute-neu"
  location = var.resourceGroupLocation
}

resource "azurerm_resource_group" "rg_recovery" {
  name     = "rg-recovery-neu"
  location = var.resourceGroupLocation
}


# Create Hub Virtual Network
resource "azurerm_virtual_network" "vnet_hub" {
  name                = "vnet-hub-neu"
  resource_group_name = azurerm_resource_group.rg_compute.name
  location            = azurerm_resource_group.rg_compute.location
  address_space       = ["10.20.0.0/16"]
}


# Create Spoke Virtual Network
resource "azurerm_virtual_network" "vnet_Spoke_1" {
  name                = "vnet-spoke-neu-001"
  resource_group_name = azurerm_resource_group.rg_compute.name
  location            = azurerm_resource_group.rg_compute.location
  address_space       = ["10.30.0.0/16"]
}


# Hub and Spoke Peering
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "hub-to-spoke"
  resource_group_name          = azurerm_resource_group.rg_compute.name
  virtual_network_name         = azurerm_virtual_network.vnet_hub.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet_Spoke_1.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "spoke-to-hub"
  resource_group_name          = azurerm_resource_group.rg_compute.name
  virtual_network_name         = azurerm_virtual_network.vnet_Spoke_1.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet_hub.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}




# Create Firewall Subnet
resource "azurerm_subnet" "azureFirewallSubnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg_compute.name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes     = ["10.20.0.0/24"]
}

# Create Firewall Management Subnet
resource "azurerm_subnet" "azureFirewallManagementSubnet" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = azurerm_resource_group.rg_compute.name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes     = ["10.20.1.0/24"]
}

# Create Bastion Subnet
resource "azurerm_subnet" "azureBastionSubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg_compute.name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes     = ["10.20.2.0/24"]
}

# Create Gateway Subnet
resource "azurerm_subnet" "gatewaySubnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg_compute.name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes     = ["10.20.3.0/24"]
}

# Create application gateway Subnet
resource "azurerm_subnet" "agwSubnet" {
  name                 = "agwSubnet"
  resource_group_name  = azurerm_resource_group.rg_compute.name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes     = ["10.20.4.0/24"]
}


resource "azurerm_public_ip" "pip_fw_hubMain_1" {
  name                = "pip-hubMainFirewall-neu-1"
  location            = azurerm_resource_group.rg_compute.location
  resource_group_name = azurerm_resource_group.rg_compute.name
  allocation_method   = "Static"
  sku                 = "Standard"
}



resource "azurerm_firewall_policy" "policy_fw_hubMain_1" {
  name                = "policy-fwHubMain-neu-1"
  sku                 = "Standard"
  resource_group_name = azurerm_resource_group.rg_compute.name
  location            = azurerm_resource_group.rg_compute.location
}

resource "azurerm_firewall_policy_rule_collection_group" "network_rule" {
  name               = "network-rule-collection"
  firewall_policy_id = azurerm_firewall_policy.policy_fw_hubMain_1.id
  priority           = 100

  network_rule_collection {
    name     = "allow-internet-access"
    action   = "Allow"
    priority = 100

    rule {
      name                  = "allow-internet"
      protocols             = ["TCP"]
      source_addresses      = [azurerm_subnet.vmWebSubnet.address_prefixes[0]]
      destination_addresses = ["0.0.0.0/0"]
      destination_ports     = ["80", "443"]
    }
  }
}

resource "azurerm_firewall" "fw_hubMain" {
  name                = "fw-hubMain-neu"
  location            = azurerm_resource_group.rg_compute.location
  resource_group_name = azurerm_resource_group.rg_compute.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.azureFirewallSubnet.id
    public_ip_address_id = azurerm_public_ip.pip_fw_hubMain_1.id
  }

  firewall_policy_id = azurerm_firewall_policy.policy_fw_hubMain_1.id

  # management_ip_configuration {
  #   name                 = "mgmt-configuration"
  #   subnet_id            = azurerm_subnet.azureFirewallManagementSubnet.id
  #   public_ip_address_id = azurerm_public_ip.pip_mgmt_fw_hubMain_1.id
  # }

}

resource "azurerm_monitor_diagnostic_setting" "amds_fw_hubmain_1" {
  name                       = "amds-fw-hubmain-1"
  target_resource_id         = azurerm_firewall.fw_hubMain.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law_futureMart.id

  enabled_log {
    category = "AzureFirewallApplicationRule"
  }

  enabled_log {
    category = "AzureFirewallNetworkRule"
  }
  metric {
    category = "AllMetrics"
    enabled  = true
  }


}


# Create webVM Subnet
resource "azurerm_subnet" "vmWebSubnet" {
  name                 = "VMWebSubnet"
  resource_group_name  = azurerm_resource_group.rg_compute.name
  virtual_network_name = azurerm_virtual_network.vnet_Spoke_1.name
  address_prefixes     = ["10.30.0.0/24"]
}


# Create 2 NICs
resource "azurerm_network_interface" "nic_vm_prodweb" {
  count               = 2
  name                = "nic-vm-prodweb-${count.index + 1}"
  location            = azurerm_resource_group.rg_compute.location
  resource_group_name = azurerm_resource_group.rg_compute.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vmWebSubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create 2 VMs
resource "azurerm_windows_virtual_machine" "vm_prodweb" {
  count                             = 2
  name                              = "vm-prodWeb-neu-${count.index + 1}"
  location                          = azurerm_resource_group.rg_compute.location
  resource_group_name               = azurerm_resource_group.rg_compute.name
  size                              = "Standard_D2_v3"
  computer_name                     = "prodWeb${count.index + 1}"
  admin_username                    = "adminuser"
  admin_password                    = "Welcome@123456"
  network_interface_ids             = [azurerm_network_interface.nic_vm_prodweb[count.index].id]
  license_type                      = "Windows_Server"
  zone                              = count.index + 1
  vm_agent_platform_updates_enabled = true


  os_disk {
    name                 = "osdisk-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }


  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter"
    version   = "latest"
  }

  identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.uai_futureMart_1.id]
  }

}


resource "azurerm_network_security_group" "nsg_vms_prod_web" {
  name                = "nsg-vms-prod-web"
  resource_group_name = azurerm_resource_group.rg_compute.name
  location            = azurerm_resource_group.rg_compute.location
}


# Allow only Bastion and App Gateway to access the VMs

resource "azurerm_network_security_rule" "allow_bastion" {
  name                        = "AllowBastionAccess"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = azurerm_subnet.azureBastionSubnet.address_prefixes[0]
  destination_port_range      = "3389"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_compute.name
  network_security_group_name = azurerm_network_security_group.nsg_vms_prod_web.name
}

resource "azurerm_network_security_rule" "allow_app_gateway" {
  name                        = "AllowAppGatewayAccess"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = azurerm_subnet.gatewaySubnet.address_prefixes[0]
  destination_port_ranges     = ["443", "80", "8080"]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_compute.name
  network_security_group_name = azurerm_network_security_group.nsg_vms_prod_web.name
}

#Associate the NSG With the VMSubnet
resource "azurerm_subnet_network_security_group_association" "nsg-subnetAssosiate" {
  subnet_id                 = azurerm_subnet.vmWebSubnet.id
  network_security_group_id = azurerm_network_security_group.nsg_vms_prod_web.id
}


resource "azurerm_public_ip" "pip_bastion_hub_neu_1" {
  name                = "pip-bastion-hub-neu-1"
  location            = azurerm_resource_group.rg_compute.location
  resource_group_name = azurerm_resource_group.rg_compute.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastionhost_hub_neu" {
  name                = "bastionhost-hub-neu"
  location            = azurerm_resource_group.rg_compute.location
  resource_group_name = azurerm_resource_group.rg_compute.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.azureBastionSubnet.id
    public_ip_address_id = azurerm_public_ip.pip_bastion_hub_neu_1.id
  }
}


resource "azurerm_route_table" "rt_spoke" {
  name                = "rt-spoke-1"
  location            = azurerm_resource_group.rg_compute.location
  resource_group_name = azurerm_resource_group.rg_compute.name
}

resource "azurerm_route" "forcedRoutetToFirewall" {
  name                   = "ForceToFirewall"
  resource_group_name    = azurerm_resource_group.rg_compute.name
  route_table_name       = azurerm_route_table.rt_spoke.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.fw_hubMain.ip_configuration[0].private_ip_address # Firewall Private IP

  depends_on = [azurerm_firewall.fw_hubMain] # Ensures Firewall is created first
}

resource "azurerm_subnet_route_table_association" "associate_vmWebSubnet_rtSpoke" {
  subnet_id      = azurerm_subnet.vmWebSubnet.id
  route_table_id = azurerm_route_table.rt_spoke.id
}


# Create a Web Application Firewall (WAF) policy
resource "azurerm_web_application_firewall_policy" "policy_waf_agw_hub_1" {
  name                = "policy-waf-agw-hub-1"
  resource_group_name = azurerm_resource_group.rg_compute.name
  location            = azurerm_resource_group.rg_compute.location

  # Configure the policy settings
  policy_settings {
    enabled                 = false
    file_upload_limit_in_mb = 100
    # js_challenge_cookie_expiration_in_minutes = 5
    max_request_body_size_in_kb = 128
    mode                        = "Detection"
    request_body_check          = true
    # request_body_inspect_limit_in_kb          = 128
  }

  # Define managed rules for the WAF policy
  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  #   # Define a custom rule to block traffic from a specific IP address
  #   custom_rules {
  #     name      = "BlockSpecificIP"
  #     priority  = 1
  #     rule_type = "MatchRule"

  #     match_conditions {
  #       match_variables {
  #         variable_name = "RemoteAddr"
  #       }
  #       operator           = "IPMatch"
  #       negation_condition = false
  #       match_values       = ["192.168.1.1"] # Replace with the IP address to block
  #     }

  #     action = "Block"
  #   }
  # }}
}

# Create application gateway public IP address
resource "azurerm_public_ip" "pip_agw_hub_1" {
  name                = "pip-agw-hub-neu-1"
  location            = azurerm_resource_group.rg_compute.location
  resource_group_name = azurerm_resource_group.rg_compute.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create the Application Gateway
resource "azurerm_application_gateway" "agw_prod_futureMart" {
  name                = "agw-prod-futureMart-neu-1"
  location            = azurerm_resource_group.rg_compute.location
  resource_group_name = azurerm_resource_group.rg_compute.name

  # Configure the SKU and capacity
  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  # Enable autoscaling (optional)
  autoscale_configuration {
    min_capacity = 1
    max_capacity = 10
  }

  # Configure the gateway's IP settings
  gateway_ip_configuration {
    name      = "ip-config-agw"
    subnet_id = azurerm_subnet.agwSubnet.id
  }

  # Configure the frontend IP
  frontend_ip_configuration {
    name                 = "agw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.pip_agw_hub_1.id
  }

  # Define the frontend port
  frontend_port {
    name = "agw-frontend-port"
    port = 80
  }

  # Define the backend address pool with IP addresses
  backend_address_pool {
    name         = "agw-backend-pool"
    ip_addresses = ["10.30.0.4", "10.30.0.5"] # Replace with your backend IP addresses
  }

  # Configure backend HTTP settings
  backend_http_settings {
    name                  = "agw-backend-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  # Define the HTTP listener
  http_listener {
    name                           = "agw-http-listener"
    frontend_ip_configuration_name = "agw-frontend-ip"
    frontend_port_name             = "agw-frontend-port"
    protocol                       = "Http"
  }

  # Define the request routing rule
  request_routing_rule {
    name                       = "agw-routing-rule"
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = "agw-http-listener"
    backend_address_pool_name  = "agw-backend-pool"
    backend_http_settings_name = "agw-backend-http-settings"
  }

  # Associate the WAF policy with the Application Gateway
  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }
}


resource "azurerm_monitor_diagnostic_setting" "agw_monitor_diagnostic_setting" {
  name                       = "agw-monitor-diagnostic-setting"
  target_resource_id         = azurerm_application_gateway.agw_prod_futureMart.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law_futureMart.id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }
  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }
  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}


# Configure Azure Backup 
/*Note :In case of an error there is already a service fault  
with the name "tfuturefinancebackupvault" check the portal if there is a vault uncomment the data section
to include the alredy existing vault in the state file and comment this section and it should work ok */
resource "azurerm_recovery_services_vault" "backupVault_futureMartRecovery" {
  name                = "backupvault-futureMartRecovery-neu"
  location            = azurerm_resource_group.rg_recovery.location
  resource_group_name = azurerm_resource_group.rg_recovery.name
  sku                 = "Standard"
  storage_mode_type   = "LocallyRedundant"
}


resource "azurerm_backup_policy_vm" "vmBackupPolicy_daily" {
  name                = "backuppolicy-daily"
  resource_group_name = azurerm_resource_group.rg_recovery.name
  recovery_vault_name = azurerm_recovery_services_vault.backupVault_futureMartRecovery.name #comment in case of vault exist error

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 30
  }
}

# Assign Backup Policy to VMs
resource "azurerm_backup_protected_vm" "backupVMs" {
  count               = 2
  resource_group_name = azurerm_resource_group.rg_recovery.name
  recovery_vault_name = azurerm_recovery_services_vault.backupVault_futureMartRecovery.name #comment in case of vault exist error
  source_vm_id        = azurerm_windows_virtual_machine.vm_prodweb[count.index].id
  backup_policy_id    = azurerm_backup_policy_vm.vmBackupPolicy_daily.id
}



# #Uncomment In case of service vault already exist error
# # Dont Forget to comment the recovery cretion code
# data "azurerm_recovery_services_vault" "backupVault_futureMartRecovery" {
#   name                = "backupvault-futureMartRecovery-neu"
#   resource_group_name = azurerm_resource_group.rg_recovery.name
# }

# resource "azurerm_backup_policy_vm" "vmBackupPolicy_daily" {
#   name                = "backuppolicy-daily"
#   resource_group_name = azurerm_resource_group.rg_recovery.name
#   recovery_vault_name = data.azurerm_recovery_services_vault.backupVault_futureMartRecovery.name 


#   backup {
#     frequency = "Daily"
#     time      = "23:00"
#   }

#   retention_daily {
#     count = 30
#   }
# }

# # Assign Backup Policy to VMs
# resource "azurerm_backup_protected_vm" "backupVMs" {
#   count               = 2
#   resource_group_name = azurerm_resource_group.rg_recovery.name
#   recovery_vault_name = data.azurerm_recovery_services_vault.backupVault_futureMartRecovery.name 
#   source_vm_id        = azurerm_windows_virtual_machine.vm_prodweb[count.index].id
#   backup_policy_id    = azurerm_backup_policy_vm.vmBackupPolicy_daily.id
# }



# Create Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law_futureMart" {
  name                       = "law-futureMart-neu-1"
  location                   = azurerm_resource_group.rg_compute.location
  resource_group_name        = azurerm_resource_group.rg_compute.name
  sku                        = "PerGB2018"
  retention_in_days          = 30
  internet_ingestion_enabled = true
}



resource "azurerm_log_analytics_solution" "vminsights" {
  solution_name         = "VMInsights"
  location              = azurerm_resource_group.rg_compute.location
  resource_group_name   = azurerm_resource_group.rg_compute.name
  workspace_resource_id = azurerm_log_analytics_workspace.law_futureMart.id
  workspace_name        = azurerm_log_analytics_workspace.law_futureMart.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/VMInsights"
  }
}



resource "azurerm_monitor_data_collection_rule" "dcr_law_futureMart" {
  name                = "dcr-law-futureMart"
  resource_group_name = azurerm_resource_group.rg_compute.name
  location            = azurerm_resource_group.rg_compute.location

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.law_futureMart.id
      name                  = "fm-destination-log"
    }

    azure_monitor_metrics {
      name = "fm-destination-metrics"
    }
  }



  data_flow {
    streams      = ["Microsoft-InsightsMetrics", "Microsoft-Syslog", "Microsoft-Perf"]
    destinations = ["fm-destination-log"]
  }


  data_sources {

    performance_counter {
      streams                       = ["Microsoft-Perf", "Microsoft-InsightsMetrics"]
      sampling_frequency_in_seconds = 60
      counter_specifiers            = ["Processor(*)\\% Processor Time"]
      name                          = "fm-datasource-perfcounter"
    }

  }


  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.uai_futureMart_1.id]
  }

  depends_on = [
    azurerm_log_analytics_solution.vminsights
  ]
}





resource "azurerm_monitor_data_collection_rule_association" "dcra_vm" {
  count                   = 2
  name                    = "dcra-vm-${count.index + 1}"
  target_resource_id      = azurerm_windows_virtual_machine.vm_prodweb[count.index].id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr_law_futureMart.id
}




resource "azurerm_user_assigned_identity" "uai_futureMart_1" {
  name                = "uai-futureMart-1"
  location            = azurerm_resource_group.rg_compute.location
  resource_group_name = azurerm_resource_group.rg_compute.name
}

# This extension is needed for other extensions
resource "azurerm_virtual_machine_extension" "daa-agent" {
  count                      = 2
  name                       = "DependencyAgentWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm_prodweb[count.index].id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentWindows"
  type_handler_version       = "9.10"
  automatic_upgrade_enabled  = true
  auto_upgrade_minor_version = true
}


# Add logging and monitoring extensions
resource "azurerm_virtual_machine_extension" "azuremonitorwindowsagent" {
  depends_on                 = [azurerm_virtual_machine_extension.daa-agent]
  count                      = 2
  name                       = "AzureMonitorWindowsAgent"
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.8"
  automatic_upgrade_enabled  = true
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.vm_prodweb[count.index].id

  settings = jsonencode({
    workspaceId               = azurerm_log_analytics_workspace.law_futureMart.id
    azureResourceId           = azurerm_windows_virtual_machine.vm_prodweb[count.index].id
    stopOnMultipleConnections = false

    authentication = {
      managedIdentity = {
        identifier-name  = "mi_res_id"
        identifier-value = azurerm_user_assigned_identity.uai_futureMart_1.id
      }
    }
  })
  protected_settings = jsonencode({
    "workspaceKey" = azurerm_log_analytics_workspace.law_futureMart.primary_shared_key
  })


}


# resource "azurerm_virtual_machine_extension" "msmonitor-agent" {
#   depends_on           = [azurerm_virtual_machine_extension.daa-agent]
#   count                = 2
#   name                 = "MicrosoftMonitoringAgent" # Must be called this
#   virtual_machine_id   = azurerm_windows_virtual_machine.vm_prodweb[count.index].id
#   publisher            = "Microsoft.EnterpriseCloud.Monitoring"
#   type                 = "MicrosoftMonitoringAgent"
#   type_handler_version = "1.0"
#   # Not yet supported
#   # automatic_upgrade_enabled  = true
#   # auto_upgrade_minor_version = true
#   settings           = <<SETTINGS
#     {
#         "workspaceId": "${azurerm_log_analytics_workspace.law_futureMart.id}",
#         "azureResourceId": "${azurerm_windows_virtual_machine.vm_prodweb[count.index].id}",
#         "stopOnMultipleConnections": "false"
#     }
#   SETTINGS
#   protected_settings = <<PROTECTED_SETTINGS
#     {
#       "workspaceKey": "${azurerm_log_analytics_workspace.law_futureMart.primary_shared_key}"
#     }
#   PROTECTED_SETTINGS
# }



resource "azurerm_portal_dashboard" "db_futureMart" {
  name                = "futureMart-dashboard"
  resource_group_name = azurerm_resource_group.rg_compute.name
  location            = azurerm_resource_group.rg_compute.location

  # Dashboard configuration
  dashboard_properties = file("./Fixed_Dashboard.json")

}


# Create Action Group for Email Notification
resource "azurerm_monitor_action_group" "emailAlertActionGroup1" {
  name                = "emailAlertActionGroup-futureMart-neu-1"
  resource_group_name = azurerm_resource_group.rg_compute.name
  short_name          = "FFAlert"

  email_receiver {
    name          = "admin"
    email_address = "ahmedybasha1@outlook.com"
  }
}

# Create Azure Monitor Alert for High CPU Usage
resource "azurerm_monitor_metric_alert" "alertHighCPU" {
  name                     = "AlertHighCPUUsage"
  resource_group_name      = azurerm_resource_group.rg_compute.name
  scopes                   = azurerm_windows_virtual_machine.vm_prodweb[*].id
  description              = "Alert when CPU exceeds 80% for 5 minutes"
  severity                 = 2
  target_resource_type     = "Microsoft.Compute/virtualMachines"
  target_resource_location = azurerm_resource_group.rg_compute.location

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  window_size = "PT5M"
  frequency   = "PT1M"
  action {
    action_group_id = azurerm_monitor_action_group.emailAlertActionGroup1.id
  }
}



