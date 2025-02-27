variable "do_token" {}
variable "cloudflare_email" {}
variable "cloudflare_token" {}


provider "digitalocean" {
  token = "${var.do_token}"
}

provider "cloudflare" {
  version = "~> 1.0"
  email = "${var.cloudflare_email}"
  token = "${var.cloudflare_token}"
}


resource "digitalocean_kubernetes_cluster" "sikademo" {
  name    = "sikademo"
  region  = "fra1"
  version = "1.15.4-do.0"

  node_pool {
    name       = "sikademo"
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


resource "cloudflare_record" "k8s" {
  domain = "sikademo.com"
  name   = "k8s"
  value  = "${digitalocean_loadbalancer.sikademo.ip}"
  type   = "A"
  proxied = false
}

resource "cloudflare_record" "k8s_wildcard" {
  domain = "sikademo.com"
  name   = "*.k8s"
  value  = "k8s.sikademo.com"
  type   = "CNAME"
  proxied = false
}


output "kubeconfig" {
  value = "${digitalocean_kubernetes_cluster.sikademo.kube_config.0.raw_config}"
}
