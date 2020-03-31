variable project {
  description = "Project ID"
}
variable region {
  description = "Region"
  # Значение по умолчанию
  default = "europe-north1"
}
variable zone {
  description = "Zone"
  # Значение по умолчанию
  default = "europe-north1-b"
}
variable public_key_path {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}
variable private_key {
  description = "SSH pisk key"
}
variable docker_image {
  description = "docker images"
  default     = "microservices-docker"
}
