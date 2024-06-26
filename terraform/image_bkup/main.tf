terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

variable "yandex_cloud_token" {
  type        = string
}

provider "yandex" {
  token     = var.yandex_cloud_token
  cloud_id  = "b1g4hl204viqn59ct85b"
  folder_id = "b1g010mi049m159v5u2f"
  zone      = "ru-central1-a"
}

#webserver1 disk_id
data "yandex_compute_instance" "webserver1" {
  name = "webserver1"
} 

output "webserver1_disk_id" {
  value = "${data.yandex_compute_instance.webserver1.boot_disk[0].disk_id}"
}

#webserver2 disk_id
data "yandex_compute_instance" "webserver2" {
  name = "webserver2"
} 

output "webserver2_disk_id" {
  value = "${data.yandex_compute_instance.webserver2.boot_disk[0].disk_id}"
}

#bastion disk_id
data "yandex_compute_instance" "bastion" {
  name = "bastion"
}

output "bastion_disk_id" {
  value = "${data.yandex_compute_instance.bastion.boot_disk[0].disk_id}"
}

#elasticsearch disk_id
data "yandex_compute_instance" "elastic" {
  name = "elastic"
}

output "elastic_disk_id" {
  value = "${data.yandex_compute_instance.elastic.boot_disk[0].disk_id}"
}

#kibana disk_id
data "yandex_compute_instance" "kibana" {
  name = "kibana"
}

output "kibana_disk_id" {
  value = "${data.yandex_compute_instance.kibana.boot_disk[0].disk_id}"
}

#zabbix_server disk_id
data "yandex_compute_instance" "zabbix" {
  name = "zabbix"
}  

output "zabbix_disk_id" {
  value = "${data.yandex_compute_instance.zabbix.boot_disk[0].disk_id}"
}

resource "yandex_compute_snapshot_schedule" "myvpc" {
  name           = "myvpc"

  schedule_policy {
	expression = "30 21 ? * *" # time in UTC±0:00
  }

  snapshot_count = 7
    
  disk_ids = [
    data.yandex_compute_instance.webserver1.boot_disk[0].disk_id, 
    data.yandex_compute_instance.webserver2.boot_disk[0].disk_id,
    data.yandex_compute_instance.bastion.boot_disk[0].disk_id,
    data.yandex_compute_instance.elastic.boot_disk[0].disk_id,
    data.yandex_compute_instance.kibana.boot_disk[0].disk_id,
    data.yandex_compute_instance.zabbix.boot_disk[0].disk_id
    ]
}