<div align="center">
  <img src="https://upload.wikimedia.org/wikipedia/commons/6/60/Nextcloud_Logo.svg" alt="Nextcloud Logo" width="120"/>

# Nextcloud: Sistem Kolaborasi dan Penyimpanan Data Self-Hosted

*Implementasi Self-Hosted Cloud Storage dan Sistem Kolaborasi Berbasis Docker*

</div>

## 📑 Daftar Isi

| [Sekilas Tentang](#abstrak) | [Instalasi](#instalasi--konfigurasi) | [Konfigurasi](#konfigurasi-reverse-proxy-via-web-gui) | [Keamanan](#keamanan--backup) | [Cara Pemakaian](#penggunaan-nextcloud) | [Pembahasan](#pembahasan) | [Referensi](#referensi) |

## Abstrak

Dokumen ini menjelaskan implementasi Nextcloud sebagai sistem kolaborasi dan penyimpanan data self-hosted. Implementasi dilakukan pada lingkungan Mini-PC berbasis Ubuntu 22.04 dengan penggunaan Docker, Docker Compose, Nginx Proxy Manager, dan MariaDB. Tujuan pekerjaan ini adalah menyediakan panduan teknis lengkap yang mencakup instalasi, konfigurasi, keamanan, backup, serta pengujian performa awal.

[⬆️ Kembali ke atas](#📑-daftar-isi)

---

## Latar Belakang dan Tujuan

Kebutuhan organisasi/akademik terhadap sistem penyimpanan dan kolaborasi data yang aman, dapat dikendalikan, dan hemat biaya mendorong penggunaan solusi self-hosted. Nextcloud dipilih karena fitur kolaborasi (file sharing, calendar, talk, docs), fleksibilitas deployment, dan dukungan ekosistem aplikasi. Tujuan laporan ini adalah:

* Mendesain dan mengimplementasikan Nextcloud self-hosted pada Mini-PC.
* Menyusun dokumentasi teknis yang dapat direplikasi.
* Melakukan pengujian performa dasar dan menyiapkan prosedur backup dan hardening.

[⬆️ Kembali ke atas](#📑-daftar-isi)

---

## Ruang Lingkup dan Batasan

Ruang lingkup:

* Instalasi menggunakan Docker Compose.
* Konfigurasi reverse proxy via Nginx Proxy Manager.
* Pengaturan SSL via Let's Encrypt.
* Backup otomatis sederhana untuk data dan database.
* Pengujian performa dasar (upload/download, penggunaan sumber daya).

Batasan:

* Pengujian menggunakan skenario kecil (≤ 50 pengguna aktif simultan).
* Tidak memasukkan integrasi enterprise storage (NAS/S3) secara lengkap.
* Evaluasi keamanan fokus pada best-practice dasar (firewall, update, SSL).

[⬆️ Kembali ke atas](#📑-daftar-isi)

---

## Tinjauan Pustaka Singkat

* Prinsip containerization dan orkestrasi ringan dengan Docker.
* Arsitektur reverse proxy untuk mengamankan dan memetakan domain.
* Mekanisme penyimpanan Nextcloud (data directory) dan peran DBMS (MariaDB).

[⬆️ Kembali ke atas](#📑-daftar-isi)

---

## Arsitektur Sistem

Sistem diimplementasikan pada Mini-PC dengan topologi sederhana:

* Host: Mini-PC (Ubuntu 22.04)
* Reverse Proxy: Nginx Proxy Manager (container terpisah; mengelola TLS/SSL dan virtual host)
* Aplikasi: Nextcloud (container)
* Database: MariaDB (container)
* Network: user-defined Docker network (`jeff`)

Diagram arsitektur tersedia pada `diagram-arsitektur.png` di repository.

[⬆️ Kembali ke atas](#📑-daftar-isi)

---

## Teknologi yang Digunakan

* Ubuntu 22.04 (host)
* Docker & Docker Compose (v3.8)
* Nextcloud (image resmi)
* MariaDB (image resmi)
* Nginx Proxy Manager (opsional, pada host atau container terpisah)
* Certbot / Let's Encrypt untuk TLS

[⬆️ Kembali ke atas](#📑-daftar-isi)

---

## Instalasi & Konfigurasi

### 1. Persiapan Host

1. Update sistem:

```bash
sudo apt update && sudo apt upgrade -y
```

2. Pasang Docker & Docker Compose (ikuti panduan resmi Docker untuk Ubuntu 22.04).
3. Pastikan port 80 dan 443 terbuka untuk Nginx Proxy Manager/Let's Encrypt.

### 2. Struktur Repository

Direktori contoh:

```
nextcloud/
├─ docker-compose.yml
├─ config/
│  └─ config.php (opsional, diisi setelah instalasi awal)
├─ data/
└─ backup/
```

### 3. Contoh `docker-compose.yml`

File lengkap tersedia di `docker-compose.yml`. Secara ringkas:

* Service `db` untuk MariaDB
* Service `app` untuk Nextcloud (menggunakan image resmi)
* Volumes host-mounted agar data persisten
* Network `jeff` untuk isolasi

### 4. Konfigurasi Reverse Proxy via Web GUI

Setelah container **Nginx Proxy Manager** dijalankan, antarmuka administrasi dapat diakses melalui browser dengan alamat:

```
http://<IP-server>:81
```

Contoh:
`http://192.168.1.10:81`

#### 1. Login Awal

Gunakan kredensial bawaan berikut:

* **Email:** `admin@example.com`
* **Password:** `changeme`

Segera ubah password setelah login pertama untuk alasan keamanan.

#### 2. Menambahkan Proxy Host

Masuk ke tab **“Proxy Hosts”** dan pilih **Add Proxy Host**, lalu isi kolom berikut:

| Kolom                     | Nilai Contoh        | Keterangan                                       |
| ------------------------- | ------------------- | ------------------------------------------------ |
| **Domain Names**          | `drive.hq.idenx.id` | Domain publik untuk akses Nextcloud              |
| **Scheme**                | `http`              | Gunakan HTTP karena SSL akan dikelola oleh NPM   |
| **Forward Hostname / IP** | `nc-tristan-app`    | Nama container Nextcloud (bisa juga `IP-server`) |
| **Forward Port**          | `23001`             | Port container Nextcloud                         |
| **Cache Assets**          | Centang             | Untuk efisiensi akses statis                     |
| **Block Common Exploits** | Centang             | Perlindungan dasar terhadap serangan umum        |

#### 3. Mengaktifkan SSL (HTTPS)

Masih di form yang sama, buka tab **SSL** dan atur:

* **SSL Certificate:** “Request a new SSL Certificate”
* **Force SSL:** ✅ aktif
* **HTTP/2 Support:** ✅ aktif
* **HSTS Enabled:** (opsional, aktifkan jika sudah yakin domain fix)
* **Agree to Let's Encrypt TOS:** ✅

Klik **Save**, maka NPM akan otomatis:

1. Menghubungi Let’s Encrypt untuk membuat sertifikat TLS.
2. Menyimpan sertifikat di volume `/letsencrypt`.
3. Mengaktifkan akses aman `https://drive.hq.idenx.id`.

#### 4. Verifikasi Akses

Buka browser dan kunjungi:

```
https://drive.hq.idenx.id
```

Jika konfigurasi berhasil, halaman login Nextcloud akan muncul dengan ikon gembok hijau (SSL aktif).
Apabila domain belum resolve ke IP server, pastikan pengaturan DNS dan port forwarding router telah sesuai (port 443 diarahkan ke server host).

#### 5. Tampilan Dashboard

Antarmuka NPM berbentuk web modern yang menampilkan daftar **Proxy Host**, **SSL Certificates**, dan **Access Lists**.
Contohnya seperti berikut:

![Nginx Proxy Manager Dashboard](docs/npm-dashboard.png)

(*gambar dapat diganti dengan screenshot asli milik kamu nanti*)

[⬆️ Kembali ke atas](#📑-daftar-isi)

---

## Penggunaan Nextcloud

Setelah instalasi dan konfigurasi selesai, Nextcloud dapat diakses melalui browser di alamat domain yang sudah dikonfigurasi, misalnya:

```
https://drive.hq.idenx.id
```

Berikut panduan penggunaan untuk pengguna umum:

### 1. Login ke Nextcloud

* Buka browser dan akses domain Nextcloud.
* Masukkan **username** dan **password** yang telah dibuat saat instalasi.
* Setelah login, pengguna akan masuk ke tampilan beranda (dashboard) Nextcloud.

### 2. Mengunggah (Upload) File

* Klik ikon **➕ Upload** di pojok kanan atas area file.
* Pilih file dari komputer yang ingin diunggah.
* File akan tersimpan di folder utama pengguna dan dapat diakses kapan saja.

### 3. Mengunduh (Download) File

* Klik kanan pada file yang ingin diunduh, lalu pilih **Download**.
* File akan otomatis tersimpan di perangkat lokal pengguna.

### 4. Membuat Folder Baru

* Klik ikon **Folder Baru**.
* Beri nama folder sesuai kebutuhan.
* Folder ini bisa diisi file pribadi atau dibagikan dengan pengguna lain.

### 5. Berbagi File atau Folder

* Klik ikon **Share (bagikan)** di samping file/folder.
* Pilih **Share link** untuk membagikan kepada publik, atau **Share with users** untuk membatasi akses hanya ke pengguna tertentu.
* Dapat ditambahkan **password** dan **tanggal kadaluarsa** untuk keamanan.

### 6. Sinkronisasi dengan Aplikasi Desktop dan Mobile

* Unduh aplikasi Nextcloud Desktop (Windows, macOS, Linux) atau Mobile (Android, iOS) dari [https://nextcloud.com/install](https://nextcloud.com/install).
* Masukkan URL server (misal `https://drive.hq.idenx.id`) dan login dengan akun Nextcloud kamu.
* Aplikasi akan otomatis menyinkronkan file antara perangkat dan server.

### 7. Menggunakan Aplikasi Tambahan

* Dari menu pojok kanan atas, klik **Apps** untuk melihat daftar aplikasi tambahan seperti:

  * **Talk:** video call dan chat.
  * **Calendar:** kalender dan sinkronisasi dengan perangkat.
  * **Contacts:** manajemen kontak.
  * **OnlyOffice/Collabora:** untuk mengedit dokumen langsung di browser.

### 8. Mengganti Tema atau Bahasa

* Klik profil di pojok kanan atas → **Settings** → **Personal Info**.
* Di bagian **Appearance**, pilih tema terang/gelap.
* Di bagian **Language**, ubah ke Bahasa Indonesia atau bahasa lain sesuai preferensi.

[⬆️ Kembali ke atas](#📑-daftar-isi)

---

## Keamanan & Backup

### Keamanan Dasar

* Aktifkan TLS (HTTPS) dengan Let's Encrypt melalui Nginx Proxy Manager.
* Selalu perbarui image Docker dan host OS.
* Gunakan firewall (ufw) untuk membatasi akses hanya pada port yang diperlukan (80, 443, SSH).
* Konfigurasi file permission: data directory harus milik www-data pada container Nextcloud.

### Backup

Contoh strategi backup sederhana:

* Backup file data (sinkron ke disk eksternal atau NAS) setiap hari.
* Backup database (dump MariaDB) setiap hari.
* Simpan rotasi backup 7 hari.
* Contoh skrip backup ada di folder `scripts/` (tidak disertakan di sini, bisa dibuat terpisah).

[⬆️ Kembali ke atas](#📑-daftar-isi)

---

## Pembahasan

* Implementasi container memudahkan replikasi dan manajemen layanan.
* Bottleneck yang paling mungkin adalah I/O storage dan bandwidth uplink.
* Untuk skala lebih besar, pertimbangkan integrasi object storage (S3) atau NFS dengan performa lebih baik.

[⬆️ Kembali ke atas](#📑-daftar-isi)

---

## Kesimpulan & Saran

* Nextcloud cocok untuk kebutuhan kampus skala kecil sampai menengah dengan kontrol penuh atas data.
* Rekomendasi: gunakan SSD untuk data directory, atur backup otomatis, dan pantau resource secara periodik.
* Pengembangan lanjutan: integrasi OnlyOffice/Collabora untuk editing dokumen real-time, dan konfigurasi clustering untuk high-availability.

[⬆️ Kembali ke atas](#📑-daftar-isi)

---

## Lampiran

* `docker-compose.yml` — konfigurasi service
* `diagram-arsitektur.png` — diagram topologi
* `scripts/` — (opsional) skrip backup dan maintenance

[⬆️ Kembali ke atas](#📑-daftar-isi)

---

## Troubleshooting Umum

Berikut beberapa permasalahan umum yang sering muncul saat implementasi Nextcloud self-hosted menggunakan Docker dan Nginx Proxy Manager, beserta solusinya:

### 1. Port 80/443 Sudah Digunakan

**Masalah:**
Pesan error seperti `Bind for 0.0.0.0:80 failed: port is already allocated` saat menjalankan `docker-compose up`.

**Solusi:**

* Pastikan tidak ada service lain yang menggunakan port tersebut (contoh: Apache).
* Jalankan `sudo lsof -i :80` atau `sudo netstat -tulpn | grep :80` untuk melihat proses yang memakai port.
* Hentikan service tersebut dengan `sudo systemctl stop apache2`.

### 2. SSL Tidak Aktif / Sertifikat Gagal Terbit

**Masalah:**
Nginx Proxy Manager gagal membuat sertifikat Let's Encrypt.

**Solusi:**

* Pastikan domain mengarah ke IP publik server (gunakan `ping drive.hq.idenx.id`).
* Port 80 dan 443 harus dapat diakses dari luar jaringan.
* Coba ulangi pembuatan sertifikat dengan menonaktifkan firewall sementara (`sudo ufw disable`).

### 3. Nextcloud Tidak Bisa Diakses Setelah Restart

**Masalah:**
Setelah reboot server, container tidak otomatis berjalan.

**Solusi:**

* Pastikan setiap service di `docker-compose.yml` memiliki opsi `restart: unless-stopped`.
* Jalankan `docker ps -a` untuk memastikan semua container aktif.
* Jika belum berjalan, jalankan `docker compose up -d`.

### 4. File Upload Gagal di Atas Ukuran Tertentu

**Masalah:**
Upload file besar (misalnya >512 MB) gagal atau berhenti di tengah.

**Solusi:**

* Edit file `config.php` Nextcloud, tambahkan:

  ```php
  'php.upload_max_filesize' => '2G',
  'php.post_max_size' => '2G',
  'php.memory_limit' => '512M',
  ```
* Restart container Nextcloud: `docker restart nc-tristan-app`.

### 5. DNS Lokal Tidak Resolve

**Masalah:**
Domain `drive.hq.idenx.id` tidak bisa diakses dari dalam jaringan lokal, tapi bisa dari luar.

**Solusi:**

* Tambahkan entri DNS manual di `/etc/hosts` untuk mengarahkan domain ke IP lokal.

  ```
  192.168.1.10  drive.hq.idenx.id
  ```
* Jika menggunakan router dengan DNS internal, tambahkan record A di DNS router.

### 6. Database Connection Error

**Masalah:**
Nextcloud menampilkan pesan `Error: Can't connect to database`.

**Solusi:**

* Periksa container database dengan `docker logs nc-tristan-db`.
* Pastikan environment `MYSQL_*` di `docker-compose.yml` sesuai.
* Jalankan ulang urutan container:

  ```bash
  docker compose down
  docker compose up -d db
  sleep 10
  docker compose up -d app
  ```

[⬆️ Kembali ke atas](#📑-daftar-isi)

---

## Referensi

* Dokumentasi resmi Nextcloud: [https://nextcloud.com](https://nextcloud.com)
* Dokumentasi Docker: [https://docs.docker.com](https://docs.docker.com)
