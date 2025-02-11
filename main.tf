terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.88"
    }
  }
}
provider "yandex" {
  token     = "y0__xCA449iGMHdEyCzqcmQEs4kHSEniIHGPEh9fmU9cSN6S_2z"
  cloud_id  = "b1g2plbt4oav513ephpl"
  folder_id = "b1gjm8ap3mu8tgq2irn5"
  zone      = "ru-central1-a"
}

resource "yandex_compute_disk" "boot-disk" {
  count    = 3
  name     = "boot-disk-${count.index}"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  size     = "13"
  image_id = "fd81n0sfjm6d5nq6l05g"
}


resource "yandex_compute_instance" "logbroker" {
  count = 2
  name  = "logbroker-${count.index}"

  resources {
    cores         = 2
    memory        = 3
    core_fraction = 20
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk[count.index].id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  allow_stopping_for_update = true
}

resource "yandex_compute_instance" "clickhouse" {
  name = "clickhouse"

  resources {
    cores         = 2
    memory        = 3
    core_fraction = 20
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk[2].id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  allow_stopping_for_update = true
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

output "internal_ip_addresses_logbroker" {
  value = yandex_compute_instance.logbroker[*].network_interface.0.ip_address
}

output "internal_ip_addresses_clickhouse" {
  value = yandex_compute_instance.clickhouse.network_interface.0.ip_address
}

output "external_ip_addresses_logbroker" {
  value = yandex_compute_instance.logbroker[*].network_interface.0.nat_ip_address
}

output "external_ip_addresses_clickhouse" {
  value = yandex_compute_instance.clickhouse.network_interface.0.nat_ip_address
}
