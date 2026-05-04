#!/bin/bash

IP=localhost
PORT=22
PASS=alpine

echo "[*] Waiting for SSH..."
until sshpass -p $PASS ssh -o StrictHostKeyChecking=no -p $PORT root@$IP "echo ok" 2>/dev/null; do
    sleep 1
done

echo "[✓] Connected"

echo "[*] Preparing directories..."
sshpass -p $PASS ssh -o StrictHostKeyChecking=no -p $PORT root@$IP \
"rm -rf /var/mobile/Media/Downloads/1 && mkdir -p /var/mobile/Media/Downloads/1"

echo "[*] Uploading Activation..."
sshpass -p $PASS scp -O -r -P $PORT -o StrictHostKeyChecking=no \
~/Desktop/Activation root@$IP:/var/mobile/Media/Downloads/1

echo "[*] Uploading script..."
sshpass -p $PASS scp -O -P $PORT -o StrictHostKeyChecking=no \
device.sh root@$IP:/tmp/device.sh

echo "[*] Running device script..."
sshpass -p $PASS ssh -o StrictHostKeyChecking=no -p $PORT root@$IP \
"chmod +x /tmp/device.sh && sh /tmp/device.sh"

echo "[✓] All done"
