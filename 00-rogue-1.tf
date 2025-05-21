resource "google_compute_network" "prod1" {
  name                            = "prod1"
  routing_mode                    = "REGIONAL"
  auto_create_subnetworks         = false
  mtu                             = 1460
  delete_default_routes_on_create = false

}

#subnets for prod1 vpc

resource "google_compute_subnetwork" "iowa-app01" {
  name                     = "iowa-app01"
  ip_cidr_range            = "10.32.18.0/24"
  region                   = "us-central1"
  network                  = google_compute_network.prod1.id
  private_ip_google_access = true
  
}


resource "google_compute_subnetwork" "tokyo-app01" {
  name                     = "tokyo-app01"
  ip_cidr_range            = "10.32.38.0/24"
  region                   = "asia-northeast1"
  network                  = google_compute_network.prod1.id
  private_ip_google_access = true
  
}

#routers for prod1 vpc
resource "google_compute_router" "router-iowa-app01" {
  name    = "router-iowa-app01"
  region  = "us-central1"
  network = google_compute_network.prod1.id
}

resource "google_compute_router" "router-tokyo-app01" {
  name    = "router-tokyo-app01"
  region  = "asia-northeast1"
  network = google_compute_network.prod1.id
}

#nat routers for app01 in prod1 vpc 

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat
resource "google_compute_router_nat" "nat-tokyo-app01" {
  name   = "nat-tokyo-app01"
  router = google_compute_router.router-tokyo-app01.name
  region = "asia-northeast1"

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  nat_ip_allocate_option             = "MANUAL_ONLY"

  subnetwork {
    name                    = google_compute_subnetwork.tokyo-app01.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  nat_ips = [google_compute_address.nat-tokyo-app01.self_link]
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address
resource "google_compute_address" "nat-tokyo-app01" {
  name         = "nat-tokyo-app01"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
#Theo deleted this line
  /*depends_on = [google_project_service.compute]*/
  region = "asia-northeast1"

}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat
resource "google_compute_router_nat" "nat-iowa-app01" {
  name   = "nat-iowa-app01"
  router = google_compute_router.router-iowa-app01.name
  region = "us-central1"

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  nat_ip_allocate_option             = "MANUAL_ONLY"

  subnetwork {
    name                    = google_compute_subnetwork.iowa-app01.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  nat_ips = [google_compute_address.nat-iowa-app01.self_link]
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address
resource "google_compute_address" "nat-iowa-app01" {
  name         = "nat-iowa-app01"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
#Theo deleted this line
  /*depends_on = [google_project_service.compute]*/
#Unnecessary line because iowa-app01 is the default region  
  region = "us-central1"
}

#firewall rules for prod1 vpc

resource "google_compute_firewall" "rogue-1-allow-ssh" {
  name    = "rogue-1-allow-ssh"
  network = google_compute_network.prod1.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "rogue-1-allow-http" {
  name    = "rogue-1-allow-web"
  network = google_compute_network.prod1.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "rogue-1-allow-rdp" {
  name    = "rogue-1-allow-rdp"
  network = google_compute_network.prod1.name

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "rogue-1-allow-icmp" {
  name    = "rogue-1-allow-icmp"
  network = google_compute_network.prod1.name

  allow {
    protocol = "icmp"
    
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "rogue-1-allow-db" {
  name    = "rogue-1-allow-db"
  network = google_compute_network.prod1.name

  allow {
    protocol = "tcp"
    ports    = ["3306", "1521"]
  }

  source_ranges = ["0.0.0.0/0"]
}
