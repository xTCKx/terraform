variable "esxi_hostname" {
  type    = string
  default = "192.168.1.7"
}

variable "esxi_hostport" {
  type    = string
  default = "22"
}

variable "esxi_hostssl" {
  type    = string
  default = "443"
}

variable "esxi_username" {
  type    = string
  default = "root"
}

variable "esxi_password" {
  type    = string
  default = "Welkom01!"
}

variable "disk_store" {
  type    = string
  default = "datastore1"
}

variable "vm_memsize" {
  type    = number
  default = 2048
}

variable "vm_numvcpus" {
  type    = number
  default = 1
}

variable "ovf_source" {
  type    = string
  default = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.ova"
}

variable "webserver_count" {
  type    = number
  default = 2
}

variable "virtual_network" {
  type    = string
  default = "VM Network"
}

