import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/qr_service.dart';
import '../../services/sheets_services.dart';
import 'onboarding_screen.dart';
import 'review_absensi_screen.dart';
import 'riwayat_screen.dart';

class GuruDashboard extends StatefulWidget {
  final String kelas;
  final String mapel;

  const GuruDashboard({super.key, required this.kelas, required this.mapel});

  @override
  State<GuruDashboard> createState() => _GuruDashboardState();
}

class _GuruDashboardState extends State<GuruDashboard> {
  int _currentIndex = 0;
  final SheetsService _sheetsService = SheetsService();

  // Hasil scan sesi ini yang BELUM disimpan ke backend: siswaId -> status.
  // Diisi tiap kali scan sukses, dikosongkan lagi setelah berhasil disimpan
  // lewat layar "Tinjau Absensi".
  final Map<String, String> _scanResults = {};
  List<Map<String, dynamic>> _studentsCache = [];

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Kamu perlu login lagi untuk masuk ke aplikasi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthService>().signOut();
    }
  }

  void _openCameraScanner() {
    // Cegah 1 kode QR yang sama terdeteksi berkali-kali dalam waktu singkat
    // (kamera bisa fire onDetect beberapa kali per detik untuk kode yang sama).
    DateTime? lastDetectAt;
    String? lastCode;

    // PENTING: variabel overlay HARUS di luar builder StatefulBuilder.
    // Kalau dideklarasikan di dalam builder, tiap kali setModalState()
    // dipanggil, builder dijalankan ulang dan variabel ini ke-reset ke
    // null sebelum sempat dirender -> overlay tidak akan pernah muncul.
    String? overlayNama;
    bool overlaySukses = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          void showOverlay(String nama, bool sukses) {
            setModalState(() {
              overlayNama = nama;
              overlaySukses = sukses;
            });
            Future.delayed(const Duration(milliseconds: 900), () {
              if (context.mounted) {
                setModalState(() => overlayNama = null);
              }
            });
          }

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                AppBar(
                  title: const Text('Pindai QR Siswa'),
                  automaticallyImplyLeading: false,
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Selesai',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Arahkan kamera ke kartu QR tiap siswa satu per satu. '
                    'Scanner tetap terbuka sampai kamu tekan "Selesai".',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MobileScanner(
                        onDetect: (capture) {
                          final List<Barcode> barcodes = capture.barcodes;
                          if (barcodes.isEmpty) return;
                          final String rawCode = barcodes.first.rawValue ?? '';
                          if (rawCode.isEmpty) return;

                          final now = DateTime.now();
                          if (rawCode == lastCode &&
                              lastDetectAt != null &&
                              now.difference(lastDetectAt!) <
                                  const Duration(seconds: 2)) {
                            return; // masih kode yang sama, abaikan supaya tidak dobel
                          }
                          lastCode = rawCode;
                          lastDetectAt = now;

                          _processAttendance(rawCode, showOverlay);
                        },
                      ),
                      // Overlay feedback: centang hijau (sukses) atau silang merah (gagal)
                      if (overlayNama != null)
                        Container(
                          color: Colors.black.withValues(alpha: 0.55),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                scale: 1.0,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.elasticOut,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: overlaySukses
                                        ? const Color(0xFF1FA97A)
                                        : const Color(0xFFE0587A),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    overlaySukses
                                        ? Icons.check_rounded
                                        : Icons.close_rounded,
                                    color: Colors.white,
                                    size: 56,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                overlayNama!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Scan QR TIDAK langsung menulis ke backend lagi. Hasil scan cuma
  /// disimpan ke state lokal (_scanResults) dulu; guru mengoreksi &
  /// mengirim semuanya sekaligus lewat layar "Tinjau Absensi".
  Future<void> _processAttendance(
    String qrData,
    void Function(String nama, bool sukses) showOverlay,
  ) async {
    if (_studentsCache.isEmpty) {
      _studentsCache = await _sheetsService.getStudents(kelas: widget.kelas);
    }
    final studentId = QRService.validateQR(qrData, _studentsCache);
    if (studentId == null) {
      HapticFeedback.heavyImpact();
      showOverlay('QR tidak valid /\nbukan siswa kelas ini', false);
      return;
    }

    final nama = _studentsCache.firstWhere(
      (s) => (s['ID'] ?? '').toString() == studentId,
      orElse: () => const {},
    )['Nama']?.toString();

    setState(() => _scanResults[studentId] = 'Hadir');

    HapticFeedback.mediumImpact();
    showOverlay(nama?.isNotEmpty == true ? nama! : studentId, true);
  }

  Future<void> _bukaTinjauAbsensi() async {
    final email = context.read<AuthService>().currentUser?.email;
    if (email == null) return;

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewAbsensiScreen(
          kelas: widget.kelas,
          mapel: widget.mapel,
          guruEmail: email,
          scanResults: Map<String, String>.from(_scanResults),
        ),
      ),
    );

    if (saved == true && mounted) {
      setState(() {
        _scanResults.clear(); // sesi absen selesai, mulai bersih lagi
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Absensi berhasil disimpan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _BerandaTab(
        key: ValueKey('${widget.kelas}-${widget.mapel}-$_currentIndex'),
        kelas: widget.kelas,
        mapel: widget.mapel,
        onLihatSemua: () => setState(() => _currentIndex = 2),
      ),
      const SizedBox.shrink(), // Placeholder index 1 (Tombol Scan)
      RiwayatScreen(kelas: widget.kelas, mapel: widget.mapel),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('${widget.kelas} - ${widget.mapel}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Ganti Kelas/Mapel',
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const OnboardingKelasMapelScreen(),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: pages[_currentIndex],
      floatingActionButton: _scanResults.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _bukaTinjauAbsensi,
              icon: const Icon(Icons.fact_check_rounded),
              label: Text('Tinjau (${_scanResults.length})'),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) {
            // Tombol Beranda -> kembali ke halaman pilih kelas & mapel.
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const OnboardingKelasMapelScreen(),
              ),
            );
          } else if (index == 1) {
            _openCameraScanner(); // Tombol tengah langsung membuka scanner (F-GURU-05)
          } else {
            setState(() => _currentIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 24,
              child: Icon(Icons.qr_code_scanner, color: Colors.white),
            ),
            label: 'Scan QR',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
        ],
      ),
    );
  }
}

class _BerandaTab extends StatefulWidget {
  final String kelas;
  final String mapel;
  final VoidCallback onLihatSemua;

  const _BerandaTab({
    super.key,
    required this.kelas,
    required this.mapel,
    required this.onLihatSemua,
  });

  @override
  State<_BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<_BerandaTab> {
  final SheetsService _sheetsService = SheetsService();
  List<Map<String, dynamic>> _kehadiranHariIni = [];
  bool _loading = true;

  static const _namaBulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final email = context.read<AuthService>().currentUser?.email;
    if (email == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final semua = await _sheetsService.getAttendance(
      emailGuru: email,
      kelas: widget.kelas,
      mapel: widget.mapel,
    );
    final now = DateTime.now();
    final hariIni = semua.where((item) {
      final ts = item['timestamp']?.toString();
      if (ts == null || ts.isEmpty) return false;
      final parsed = DateTime.tryParse(ts);
      if (parsed != null) {
        return parsed.year == now.year &&
            parsed.month == now.month &&
            parsed.day == now.day;
      }
      // fallback kalau formatnya bukan ISO, cek awal string 'yyyy-MM-dd'
      final todayStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      return ts.startsWith(todayStr);
    }).toList();

    if (!mounted) return;
    setState(() {
      _kehadiranHariIni = hariIni;
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
        return const Color(0xFFE0587A);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tanggalStr =
        '${now.day} ${_namaBulan[now.month - 1]} ${now.year}';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KELAS SAAT INI',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.kelas,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.mapel,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.dashboard_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daftar Kehadiran',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Hari ini, $tanggalStr',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
              TextButton(
                onPressed: widget.onLihatSemua,
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_kehadiranHariIni.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Belum ada siswa yang diabsen hari ini.\nTekan tombol scan untuk mulai.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            ..._kehadiranHariIni.map((item) {
              final nama = (item['nama'] ?? item['siswaId'] ?? '-').toString();
              final nis = item['nis']?.toString();
              final status = (item['status'] ?? '-').toString();
              final inisial = nama.isNotEmpty ? nama[0].toUpperCase() : '?';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                      child: Text(
                        inisial,
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nama,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (nis != null && nis.isNotEmpty)
                            Text(
                              'NIS: $nis',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}