\# Day 002 — October 24, 2026


\## Title

Processes and Systemd - created a tivial hearbeat process and made it survive crash and reboot



\## 🎯 Today's Logs

1. created a trivial heartbeat.sh file
2. made it executable
3. created a unit file for that executable to turn it into a service
4. enabled the service through systemctl.



\## ⚠️ Challenges \& Problems

Faced a simple problem where i status error 203/EXEC


\## 🔍 How I Solved Them


this problem occured because i forgot to add the line "#!/bin/bash"
