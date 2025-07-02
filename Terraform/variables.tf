variable "resource_group_name" {
  description = "Nombre del grupo de recursos"
  type        = string
  default     = "my-app-resources"
}

variable "location" {
  description = "Región de Azure donde se desplegarán los recursos"
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default = {
    Environment = "Dev"
    Project     = "MyApp"
  }
}

variable "acr_name" {
  description = "Nombre base del Azure Container Registry"
  type        = string
  default     = "myappacr"
}

variable "acr_sku" {
  description = "SKU del Azure Container Registry"
  type        = string
  default     = "Basic"
}

variable "app_name" {
  description = "Nombre de la aplicación"
  type        = string
  default     = "myapp"
}

variable "docker_image" {
  description = "Nombre de la imagen Docker"
  type        = string
  default     = "demo-app"
}

variable "docker_image_tag" {
  description = "Tag de la imagen Docker"
  type        = string
  default     = "latest"
}

variable "app_port" {
  description = "Puerto de la aplicación"
  type        = number
  default     = 80
}

variable "container_cpu" {
  description = "CPU asignada al contenedor"
  type        = number
  default     = 0.5
}

variable "container_memory" {
  description = "Memoria asignada al contenedor (GB)"
  type        = number
  default     = 1.5
}

variable "log_retention_days" {
  description = "Días de retención de logs"
  type        = number
  default     = 30
}

variable "enable_purge_protection" {
  description = "Habilitar protección contra purgado en Key Vault"
  type        = bool
  default     = false
}

variable "acr_sp_client_id" {
  description = "Client ID del App Registration (Service Principal) para autenticarse en el ACR"
  type        = string
}

variable "acr_sp_client_secret" {
  description = "Client Secret del App Registration (Service Principal) para autenticarse en el ACR"
  type        = string
  sensitive   = true
}
