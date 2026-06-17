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
    local TARGET_IP=${3:-127.0.0.1}
    local USE_SSL=$4
    local EMAIL=$5
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
        proxy_pass http://${TARGET_IP}:${PORT};
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

    if [[ "$USE_SSL" =~ ^[Yy]$ ]]; then
        echo "Mengkonfigurasi SSL via Certbot..."
        if ! command -v certbot &> /dev/null; then
            echo "Menginstall certbot dan plugin nginx..."
            apt-get update && apt-get install -y certbot python3-certbot-nginx
        fi
        
        local certbot_cmd="certbot --nginx -d \"$DOMAIN\" --agree-tos --redirect"
        if [ -n "$EMAIL" ]; then
            certbot_cmd="$certbot_cmd -m \"$EMAIL\" --no-eff-email"
        else
            certbot_cmd="$certbot_cmd --register-unsafely-without-email"
        fi
        
        eval $certbot_cmd
        
        if [ $? -eq 0 ]; then
            echo "SSL (HTTPS) berhasil diaktifkan untuk $DOMAIN!"
        else
            echo "Gagal mengaktifkan SSL. Pastikan domain $DOMAIN sudah pointing (A Record) ke IP VPS ini dan DNS sudah terpropagasi."
        fi
    fi
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

function list_domains() {
    echo "========================================="
    echo "       Daftar Domain Terdaftar           "
    echo "========================================="
    local count=0
    if [ -d "$NGINX_AVAILABLE_DIR" ]; then
        for file in "$NGINX_AVAILABLE_DIR"/*.conf; do
            if [ -f "$file" ]; then
                local domain=$(basename "$file" .conf)
                echo "- $domain"
                count=$((count+1))
            fi
        done
    fi
    if [ $count -eq 0 ]; then
        echo "Belum ada domain yang terdaftar."
    fi
    echo "========================================="
}

function interactive_menu() {
    clear
    echo "Mendeteksi informasi server..."
    IP_INFO=$(curl -sS --max-time 3 ipinfo.io)
    if [ -n "$IP_INFO" ] && echo "$IP_INFO" | grep -q '"ip"'; then
        SERVER_IP=$(echo "$IP_INFO" | grep '"ip"' | cut -d '"' -f 4)
        SERVER_CITY=$(echo "$IP_INFO" | grep '"city"' | cut -d '"' -f 4)
        SERVER_COUNTRY=$(echo "$IP_INFO" | grep '"country"' | cut -d '"' -f 4)
        SERVER_ORG=$(echo "$IP_INFO" | grep '"org"' | cut -d '"' -f 4)
    else
        SERVER_IP=$(curl -sS --max-time 3 ifconfig.me || echo "127.0.0.1")
        SERVER_CITY="Tidak diketahui"
        SERVER_COUNTRY="Tidak diketahui"
        SERVER_ORG="Tidak diketahui"
    fi

    while true; do
        clear
        echo "========================================="
        echo "       Pterodactyl Domain Manager        "
        echo "========================================="
        echo " IP VPS    : $SERVER_IP"
        echo " Lokasi    : $SERVER_CITY, $SERVER_COUNTRY"
        echo " Provider  : $SERVER_ORG"
        echo "========================================="
        echo "1. Tambah Konfigurasi Domain"
        echo "2. Hapus Konfigurasi Domain"
        echo "3. List Domain Terdaftar"
        echo "4. Keluar"
        echo "========================================="
        read -p "Pilih menu [1-4]: " pilihan

        case $pilihan in
            1)
                echo ""
                read -p "Masukkan nama domain (contoh: panel.domain.com): " input_domain
                read -p "Masukkan IP target (biarkan kosong untuk $SERVER_IP): " input_ip
                input_ip=${input_ip:-$SERVER_IP}
                
                read -p "Masukkan port target (contoh: 8080): " input_port
                
                read -p "Gunakan SSL/HTTPS via Certbot? Pastikan domain sudah pointing ke IP ini (y/n): " use_ssl
                local input_email=""
                if [[ "$use_ssl" =~ ^[Yy]$ ]]; then
                    read -p "Masukkan Email untuk notifikasi SSL (kosongkan jika tidak perlu): " input_email
                fi
                
                add_domain "$input_domain" "$input_port" "$input_ip" "$use_ssl" "$input_email"
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            2)
                echo ""
                read -p "Masukkan nama domain yang ingin dihapus: " input_domain
                delete_domain "$input_domain"
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            3)
                echo ""
                list_domains
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            4)
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
