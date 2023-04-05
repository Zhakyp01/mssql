resource "google_compute_network" "private_network" {
  provider = google-beta

  name = "private-network"
  auto_create_subnetworks = false
}

resource "google_compute_global_address" "private_ip_address" {
  provider = google-beta

  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.private_network.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google-beta

  network                 = google_compute_network.private_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "instance" {
  provider = google-beta
  name                = "private-instance-${random_id.db_name_suffix.hex}"
  region              = "us-central1"
  database_version    = "SQLSERVER_2019_ENTERPRISE"
  deletion_protection = false
  depends_on = [google_service_networking_connection.private_vpc_connection]
  root_password = "admin"

  settings {
    tier      = "db-custom-12-61440"
    disk_size = "100"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.private_network.id
    }
  }
}


provider "google-beta" {
  region = "us-central1"
  zone   = "us-central1-a"
  project = "my-project-test-382316"
  credentials = "creds.json"
}
