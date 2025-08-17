#!/bin/bash

# IPv6 Proxy Setup Script
# Setup tunnel and create IPv6 proxy with rotation

set -e

# Configure tunnel SIT
TUNNEL_NAME="sit1"
LOCAL_IP="172.236.152.156"
REMOTE_IP="103.172.116.132"
IPV6_GATEWAY="2a11:6c7:f07:c::1/64"
IPV6_PREFIX="2a11:6c7:f07:c::"

echo "Installing required packages..."
apt update
apt install -y dante-server iptables-persistent netfilter-persistent

echo "Configuring IPv6 forwarding..."
echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -p

echo "Creating SIT tunnel..."
# Remove old tunnel if exists
ip tunnel del $TUNNEL_NAME 2>/dev/null || true

# Create new tunnel
ip tunnel add $TUNNEL_NAME mode sit remote $REMOTE_IP local $LOCAL_IP ttl 255
ip link set $TUNNEL_NAME up
ip addr add $IPV6_GATEWAY dev $TUNNEL_NAME
ip route add ::/0 dev $TUNNEL_NAME

echo "Creating 100 additional IPv6 addresses..."
for i in {1..100}; do
    ipv6_addr="${IPV6_PREFIX}$(printf "%x" $i)"
    ip addr add ${ipv6_addr}/64 dev $TUNNEL_NAME
    echo "Added IPv6: $ipv6_addr"
done

echo "Configuring Dante SOCKS5 proxy..."
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

echo "Creating systemd service for Dante..."
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

echo "Setup completed!"
echo "SOCKS5 Proxy: $LOCAL_IP:1080"
echo "Tunnel IPv6 Gateway: $IPV6_GATEWAY"
echo "Available 100 IPv6 addresses from ${IPV6_PREFIX}1 to ${IPV6_PREFIX}64"
