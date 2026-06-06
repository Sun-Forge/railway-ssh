#!/bin/bash
echo "=== Starting SSH service ==="
service ssh start

if [ -z "$TAILSCALE_AUTH_KEY" ]; then
    echo "Error: Set TAILSCALE_AUTH_KEY"
    echo "Get one at: https://login.tailscale.com/admin/settings/keys"
    exit 1
fi

echo "=== Starting Tailscale daemon ==="
tailscaled --tun=userspace-networking \
           --socks5-server=localhost:1055 \
           --outbound-http-proxy-listen=localhost:1055 \
           > /tmp/tailscaled.log 2>&1 &
sleep 3

echo "=== Connecting to Tailscale network ==="
tailscale up \
  --authkey="$TAILSCALE_AUTH_KEY" \
  --hostname="${TAILSCALE_HOSTNAME:-docker-aapanel-$(hostname)}" \
  --accept-routes \
  --ssh

sleep 5

AAPANEL_PORT=$(cat /www/server/panel/data/port.pl 2>/dev/null || echo 8888)
echo "Detected aaPanel port: $AAPANEL_PORT"

TS_IP=$(tailscale ip -4 2>/dev/null)
TS_NAME=$(tailscale status --json 2>/dev/null | grep -o '"DNSName":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -n "$TS_IP" ]; then
  echo "✅ Tailscale connected!"
  echo "SSH:    ssh trthaodev@$TS_IP"
  echo "Panel:  http://$TS_IP:$AAPANEL_PORT"
else
  echo "⚠️  Could not get Tailscale IP."
  cat /tmp/tailscaled.log
fi

python3 -m http.server 8080 >/dev/null 2>&1 &
wait
