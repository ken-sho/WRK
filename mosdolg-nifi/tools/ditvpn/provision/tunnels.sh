#!/bin/bash

# 172.24.63.139:8443 NiFi Node 1 Web Interface
# 10.89.1.20:22 SSH gate to all VMs
ssh -t -t -L $CLIENT_IP_ADDR:8443:172.24.63.139:8443 -L $CLIENT_IP_ADDR:22222:10.89.1.20:22 -o ServerAliveInterval=20 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null vagrant@0.0.0.0 &
#ssh -L 0.0.0.0:3306:10.126.155.24:3306 root@SMD-BUS01P-172.24.63.139@SMD-BUS01P-172.24.63.139:mashkovdv@localhost
#ssh -L 0.0.0.0:5432:172.24.63.137:5432 root@SMD-DATA01P-172.24.63.137:mashkovdv@localhost
#ssh -L 0.0.0.0:5433:172.24.63.145:5432 root@SMD-IDDA01P-172.24.63.145:mashkovdv@localhost
#ssh -L 0.0.0.0:18081:172.24.63.134:8081 root@SMD-CORE01P-172.24.63.134:mashkovdv@localhost
#ssh -L 0.0.0.0:18082:172.24.63.129:8082 root@SMD-WEB01P-172.24.63.129:mashkovdv@localhost