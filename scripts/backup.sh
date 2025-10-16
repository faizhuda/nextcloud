#!/bin/bash

# 📅 Inisialisasi tanggal dan direktori backup
DATE=$(date +%F_%H-%M-%S)
BACKUP_DIR="/disk/data-01/tristan/backup/$DATE"
DB_CONTAINER="nc-tristan-db"
DB_USER="root"
DB_PASS="change_this_root_password"
DB_NAME="nextcloud"

echo "=== 🗄️ Memulai proses backup Nextcloud pada $DATE ==="
mkdir -p "$BACKUP_DIR"

# 1️⃣ Backup Database (MariaDB)
echo "📦 Membuat dump database..."
docker exec "$DB_CONTAINER" \
  mysqldump -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_DIR/db_$DATE.sql"

# 2️⃣ Backup Data File Nextcloud
echo "💽 Mengarsipkan data Nextcloud..."
tar -czf "$BACKUP_DIR/nextcloud_data_$DATE.tar.gz" /disk/data-01/tristan/data-nc/nc

# 3️⃣ Backup Konfigurasi (config.php)
echo "⚙️ Menyalin file konfigurasi..."
cp /disk/data-01/tristan/data-nc/nc/config/config.php "$BACKUP_DIR/config_$DATE.php"

# 4️⃣ Verifikasi ukuran backup
echo "📏 Ukuran backup:"
du -sh "$BACKUP_DIR"

# 5️⃣ Menghapus backup lama (>7 hari)
echo "🧹 Menghapus backup lama..."
find /disk/data-01/tristan/backup/* -mtime +7 -type d -exec rm -rf {} \;

# 6️⃣ Logging
LOGFILE="/disk/data-01/tristan/backup/backup.log"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup selesai di $BACKUP_DIR" >> "$LOGFILE"

echo "✅ Backup selesai dan disimpan di $BACKUP_DIR"
