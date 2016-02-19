#!/bin/bash

# execute with privileges only
if [ $EUID != 0 ]; then
    sudo bash "$0" "$@"
    exit $?
fi

# run inside iitg-tproxy/src/bash folder
cd "$(dirname "$0")"

source /etc/iitg-tproxy/config/config.sh

. /etc/iitg-tproxy/src/bash/script.sh stop

if pgrep "redsocks" > /dev/null
then
    sudo killall redsocks
fi

if [ -f /etc/iitg-tproxy/log/pid ]
then
	sed 's|[0-9]*|sudo kill &|g' /etc/iitg-tproxy/log/pid | bash
	rm -rf /etc/iitg-tproxy/log/pid

fi

echo "Transparent proxy stopped."
exit
