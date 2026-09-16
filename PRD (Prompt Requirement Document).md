# PRD — RDP Awan macOS

## 1. Identitas Project

**Nama project:** RDP Awan macOS  
**Platform:** GitHub Actions  
**Runner:** `macos-latest`  
**Repository:** Repository baru, terpisah dari project RDP Windows  
**Tujuan:** Membuat lingkungan macOS sementara yang dapat diakses secara remote dari perangkat pengguna melalui jaringan privat Tailscale.

---

## 2. Latar Belakang

Project ini merupakan pengembangan terpisah dari project `RDP-Awan` yang sebelumnya menggunakan Windows GitHub Actions sebagai remote desktop.

Repository Windows **tidak boleh diubah**.

Project baru harus dibuat khusus untuk macOS dan tidak boleh berasumsi bahwa mekanisme Windows RDP dapat digunakan langsung di macOS.

Referensi konsep project sebelumnya:

- Repository Windows: `https://github.com/gunawan-ly/RDP-Awan.git`
- Target baru: `macos-latest`

---

## 3. Tujuan Utama

Membangun workflow GitHub Actions yang:

1. Menjalankan `macos-latest`.
2. Menyiapkan lingkungan macOS agar dapat digunakan secara remote.
3. Menggunakan **Tailscale sebagai jaringan privat utama**.
4. Menyediakan akses GUI macOS dari perangkat pengguna.
5. Meminimalkan konfigurasi yang harus dilakukan secara manual.
6. Menjaga setiap komponen tetap modular agar mudah diperbaiki atau diganti.
7. Tidak mengganggu atau bergantung secara langsung pada repository RDP Windows.

---

## 4. Arsitektur yang Diinginkan

Konsep umum:

```text
                 GitHub Actions
                       │
                       ▼
                macos-latest
                       │
             ┌─────────┴─────────┐
             │                   │
        macOS GUI            Tailscale
             │                   │
             └─────────┬─────────┘
                       │
                 Tailscale Network
                       │
                       ▼
                Perangkat User
                       │
                       ▼
                 VNC Client
```

Tailscale digunakan untuk menghubungkan perangkat user dengan runner macOS melalui jaringan privat.

**Jangan mengekspos VNC secara langsung ke internet jika dapat dihindari.**

---

# 5. Tahapan Pengembangan

Project harus dikerjakan secara bertahap.

Jangan langsung membuat seluruh sistem dalam satu workflow besar.

## Phase 1 — macOS Runner

Buat workflow dasar menggunakan:

```yaml
runs-on: macos-latest
```

Workflow harus dapat:

- menjalankan runner;
- menampilkan versi macOS;
- menampilkan arsitektur CPU;
- menampilkan user aktif;
- menampilkan hostname;
- menampilkan informasi disk;
- memastikan environment dapat menjalankan shell script;
- mempertahankan workflow tetap berjalan untuk pengujian berikutnya.

Tujuan Phase 1:

> Memastikan runner macOS dapat berjalan dengan stabil sebelum memasang komponen remote access.

---

## Phase 2 — Tailscale

Setelah Phase 1 berhasil, tambahkan Tailscale.

Target:

```text
macos-latest
      │
      ▼
  Tailscale
      │
      ▼
Tailscale Network
```

Persyaratan:

- Tailscale harus berjalan sebagai bagian dari workflow.
- Authentication menggunakan GitHub Actions Secrets.
- Jangan menuliskan authentication key secara langsung di source code.
- Jangan mencetak secret ke log.
- Setelah terhubung, tampilkan informasi non-sensitif yang diperlukan untuk mengetahui bahwa runner berhasil masuk ke jaringan Tailscale.
- Verifikasi konektivitas dari perangkat user.

Secret yang kemungkinan diperlukan:

```text
TAILSCALE_AUTH_KEY
```

Namun agent harus memverifikasi sendiri apakah secret tersebut merupakan metode yang paling sesuai berdasarkan dokumentasi Tailscale/GitHub Actions saat ini.

**Jangan membuat secret tambahan jika memang tidak diperlukan.**

---

# 6. Phase 3 — Remote GUI

Setelah Tailscale berhasil, siapkan mekanisme remote GUI untuk macOS.

Target:

```text
User Device
     │
     │ Tailscale
     ▼
macOS Runner
     │
     ▼
macOS GUI
```

Pendekatan awal yang perlu diteliti adalah:

- VNC server;
- macOS Screen Sharing;
- atau solusi remote GUI lain yang kompatibel dengan GitHub-hosted macOS runner.

Agent harus memilih pendekatan berdasarkan:

1. kompatibilitas dengan `macos-latest`;
2. dapat berjalan tanpa interaksi fisik;
3. dapat dikontrol melalui shell/workflow;
4. dapat diakses melalui Tailscale;
5. stabil selama workflow berjalan;
6. tidak memerlukan port VNC terbuka ke internet.

Jangan berasumsi bahwa mekanisme RDP Windows dapat digunakan.

---

# 7. Phase 4 — Remote Desktop Integration

Setelah GUI berhasil diakses, integrasikan seluruh komponen:

```text
GitHub Actions
      │
      ▼
macOS Runner
      │
      ├── macOS GUI
      │
      ├── Remote GUI Server
      │
      └── Tailscale
             │
             ▼
         User Device
```

Workflow idealnya dapat melakukan setup secara otomatis.

User hanya perlu:

1. menjalankan workflow;
2. menunggu setup selesai;
3. mendapatkan informasi koneksi yang diperlukan;
4. membuka client remote desktop/VNC;
5. terhubung melalui Tailscale.

---

# 8. Keep Alive

Runner harus tetap hidup selama masih digunakan.

GitHub Actions runner bersifat sementara.

Karena itu workflow membutuhkan mekanisme agar job tetap berjalan selama sesi remote desktop digunakan.

Namun:

- jangan membuat infinite loop sebelum seluruh setup berhasil;
- setup harus selesai terlebih dahulu;
- berikan log/status yang jelas;
- gunakan mekanisme keep-alive yang sederhana dan mudah dihentikan.

Contoh konsep:

```text
Start
  ↓
Setup macOS
  ↓
Setup Tailscale
  ↓
Setup Remote GUI
  ↓
Verify
  ↓
READY
  ↓
Keep Alive
```

---

# 9. Struktur Repository

Gunakan struktur modular.

Struktur awal yang direkomendasikan:

```text
RDP-Awan-macOS/
│
├── .github/
│   └── workflows/
│       └── macos.yml
│
├── scripts/
│   ├── setup-tailscale.sh
│   ├── setup-vnc.sh
│   └── keep-alive.sh
│
└── README.md
```

Struktur tersebut **bukan aturan mutlak**.

Agent boleh mengubah struktur jika memiliki alasan teknis yang jelas.

Hindari membuat terlalu banyak file hanya untuk memecah script kecil.

---

# 10. GitHub Secrets

Jangan menentukan secret berdasarkan asumsi dari project Windows.

Audit kebutuhan secret terlebih dahulu.

Secret awal yang diperkirakan:

```text
TAILSCALE_AUTH_KEY
```

Jika remote GUI membutuhkan credential:

```text
VNC_PASSWORD
```

atau metode credential lain yang lebih sesuai.

Ketentuan:

- Semua credential sensitif harus menggunakan GitHub Secrets.
- Tidak boleh hardcode credential.
- Tidak boleh echo secret ke log.
- Jangan menyimpan credential di repository.
- Gunakan permission seminimal mungkin.

---

# 11. Keamanan

Prioritas keamanan:

### Tailscale

Gunakan Tailscale sebagai jaringan privat.

Hindari:

```text
Internet → VNC port → macOS
```

Lebih diutamakan:

```text
User
  │
Tailscale
  │
macOS Runner
```

### Secrets

Tidak boleh ada:

```bash
echo "$TAILSCALE_AUTH_KEY"
```

atau bentuk lain yang menyebabkan credential muncul pada log.

### Repository

Jangan commit:

- auth key;
- password;
- token;
- credential;
- session key;
- konfigurasi yang mengandung secret.

---

# 12. Persyaratan Teknis

Gunakan shell dan tooling yang memang tersedia atau dapat dipasang pada `macos-latest`.

Sebelum menggunakan command tertentu:

1. periksa apakah command tersedia;
2. periksa arsitektur runner;
3. periksa permission;
4. jika membutuhkan instalasi software, gunakan metode yang kompatibel dengan macOS runner.

Jangan menyalin command PowerShell/Windows lalu menganggapnya kompatibel.

---

# 13. Dokumentasi

Setiap tahap harus menghasilkan informasi yang cukup untuk debugging.

Log harus menjelaskan:

```text
[INFO] macOS setup started
[INFO] Tailscale setup started
[INFO] Tailscale connected
[INFO] Remote GUI setup started
[INFO] Remote GUI ready
[INFO] Connection information available
[INFO] Keep-alive started
```

Jangan tampilkan credential sensitif.

README harus menjelaskan:

- cara membuat repository;
- cara menambahkan GitHub Secrets;
- cara menjalankan workflow;
- cara mengetahui runner sudah siap;
- cara terhubung dari perangkat user;
- cara menghentikan session;
- batasan GitHub-hosted runner.

---

# 14. Prinsip Pengembangan

## Jangan Overengineering

Tujuan project adalah membuat remote macOS yang dapat digunakan.

Jangan membuat:

- framework yang tidak diperlukan;
- service yang kompleks;
- konfigurasi berlebihan;
- dependency yang tidak diperlukan.

---

## Modular

Komponen berikut sebaiknya terpisah:

```text
macOS setup
     │
     ├── Tailscale
     │
     ├── Remote GUI
     │
     └── Keep Alive
```

Sehingga jika VNC diganti dengan metode lain, konfigurasi Tailscale tidak perlu ditulis ulang.

---

## Incremental Testing

Setiap phase harus diuji sebelum melanjutkan.

Urutan:

```text
Phase 1
macOS runner
    ↓
TEST
    ↓
Phase 2
Tailscale
    ↓
TEST
    ↓
Phase 3
Remote GUI
    ↓
TEST
    ↓
Phase 4
Integration
    ↓
TEST
    ↓
FINAL
```

Jika suatu phase gagal, berhenti di phase tersebut dan debug terlebih dahulu.

---

# 15. Kriteria Keberhasilan

Project dianggap berhasil apabila:

### Runner

- `macos-latest` berhasil dijalankan.
- macOS environment dapat digunakan melalui shell.
- workflow tetap berjalan selama sesi remote.

### Tailscale

- runner berhasil masuk ke Tailnet;
- perangkat user dapat melihat runner;
- koneksi privat dapat digunakan.

### GUI

- macOS GUI dapat diakses dari perangkat user;
- mouse dan keyboard dapat digunakan;
- koneksi dilakukan melalui jaringan Tailscale.

### Integration

Dengan menjalankan satu workflow, sistem dapat melakukan:

```text
Start
 ↓
macOS
 ↓
Tailscale
 ↓
Remote GUI
 ↓
Verification
 ↓
READY
 ↓
Remote Session
```

---

# 16. Hubungan Dengan Project RDP Windows

Repository:

```text
RDP-Awan
```

merupakan referensi konsep saja.

**Jangan mengubah repository tersebut.**

Gunakan repository baru untuk macOS.

Jika ada konsep dari project Windows yang ingin digunakan kembali, evaluasi apakah konsep tersebut memang platform-independent.

Contoh:

|Komponen|Windows|macOS|
|---|---|---|
|GitHub Actions|Ya|Ya|
|Hosted runner|Ya|Ya|
|Keep-alive|Ya|Ya|
|Tailscale|Ya|Ya|
|PowerShell|Ya|Tidak menjadi dasar|
|Windows RDP|Ya|Tidak|
|VNC|Bisa|Kandidat utama|
|macOS Screen Sharing|Tidak|Kandidat|

---

# 17. Cara Agent Bekerja

Agent tidak diharuskan mengikuti desain teknis di atas secara buta.

Agent harus:

1. membaca PRD ini;
2. memahami tujuan;
3. melakukan analisis terhadap environment `macos-latest`;
4. memeriksa dokumentasi resmi jika diperlukan;
5. mengidentifikasi keterbatasan;
6. memilih implementasi yang paling sesuai;
7. membuat perubahan;
8. menguji setiap phase;
9. melaporkan hasil dan masalah.

Jika menemukan asumsi dalam PRD yang secara teknis salah, **jangan dipaksakan**.

Laporkan:

```text
Asumsi:
...

Masalah:
...

Temuan:
...

Solusi yang disarankan:
...
```

---

# 18. Aturan Komunikasi Dengan Penghubung

Project ini dikembangkan secara kolaboratif.

User akan menjadi penghubung antara agent implementasi dan pihak yang melakukan review/arsitektur.

Jika agent menemukan keputusan teknis yang memiliki beberapa pilihan signifikan, jangan mengambil keputusan besar secara diam-diam.

Berikan:

1. masalah;
2. opsi;
3. konsekuensi masing-masing;
4. rekomendasi teknis agent;
5. hal yang perlu diputuskan user.

Contoh:

```text
Masalah:
Metode A tidak kompatibel dengan macos-latest.

Opsi:
A. VNC Server
B. Screen Sharing
C. Solusi C

Rekomendasi:
B

Alasan:
...

Keputusan yang dibutuhkan:
Apakah lanjut dengan B?
```

---

# 19. Output Yang Diharapkan Dari Agent

Pada setiap tahap, agent harus melaporkan:

### Status

```text
Phase: 1
Status: SUCCESS / FAILED / BLOCKED
```

### Perubahan

Daftar file yang dibuat/diubah.

### Testing

Command atau workflow yang diuji.

### Hasil

Apa yang berhasil dan apa yang belum.

### Next Step

Langkah berikutnya yang disarankan.

---

# 20. Kondisi Awal

Mulai dari repository baru.

Jangan mengasumsikan bahwa:

- Tailscale sudah terpasang;
- VNC sudah tersedia;
- credential sudah tersedia;
- konfigurasi Windows dapat digunakan;
- GUI sudah siap;
- runner memiliki service tertentu.

Semua harus diverifikasi pada `macos-latest`.

---

# 21. Langkah Pertama Agent

**Jangan langsung membangun seluruh project.**

Mulai dengan Phase 1.

Tugas pertama:

1. Buat workflow `.github/workflows/macos.yml`.
2. Gunakan `macos-latest`.
3. Verifikasi environment.
4. Jalankan workflow.
5. Pastikan runner dapat dipertahankan hidup.
6. Laporkan hasil.
7. Tunggu arahan berikutnya sebelum melakukan perubahan besar.

Setelah Phase 1 tervalidasi, lanjutkan ke Phase 2.