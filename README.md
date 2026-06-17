# Pterodactyl Nginx Manager

Script Bash interaktif (TUI) untuk mengotomatisasi pembuatan dan penghapusan konfigurasi Nginx Reverse Proxy khusus untuk **Pterodactyl Panel** maupun **Wings (Node)**.

Script ini otomatis membuat konfigurasi *server block* lengkap dengan dukungan **WebSocket** (`upgrade`) yang dibutuhkan oleh daemon Pterodactyl, serta mendukung struktur Nginx bawaan Debian/Ubuntu (`sites-available` & `sites-enabled`).

## ✨ Fitur

- 🚀 **Interactive Menu (TUI)** - Sangat mudah digunakan tanpa perlu mengingat perintah panjang.
- ➕ **Tambah Domain Otomatis** - Mengarahkan (Reverse Proxy) domain ke port Pterodactyl lokal Anda (misal `8080`).
- 🗑️ **Hapus Domain Otomatis** - Membersihkan konfigurasi Nginx dengan bersih.
- 🔄 **Auto-Reload** - Otomatis me-reload Nginx setiap ada perubahan konfigurasi.
- 🐳 **Docker Support** - Tersedia `Dockerfile` dan GitHub Actions untuk otomatis build container Nginx yang siap pakai.

---

## ⚡ Cara Penggunaan (Otomatis / One-Liner)

Anda tidak perlu men-download script secara manual. Cukup jalankan satu baris perintah berikut di Terminal VPS (Ubuntu/Debian) Anda:

```bash
bash <(curl -s https://raw.githubusercontent.com/muhammadtsaqf/pterodactyl-nginx-manager/main/nginx-manager.sh)
```

Setelah perintah dijalankan, Anda akan melihat menu seperti ini:
```text
=========================================
       Pterodactyl Domain Manager        
=========================================
1. Tambah Konfigurasi Domain
2. Hapus Konfigurasi Domain
3. Keluar
=========================================
Pilih menu [1-3]: 
```



---

## 🛠️ Struktur File
- `nginx-manager.sh` : File script utama.
- `Dockerfile` : Konfigurasi untuk mem-build image Docker Nginx.
- `.github/workflows/docker-publish.yml` : Workflow CI/CD untuk otomatis merilis image ke GitHub Container Registry.
