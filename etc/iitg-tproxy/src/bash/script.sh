#!/bin/sh

case $1 in

start)

	echo "Setting-up iptable rules ..."

	# refer iptables manual for information on PREROUTING and OUTPUT chains

        # create new table redsocks
        sudo iptables -t nat -N REDSOCKS

	sudo iptables -t nat -A REDSOCKS -d 0.0.0.0/8 -j RETURN
	sudo iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
	sudo iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
	sudo iptables -t nat -A REDSOCKS -d 169.254.0.0/16 -j RETURN
	sudo iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
	sudo iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
	sudo iptables -t nat -A REDSOCKS -d 202.141.80.0/23 -j RETURN
	sudo iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN
	sudo iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN

	# redirect UDP port 53 to 7613(port of fake DNS)
	sudo iptables -t nat -A REDSOCKS -p udp --dport 53 -j REDIRECT --to 7613

	# redirect TCP port 80 to 8123(http-relay) and others to 8124(http-connect)
	sudo iptables -t nat -A REDSOCKS -p tcp --dport 80 -j REDIRECT --to 8123
	sudo iptables -t nat -A REDSOCKS -p tcp -m multiport --dports 22,443,5222,5228 -j REDIRECT --to 8124

	# jump to redsocks table
	sudo iptables -t nat -A OUTPUT -j REDSOCKS
	sudo iptables -t nat -A PREROUTING -j REDSOCKS

	# accept traffic on ports 8123, 8124 ports on all interfaces
	sudo iptables -A INPUT -p tcp -m multiport --dports 8123,8124 -j ACCEPT

	echo "iptable configured"
;;
stop)
	sudo iptables -t nat -D OUTPUT -j REDSOCKS
        sudo iptables -t nat -D PREROUTING -j REDSOCKS
	sudo iptables -D INPUT -p tcp -m multiport --dports 8123,8124 -j ACCEPT

	sudo iptables -t nat -F REDSOCKS
	sudo iptables -t nat -X REDSOCKS

esac