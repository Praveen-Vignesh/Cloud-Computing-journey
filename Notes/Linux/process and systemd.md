Every process runs with a process id 

systemd comes in when we cant to manage process by adding them to automatically restart when crashed or run with computer boot as startup or look for its log etc,....

a unit file turns a process / executable to a service which is managed by systemd


for eg a file called heartbeat.sh contains
    #!/bin/bash
    while true; do
        echo "heartbeat at $(date)"
        sleep 10
    done

a unit file is added to the location "/etc/systemd/system/heartbeat.service"

this unit file is metadata about the above executable file
this metadata tells systemd how to manage this background process

for eg the unit file can contain

[Unit]
Description=A trivial heartbeat service for learning systemd
After=network.target

[Service]
ExecStart=/home/praveen/bin/heartbeat.sh
Restart=on-failure
User=praveen

[Install]
WantedBy=multi-user.target



here we have a description for the process
and "after = network.target" basically tells that only start after network is active

exec line tells where the program lives
restart= on-failure tells to restart the program when crashed
the process is ran through user praveen privilages

wantedby=multi-user.target means 'start this at boot once the sytem reached normal multi user operation"


then use systemctl to enable and start a process or kill a process
use journalctl to read the logs properly