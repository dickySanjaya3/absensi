import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/sheets_services.dart';
import '../../widgets/admin_widgets.dart';

/// Daftar status yang bisa dipilih guru untuk tiap siswa.
/// Hadir dihilangkan karena sudah otomatis dari scan QR
const List<String> kStatusOptions = ['Izin', 'Sakit', 'Alpa'];

/// Layar "Tinjau Absensi": menampilkan SEMUA siswa satu kelas.
/// Siswa yang sudah discan QR otomatis berstatus 'Hadir' (bisa diubah),
/// siswa yang belum discan default 'Alpa' (bisa diubah manual).
/// Guru menekan "Simpan" sekali di akhir -> baru terkirim ke backend
/// lewat 1 request batch (writeAttendanceBatch).
class ReviewAbsensiScreen extends StatefulWidget {
  final String kelas;
  final String mapel;
  final String guruEmail;

  /// siswaId -> status, hasil dari scan QR sebelumnya (biasanya semua 'Hadir').
  final Map<String, String> scanResults;

  const ReviewAbsensiScreen({
    super.key,
    required this.kelas,
    required this.mapel,
    required this.guruEmail,
    required this.scanResults,
  });

  @override
  State<ReviewAbsensiScreen> createState() => _ReviewAbsensiScreenState();
}

class _ReviewAbsensiScreenState extends State<ReviewAbsensiScreen> {
  final SheetsService _sheetsService = SheetsService();

  bool _loading = true;
  bool _saving = false;
  List<Map<String, dynamic>> _siswa = [];
  final Map<String, String> _statusPerSiswa = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final siswa = await _sheetsService.getStudents(kelas: widget.kelas);
    if (!mounted) return;
    setState(() {
      _siswa = siswa;
      for (final s in siswa) {
        final id = (s['ID'] ?? '').toString();
        // Kalau siswa ini sudah discan -> pakai status hasil scan (biasanya
        // 'Hadir'). Kalau belum discan -> default 'Alpa', guru bisa ganti.
        _statusPerSiswa[id] = widget.scanResults[id] ?? 'Alpa';
      }
      _loading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Hadir':
        return const Color(0xFF1FA97A);
      case 'Izin':
        return const Color(0xFF2F6FED);
      case 'Sakit':
        return const Color(0xFFE7A008);
      case 'Alpa':
      default:
        return const Color(0xFFE0587A);
    }
  }

  Future<void> _simpan() async {
    setState(() => _saving = true);
    final items = _siswa.map((s) {
      final id = (s['ID'] ?? '').toString();
      return {
        'siswaId': id,
        'status': _statusPerSiswa[id] ?? 'Alpa',
      };
    }).toList();

    final errorMsg = await _sheetsService.writeAttendanceBatch(
      guruEmail: widget.guruEmail,
      kelas: widget.kelas,
      mapel: widget.mapel,
      items: items,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (errorMsg == null) {
      // Success - tampilkan dialog cantik
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1FA97A),
                  Color(0xFF16825E),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon success
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                Text(
                  'Berhasil!',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Message
                Text(
                  'Absensi berhasil disimpan untuk ${_siswa.length} siswa',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Auto redirect message
                Text(
                  'Kembali ke dashboard...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      
      // Auto close dialog dan kembali ke dashboard setelah 2 detik
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      
      // Close dialog
      Navigator.of(context).pop();
      // Close review screen dan kembali ke dashboard
      Navigator.of(context).pop(true);
    } else {
      // Error - tampilkan toast
      showModernToast(
        context: context,
        message: 'Gagal menyimpan: $errorMsg',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sudahDiscanCount =
        _statusPerSiswa.values.where((s) => s == 'Hadir').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          // Custom Header with rounded bottom
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF005DA7),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Tinjau Absensi - ${widget.kelas}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Info banner
          Container(
            width: double.infinity,
            color: Colors.indigo.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Text(
              '$sudahDiscanCount dari ${_siswa.length} siswa sudah discan. '
              'Sisanya bisa kamu isi manual di bawah sebelum disimpan.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          // Body content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _siswa.isEmpty
                    ? const Center(child: Text('Belum ada siswa di kelas ini.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _siswa.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final s = _siswa[index];
                          final id = (s['ID'] ?? '').toString();
                          final nama = (s['Nama'] ?? '-').toString();
                          final status = _statusPerSiswa[id] ?? 'Alpa';

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      Colors.indigo.withValues(alpha: 0.1),
                                  child: Text(
                                    nama.isNotEmpty
                                        ? nama[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.indigo,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    nama,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                // Dropdown atau badge read-only untuk "Hadir"
                                _statusPerSiswa[id] == 'Hadir'
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _statusColor('Hadir')
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              size: 16,
                                              color: _statusColor('Hadir'),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Hadir',
                                              style: TextStyle(
                                                color: _statusColor('Hadir'),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : DropdownButton<String>(
                                        value: status,
                                        underline: const SizedBox.shrink(),
                                        items: kStatusOptions
                                            .map(
                                              (opt) => DropdownMenuItem(
                                                value: opt,
                                                child: Text(
                                                  opt,
                                                  style: TextStyle(
                                                    color: _statusColor(opt),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) {
                                          if (val == null) return;
                                          setState(
                                              () => _statusPerSiswa[id] = val);
                                        },
                                      ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            minimum: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF005DA7).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: const Border(
                    bottom: BorderSide(
                      color: Color(0xFF004883),
                      width: 4,
                    ),
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _saving ? null : _simpan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005DA7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.only(
                      top: 18,
                      bottom: 22,
                      left: 24,
                      right: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor:
                        const Color(0xFF005DA7).withValues(alpha: 0.6),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.save_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Simpan Absensi',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}