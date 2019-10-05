// Configure the Google Cloud provider
provider "google" {
 credentials = "${file("CREDENTIALS_FILE.json")}"
 project     = "ebiz-europe-west5"
 region      = "europe-north1"
}

resource "google_compute_network" "custom_vpc" {
  name = "elarib-terraform-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "custom_subnet" {
  name          = "elarib-tf-subnet"
  ip_cidr_range = "10.2.0.0/16"
  network       = "${google_compute_network.custom_vpc.self_link}"
}

resource "google_compute_firewall" "custom_firewall_rule" {
  name    = "elarib-tf-http-server-firewall"
  network = "${google_compute_network.custom_vpc.name}"

  #enable_logging = true

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports = ["80", "22", "5000"]
  }

  target_tags = ["http-server"]

  source_ranges = ["0.0.0.0/0"]


}


// Terraform plugin for creating random ids
resource "random_id" "instance_id" {
 byte_length = 8
}

// A single Google Cloud Engine instance
resource "google_compute_instance" "default" {
 name         = "elarib-test-vm-${random_id.instance_id.hex}"
 machine_type = "g1-small"
 zone         = "europe-north1-a"

 boot_disk {
   initialize_params {
     image = "debian-cloud/debian-9"
   }
 }

// Make sure flask is installed on all new instances for later steps
 metadata_startup_script = "sudo apt-get update; sudo apt-get install -yq build-essential python-pip rsync; pip install flask"

 network_interface {
   network = "${google_compute_network.custom_vpc.self_link}"
   subnetwork = "${google_compute_subnetwork.custom_subnet.self_link}"

     access_config {
      // Include this section to give the VM an external ip address
    }
 }

 metadata = {
   ssh-keys = "elarib:${file("~/.ssh/id_rsa.pub")}"
 }

   // Apply the firewall rule to allow external IPs to access this instance
  tags = ["${google_compute_firewall.custom_firewall_rule.target_tags[0]}"]
 
}

// A variable for extracting the external ip of the instance
output "ip" {
  value = "${google_compute_instance.default.network_interface.0.access_config.0.nat_ip}"
}