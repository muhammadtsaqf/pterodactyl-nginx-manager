#!/bin/bash

# nginx-manager.sh
# Script untuk menambah dan menghapus konfigurasi Nginx reverse proxy 
# khusus untuk Pterodactyl Panel / Node

NGINX_AVAILABLE_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"

function show_usage() {
    echo "Usage:"
    echo "  $0 add <domain> <port>"
    echo "  $0 delete <domain>"
    echo "Example:"
    echo "  $0 add panel.example.com 8080"
    echo "  $0 delete panel.example.com"
}

function reload_nginx() {
    echo "Testing Nginx configuration..."
    nginx -t
    if [ $? -eq 0 ]; then
        echo "Reloading Nginx..."
        nginx -s reload
        echo "Nginx reloaded successfully."
    else
        echo "Nginx configuration test failed. Aborting reload."
        exit 1
    fi
}

function add_domain() {
    local DOMAIN=$1
    local PORT=$2
    local CONF_FILE="${NGINX_AVAILABLE_DIR}/${DOMAIN}.conf"
    local LINK_FILE="${NGINX_ENABLED_DIR}/${DOMAIN}.conf"

    if [ -z "$DOMAIN" ] || [ -z "$PORT" ]; then
        echo "Error: Missing domain or port."
        show_usage
        exit 1
    fi

    if [ -f "$CONF_FILE" ]; then
        echo "Error: Configuration for $DOMAIN already exists at $CONF_FILE"
        exit 1
    fi

    echo "Creating Nginx configuration for $DOMAIN proxying to port $PORT..."

    cat > "$CONF_FILE" <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    location / {
        proxy_pass http://127.0.0.1:${PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Pterodactyl Websocket Support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

    echo "Enabling site by creating symlink..."
    ln -s "$CONF_FILE" "$LINK_FILE"

    echo "Configuration created: $CONF_FILE"
    reload_nginx
}

function delete_domain() {
    local DOMAIN=$1
    local CONF_FILE="${NGINX_AVAILABLE_DIR}/${DOMAIN}.conf"
    local LINK_FILE="${NGINX_ENABLED_DIR}/${DOMAIN}.conf"

    if [ -z "$DOMAIN" ]; then
        echo "Error: Missing domain."
        show_usage
        exit 1
    fi

    if [ ! -f "$CONF_FILE" ]; then
        echo "Error: Configuration for $DOMAIN does not exist at $CONF_FILE"
        exit 1
    fi

    echo "Deleting Nginx configuration for $DOMAIN..."
    rm -f "$CONF_FILE"
    rm -f "$LINK_FILE"
    echo "Configuration deleted."
    
    reload_nginx
}

function interactive_menu() {
    while true; do
        clear
        echo "========================================="
        echo "       Pterodactyl Domain Manager        "
        echo "========================================="
        echo "1. Tambah Konfigurasi Domain"
        echo "2. Hapus Konfigurasi Domain"
        echo "3. Keluar"
        echo "========================================="
        read -p "Pilih menu [1-3]: " pilihan

        case $pilihan in
            1)
                echo ""
                read -p "Masukkan nama domain (contoh: panel.domain.com): " input_domain
                read -p "Masukkan port target (contoh: 8080): " input_port
                add_domain "$input_domain" "$input_port"
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            2)
                echo ""
                read -p "Masukkan nama domain yang ingin dihapus: " input_domain
                delete_domain "$input_domain"
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            3)
                echo "Keluar dari program."
                exit 0
                ;;
            *)
                echo "Pilihan tidak valid!"
                sleep 1
                ;;
        esac
    done
}

# Jika script dijalankan tanpa argumen, tampilkan menu interaktif
if [ -z "$1" ]; then
    interactive_menu
elif [ "$1" == "add" ]; then
    add_domain "$2" "$3"
elif [ "$1" == "delete" ]; then
    delete_domain "$2"
else
    show_usage
fi
