variable "digitalocean_token" {}

provider "digitalocean" {
  token = var.digitalocean_token
}

resource "random_string" "token" {
  length = 32
  special = false
}

output "inlets_token" {
  value = random_string.token.result
}

data "template_file" "user_data" {
  template = "${file("user_data.sh.tpl")}"

  vars = {
    inletstoken = random_string.token.result
  }
}

resource "digitalocean_droplet" "inlets_server" {
  image  = "ubuntu-18-04-x64"
  name   = "inlets-exit-node-01"
  region = "LON1"
  size   = "s-1vcpu-1gb"
  user_data = data.template_file.user_data.rendered
}

output "inlet_address" {
  value = digitalocean_droplet.inlets_server.ipv4_address
}

variable cloudflare_email {}

variable cloudflare_token {}

variable cloudflare_zone_id {}

provider "cloudflare" {
  version = "~> 2.0"
  email   = var.cloudflare_email
  api_key = var.cloudflare_token
}

resource "random_pet" "inlets_name" {}

resource "cloudflare_record" "inlets_record" {
  zone_id = var.cloudflare_zone_id
  name    = random_pet.inlets_name.id
  value   = digitalocean_droplet.inlets_server.ipv4_address
  type    = "A"
  proxied = true
}

output "inlet_host" {
  value = cloudflare_record.inlets_record.hostname
}

