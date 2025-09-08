terraform {
  required_providers {
    esxi = {
      source = "registry.terraform.io/josenk/esxi"
    }
  }
}

provider "esxi" {
  esxi_hostname = var.esxi_hostname
  esxi_hostport = var.esxi_hostport
  esxi_hostssl  = "443"
  esxi_username = "root"
  esxi_password = "Welkom01!"
}

resource "esxi_guest" "webserver" {
  count      = 2
  guest_name = "webserver+${count.index + 1}"
  disk_store = "datastore1"
  memsize    = 2048
  numvcpus   = 1

  ovf_source = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.ova"
  network_interfaces {
    virtual_network = "VM Network"
  }

  guestinfo = {
    "metadata"          = filebase64("metadata.yaml")
    "metadata.encoding" = "base64"
    "userdata"          = filebase64("userdata.yaml")
    "userdata.encoding" = "base64"
  }

}

resource "esxi_guest" "databaseserver" {
  guest_name = "databaseserver"
  disk_store = "datastore1"
  memsize    = 2048
  numvcpus   = 1

  ovf_source = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.ova"
  network_interfaces {
    virtual_network = "VM Network"
  }

  guestinfo = {
    "metadata"          = filebase64("metadata.yaml")
    "metadata.encoding" = "base64"
    "userdata"          = filebase64("userdata.yaml")
    "userdata.encoding" = "base64"
  }


}






##guestinfo base64
