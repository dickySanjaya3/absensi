# Absensi Siswa QR

## Login

Login selalu memeriksa email dan password langsung ke spreadsheet. Akun Google
yang dipilih pada dialog Google Sign-In harus memiliki akses edit ke spreadsheet.
Isi akun admin pada tab `Admin` sebelum login pertama kali.

## Struktur Google Sheets

Gunakan spreadsheet dengan ID yang ada di `lib/services/sheets_services.dart`
dan buat tab berikut. Baris pertama adalah header, data dimulai dari baris 2.

| Tab | Kolom |
| --- | --- |
| `Admin` | `Email`, `Password`, `Nama` |
| `Akun Guru` | `Email`, `Nama Guru`, `Status`, `Password` |
| `Kelas` | `Nama Kelas` |
| `Siswa` | `ID`, `Nama Siswa`, `Kelas`, `NIM` |
| `Assignment` | `Email Guru`, `Kelas`, `Mata Pelajaran` |
| `Absensi` | `timestamp`, `emailGuru`, `kelas`, `mapel`, `siswaId`, `status` |

Admin membuka menu **Kelola Akun Guru** untuk tambah, edit, dan hapus akun.
Setiap perubahan ditulis langsung ke tab `Akun Guru`, sehingga akun tersebut dapat
digunakan pada login berikutnya.

Menu **CRUD Data Siswa** membaca dan mengelola tab `Siswa`. Menu **Kelola
Assignment** menghubungkan guru dengan kelas dan mata pelajaran. Guru hanya
melihat assignment miliknya, dan hasil scan QR serta perubahan status riwayat
ditulis ke tab `Absensi` dengan filter guru, kelas, dan mapel.

Saat admin membuka salah satu menu pengelolaan, aplikasi otomatis membuat tab
dan header yang belum tersedia. Untuk tab `Akun Guru` lama yang hanya memiliki
tiga kolom, aplikasi menambahkan kolom `Password` di kolom D. Data lama tidak
dihapus.

## Izin akses

Akun Google yang dipakai aplikasi untuk otorisasi API harus memiliki akses edit
ke spreadsheet. Google Sign-In digunakan sebagai izin teknis ke Sheets; form
login aplikasi tetap menggunakan email dan password pada tab `Admin` atau
`Akun Guru`.

Password pada spreadsheet saat ini disimpan sebagai teks biasa karena format
tersebut diperlukan untuk verifikasi langsung dari aplikasi. Untuk produksi,
gunakan backend autentikasi khusus (misalnya Firebase Authentication) dan
simpan hanya identitas/role di Sheets.
# absensi

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
