terraform {
  backend "gcs" {
    bucket = "storage-bucket-docker-271613"
    prefix = "stage"
  }
}
