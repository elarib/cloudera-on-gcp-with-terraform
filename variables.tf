variable "project_name" {
  type        = "string"
  description = "The name of the project to instanciate the instance at."
  default     = "ebiz-europe-west5"
}

variable "region_name" {
  type        = "string"
  description = "The region that this terraform configuration will instanciate at."
  default     = "europe-north1"
}

variable "zone_name" {
  type        = "string"
  description = "The zone that this terraform configuration will instanciate at."
  default     = "europe-north1-a"
}

variable "machine_size" {
  type        = "string"
  description = "The size that this instance will be."
  default     = "n1-standard-2"
}

variable "image_name" {
  type        = "string"
  description = "The kind of VM this instance will become"
  default     = "centos-cloud/centos-7-v20190916"
}

variable "bootstrap_script_path" {
  type        = "string"
  description = "Where is the path to the script locally on the machine?"
  default     = "./scripts/bootstrap-cloudera-instance.sh"
}

variable "private_key_path" {
  type        = "string"
  description = "The path to the private key used to connect to the instance"
  default     = "~/.ssh/id_rsa_gcp"
}

variable "username" {
  type        = "string"
  description = "The name of the user that will be used to remote exec the script"
  default     = "elarib"
}

variable "cloudera_db_list" {
  default = [
    "cloudera-db",
    "hive-db",
    "oozie-db"
  ]
}
variable "cloudera_db_user" {
  default = "elarib"
}

variable "cloudera_db_password" {
  default = "changeme"
}
