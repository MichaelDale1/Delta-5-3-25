# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router
resource "google_compute_router" "router-iowa" {
  name    = "router-iowa"
  region  = "us-central1"
  network = google_compute_network.summer-ready.id
}

resource "google_compute_router" "router-belgium" {
  name    = "router-belgium"
  region  = "europe-west1"
  network = google_compute_network.summer-ready.id
}

resource "google_compute_router" "router-saopaulo" {
  name    = "router-saopaulo"
  region  = "southamerica-east1"
  network = google_compute_network.summer-ready.id
}

resource "google_compute_router" "router-tokyo" {
  name    = "router-tokyo"
  region  = "asia-northeast1"
  network = google_compute_network.summer-ready.id
}

