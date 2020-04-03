terraform {
  backend "gcs" {
    bucket = "storage-bucket-docker2-272817"
    prefix = "stage"
  }
}
