# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork
resource "google_compute_subnetwork" "hq-internal-iowa" {
  name                     = "hq-internal-iowa"
  ip_cidr_range            = "10.22.18.0/24"
  region                   = "us-central1"
  network                  = google_compute_network.summer-ready.id
  private_ip_google_access = true
}

# Regional Proxy-Only Subnet 
# Required for Regional Application Load Balancer for traffic offloading
resource "google_compute_subnetwork" "regional_proxy_subnet" {
  name          = "regional-proxy-subnet"
  region        = "us-central1"
  ip_cidr_range = "10.22.118.0/24"
  # This purpose reserves this subnet for regional Envoy-based load balancers
  purpose = "REGIONAL_MANAGED_PROXY"
  network = google_compute_network.summer-ready.id
  role    = "ACTIVE"
}

resource "google_compute_subnetwork" "belgium1" {
  name                     = "belgium1"
  ip_cidr_range            = "10.22.38.0/24"
  region                   = "europe-west1"
  network                  = google_compute_network.summer-ready.id
  private_ip_google_access = true

}

/*resource "google_compute_subnetwork" "belgium2" {
  name                     = "belgium2"
  ip_cidr_range            = "10.22.39.0/24"
  region                   = "europe-west1"
  network                  = google_compute_network.summer-ready.id
  private_ip_google_access = true
  
}*/

resource "google_compute_subnetwork" "saopaulo" {
  name                     = "saopaulo"
  ip_cidr_range            = "10.22.58.0/24"
  region                   = "southamerica-east1"
  network                  = google_compute_network.summer-ready.id
  private_ip_google_access = true

}

resource "google_compute_subnetwork" "tokyo1" {
  name                     = "tokyo1"
  ip_cidr_range            = "10.22.78.0/24"
  region                   = "asia-northeast1"
  network                  = google_compute_network.summer-ready.id
  private_ip_google_access = true

}

/*resource "google_compute_subnetwork" "tokyo2" {
  name                     = "tokyo2"
  ip_cidr_range            = "10.22.77.0/24"
  region                   = "asia-northeast1"
  network                  = google_compute_network.summer-ready.id
  private_ip_google_access = true
  
}*/

