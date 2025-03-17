output "current_subscription_display_name" {
  value = data.azurerm_subscription.currentSubscription.display_name
}

output "Firewall_public_ip" {
  value = azurerm_public_ip.pip_fw_hubMain_1.ip_address
}

output "firewall_private_ip" {
  value = azurerm_firewall.fw_hubMain.ip_configuration[0].private_ip_address
}

output "agw_public_ip" {
  value = azurerm_public_ip.pip_agw_hub_1.ip_address
}

output "bastion_public_ip" {
  value = azurerm_public_ip.pip_bastion_hub_neu_1.ip_address
}


