#!/bin/bash

PROXY_CFG=~/3proxy/3proxy.cfg
PROXY_DB=~/proxy_db.txt
TUNNELS=~/tunnels.txt
HOST_IPV4=$(hostname -I | awk '{print $1}')
PROXY_NETWORK=$(grep "rule" ~/ndppd/ndppd.conf | awk '{print $2}' | cut -d/ -f1)

# ⚡ Tạo IPv6 ngẫu nhiên
gen_ipv6() {
    HEX=$(openssl rand -hex 8 | sed 's/../&:/g;s/:$//')
    echo "${PROXY_NETWORK}:${HEX}"
}

# ✅ Tìm port cao nhất đang dùng để sinh tiếp
get_next_port() {
    if [[ -s $PROXY_DB ]]; then
        LAST_PORT=$(awk '{print $2}' $PROXY_DB | sort -n | tail -1)
        echo $((LAST_PORT+1))
    else
        echo 1500
    fi
}

# ✅ Thêm proxy mới (vĩnh viễn, không hạn)
add_proxy() {
    echo "Nhập số lượng proxy muốn thêm:"
    read COUNT

    START_PORT=$(get_next_port)
    PORT=$START_PORT

    for ((i=1;i<=COUNT;i++)); do
        IPV6=$(gen_ipv6)
        echo "proxy -6 -s0 -n -a -p$PORT -i$HOST_IPV4 -e$IPV6" >> $PROXY_CFG
        echo "$IPV6 $PORT PERMANENT" >> $PROXY_DB
        echo "http://$HOST_IPV4:$PORT" >> $TUNNELS
        echo "✅ Thêm proxy $HOST_IPV4:$PORT ($IPV6)"
        ((PORT++))
    done

    restart_proxy
}

# ✅ Import proxy cho khách (có hạn)
import_proxy() {
    echo "Nhập file list proxy của khách:"
    read FILE
    echo "Nhập số ngày sử dụng (default 30):"
    read DAYS
    [[ -z "$DAYS" ]] && DAYS=30
    EXPIRY=$(date -d "+$DAYS days" +%F)

    while read LINE; do
        PORT=$(echo $LINE | cut -d: -f3)
        echo "$LINE $EXPIRY" >> $PROXY_DB
    done < $FILE

    echo "✅ Import xong, hạn sử dụng đến: $EXPIRY"
}

# ✅ Kiểm tra & xóa proxy hết hạn
check_expiry() {
    TODAY=$(date +%F)
    TMP=$(mktemp)

    while read LINE; do
        EXPIRY=$(echo $LINE | awk '{print $3}')
        PORT=$(echo $LINE | awk '{print $2}')

        if [[ "$EXPIRY" != "PERMANENT" && "$TODAY" > "$EXPIRY" ]]; then
            echo "⚠️ Xóa proxy hết hạn: $LINE"
            sed -i "/-p$PORT /d" $PROXY_CFG
            sed -i "/:$PORT/d" $TUNNELS
        else
            echo $LINE >> $TMP
        fi
    done < $PROXY_DB

    mv $TMP $PROXY_DB
    restart_proxy
}

# ✅ Restart 3proxy
restart_proxy() {
    pkill 3proxy
    ~/3proxy/src/3proxy ~/3proxy/3proxy.cfg &
}

# ✅ Menu
menu() {
    echo "====== Proxy Manager ======"
    echo "1) Thêm proxy mới (không hạn)"
    echo "2) Import list proxy của khách (có hạn)"
    echo "3) Kiểm tra & xóa proxy hết hạn"
    echo "4) Xem danh sách proxy còn hạn"
    echo "0) Thoát"
    read CHOICE
    case $CHOICE in
        1) add_proxy ;;
        2) import_proxy ;;
        3) check_expiry ;;
        4) cat $PROXY_DB ;;
        0) exit ;;
        *) echo "Sai lựa chọn!" ;;
    esac
}

menu
