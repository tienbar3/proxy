#!/bin/bash

# IPv6 Proxy Setup Script
# Cấu hình tunnel và tạo proxy IPv6 với rotation

set -e

# Cấu hình tunnel SIT
TUNNEL_NAME="sit1"
LOCAL_IP="172.236.152.156"
REMOTE_IP="103.172.116.132"
IPV6_GATEWAY="2a11:6c7:f07:c::1/64"
IPV6_PREFIX="2a11:6c7:f07:c::"

echo "Đang cài đặt các gói cần thiết..."
apt update
apt install -y dante-server iptables-persistent netfilter-persistent

echo "Cấu hình IPv6 forwarding..."
echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -p

echo "Tạo tunnel SIT..."
# Xóa tunnel cũ nếu có
ip tunnel del $TUNNEL_NAME 2>/dev/null || true

# Tạo tunnel mới
ip tunnel add $TUNNEL_NAME mode sit remote $REMOTE_IP local $LOCAL_IP ttl 255
ip link set $TUNNEL_NAME up
ip addr add $IPV6_GATEWAY dev $TUNNEL_NAME
ip route add ::/0 dev $TUNNEL_NAME

echo "Tạo 100 địa chỉ IPv6 phụ..."
for i in {1..100}; do
    ipv6_addr="${IPV6_PREFIX}$(printf "%x" $i)"
    ip addr add ${ipv6_addr}/64 dev $TUNNEL_NAME
    echo "Đã thêm IPv6: $ipv6_addr"
done

echo "Cấu hình Dante SOCKS5 proxy..."
cat > /etc/danted.conf << 'EOF'
# Dante SOCKS5 server configuration
logoutput: /var/log/danted.log
internal: 0.0.0.0 port = 1080
external.rotation: route

# Authentication method
socksmethod: none

# Client access rules
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error connect disconnect
}

# SOCKS rules
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error connect disconnect
    socksmethod: none
}
EOF

echo "Tạo service systemd cho Dante..."
cat > /etc/systemd/system/danted.service << 'EOF'
[Unit]
Description=Dante SOCKS5 Server
After=network.target

[Service]
Type=forking
PIDFile=/var/run/danted.pid
ExecStart=/usr/sbin/danted -f /etc/danted.conf -p /var/run/danted.pid
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable danted
systemctl start danted

echo "Cấu hình hoàn tất!"
echo "SOCKS5 Proxy: $LOCAL_IP:1080"
echo "Tunnel IPv6 Gateway: $IPV6_GATEWAY"
echo "Có 100 địa chỉ IPv6 từ ${IPV6_PREFIX}1 đến ${IPV6_PREFIX}64"
