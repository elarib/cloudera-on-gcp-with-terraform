provider "google" {
  credentials = "${file("CREDENTIALS_FILE.json")}"
  project = "${var.project_name}"
  region  = "${var.region_name}"
  zone    = "${var.zone_name}"

}

// The cloudera DB

resource "google_sql_database_instance" "cloudera-mysql-instance" {
  name = "cloudera-db"
  database_version = "MYSQL_5_7"

  region  = "${var.region_name}"

  settings {
    tier = "db-n1-standard-1"
    ip_configuration {
      ipv4_enabled = true
      authorized_networks = [
        {
          name = "all"
          value = "0.0.0.0/0"
        }
      ]
    }
  }
}

resource "google_sql_database" "cloudera-db" {
  count      = "${length(var.cloudera_db_list)}"
  name     = "${element(var.cloudera_db_list, count.index)}"
  instance = "${google_sql_database_instance.cloudera-mysql-instance.name}"
}

resource "google_sql_user" "elarib-admin" {
  name     = "${var.cloudera_db_user}"
  instance = "${google_sql_database_instance.cloudera-mysql-instance.name}"
  password = "${var.cloudera_db_password}"
}


resource "google_compute_instance" "cloudera-master" {
 name         = "cloudera-master"
 machine_type = "${var.machine_size}"

 boot_disk {
   initialize_params {
     image = "${var.image_name}"
   }
 }

 network_interface {
   network = "${google_compute_network.elarib_vpc.self_link}"
   subnetwork = "${google_compute_subnetwork.cloudera.self_link}"

     access_config {
      // Include this section to give the VM an external ip address
    }
 }

  
  provisioner "file" {
    source      = "${var.bootstrap_script_path}"
    destination = "/tmp/script.sh"
    connection {
      type        = "ssh"
      host        = "${google_compute_instance.cloudera-master.network_interface.0.access_config.0.nat_ip}"
      user        = "${var.username}"
      timeout     = "5mn"
      private_key = "${file(var.private_key_path)}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "/tmp/script.sh master ${google_sql_database_instance.cloudera-mysql-instance.public_ip_address} ${var.cloudera_db_list[0]} ${var.cloudera_db_user} ${var.cloudera_db_password}",
    ]

    connection {
      type        = "ssh"
      host        = "${google_compute_instance.cloudera-master.network_interface.0.access_config.0.nat_ip}"
      user        = "${var.username}"
      timeout     = "5mn"
      private_key = "${file(var.private_key_path)}"
    }
  }

 metadata = {
   # Terraform cannot handle secure private_key (at least for now :P )
   ssh-keys = "elarib:${file("~/.ssh/id_rsa_gcp.pub")}"
 }
   // Apply the firewall rule to allow external IPs to access this instance
  tags = ["${google_compute_firewall.ingress_cloudera_firewall_rule.target_tags[0]}"]
 
}

resource "google_compute_instance" "cloudera-node" {
 count = 3
 name         = "cloudera-node-${count.index}"
 machine_type = "${var.machine_size}"

 boot_disk {
   initialize_params {
     image = "${var.image_name}"
   }
 }

 network_interface {
   network = "${google_compute_network.elarib_vpc.self_link}"
   subnetwork = "${google_compute_subnetwork.cloudera.self_link}"

     access_config {
      // Include this section to give the VM an external ip address
    }
 }

  # We connect to our instance via Terraform and remotely executes our script using SSH
  provisioner "file" {
    source      = "${var.bootstrap_script_path}"
    destination = "/tmp/script.sh"
    connection {
      type        = "ssh"
      user        = "${var.username}"
      timeout     = "5mn"
      private_key = "${file(var.private_key_path)}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "/tmp/script.sh node",
    ]

    connection {
      type        = "ssh"
      user        = "${var.username}"
      timeout     = "5mn"
      private_key = "${file(var.private_key_path)}"
    }
  }

 metadata = {
   ssh-keys = "elarib:${file("~/.ssh/id_rsa_gcp.pub")}"
 }
   // Apply the firewall rule to allow external IPs to access this instance
  tags = ["${google_compute_firewall.ingress_cloudera_firewall_rule.target_tags[0]}"]
 
}

output "cloudera-db-ip" {
  value = "${google_sql_database_instance.cloudera-mysql-instance.public_ip_address}"
}
output "ip" {
  value = "${google_compute_instance.cloudera-master.network_interface.0.access_config.0.nat_ip}"
}