#!/bin/bash

# Tải script proxy_manager.sh từ GitHub
echo "📥 Đang tải proxy_manager.sh ..."
wget -O ~/proxy_manager.sh https://raw.githubusercontent.com/tienbar3/proxy/main/proxy_manager.sh

# Cấp quyền chạy
chmod +x ~/proxy_manager.sh

# Chạy thử lần đầu
echo "🚀 Chạy proxy_manager.sh ..."
~/proxy_manager.sh
