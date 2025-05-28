# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat
resource "google_compute_router_nat" "nat-iowa" {
  name   = "nat-iowa"
  router = google_compute_router.router-iowa.name
  region = "us-central1"

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  nat_ip_allocate_option             = "MANUAL_ONLY"

  subnetwork {
    name                    = google_compute_subnetwork.hq-internal-iowa.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  nat_ips = [google_compute_address.nat-iowa.self_link]
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address
resource "google_compute_address" "nat-iowa" {
  name         = "nat-iowa"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
  #Theo deleted this line
  /*depends_on = [google_project_service.compute]*/
  #Unnecessary line because iowa is the default region  
  region = "us-central1"
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat
resource "google_compute_router_nat" "nat-tokyo" {
  name   = "nat-tokyo"
  router = google_compute_router.router-tokyo.name
  region = "asia-northeast1"

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  nat_ip_allocate_option             = "MANUAL_ONLY"

  subnetwork {
    name                    = google_compute_subnetwork.tokyo1.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  nat_ips = [google_compute_address.nat-tokyo.self_link]
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address
resource "google_compute_address" "nat-tokyo" {
  name         = "nat-tokyo"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
  #Theo deleted this line
  /*depends_on = [google_project_service.compute]*/
  region = "asia-northeast1"

}

