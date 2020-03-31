variable zone {
  description = "Zone"
  # Значение по умолчанию
  default = "europe-north1-b"
}
variable docker_image {
  description = "Disk image for reddit db"
  default     = "microservices-docker"
}
variable private_key {
  description = "SSH pisk key"
  default     = "/root/.ssh/appuser"
}
variable "enable_provision" {
  default = true
}
