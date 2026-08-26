import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/qr_service.dart';
import '../../services/sheets_services.dart';
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

  final Map<String, String> _scanResults = {};
  List<Map<String, dynamic>> _studentsCache = [];

  Future<void> _openCameraScanner() async {
    // Refresh data siswa
    try {
      final students = await _sheetsService.getStudents(kelas: widget.kelas);
      if (!mounted) return;
      _studentsCache = students;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data siswa: $e')),
      );
      return;
    }

    // State untuk kendali
    bool isProcessing = false;
    String? lastCode;
    DateTime? lastDetectAt;
    bool overlayVisible = false;

    // Overlay state
    String? overlayNama;
    bool overlaySukses = true;

    // Controller
    final controller = MobileScannerController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          void showOverlay(String nama, bool sukses) {
            if (!context.mounted) return;
            setModalState(() {
              overlayNama = nama;
              overlaySukses = sukses;
              overlayVisible = true;
            });
            Future.delayed(const Duration(milliseconds: 900), () {
              if (context.mounted) {
                setModalState(() {
                  overlayNama = null;
                  overlayVisible = false;
                });
              }
            });
          }

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              children: [
                AppBar(
                  title: const Text('Pindai QR Siswa'),
                  automaticallyImplyLeading: false,
                  actions: [
                    TextButton(
                      onPressed: () {
                        controller.dispose();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Selesai',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Arahkan QR ke dalam bingkai untuk scan otomatis',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // ----- KAMERA -----
                      MobileScanner(
                        controller: controller,
                        onDetect: (capture) async {
                          if (isProcessing || overlayVisible) return;

                          final barcodes = capture.barcodes;
                          if (barcodes.isEmpty) return;
                          final rawCode = barcodes.first.rawValue ?? '';
                          if (rawCode.isEmpty) return;

                          final now = DateTime.now();
                          if (rawCode == lastCode &&
                              lastDetectAt != null &&
                              now.difference(lastDetectAt!) <
                                  const Duration(seconds: 2)) {
                            return;
                          }

                          lastCode = rawCode;
                          lastDetectAt = now;
                          isProcessing = true;

                          try {
                            await _processAttendance(rawCode, showOverlay);
                          } catch (e) {
                            debugPrint('Error proses absensi: $e');
                          }

                          await Future.delayed(const Duration(milliseconds: 500));
                          isProcessing = false;
                        },
                      ),

                      // ----- OVERLAY GRID / BINGKAI SCANNER -----
                      IgnorePointer(
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.transparent,
                          child: CustomPaint(
                            painter: ScannerOverlayPainter(
                              scanAreaSize: 220,
                              strokeWidth: 4,
                              cornerLength: 28,
                              borderColor: Colors.greenAccent,
                              label: 'Arahkan QR ke sini',
                            ),
                          ),
                        ),
                      ),

                      // ----- OVERLAY FEEDBACK (centang/silang) -----
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
    ).whenComplete(() {
      controller.dispose();
    });
  }

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

    if (!mounted) return;
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
      setState(() => _scanResults.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Absensi berhasil disimpan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nama = context.watch<AuthService>().currentUser?.nama ?? '';
    
    final pages = [
      _BerandaTab(
        key: ValueKey('${widget.kelas}-${widget.mapel}-$_currentIndex'),
        kelas: widget.kelas,
        mapel: widget.mapel,
        onLihatSemua: () => setState(() => _currentIndex = 2),
        scanResults: _scanResults,
      ),
      const SizedBox.shrink(),
      RiwayatScreen(kelas: widget.kelas, mapel: widget.mapel),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: const Color(0xFF005DA7),
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      nama.isNotEmpty ? nama : 'Guru',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: pages[_currentIndex],
      floatingActionButton: _scanResults.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _bukaTinjauAbsensi,
              backgroundColor: const Color(0xFF005DA7),
              icon: const Icon(Icons.fact_check_rounded),
              label: Text(
                'Tinjau (${_scanResults.length})',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Beranda Button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_currentIndex != 0) {
                        setState(() => _currentIndex = 0);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentIndex == 0
                            ? const Color(0xFF005DA7)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home,
                            color: _currentIndex == 0
                                ? Colors.white
                                : const Color(0xFF9CA3AF),
                            size: 22,
                          ),
                          if (_currentIndex == 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Beranda',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // QR Scanner Button
                GestureDetector(
                  onTap: _openCameraScanner,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFF005DA7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Riwayat Button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_currentIndex != 2) {
                        setState(() => _currentIndex = 2);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentIndex == 2
                            ? const Color(0xFF005DA7)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            color: _currentIndex == 2
                                ? Colors.white
                                : const Color(0xFF9CA3AF),
                            size: 22,
                          ),
                          if (_currentIndex == 2) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Riwayat',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== SCANNER OVERLAY PAINTER ====================

class ScannerOverlayPainter extends CustomPainter {
  final double scanAreaSize;
  final double strokeWidth;
  final double cornerLength;
  final Color borderColor;
  final String label;

  ScannerOverlayPainter({
    this.scanAreaSize = 220,
    this.strokeWidth = 4,
    this.cornerLength = 28,
    this.borderColor = Colors.greenAccent,
    this.label = 'Arahkan QR ke sini',
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Hitung posisi kotak scan di tengah
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2;
    final right = left + scanAreaSize;
    final bottom = top + scanAreaSize;

    // Buat gelap di luar area scan (dimming)
    final dimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Dimming: atas
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), dimPaint);
    // Dimming: bawah
    canvas.drawRect(
      Rect.fromLTWH(0, bottom, size.width, size.height - bottom),
      dimPaint,
    );
    // Dimming: kiri
    canvas.drawRect(Rect.fromLTWH(0, top, left, scanAreaSize), dimPaint);
    // Dimming: kanan
    canvas.drawRect(
      Rect.fromLTWH(right, top, size.width - right, scanAreaSize),
      dimPaint,
    );

    // --- Gambar sudut-sudut ---

    // Kiri Atas
    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), paint);

    // Kanan Atas
    canvas.drawLine(
      Offset(right - cornerLength, top),
      Offset(right, top),
      paint,
    );
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerLength), paint);

    // Kiri Bawah
    canvas.drawLine(
      Offset(left, bottom - cornerLength),
      Offset(left, bottom),
      paint,
    );
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerLength, bottom), paint);

    // Kanan Bawah
    canvas.drawLine(
      Offset(right - cornerLength, bottom),
      Offset(right, bottom),
      paint,
    );
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - cornerLength), paint);

    // --- Teks di bawah kotak scan ---
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final textX = (size.width - textPainter.width) / 2;
    final textY = bottom + 24;
    textPainter.paint(canvas, Offset(textX, textY));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ======================== TAB BERANDA ========================

class _BerandaTab extends StatefulWidget {
  final String kelas;
  final String mapel;
  final VoidCallback onLihatSemua;
  final Map<String, String> scanResults;

  const _BerandaTab({
    super.key,
    required this.kelas,
    required this.mapel,
    required this.onLihatSemua,
    required this.scanResults,
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
    final tanggalStr = '${now.day} ${_namaBulan[now.month - 1].substring(0, 3)} ${now.year}';

    // Count stats
    int totalHadir = 0, totalIzin = 0, totalSakit = 0, totalAlpa = 0;
    for (final item in _kehadiranHariIni) {
      final status = (item['status'] ?? '').toString();
      switch (status) {
        case 'Hadir':
          totalHadir++;
          break;
        case 'Izin':
          totalIzin++;
          break;
        case 'Sakit':
          totalSakit++;
          break;
        case 'Alpa':
          totalAlpa++;
          break;
      }
    }
    final totalSiswa = totalHadir + totalIzin + totalSakit + totalAlpa;

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF005DA7),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Card Info Kelas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0073CC), Color(0xFF005DA7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KELAS SAAT INI',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.kelas,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.mapel,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Total Siswa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Siswa',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                Text(
                  '$totalSiswa',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF005DA7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Stats Grid (4 boxes)
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'HADIR',
                  value: totalHadir,
                  color: const Color(0xFF1FA97A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  label: 'IZIN',
                  value: totalIzin,
                  color: const Color(0xFF2F6FED),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  label: 'SAKIT',
                  value: totalSakit,
                  color: const Color(0xFFE7A008),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  label: 'ALPA',
                  value: totalAlpa,
                  color: const Color(0xFFE0587A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daftar Kehadiran',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hari ini, $tanggalStr',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: widget.onLihatSemua,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF005DA7),
                ),
                child: Text(
                  'Lihat Semua',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // List Kehadiran
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_kehadiranHariIni.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF005DA7).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner,
                      size: 48,
                      color: Color(0xFF005DA7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada siswa yang diabsen',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tekan tombol scan QR untuk\nmemulai absensi hari ini.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._kehadiranHariIni.map((item) {
              final nama = (item['nama'] ?? item['siswaId'] ?? '-').toString();
              final nis = item['nis']?.toString();
              final status = (item['status'] ?? '-').toString();
              final inisial = nama.isNotEmpty ? nama[0].toUpperCase() : '?';
              
              return _AttendanceListItem(
                inisial: inisial,
                nama: nama,
                nis: nis,
                status: status,
                statusColor: _statusColor(status),
              );
            }),
        ],
      ),
    );
  }
}


// Stat Box Widget
class _StatBox extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF9CA3AF),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Attendance List Item Widget
class _AttendanceListItem extends StatelessWidget {
  final String inisial;
  final String nama;
  final String? nis;
  final String status;
  final Color statusColor;

  const _AttendanceListItem({
    required this.inisial,
    required this.nama,
    this.nis,
    required this.status,
    required this.statusColor,
  });

  IconData _getStatusIcon() {
    switch (status) {
      case 'Hadir':
        return Icons.check_circle;
      case 'Izin':
      case 'Sakit':
        return Icons.cancel;
      case 'Alpa':
        return Icons.radio_button_unchecked;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    inisial,
                    style: GoogleFonts.poppins(
                      color: statusColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                if (nis != null && nis!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    nis!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
