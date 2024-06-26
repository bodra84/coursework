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

#webserver
resource "yandex_compute_instance" "webserver" {
  count       = 2
  name        = "webserver${count.index + 1}"
  hostname    = "webserver${count.index + 1}"
  platform_id = "standard-v3"
  zone        = "ru-central1-${count.index == 0? "a" : "b"}"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }
  
  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4a9mnca2bmgol2r8"
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = count.index == 0? yandex_vpc_subnet.web-sub-a.id : yandex_vpc_subnet.web-sub-b.id  
    security_group_ids = [ yandex_vpc_security_group.web-sg.id, yandex_vpc_security_group.sg-internet.id ]    
  }

  metadata = {
    user-data = "${file("./metadata/meta_web.yml")}"
  }
}

#bastion
resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  hostname    = "bastion"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }
  
  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = "fd806u1okplml22f4pmo"
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {    
    subnet_id          =  yandex_vpc_subnet.external-sub-a.id     
    security_group_ids = [ yandex_vpc_security_group.bastion-sg.id, yandex_vpc_security_group.sg-internet.id ]  
    nat                = true  
  }
  
  metadata = {
    user-data = "${file("./metadata/meta_bastion.yml")}"
  }
}

output "bastion_nat_ip_address" {
  value = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}

#elasticsearch
resource "yandex_compute_instance" "elastic" {
  name        = "elastic"
  hostname    = "elastic"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 4
    memory        = 4
    core_fraction = 20
  }
  
  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4a9mnca2bmgol2r8"
      size     = 15
      type     = "network-hdd"
    }
  }

  network_interface {    
    subnet_id          =  yandex_vpc_subnet.web-sub-a.id     
    security_group_ids = [ yandex_vpc_security_group.elastic-sg.id, yandex_vpc_security_group.sg-internet.id ]      
  }
  
  metadata = {
    user-data = "${file("./metadata/meta_web.yml")}"
  }
}

#kibana
resource "yandex_compute_instance" "kibana" {
  name        = "kibana"
  hostname    = "kibana"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }
  
  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4a9mnca2bmgol2r8"
      size     = 15
      type     = "network-hdd"
    }
  }

  network_interface {    
    subnet_id          = yandex_vpc_subnet.external-sub-a.id    
    security_group_ids = [ yandex_vpc_security_group.kibana-sg.id, yandex_vpc_security_group.sg-internet.id ]  
    nat = true    
  }
  
  metadata = {
    user-data = "${file("./metadata/meta_web.yml")}"
  }
}

output "kibana_nat_ip_address" {
  value = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}

#zabbix_server
resource "yandex_compute_instance" "zabbix" {
  name        = "zabbix"
  hostname    = "zabbix"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }
  
  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4a9mnca2bmgol2r8"
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {    
    subnet_id          = yandex_vpc_subnet.external-sub-a.id    
    security_group_ids = [ yandex_vpc_security_group.zabbix-sg.id, yandex_vpc_security_group.sg-internet.id ]  
    nat = true    
  }
  
  metadata = {
    user-data = "${file("./metadata/meta_web.yml")}"
  }
}

output "zabbix_nat_ip_address" {
  value = yandex_compute_instance.zabbix.network_interface.0.nat_ip_address
}

#network
resource "yandex_vpc_network" "bodranet" {
  name = "bodranet"
}

#subnets
resource "yandex_vpc_subnet" "web-sub-a" {
  name = "web-sub-a"
  v4_cidr_blocks = ["10.0.1.0/24"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.bodranet.id
  route_table_id = yandex_vpc_route_table.bastion-route.id
}

resource "yandex_vpc_subnet" "web-sub-b" {
  name = "web-sub-b"
  v4_cidr_blocks = ["10.0.2.0/24"]
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.bodranet.id
  route_table_id = yandex_vpc_route_table.bastion-route.id
}

resource "yandex_vpc_subnet" "external-sub-a" {
  name = "external-sub-a"
  v4_cidr_blocks = ["10.0.3.0/24"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.bodranet.id
}

resource "yandex_vpc_route_table" "bastion-route" {
  name        = "bastion-route"

  depends_on = [ yandex_compute_instance.bastion ]

  network_id = yandex_vpc_network.bodranet.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.bastion.network_interface.0.ip_address
  }
}

#security_ for internet
resource "yandex_vpc_security_group" "sg-internet" {
  name        = "sg-internet"
  network_id  = yandex_vpc_network.bodranet.id

  egress {
    protocol       = "ANY"    
    v4_cidr_blocks = ["0.0.0.0/0"] 
    from_port      = 0
    to_port        = 65535 
  }

  ingress {
    protocol       = "ICMP"    
    v4_cidr_blocks = ["0.0.0.0/0"] 
  }
}

#security_group for bastion
resource "yandex_vpc_security_group" "bastion-sg" {
  name        = "bastion security group"
  network_id  = yandex_vpc_network.bodranet.id

  ingress {
    protocol          = "ANY"
    from_port         = 0
    to_port           = 65535
    v4_cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]  
  }

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]        
    port           = 22
   }  
}

#security_group for alb
resource "yandex_vpc_security_group" "alb-sg" {
  name        = "alb_load_balancer security group"
  network_id  = yandex_vpc_network.bodranet.id

  ingress {
    protocol       = "TCP"   
    v4_cidr_blocks = ["0.0.0.0/0"]    
    port           = 80
   }

   ingress {
    protocol       = "TCP"   
    v4_cidr_blocks = ["0.0.0.0/0"]    
    port           = 443
   }

   ingress {
    protocol       = "TCP"   
    predefined_target = "loadbalancer_healthchecks"        
    port           = 30080     
   }
}

#security_group for web
resource "yandex_vpc_security_group" "web-sg" {
  name        = "webserver security group"
  network_id  = yandex_vpc_network.bodranet.id
  
  ingress {
    protocol       = "TCP"    
    security_group_id = yandex_vpc_security_group.alb-sg.id
  }

  ingress {
    protocol          = "TCP"      
    security_group_id = yandex_vpc_security_group.bastion-sg.id   
    port              = 22
   }    

  ingress {
    protocol       = "TCP"    
    security_group_id = yandex_vpc_security_group.zabbix-sg.id   
    from_port         = 10050
    to_port           = 10051
  }
}

#security_group for elasticsearch
resource "yandex_vpc_security_group" "elastic-sg" {
  name        = "elastic security group"
  network_id  = yandex_vpc_network.bodranet.id
  
  ingress {
    protocol       = "TCP"    
    v4_cidr_blocks = ["0.0.0.0/0"]  
    port           = 9200
  }

  ingress {
    protocol          = "TCP"      
    security_group_id = yandex_vpc_security_group.bastion-sg.id   
    port              = 22
   }    
}

#security_group for kibana
resource "yandex_vpc_security_group" "kibana-sg" {
  name        = "kibana security group"
  network_id  = yandex_vpc_network.bodranet.id
  
  ingress {
    protocol       = "TCP"    
    v4_cidr_blocks = ["0.0.0.0/0"]  
    port           = 5601
  }

  ingress {
    protocol          = "TCP"      
    security_group_id = yandex_vpc_security_group.bastion-sg.id   
    port              = 22
  }    
}

#security_group for zabbix
resource "yandex_vpc_security_group" "zabbix-sg" {
  name        = "zabbix security group"
  network_id  = yandex_vpc_network.bodranet.id
  
  ingress {
    protocol       = "TCP"    
    v4_cidr_blocks = ["0.0.0.0/0"]  
    from_port         = 10050
    to_port           = 10051
  }

  ingress {
    protocol       = "TCP"    
    v4_cidr_blocks = ["0.0.0.0/0"]  
    port         = 80
  }

  ingress {
    protocol          = "TCP"      
    security_group_id = yandex_vpc_security_group.bastion-sg.id   
    port              = 22
  }    
}

#target group
resource "yandex_alb_target_group" "bodra-tg" {
  name      = "bodra-tg"

  target {
    subnet_id  = yandex_vpc_subnet.web-sub-a.id
    ip_address = yandex_compute_instance.webserver[0].network_interface.0.ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.web-sub-b.id
    ip_address = yandex_compute_instance.webserver[1].network_interface.0.ip_address    
  }
}

#backend group
resource "yandex_alb_backend_group" "bodra-bg" {
  name      = "bodra-bg"

  http_backend {
    name = "bodra-http"
    port = 80
  target_group_ids = [yandex_alb_target_group.bodra-tg.id]
    healthcheck {
      timeout = "10s"
      interval = "2s"
      http_healthcheck {
        path  = "/"
      }
    }
  }
}

#http-router
resource "yandex_alb_http_router" "bodra-rt" {
  name      = "bodra-rt"
}

#virtual host
resource "yandex_alb_virtual_host" "bodra-vh" {
  name      = "bodra-vh"
  http_router_id = yandex_alb_http_router.bodra-rt.id
  route {
    name = "bodra-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.bodra-bg.id
      }
    }
  }
}

#load-balancer
resource "yandex_alb_load_balancer" "bodra-lb" {
  name = "bodra-lb"

  network_id  = yandex_vpc_network.bodranet.id
  security_group_ids = [ yandex_vpc_security_group.alb-sg.id, yandex_vpc_security_group.sg-internet.id ]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.web-sub-a.id
    }
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.web-sub-b.id
    }
  }

  listener {
    name = "bodra-list"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.bodra-rt.id
      }
    }
  }
}

output "alb_external_ip_address" {
  value = yandex_alb_load_balancer.bodra-lb.listener.0.endpoint.0.address.0.external_ipv4_address[0].address
}