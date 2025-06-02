resource "google_compute_network" "prod1" {
  name                            = "prod1"
  routing_mode                    = "REGIONAL"
  auto_create_subnetworks         = false
  mtu                             = 1460
  delete_default_routes_on_create = false

}

#subnets for prod1 vpc

# resource "google_compute_subnetwork" "iowa-app01" {
#   name                     = "iowa-app01"
#   ip_cidr_range            = "10.32.18.0/24"
#   region                   = "us-central1"
#   network                  = google_compute_network.prod1.id
#   private_ip_google_access = true

# }


resource "google_compute_subnetwork" "tokyo-app01" {
  name                     = "tokyo-app01"
  ip_cidr_range            = "10.32.38.0/24"
  region                   = "asia-northeast1"
  network                  = google_compute_network.prod1.id
  private_ip_google_access = true

}

# Regional Proxy-Only Subnet 
# Required for Regional Application Load Balancer for traffic offloading
resource "google_compute_subnetwork" "regional_proxy_subnet_for_prod1" {
  name          = "regional-proxy-subnet-for-prod1-vpc"
  region        = "asia-northeast1"
  ip_cidr_range = "10.32.138.0/24"
  # This purpose reserves this subnet for regional Envoy-based load balancers
  purpose = "REGIONAL_MANAGED_PROXY"
  network = google_compute_network.prod1.id
  role    = "ACTIVE"
}


#routers for prod1 vpc
# resource "google_compute_router" "router-iowa-app01" {
#   name    = "router-iowa-app01"
#   region  = "us-central1"
#   network = google_compute_network.prod1.id
# }

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
# resource "google_compute_router_nat" "nat-iowa-app01" {
#   name   = "nat-iowa-app01"
#   router = google_compute_router.router-iowa-app01.name
#   region = "us-central1"

#   source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
#   nat_ip_allocate_option             = "MANUAL_ONLY"

#   subnetwork {
#     name                    = google_compute_subnetwork.iowa-app01.id
#     source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
#   }

#   nat_ips = [google_compute_address.nat-iowa-app01.self_link]
# }

# # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address
# resource "google_compute_address" "nat-iowa-app01" {
#   name         = "nat-iowa-app01"
#   address_type = "EXTERNAL"
#   network_tier = "PREMIUM"
# #Theo deleted this line
#   /*depends_on = [google_project_service.compute]*/
# #Unnecessary line because iowa-app01 is the default region  
#   region = "us-central1"
# }

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

# resource "google_compute_firewall" "rogue-1-allow-rdp" {
#   name    = "rogue-1-allow-rdp"
#   network = google_compute_network.prod1.name

#   allow {
#     protocol = "tcp"
#     ports    = ["3389"]
#   }

#   source_ranges = ["0.0.0.0/0"]
# }

# resource "google_compute_firewall" "rogue-1-allow-icmp" {
#   name    = "rogue-1-allow-icmp"
#   network = google_compute_network.prod1.name

#   allow {
#     protocol = "icmp"

#   }

#   source_ranges = ["0.0.0.0/0"]
# }

# resource "google_compute_firewall" "rogue-1-allow-db" {
#   name    = "rogue-1-allow-db"
#   network = google_compute_network.prod1.name

#   allow {
#     protocol = "tcp"
#     ports    = ["3306", "1521"]
#   }

#   source_ranges = ["0.0.0.0/0"]
# }

resource "google_compute_instance" "tokyo1-vm" {
  name         = "my-instance-tokyo"
  machine_type = "n2-standard-2"
  zone         = "asia-northeast1-a"


  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      labels = {
        my_label = "value"
      }
    }
  }



  network_interface {

    subnetwork = google_compute_subnetwork.tokyo-app01.name
    #We can comment out if we don't want a piblic IP especially since we have the nat gateway
    access_config {
      // Ephemeral public IP
    }
  }

  #A separate start up file
  metadata_startup_script = file("./startup-dr.sh")

}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_instance_template
# https://developer.hashicorp.com/terraform/language/functions/file
# Google Compute Engine: Regional Instance Template
resource "google_compute_region_instance_template" "app-tokyo" {
  name = "app-tokyo-template-terraform"
  #region is needed when the subnet is not in the default region
  region       = "asia-northeast1"
  description  = "This template is used to clone our vm"
  machine_type = "e2-medium"

  # Create a new disk from an image and set as boot disk
  disk {
    source_image = "debian-cloud/debian-12"
    boot         = true
  }

  # Network Configurations 
  network_interface {
    subnetwork = google_compute_subnetwork.tokyo-app01.id
    /*access_config {
      # Include this section to give the VM an external IP address
    } */
  }

  # Install Webserver using file() function
  metadata_startup_script = file("./startup-dr.sh")
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_health_check
# Resource: Regional Health Check
# Using the health check in prod LB
resource "google_compute_region_health_check" "app01-tokyo" {
  name                = "app-hc-tokyo"
  region              = "asia-northeast1" /*(optional if provider default is set)*/
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
  http_health_check {
    request_path = "/index.html"
    port         = 80
  }
}

#The health check didn't refer to another object

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones
# Datasource: Get a list of Google Compute zones that are UP in a region
#Data needed per region
data "google_compute_zones" "available-tokyo" {
  status = "UP"
  region = "asia-northeast1" /*(optional if provider default is set)*/
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_instance_group_manager
# Resource: Managed Instance Group
resource "google_compute_region_instance_group_manager" "app01-prod" {
  depends_on         = [google_compute_router_nat.nat-tokyo-app01]
  name               = "app01-mig-prod"
  base_instance_name = "app01-prod"
  region             = "asia-northeast1" /*(optional if provider default is set)*/

  # Compute zones to be used for VM creation
  distribution_policy_zones = data.google_compute_zones.available-tokyo.names

  # Instance Template
  version {
    instance_template = google_compute_region_instance_template.app-tokyo.self_link
  }

  # Named Port
  named_port {
    name = "webserver"
    port = 80
  }

  # Autohealing Config
  auto_healing_policies {
    health_check      = google_compute_region_health_check.app01-tokyo.id
    initial_delay_sec = 300
  }
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_autoscaler
# Resource: MIG Autoscaling
resource "google_compute_region_autoscaler" "app01-prod" {
  name   = "app-autoscaler"
  target = google_compute_region_instance_group_manager.app01-prod.id
  region = "asia-northeast1" /*(optional if provider default is set)*/

  autoscaling_policy {
    max_replicas    = 4
    min_replicas    = 2
    cooldown_period = 60

    # 50% CPU for autoscaling event
    cpu_utilization {
      target = 0.5
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_health_check
# Resource: Regional Health Check
resource "google_compute_region_health_check" "lb-app01-tokyo" {
  name                = "lb-health-check-app01"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
  region              = "asia-northeast1" /*(optional if provider default is set)*/

  http_health_check {
    request_path = "/index.html"
    port         = 80
  }
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_backend_service
# Resource: Regional Backend Service
resource "google_compute_region_backend_service" "lb-app01-tokyo" {
  name                  = "lb-backend-service-app01-tokyo"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_region_health_check.lb-app01-tokyo.self_link]
  port_name             = "webserver"
  region                = "asia-northeast1" /*(optional if provider default is set)*/
  # This refer TF 10 the Autoscale policy file
  backend {
    group           = google_compute_region_instance_group_manager.app01-prod.instance_group
    capacity_scaler = 1.0
    balancing_mode  = "UTILIZATION"
  }
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address
# Resource: Reserve Regional Static IP Address
resource "google_compute_address" "lb-tokyo" {
  name   = "lb-static-ip-tokyo"
  region = "asia-northeast1"
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_forwarding_rule
# Resource: Regional Forwarding Rule
resource "google_compute_forwarding_rule" "lb-app01-tokyo" {
  name                  = "lb-forwarding-rule-tokyo"
  target                = google_compute_region_target_http_proxy.lb-tokyo.self_link
  port_range            = "80"
  ip_protocol           = "TCP"
  ip_address            = google_compute_address.lb-tokyo.address
  load_balancing_scheme = "EXTERNAL_MANAGED" # Current Gen LB (not classic)
  network               = google_compute_network.prod1.id
  region                = "asia-northeast1"

  # During the destroy process, we need to ensure LB is deleted first, before proxy-only subnet
  #This is in File 3 TF / Subnets proxy subnet for iowa
  depends_on = [google_compute_subnetwork.regional_proxy_subnet_for_prod1]
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_url_map
# Resource: Regional URL Map
resource "google_compute_region_url_map" "lb-tokyo" {
  name            = "lb-url-map-tokyo"
  default_service = google_compute_region_backend_service.lb-app01-tokyo.self_link
  region          = "asia-northeast1"
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_target_http_proxy
# Resource: Regional HTTP Proxy
resource "google_compute_region_target_http_proxy" "lb-tokyo" {
  name    = "lb-http-proxy"
  url_map = google_compute_region_url_map.lb-tokyo.self_link
  region  = "asia-northeast1"
}

output "lb_static_ip_address-tokyo" {
  description    = "The static IP address of the Tokyo load balancer."
  value = "http://${google_compute_address.lb-tokyo.address}"
  #region = "asia-northeast1" /*(optional if provider default is set)*/
}

output "compute_zones-tokyo" {
  # convert set into string delimited by commas (CSV) before output
  value = join(", ", data.google_compute_zones.available-tokyo.names)
}