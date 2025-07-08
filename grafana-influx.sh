#!/bin/bash

# Grafana + InfluxDB Installer for Rust Server Metrics (v.1.0.3) by lilciv

#Root user check
RootCheck() {
    if [ "$EUID" -ne 0 ]
      then echo "Current user is not root! Please rerun this script as the root user."
      exit
    else
      Dependencies
    fi
}

#Install Docker & Docker Compose
Dependencies() {
    sudo apt install ca-certificates curl gnupg lsb-release -y
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install docker-ce docker-ce-cli containerd.io -y
    sudo apt install docker-compose-plugin -y
    docker network create web
    DBCreds
}

#Get InfluxDB Credentials
DBCreds() {
    clear
    echo
    read -p 'InfluxDB Username: ' dbuser
    read -sp 'InfluxDB Password: ' dbpass
    dbadminpass="$(tr -dc '[:alpha:]' < /dev/urandom | fold -w ${1:-20} | head -n1)"
    DomainNames
}

#Get Domain Names
DomainNames() {
    clear
    echo
    read -p 'Grafana Domain (eg. grafana.example.com): ' grafanadomain
    read -p 'InfluxDB Domain (eg. influx.example.com): ' influxdomain
    AcmeClient
}

#Install acme.sh
AcmeClient() {
    echo "Installing acme.sh..."
    apt install socat -y
    curl https://get.acme.sh | sh
    SSL
}

#Obtain Let's Encrypt Certificate
SSL() {
    clear
    mkdir -p /etc/letsencrypt/live/$grafanadomain
    /root/.acme.sh/./acme.sh --set-default-ca --server letsencrypt
    /root/.acme.sh/./acme.sh --issue -d $grafanadomain -d $influxdomain --standalone --key-file /etc/letsencrypt/live/$grafanadomain/privkey.pem --fullchain-file /etc/letsencrypt/live/$grafanadomain/fullchain.pem --reloadcmd "docker restart InfluxDB && docker restart Grafana"
    echo
    echo
    read -n1 -p "Did your certificate obtain correctly? (You can ignore the reload error) [y,n]" correct
    case $correct in  
      y|Y) InfluxDB ;; 
      n|N) SSL ;; 
      *) exit ;; 
    esac
}

#Deploy InfluxDB
InfluxDB() {
    clear
    docker run -d --network web -p 8086:8086 --name InfluxDB --log-opt max-size=50m --restart unless-stopped -v /etc/letsencrypt/live/$grafanadomain:/etc/ssl -v /root/Docker/Volumes/InfluxDB/influxdb:/var/lib/influxdb -e INFLUXDB_DB=db01 -e INFLUXDB_HTTP_AUTH_ENABLED=true -e INFLUXDB_USER=$dbuser -e INFLUXDB_USER_PASSWORD=$dbpass -e INFLUXDB_ADMIN_USER=influxadmin -e INFLUXDB_ADMIN_PASSWORD=$dbadminpass -e INFLUXDB_HTTP_HTTPS_ENABLED=true -e INFLUXDB_HTTP_HTTPS_CERTIFICATE="/etc/ssl/fullchain.pem" -e INFLUXDB_HTTP_HTTPS_PRIVATE_KEY="/etc/ssl/privkey.pem" -e INFLUXDB_DATA_MAX_VALUES_PER_TAG=0 -e INFLUXDB_DATA_MAX_SERIES_PER_DATABASE=0 influxdb:1.8
    GrafanaProvision
}

GrafanaProvision() {
    mkdir -p /root/Docker/Volumes/Grafana/provisioning/datasources
    cat > /root/Docker/Volumes/Grafana/provisioning/datasources/influx.yml << EOF
apiVersion: 1

datasources:
- name: RSMInfluxDB
  type: influxdb
  access: proxy
  url: https://InfluxDB:8086
  user: $dbuser
  database: db01
  basicAuth: false
  isDefault: true
  jsonData:
     tlsAuth: false
     tlsAuthWithCACert: false
     dbName: db01
     tlsSkipVerify: true
  secureJsonData:
    password: $dbpass
    tlsCACert: ""
    tlsClientCert: ""
    tlsClientKey: ""
  version: 1
  editable: true
EOF
    Grafana
}

#Deploy Grafana
Grafana() {
    docker run -d --network web --name Grafana --user 0 --restart unless-stopped -p 443:3000 -v /root/Docker/Volumes/Grafana:/var/lib/grafana -v /etc/letsencrypt/live/$grafanadomain:/etc/ssl/ -v /root/Docker/Volumes/Grafana/provisioning:/etc/grafana/provisioning -e GF_SERVER_CERT_FILE=/etc/ssl/fullchain.pem -e GF_SERVER_CERT_KEY=/etc/ssl/privkey.pem -e GF_SERVER_PROTOCOL=https grafana/grafana:12.0.2
    Finish
}

#Cleanup + Finalize
Finish() {
    docker restart InfluxDB
    docker restart Grafana
    sleep 3
    docker exec InfluxDB influx -unsafeSsl -ssl -username influxadmin -password $dbadminpass -execute 'ALTER RETENTION POLICY "autogen" ON "db01" DURATION 4w SHARD DURATION 24h'
    clear
    echo
    echo Installation complete!
    echo
    echo Your Grafana dashboard is located at https://$grafanadomain
    echo It has already been configured with your InfluxDB data source! You can now import the latest RSM dashboard from https://github.com/Pinkstink-Rust/Rust-Server-Metrics/releases/latest
    echo The default login is admin/admin. Please change this.
    echo
    echo
    echo Your InfluxDB instance is located at https://$influxdomain:8086
    echo
    echo Here is your Rust Server Metrics config below. Just adjust the Server Tag portion:
    echo
    echo
    cat <<EOF
{
  "Enabled": true,
  "Influx Database Url": "https://$influxdomain:8086",
  "Influx Database Name": "db01",
  "Influx Database User": "$dbuser",
  "Influx Database Password": "$dbpass",
  "Server Tag": "CHANGE-ME",
  "Debug Logging": false,
  "Amount of metrics to submit in each request": 1000,
  "Gather Player Averages (Client FPS, Client Latency, Player FPS, Player Memory, Player Latency, Player Packet Loss)": true
}
EOF
    echo
}

RootCheck
