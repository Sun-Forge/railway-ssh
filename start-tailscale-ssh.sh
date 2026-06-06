#!/bin/bash
echo "=== Bắt đầu dịch vụ SSH ==="
service ssh start

if [ -z "$TAILSCALE_AUTH_KEY" ]; then
  echo "⚠️  Không tìm thấy biến môi trường TAILSCALE_AUTH_KEY!"
  echo "➡️  Tạo key tại: https://login.tailscale.com/admin/settings/keys"
  exit 1
fi

echo "=== Khởi động Tailscale daemon ==="
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055 > /tmp/tailscaled.log 2>&1 &
sleep 3

echo "=== Kết nối vào Tailscale network ==="
tailscale up \
  --authkey="$TAILSCALE_AUTH_KEY" \
  --hostname="${TAILSCALE_HOSTNAME:-docker-ssh-$(hostname)}" \
  --accept-routes \
  --ssh

sleep 5

echo "=== Thông tin SSH của bạn ==="
TS_IP=$(tailscale ip -4 2>/dev/null)
TS_NAME=$(tailscale status --json 2>/dev/null | grep -o '"DNSName":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -n "$TS_IP" ]; then
  echo "✅ Đã kết nối Tailscale thành công!"
  echo "🔗 IP Tailscale: $TS_IP"
  [ -n "$TS_NAME" ] && echo "🔗 Hostname:     $TS_NAME"
  echo "Kết nối SSH: ssh trthaodev@$TS_IP"
else
  echo "⚠️  Không lấy được IP, kiểm tra: /tmp/tailscaled.log"
  cat /tmp/tailscaled.log
fi

python3 -m http.server 8080
