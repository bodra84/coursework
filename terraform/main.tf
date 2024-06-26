module "vpc_up" {
  source = "./vpc_up"  
  yandex_cloud_token = var.yandex_cloud_token
}

module "image_bkup" {
  source = "./image_bkup" 
  yandex_cloud_token = var.yandex_cloud_token 
}

variable "yandex_cloud_token" {
  type        = string
  description = "Данная переменная хранится в файле terraform.tfstate"
}

output "bastion_nat_ip_address" {
  value = module.vpc_up.bastion_nat_ip_address
}

output "kibana_nat_ip_address" {
  value = module.vpc_up.kibana_nat_ip_address
}

output "zabbix_nat_ip_address" {
  value = module.vpc_up.zabbix_nat_ip_address
}

output "alb_external_ip_address" {
  value = module.vpc_up.alb_external_ip_address
}

output "webserver1_disk_id" {
  value = module.image_bkup.webserver1_disk_id
}

output "webserver2_disk_id" {
  value = module.image_bkup.webserver2_disk_id
}

output "bastion_disk_id" {
  value = module.image_bkup.bastion_disk_id
}

output "elastic_disk_id" {
  value = module.image_bkup.elastic_disk_id
}

output "kibana_disk_id" {
  value = module.image_bkup.kibana_disk_id
}

output "zabbix_disk_id" {
  value = module.image_bkup.zabbix_disk_id
}