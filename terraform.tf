variable "do_token" {}

provider "digitalocean" {
  token = "${var.do_token}"
}

resource "digitalocean_kubernetes_cluster" "sikademo" {
  name    = "sikademo"
  region  = "fra1"
  version = "1.14.5-do.0"

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb"
    node_count = 3
  }
}


resource "digitalocean_loadbalancer" "sikademo" {
  name = "sikademo"
  region = "fra1"

  droplet_tag = "k8s:${digitalocean_kubernetes_cluster.sikademo.id}"

  healthcheck {
    port = 30001
    protocol = "tcp"
  }

  forwarding_rule {
    entry_port  = 80
    target_port = 30001
    entry_protocol = "tcp"
    target_protocol = "tcp"
  }

  forwarding_rule {
    entry_port  = 443
    target_port = 30002
    entry_protocol = "tcp"
    target_protocol = "tcp"
  }

  forwarding_rule {
    entry_port  = 8080
    target_port = 30003
    entry_protocol = "tcp"
    target_protocol = "tcp"
  }
}

output "kubeconfig" {
  value = "${digitalocean_kubernetes_cluster.sikademo.kube_config.0.raw_config}"
}
