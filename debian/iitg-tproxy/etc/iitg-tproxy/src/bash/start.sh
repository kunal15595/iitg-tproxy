#!/bin/bash

# execute with privileges only
if [ $EUID != 0 ]; then
    sudo bash "$0" "$@"
    exit $?
fi

# run inside iitg-tproxy/src/bash folder
cd "$(dirname "$0")"

source /etc/iitg-tproxy/config/config.sh

if [ -f /etc/iitg-tproxy/config/config.sh ]; then
	source /etc/iitg-tproxy/config/config.sh
else
	echo "config file not found. Aborting."
	exit 1
fi

sudo chown root:root -R /var/log
sudo chmod 777 -R /var/log

# Killing redsocks, if running
if pgrep "redsocks" > /dev/null
then
    sudo killall -I redsocks
fi

# Killing fake DNS server, if running
sudo fuser -k 7613/udp

echo "Tproxy" | sudo tee /etc/iitg-tproxy/log/tproxy

echo "Getting variables ..." | sudo tee -a /etc/iitg-tproxy/log/tproxy
source /etc/iitg-tproxy/config/config.sh #&

echo "Configuring iptables ..." | sudo tee -a /etc/iitg-tproxy/log/tproxy
. /etc/iitg-tproxy/src/bash/script.sh start #&

echo "Configuring redsocks ..." | sudo tee -a /etc/iitg-tproxy/log/tproxy
. /etc/iitg-tproxy/config/redsocks_config.sh $tproxy_server $tproxy_port $tproxy_username $tproxy_password | sudo tee /etc/iitg-tproxy/log/redsocks 2>&1 &
echo "redsocks configured successfully" | sudo tee -a /etc/iitg-tproxy/log/tproxy

echo "initiating fake DNS server ..." | sudo tee -a /etc/iitg-tproxy/log/tproxy

sudo python -u /etc/iitg-tproxy/src/py/fake_dns.py /etc/iitg-tproxy/log/pid | sudo tee /etc/iitg-tproxy/log/dns 2>&1 &
echo "DNS server initiated" | sudo tee -a /etc/iitg-tproxy/log/tproxy

echo "Starting dnsmasq on all open interfaces ..." | sudo tee -a /etc/iitg-tproxy/log/tproxy

echo "Transparent proxy initiated, running in background" | sudo tee -a /etc/iitg-tproxy/log/tproxy

echo "Done !!"

exit
