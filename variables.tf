variable "resourceGroupLocation" {
  type        = string
  default     = "North Europe"
  description = "Location of the resource group."
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

# variable "computeResourceGroupName" {
#   type        = string
#   default     = "rg-compute-neu"
# }

# variable "recoveryResourceGroupName" {
#   type        = string
#   default     = "rg-recovery-neu"
# }



