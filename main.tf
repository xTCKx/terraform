terraform {
  required_providers {
    esxi = {
      source = "registry.terraform.io/josenk/esxi"
    }
  }
}

provider "esxi" {
  esxi_hostname = "192.168.1.7"
  esxi_hostport = "22"
  esxi_hostssl  = "443"
  esxi_username = "root"
  esxi_password = "Welkom01!"
}

resource "esxi_guest" "vmtest" {
  guest_name = "vmtest"
  disk_store = "datastore1"
  memsize    = 1024
  numvcpus   = 1


  ovf_source = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.ova"
  network_interfaces {
    virtual_network = "VM Network"
  }
}


##guestinfo base64