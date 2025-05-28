#https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance

#We don't need a service account just for our VM"
/*resource "google_service_account" "default" {
  account_id   = "my-custom-sa"
  display_name = "Custom SA for VM Instance"
}*/

resource "google_compute_instance" "iowahq-vm" {
  name         = "my-instance-5-20-25"
  machine_type = "n2-standard-2"
  zone         = "us-central1-a"

  #We currently don't need a tag
  /*tags = ["foo", "bar"]*/

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      labels = {
        my_label = "value"
      }
    }
  }

  #We don't need the solid state drive right now
  /*// Local SSD disk
  scratch_disk {
    interface = "NVME"
  }*/

  network_interface {
    /*network = "default"*/
    #Specify the subnet when using a custom vpc.
    subnetwork = google_compute_subnetwork.hq-internal-iowa.name
    access_config {
      // Ephemeral public IP
    }
  }

  #Aaron remove this argument/ Look it 
  /*metadata = {
    foo = "bar"
  }*/

  #This is from Terraform Registry example:
  /* metadata_startup_script = "echo hi > /test.txt"*/

  #Aaron suggested using a separate start up file
  metadata_startup_script = file("./startup.sh")

  #This reference the service account that we didn't create above.
  /*service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.default.email
    scopes = ["cloud-platform"]
  }*/
}


resource "google_compute_instance" "sao-paulo1-vm" {
  name         = "my-instance-sao-paulo"
  machine_type = "n2-standard-2"
  zone         = "southamerica-east1-a"


  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      labels = {
        my_label = "value"
      }
    }
  }



  network_interface {

    subnetwork = google_compute_subnetwork.saopaulo.name
    access_config {
      // Ephemeral public IP
    }
  }

  #Aaron suggested using a separate start up file
  metadata_startup_script = file("./startup-dr.sh")

}