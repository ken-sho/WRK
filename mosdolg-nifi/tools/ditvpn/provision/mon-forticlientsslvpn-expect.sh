#! /bin/bash

while true; do

case "$(pidof expect | wc -w)" in

0)  echo "Restarting expect:     $(date)" >> /var/log/expect.txt
    expect -f ~/vpn/forticlientsslvpn.exp &
    ;;
1)  # all ok
    ;;
*)  echo "Removed double expect: $(date)" >> /var/log/expect.txt
    sudo kill $(pidof expect | awk '{print $1}')
    ;;
esac


sleep 3
done
