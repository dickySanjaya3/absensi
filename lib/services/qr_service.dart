class QRService {
  /// Validasi QR yang di-scan guru.
  /// [payload] = hasil scan mentah dari kamera.
  /// [students] = daftar siswa satu kelas (List<Map>) hasil getStudents(),
  ///   masing-masing punya field 'ID' dan 'QRCode' (QR yang sedang aktif).
  ///
  /// QR dianggap valid HANYA jika persis sama dengan QRCode yang tersimpan
  /// di sheet untuk siswa tsb (bukan dihitung ulang secara lokal). Ini
  /// membuat fitur "generate ulang barcode" benar-benar menonaktifkan QR lama.
  static String? validateQR(String payload, List<Map<String, dynamic>> students) {
    for (final s in students) {
      final activeQr = (s['QRCode'] ?? '').toString();
      if (activeQr.isNotEmpty && activeQr == payload) {
        return (s['ID'] ?? '').toString();
      }
    }
    return null; // tidak ada siswa dengan QRCode aktif yang cocok
  }
}