WORK IN PROGRESS

# Fast and Simple Development Env

FSDENV  (Fast and Simple Development Env) is intentded as a friendly and easy framework to start a small and self-hosted development environment

* Harbor: As a docker Registry
* Gogs: As a github style repository
* GoCD: As CI/CD 
* Wireguard VPN: To access securely the network where everything resides

## Requirements:
* docker-compose
* docker engine

## How to deploy:
* Clone the repo
* Run 
```BASH
sudo chown $(whoami): /var/run/docker.sock
```
* Run
```BASH
./starter.sh
```
