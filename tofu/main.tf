terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    null = {
      source = "hashicorp/null"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

locals {
  masters = 3
  agents = 2
  labels = {
    "k8s-cluster" : random_id.cluster.hex
    "tailscale" : "yes"
  }
}

resource "random_id" "cluster" {
  byte_length = 2
}

resource "hcloud_ssh_key" "default" {
  name       = "default"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIzm5RyD+1nfy1LquvkEog4SZtPgdhzjr49jSC8PAinp"
}

resource "hcloud_server" "master-0" {
  name        = "master-${random_id.cluster.hex}-0"
  image       = "ubuntu-22.04" # just to get the server started
  server_type = "cpx11"          # AMD 2 vCPU, 2 GB RAM, 40 GB NVMe SSD
  location    = "hel1"
  ssh_keys    = [hcloud_ssh_key.default.id]
  labels = local.labels
  user_data = <<-EOF
  if [ -e /etc/generated-hostname ]; then
    exit 0
  fi
  echo master-${random_id.cluster.hex}-0 > /etc/generated-hostname
  EOF
}

resource "hcloud_server" "master" {
  for_each    = toset([for i in range(1, local.masters): tostring(i)])
  name        = "master-${random_id.cluster.hex}-${each.key}"
  image       = "ubuntu-22.04" # just to get the server started
  server_type = "cpx11"          # AMD 2 vCPU, 2 GB RAM, 40 GB NVMe SSD
  location    = "hel1"
  labels = local.labels
  ssh_keys    = [hcloud_ssh_key.default.id]
  depends_on = [hcloud_server.master-0]
  user_data = <<-EOF
  if [ -e /etc/generated-hostname ]; then
    exit 0
  fi
  echo master-${random_id.cluster.hex}-${each.key} > /etc/generated-hostname
  EOF
}

resource "hcloud_server" "agent" {
  for_each    = toset([for i in range(0, local.agents): tostring(i)])
  name        = "agent-${random_id.cluster.hex}-${each.key}"
  image       = "ubuntu-22.04" # just to get the server started
  server_type = "cpx11"          # AMD 2 vCPU, 2 GB RAM, 40 GB NVMe SSD
  location    = "hel1"
  labels = local.labels
  ssh_keys    = [hcloud_ssh_key.default.id]
  depends_on = [hcloud_server.master-0]
  user_data = <<-EOF
  if [ -e /etc/generated-hostname ]; then
    exit 0
  fi
  echo agent-${random_id.cluster.hex}-${each.key} > /etc/generated-hostname
  EOF
}

module "master-init-system-build" {
  source            = "github.com/nix-community/nixos-anywhere//terraform/nix-build"
  attribute         = ".#nixosConfigurations.hcloud-k3s-master-init.config.system.build.toplevel"
}

module "master-system-build" {
  source            = "github.com/nix-community/nixos-anywhere//terraform/nix-build"
  attribute         = ".#nixosConfigurations.hcloud-k3s-master.config.system.build.toplevel"
}

module "agent-system-build" {
  source            = "github.com/nix-community/nixos-anywhere//terraform/nix-build"
  attribute         = ".#nixosConfigurations.hcloud-k3s-agent.config.system.build.toplevel"
}

module "master-init-disko" {
  source         = "github.com/nix-community/nixos-anywhere//terraform/nix-build"
  attribute      = ".#nixosConfigurations.hcloud-k3s-master-init.config.system.build.diskoScript"
}

module "master-disko" {
  source         = "github.com/nix-community/nixos-anywhere//terraform/nix-build"
  attribute      = ".#nixosConfigurations.hcloud-k3s-master.config.system.build.diskoScript"
}

module "agent-disko" {
  source         = "github.com/nix-community/nixos-anywhere//terraform/nix-build"
  attribute      = ".#nixosConfigurations.hcloud-k3s-agent.config.system.build.diskoScript"
}

module "master-init-install" {
  source            = "github.com/nix-community/nixos-anywhere//terraform/install"
  nixos_system      = module.master-init-system-build.result.out
  nixos_partitioner = module.master-init-disko.result.out
  target_host       = hcloud_server.master-0.ipv4_address
  disk_encryption_key_scripts = [
    {
      path = "/tmp/disk.key"
      script = "./disk-encryption-key.sh"
    }
  ]
  extra_files_script = "./extra-files-script.sh"
}

module "master-install" {
  for_each    = toset([for i in range(1, local.masters): tostring(i)])  
  source            = "github.com/nix-community/nixos-anywhere//terraform/install"
  nixos_system      = module.master-system-build.result.out
  nixos_partitioner = module.master-disko.result.out
  target_host       = hcloud_server.master[each.key].ipv4_address
  disk_encryption_key_scripts = [
    {
      path = "/tmp/disk.key"
      script = "./disk-encryption-key.sh"
    }
  ]
  extra_files_script = "./extra-files-script.sh"
}

module "agent-install" {
  for_each    = toset([for i in range(0, local.agents): tostring(i)])
  source            = "github.com/nix-community/nixos-anywhere//terraform/install"
  nixos_system      = module.agent-system-build.result.out
  nixos_partitioner = module.agent-disko.result.out
  target_host       = hcloud_server.agent[each.key].ipv4_address
  disk_encryption_key_scripts = [
    {
      path = "/tmp/disk.key"
      script = "./disk-encryption-key.sh"
    }
  ]
  extra_files_script = "./extra-files-script.sh"
}

output "public_ip" {
  value = hcloud_server.master-0.ipv4_address
}