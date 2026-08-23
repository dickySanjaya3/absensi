class QRService {
  /// Validasi QR yang di-scan guru.
  /// [payload] = hasil scan mentah dari kamera.
  /// [students] = daftar siswa satu kelas (List<Map>) hasil getStudents(),
  ///   masing-masing punya field 'ID' dan 'Barcode' (QR yang sedang aktif,
  ///   nama kolom di backend adalah 'Barcode', BUKAN 'QRCode').
  ///
  /// QR dianggap valid HANYA jika persis sama dengan Barcode yang tersimpan
  /// di sheet untuk siswa tsb (bukan dihitung ulang secara lokal). Ini
  /// membuat fitur "generate ulang barcode" benar-benar menonaktifkan QR lama.
  static String? validateQR(String payload, List<Map<String, dynamic>> students) {
    for (final s in students) {
      final activeQr = (s['Barcode'] ?? '').toString();
      if (activeQr.isNotEmpty && activeQr == payload) {
        return (s['ID'] ?? '').toString();
      }
    }
    return null; // tidak ada siswa dengan QRCode aktif yang cocok
  }
}