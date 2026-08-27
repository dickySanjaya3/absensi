import 'package:flutter/material.dart';

import '../../services/sheets_services.dart';

/// Daftar status yang bisa dipilih guru untuk tiap siswa.
const List<String> kStatusOptions = ['Hadir', 'Izin', 'Sakit', 'Alpa'];

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
      Navigator.pop(context, true); // beri tahu layar sebelumnya: sukses
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $errorMsg')),
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
                                DropdownButton<String>(
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
                                    setState(() => _statusPerSiswa[id] = val);
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
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _simpan,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Simpan Absensi'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}