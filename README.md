# GM CAFE - Gadung Melati Kasir
Sistem Kasir (Point of Sale) untuk Gadung Melati Cafe yang mendukung sinkronisasi Cloud menggunakan Google Spreadsheet.

## 🚀 Live Release (Web)
Aplikasi ini dapat diakses secara langsung melalui link berikut:
👉 **[https://gm-cafe.web.app/](https://gm-cafe.web.app/)**

## ✨ Fitur Utama
- **Multi-Platform:** Berjalan di Android dan Web.
- **Cloud Sync:** Menggunakan Google Spreadsheet sebagai database utama untuk sinkronisasi menu, meja, dan laporan.
- **Offline Mode:** Mendukung database lokal (SQFlite) untuk Android saat tidak ada koneksi internet.
- **Cetak Struk:** Integrasi printer Bluetooth (untuk versi Android).
- **Laporan Keuangan:** Laporan penjualan, pengeluaran, dan laba/rugi yang bisa diekspor ke Excel.
- **Manajemen Meja:** Dashboard visual untuk memantau meja yang terisi.

## 🛠️ Teknologi
- **Framework:** Flutter
- **Database:** Google Apps Script + Spreadsheet (Cloud) & SQFlite (Lokal)
- **Deployment:** Firebase Hosting & GitHub Actions

## 📦 Cara Menjalankan Project
1. Clone repository ini.
2. Jalankan `flutter pub get`.
3. Masukkan URL Google Apps Script Anda di menu Pengaturan Admin.
4. Jalankan aplikasi menggunakan `flutter run`.

---
*Support by @sagetdandan*
