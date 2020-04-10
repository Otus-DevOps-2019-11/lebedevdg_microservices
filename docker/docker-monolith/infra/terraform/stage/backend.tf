terraform {
  backend "gcs" {
    bucket = "storage-bucket-docker3-273507"
    prefix = "stage"
  }
}
