import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/qr_service.dart';
import '../../services/sheets_services.dart';
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

  void _openCameraScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            AppBar(
              title: const Text('Pindai QR Siswa'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final String rawCode = barcodes.first.rawValue ?? '';
                    Navigator.pop(context); // Tutup scanner
                    _processAttendance(rawCode);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processAttendance(String qrData) async {
    final email = context.read<AuthService>().currentUser?.email;
    final students = await _sheetsService.getStudents(kelas: widget.kelas);
    final studentId = QRService.validateQR(qrData, students);
    if (studentId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR tidak valid, kadaluarsa, atau bukan siswa kelas ini'),
          ),
        );
      }
      return;
    }
    if (email == null) return;
    final saved = await _sheetsService.writeAttendance(
      guruEmail: email,
      kelas: widget.kelas,
      mapel: widget.mapel,
      siswaId: studentId,
      status: 'Hadir',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved ? 'Absensi berhasil dicatat' : 'Absensi gagal disimpan',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      Center(
        child: Text(
          'Dashboard Guru\nKelas: ${widget.kelas} | Mapel: ${widget.mapel}',
        ),
      ),
      const SizedBox.shrink(), // Placeholder index 1 (Tombol Scan)
      RiwayatScreen(kelas: widget.kelas, mapel: widget.mapel),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('${widget.kelas} - ${widget.mapel}')),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {
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