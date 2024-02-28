curl -LO https://raw.githubusercontent.com/bitnami/containers/main/bitnami/harbor-portal/docker-compose.yml
curl -L https://github.com/bitnami/containers/archive/main.tar.gz | tar xz --strip=2 containers-main/bitnami/harbor-portal && cp -RL harbor-portal/2/debian-12/config . 
ls -lart 
##Igohlae2
sed -i 's/HARBOR_ADMIN_PASSWORD=bitnami/HARBOR_ADMIN_PASSWORD=Igohlae2/' docker-compose.yml
docker-compose up