resource "google_compute_network" "elarib_vpc" {
  name = "elarib-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "cloudera" {
  name          = "cloudera-subnet"
  ip_cidr_range = "10.1.0.0/16"
  network       = "${google_compute_network.elarib_vpc.self_link}"
}


resource "google_compute_firewall" "ingress_cloudera_firewall_rule" {
  name    = "cloudera-firewall-ingress"
  network = "${google_compute_network.elarib_vpc.name}"

  #enable_logging = true

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    # Yes i know ... In fact, there is plenty of ports used by cloudera ... so it's to #TOFIX for now
    ports = ["22-9999"]
  }

  target_tags = ["cloudera-instance"]

  source_ranges = ["0.0.0.0/0"]

}