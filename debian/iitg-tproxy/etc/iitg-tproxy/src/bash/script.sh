#!/bin/sh

case $1 in

start)

	echo "Setting-up iptable rules ..."

	sudo iptables -t nat -A PREROUTING -i eth0 -p udp --dport 53 -j REDIRECT --to 7613
	sudo iptables -t nat -A PREROUTING -i wlan0 -p udp --dport 53 -j REDIRECT --to 7613
	sudo iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to 7613

	sudo iptables -t nat -N REDSOCKS

	sudo iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
	sudo iptables -t nat -A REDSOCKS -p tcp -d 10.0.0.0/8 -j RETURN
	sudo iptables -t nat -A REDSOCKS -p tcp -d 172.16.0.0/16 -j RETURN
	sudo iptables -t nat -A REDSOCKS -p tcp -d 192.168.0.0/16 -j RETURN
	sudo iptables -t nat -A REDSOCKS -p tcp -d 202.141.80.0/23 -j RETURN

	sudo iptables -t nat -A REDSOCKS -p tcp --dport 80 -j REDIRECT --to 8123
	sudo iptables -t nat -A REDSOCKS -p tcp --dport 443 -j REDIRECT --to 8124
	sudo iptables -t nat -A REDSOCKS -p tcp --dport 22 -j REDIRECT --to 8124
	sudo iptables -t nat -A REDSOCKS -p tcp --dport 5228 -j REDIRECT --to 8124
	sudo iptables -t nat -A REDSOCKS -p tcp --dport 5222 -j REDIRECT --to 8124

	sudo iptables -t nat -A OUTPUT -p tcp -j REDSOCKS

	sudo iptables -t nat -A PREROUTING -i wlan1 -p tcp -j REDSOCKS
	sudo iptables -t nat -A PREROUTING -i wlan0 -p tcp -j REDSOCKS
	sudo iptables -t nat -A PREROUTING -i wlan1 -p udp -j REDSOCKS
	sudo iptables -t nat -A PREROUTING -i wlan0 -p udp -j REDSOCKS
	sudo iptables -t nat -A PREROUTING -i eth0 -p udp -j REDSOCKS
	sudo iptables -t nat -A PREROUTING -i eth0 -p tcp -j REDSOCKS
	# sudo iptables -t nat -A PREROUTING -i eth1 -p udp -j REDSOCKS
	# sudo iptables -t nat -A PREROUTING -i eth1 -p udp -j REDSOCKS

	sudo iptables -A INPUT -i wlan0 -p tcp --dport 8123 -j ACCEPT
	sudo iptables -A INPUT -i wlan0 -p tcp --dport 8124 -j ACCEPT
	sudo iptables -A INPUT -i wlan1 -p tcp --dport 8123 -j ACCEPT
	sudo iptables -A INPUT -i wlan1 -p tcp --dport 8124 -j ACCEPT
	sudo iptables -A INPUT -i eth0 -p tcp --dport 8123 -j ACCEPT
	sudo iptables -A INPUT -i eth0 -p tcp --dport 8124 -j ACCEPT
	# sudo iptables -A INPUT -i eth1 -p tcp --dport 8123 -j ACCEPT
	# sudo iptables -A INPUT -i eth1 -p tcp --dport 8124 -j ACCEPT

	echo "iptable configured"

	echo "Setting-up resolv.conf ..."
	echo $'nameserver 127.0.0.1\nnameserver 8.8.8.8\nnameserver 8.8.4.4\n' | sudo tee temp.conf
	sudo mv /etc/resolv.conf /etc/resolv.conf.iitg-tproxy-bak
	sudo mv temp.conf /etc/resolv.conf
	sudo chown root:root /etc/resolv.conf
	sudo chmod 644 /etc/resolv.conf
	echo "resolv.conf setup successful"

;;
stop)

	if [ -f /etc/resolv.conf.iitg-tproxy-bak ]
	then
	    sudo mv /etc/resolv.conf.iitg-tproxy-bak /etc/resolv.conf
	fi

	sudo iptables -t nat -F OUTPUT
	sudo iptables -t nat -F INPUT
	sudo iptables -t nat -F REDSOCKS
	sudo iptables -t nat -F PREROUTING
	sudo iptables -t nat -F POSTROUTING

	sudo iptables -t nat -X REDSOCKS

esac
