#!/bin/bash
echo "=== 🚀 Memulai proses update Nextcloud stack ==="

# 1. Masuk ke direktori proyek (ubah sesuai lokasi kamu)
cd /disk/data-01/tristan/data-nc || exit

# 2. Tarik versi image terbaru dari Docker Hub
echo "📦 Menarik image terbaru..."
docker compose pull

# 3. Hentikan semua container yang sedang berjalan
echo "🛑 Menghentikan container..."
docker compose down

# 4. Jalankan kembali container dengan image terbaru
echo "🔁 Menjalankan ulang container..."
docker compose up -d

# 5. Hapus image lama yang tidak terpakai untuk menghemat ruang
echo "🧹 Membersihkan image lama..."
docker image prune -f

# 6. Verifikasi status container
echo "📊 Status container saat ini:"
docker ps

# 7. Catat waktu update ke log
LOGFILE="/disk/data-01/tristan/data-nc/update.log"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Update selesai." >> "$LOGFILE"

echo "✅ Update selesai! Semua container sudah diperbarui dan berjalan normal."
