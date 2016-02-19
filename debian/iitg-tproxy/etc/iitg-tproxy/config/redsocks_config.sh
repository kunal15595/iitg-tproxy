#!/bin/bash

source /etc/iitg-tproxy/config/config.sh

echo "
base {
	log_debug = on;
	log_info = on;
	log = stderr;
	daemon = off;
	redirector = iptables;
}


redsocks {
	local_ip = 0.0.0.0;
	local_port = 8123;
	ip = $1;
	port = $2;
	type = http-relay;
	login = \"$3\";
	password = \"$4\";
}

redsocks {
	local_ip = 0.0.0.0;
	local_port = 8124;
	ip = $1;
	port = $2;
	type = http-connect;
	login = \"$3\";
	password = \"$4\";
}

" | sudo tee /etc/iitg-tproxy/config/redsocksauto.conf

until sudo redsocks -c /etc/iitg-tproxy/config/redsocksauto.conf; do
    echo "redsocks crashed with exit code $?.  Respawning.." >&2
    sleep 0.1
done
