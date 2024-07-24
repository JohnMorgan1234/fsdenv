terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Crear una red de Docker privada para WireGuard y otros servicios
resource "docker_network" "private_net" {
  name = "private_net"
}

# Harbor
resource "docker_image" "harbor" {
  name = "goharbor/harbor-core:v2.5.0"
}

resource "docker_container" "harbor" {
  image = docker_image.harbor.name
  name  = "harbor"

  networks_advanced {
    name = docker_network.private_net.name
  }

  env = [
    "HARBOR_ADMIN_PASSWORD=Admin12345",
    "HARBOR_DB_PASSWORD=Admin12345"
  ]

  mounts {
    target = "/data"
    source = docker_volume.harbor_data.name
    type   = "volume"
  }
}

resource "docker_volume" "harbor_data" {
  name = "harbor_data"
}

# Gogs
resource "docker_image" "gogs" {
  name = "gogs/gogs:latest"
}

resource "docker_container" "gogs" {
  image = docker_image.gogs.name
  name  = "gogs"

  networks_advanced {
    name = docker_network.private_net.name
  }

  mounts {
    target = "/data"
    source = docker_volume.gogs_data.name
    type   = "volume"
  }
}

resource "docker_volume" "gogs_data" {
  name = "gogs_data"
}

# Jenkins
resource "docker_image" "jenkins" {
  name = "jenkins/jenkins:lts"
}

resource "docker_container" "jenkins" {
  image = docker_image.jenkins.name
  name  = "jenkins"

  networks_advanced {
    name = docker_network.private_net.name
  }

  mounts {
    target = "/var/jenkins_home"
    source = docker_volume.jenkins_home.name
    type   = "volume"
  }
}

resource "docker_volume" "jenkins_home" {
  name = "jenkins_home"
}

# Wireguard VPN
resource "docker_image" "wireguard" {
  name = "linuxserver/wireguard"
}

resource "docker_container" "wireguard" {
  image = docker_image.wireguard.name
  name  = "wireguard"

  capabilities {
    add = ["NET_ADMIN"]
  }

  ports {
    internal = 51820
    external = 51820
    protocol = "udp"
  }

  env = [
    "PUID=1000",
    "PGID=1000",
    "TZ=UTC",
    "SERVERURL=172.28.242.174",  # IP PÚBLICA
    "SERVERPORT=51820",
    "PEERS=1",  # Número de clientes VPN
    "PEERDNS=8.8.8.8",  # Servidor DNS para los clientes
    "INTERNAL_SUBNET=10.13.13.0"
  ]

  mounts {
    target = "/config"
    source = docker_volume.wireguard_config.name
    type   = "volume"
  }

  networks_advanced {
    name = docker_network.private_net.name
  }
}

resource "docker_volume" "wireguard_config" {
  name = "wireguard_config"
}
