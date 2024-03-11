# WG prototype 0.2.1
# ----------------------------------------------------------------
# This is just a prototype but for now is all we need in order to generate the tunnels 
# with the proper access credentials and PNG images with QR codes and send that information to the API.



WG_IMAGE="lscr.io/linuxserver/wireguard:latest"

PUBLIC_IP_ADDR=$(curl -s ifconfig.io)
COUNTRY_CODEV2=$(curl -s ifconfig.io/country_code)
OWNER=$(hostname)
CONFIG_DIR="/tmp/config"
INT_SUBNET="10.11.12.0"
PEERS=1
SERVERS=1
TOKEN="eyJH63926714455c64.6319141863926714455ea8.4761803263926714455f18.4944500763926714455f39.13215356"
LOGS_PATH="/tmp/tunnel_factory/"
RESPONSE_FILE="response"


function is_installed() {
	pkg=$1 
	installed=$(which ${pkg}|wc -l)
	if [ "${installed}" -lt "1" ]; then 
		echo ">>>> ${pkg} IS NOT INSTALLED"
		exit 4
	else
		echo ">>>> ${pkg} is installed on the system ..... [OK]"
	fi

}

function checks() {
	# check if cfgs dir exists
	if [ ! -d ${CONFIG_DIR} ]
		then 
		echo ">> Configs directory does not exists, creating ....."
		mkdir ${CONFIG_DIR}
	fi
	# check for dependencies
	deps=("jq" "jo" "pwgen" "qrencode") # remove pwgen if not used since it's not available in AmzLinux2 image
	# deps=("jq" "jo" "pwgen")
	for dep in ${deps[@]}
	do
		echo ">> Checking dependency ${dep} .... "
		is_installed ${dep}
	done
}

function pwgen() {
  local characters="abcdefghijklmnopqrstuvwxyz0123456789"
  local password=""

  for i in {1..6}; do
    random_char="${characters:RANDOM % ${#characters}:1}"
    password="${password}${random_char}"
  done

  echo "$password"
}

function create_if_not_exist() {
	DIR_PATH=$1
	if [ ! -d ${DIR_PATH} ]
		then 
		echo ">> Container config directory [$DIR_PATH] does not exists, creating ....."
		mkdir ${DIR_PATH}
	fi
}

function gen_post_data() {
	CF=$1
	QR=$2
	CC=$3
	IP=$4
	if [ $# -lt "3" ]
	then
		echo ">> ERROR: missing data in JSON obj"
		exit 3
	fi	
	jo config_file=${CF} qr_code=${QR} country_code=${CC} public_ipv4=${IP}
}




function get_cfg() {
	echo ">> Getting CFG for $1 ........."
	sleep 3
	CFG_FILE=$(cat $1/peer1/peer1.conf | base64 | xargs | sed "s| ||g")
	echo $CFG_FILE > /tmp/tunnel.b64
	echo ">> Data saved on /tmp/tunnel.b64"
	
}

function random_port() {
	MIN_PORT_RANGE=10000
	MAX_PORT_RANGE=20000
	shuf -i ${MIN_PORT_RANGE}-${MAX_PORT_RANGE} -n 1 | head -n 1
}

function launch_container() {

	RND_STRING=$(pwgen) # If working with AMZLinux2 just calling the pwgen function :_)
	# RND_STRING=$(pwgen -A1)
	RND_PORT=$(random_port)
	CONTAINER_NAME="tunnel-${RND_STRING}"
	tunnel_id=$1

	create_if_not_exist ${CONFIG_DIR}/${CONTAINER_NAME}

	docker run -d \
	  --name=${CONTAINER_NAME} \
	  --cap-add=NET_ADMIN \
	  --cap-add=SYS_MODULE \
	  -e PUID=1000 \
	  -e PGID=1000 \
	  -e TZ=Europe/London \
	  -e SERVERURL=${PUBLIC_IP_ADDR}  \
	  -e SERVERPORT=${RND_PORT}  \
	  -e PEERS=${PEERS} \
	  -e PEERDNS=10.11.12.1  \
	  -e INTERNAL_SUBNET=${INT_SUBNET}  \
	  -e ALLOWEDIPS=172.20.0.0/16  \
	  -e LOG_CONFS=true  \
	  -p ${RND_PORT}:51820/udp \
	  -v ${CONFIG_DIR}/${CONTAINER_NAME}/:/config \
	  -v /lib/modules:/lib/modules \
	  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
	  --sysctl="net.ipv4.ip_forward=1" \
	  --restart unless-stopped \
	  ${WG_IMAGE}

	get_cfg ${CONFIG_DIR}/${CONTAINER_NAME}
}


function create_qrcode(){
	decoded_tunnel=$(base64 -d /tmp/tunnel.b64)
	qrencode -o tunnel.png -l L "${decoded_tunnel}"
	echo ">> Tunnel QR Code saved on ./tunnel.png"
}


checks
for server in $(seq 1 ${SERVERS})
do
	echo ">> Launching container ${server} ............... [OK]"
	launch_container	
done
create_qrcode