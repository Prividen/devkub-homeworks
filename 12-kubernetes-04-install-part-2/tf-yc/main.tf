terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.69.0"
    }
  }
}

provider "yandex" {
  cloud_id  = "b1gh0k7cb2gn2mh9i1uc"
  folder_id = "b1g200bppkibol684gqj"
  zone      = "ru-central1-a"
}


data "yandex_vpc_subnet" "default-subnet" {
  name = "default-ru-central1-a"
}

data "yandex_compute_image" "centos7" {
  family = "centos-7"
}

data "yandex_compute_image" "centos8" {
  family = "centos-8"
}

data "yandex_compute_image" "ubuntu-latest" {
  family = "ubuntu-2004-lts"
}


resource "yandex_compute_instance" "kube_control_plane" {
  count = 1
  name = "kb-control-${count.index}"
  hostname = "kb-control-${count.index}"

  resources {
    cores  = 4
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.centos8.id
      type = "network-ssd-nonreplicated"
      size = 93
    }
  }

  network_interface {
    subnet_id = data.yandex_vpc_subnet.default-subnet.id
    nat       = true
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    ssh-keys = "cloud-user:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_compute_instance" "kube_node" {
  count = 5
  name = "kb-worker-${count.index}"
  hostname = "kb-worker-${count.index}"

  resources {
    cores  = 4
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.centos8.id
      type = "network-hdd"
      size = 96
//      type = "network-ssd-nonreplicated"
//      size = 93
    }
  }

  network_interface {
    subnet_id = data.yandex_vpc_subnet.default-subnet.id
    nat       = true
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    ssh-keys = "cloud-user:${file("~/.ssh/id_rsa.pub")}"
  }
}


resource "yandex_dns_zone" "kb1" {
  name  = "kb1-yc-complife"
  zone  = "kb1.yc.complife.ru."
  public  = true
}


resource "yandex_dns_recordset" "control-recordset" {
  for_each = { for k, v in yandex_compute_instance.kube_control_plane: k => v }
  zone_id = yandex_dns_zone.kb1.id
  name    = each.value.hostname
  type    = "A"
  ttl     = 200
  data    = [each.value.network_interface.0.nat_ip_address]
}

resource "yandex_dns_recordset" "worker-recordset" {
  for_each = { for k, v in yandex_compute_instance.kube_node: k => v }
  zone_id = yandex_dns_zone.kb1.id
  name    = each.value.hostname
  type    = "A"
  ttl     = 200
  data    = [each.value.network_interface.0.nat_ip_address]
}

output "Control_nodes" {
  value = {
    for k, v in yandex_compute_instance.kube_control_plane :
      "${v.hostname}.${yandex_dns_zone.kb1.zone}" => "${v.network_interface.0.nat_ip_address} / ${v.network_interface.0.ip_address}"
  }
}

output "Worker_nodes" {
  value = {
    for k, v in yandex_compute_instance.kube_node :
      "${v.hostname}.${yandex_dns_zone.kb1.zone}" => "${v.network_interface.0.nat_ip_address} / ${v.network_interface.0.ip_address}"
  }
}

output "supplementary_addresses_in_ssl_keys" {
  value = yandex_compute_instance.kube_control_plane.*.network_interface.0.nat_ip_address
}

