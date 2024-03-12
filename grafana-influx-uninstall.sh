#!/bin/bash

# Grafana + InfluxDB Uninstaller (v1.0.0) by lilciv

#Root user check
RootCheck() {
    if [ "$EUID" -ne 0 ]
      then echo "Current user is not root! Please rerun this script as the root user."
      exit
    else
      Confirm
    fi
}

Confirm() {
    clear
    echo "This will delete your Grafana and InfluxDB instanced! Be sure you want to continue."
    read -s -n 1 -p "Press any key to continue . . ."
    echo ""
    DeleteContainers
}

#Delete Containers
DeleteContainers() {
    docker stop Grafana
    docker stop InfluxDB
    docker rm Grafana
    docker rm InfluxDB
    Data
}

#Keep Data?
Data() {
    read -n1 -p "Containers removed. Delete all data? [y,n]" choice
    case $choice in
      y|Y) DeleteData ;;
      n|N) exit ;;
      *) exit ;;
    esac
}

#Delete all data!
DeleteData() {
    rm -rf /root/Docker
    /root/.acme.sh/./acme.sh --uninstall
    rm -rf /root/.acme.sh
    rm -rf /etc/letsencrypt
    clear
    echo
    echo Grafana and InfluxDB data has been deleted.
}

RootCheck
