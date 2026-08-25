import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/auth_service.dart';
import '../../services/sheets_services.dart';
import '../role_router.dart';
import 'crud_assignment_screen.dart';
import 'crud_guru_screen.dart';
import 'crud_kelas_screen.dart';
import 'crud_siswa_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final SheetsService _sheetsService = SheetsService();

  int? _totalGuru;
  int? _totalSiswa;
  int? _totalKelas;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    final results = await Future.wait([
      _sheetsService.getGurus(),
      _sheetsService.getStudents(),
      _sheetsService.getClasses(),
    ]);
    if (!mounted) return;
    setState(() {
      _totalGuru = (results[0] as List).length;
      _totalSiswa = (results[1] as List).length;
      _totalKelas = (results[2] as List).length;
      _loadingStats = false;
    });
  }

  void _bukaHalaman(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _loadStats()); // refresh angka setelah balik dari CRUD
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Menu Manajemen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _ManajemenCard(
              icon: Icons.person_outline,
              iconColor: const Color(0xFF2F6FED),
              title: 'Manajemen Guru',
              subtitle: 'Tambah, edit, dan hapus data guru.',
              totalLabel: 'Total Guru',
              totalValue: _loadingStats ? null : _totalGuru,
              onKelola: () => _bukaHalaman(const CrudGuruScreen()),
            ),
            const SizedBox(height: 12),
            _ManajemenCard(
              icon: Icons.people_outline,
              iconColor: const Color(0xFF1FA97A),
              title: 'Manajemen Siswa',
              subtitle: 'Kelola data siswa dan pemetaan kelas.',
              totalLabel: 'Total Siswa',
              totalValue: _loadingStats ? null : _totalSiswa,
              onKelola: () => _bukaHalaman(const CrudSiswaScreen()),
            ),
            const SizedBox(height: 12),
            _ManajemenCard(
              icon: Icons.school_outlined,
              iconColor: const Color(0xFFE7A008),
              title: 'Manajemen Kelas',
              subtitle: 'Atur kelas dan daftar per kelas.',
              totalLabel: 'Total Kelas',
              totalValue: _loadingStats ? null : _totalKelas,
              onKelola: () => _bukaHalaman(const CrudKelasScreen()),
            ),
            const SizedBox(height: 12),
            _ManajemenCard(
              icon: Icons.assignment_outlined,
              iconColor: const Color(0xFF7C3AED),
              title: 'Kelola Assignment',
              subtitle: 'Atur penugasan guru ke kelas & mapel.',
              totalLabel: null,
              totalValue: null,
              onKelola: () => _bukaHalaman(const CrudAssignmentScreen()),
            ),
            const SizedBox(height: 12),
            _ManajemenCard(
              icon: Icons.qr_code_2_rounded,
              iconColor: const Color(0xFFE0587A),
              title: 'Kartu ID / Barcode',
              subtitle: 'Generate & cetak kartu QR siswa.',
              totalLabel: null,
              totalValue: null,
              onKelola: () => _bukaHalaman(const GenerateQRScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManajemenCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? totalLabel;
  final int? totalValue;
  final VoidCallback onKelola;

  const _ManajemenCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.totalLabel,
    required this.totalValue,
    required this.onKelola,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const Spacer(),
              if (totalLabel != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      totalLabel!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                    totalValue == null
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            totalValue.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onKelola,
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text('Kelola'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GenerateQRScreen extends StatefulWidget {
  const GenerateQRScreen({super.key});

  @override
  State<GenerateQRScreen> createState() => _GenerateQRScreenState();
}

class _GenerateQRScreenState extends State<GenerateQRScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SheetsService _sheetsService = SheetsService();
  final GlobalKey _cardKey = GlobalKey();

  List<Map<String, dynamic>> searchResults = [];
  Map<String, dynamic>? selectedSiswa;
  bool _isBusy = false;

  Future<void> _searchDatabase(String query) async {
    final students = await _sheetsService.getStudents();
    if (!mounted) return;
    setState(() {
      searchResults = students
          .where(
            (student) =>
                student['Nama'].toString().toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                student['NIS'].toString().toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                student['Jenis Kelamin'].toString().toLowerCase().contains(
                  query.toLowerCase(),
                ),
          )
          .toList();
    });
  }

  String? get _activeQr {
    final qr = selectedSiswa?['Barcode']?.toString();
    return (qr == null || qr.isEmpty) ? null : qr;
  }

  Future<void> _generateBaru() async {
    if (selectedSiswa == null) return;
    setState(() => _isBusy = true);
    final siswaId = selectedSiswa!['ID'].toString();
    final qrBaru = await _sheetsService.generateBarcode(
      kelas: selectedSiswa!['kelas'].toString(),
      siswaId: siswaId,
    );
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (qrBaru != null) {
      setState(() => selectedSiswa!['Barcode'] = qrBaru);
      _message('QR baru berhasil dibuat. QR lama otomatis nonaktif.');
    } else {
      _message(
        'Gagal generate QR. Pastikan kolom "Barcode" sudah ada di sheet kelas.',
      );
    }
  }

  Future<void> _lihatRiwayat() async {
    if (selectedSiswa == null) return;
    final siswaId = selectedSiswa!['ID'].toString();
    final history = await _sheetsService.getBarcodeHistory(siswaId);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Riwayat Barcode - ${selectedSiswa!['Nama']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: history.isEmpty
                    ? const Center(child: Text('Belum ada riwayat'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: history.length,
                        itemBuilder: (ctx, i) {
                          final h = history[i];
                          final qrLama = (h['BarcodeLama'] ?? '').toString();
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              h['Aksi'] == 'Reaktivasi'
                                  ? Icons.history
                                  : Icons.autorenew,
                              size: 20,
                            ),
                            title: Text('${h['Aksi']} — ${h['Timestamp']}'),
                            subtitle: Text(
                              'Lama: $qrLama\nBaru: ${h['BarcodeBaru']}',
                            ),
                            isThreeLine: true,
                            trailing: qrLama.isEmpty
                                ? null
                                : TextButton(
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      await _reaktivasi(qrLama);
                                    },
                                    child: const Text('Aktifkan'),
                                  ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reaktivasi(String qrLama) async {
    if (selectedSiswa == null) return;
    setState(() => _isBusy = true);
    final siswaId = selectedSiswa!['ID'].toString();
    final ok = await _sheetsService.reactivateBarcode(
      kelas: selectedSiswa!['kelas'].toString(),
      siswaId: siswaId,
      barcodeLama: qrLama,
    );
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (ok) {
      setState(() => selectedSiswa!['Barcode'] = qrLama);
      _message('QR lama berhasil diaktifkan kembali.');
    } else {
      _message('Gagal mengaktifkan QR lama.');
    }
  }

  Future<void> _exportKartu() async {
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final siswaId = selectedSiswa?['ID']?.toString() ?? 'siswa';
      final file = File('${dir.path}/kartu_id_$siswaId.png');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Kartu ID Siswa - ${selectedSiswa?['Nama'] ?? ''}');
    } catch (e) {
      _message('Gagal export kartu: $e');
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kartu ID / Barcode Siswa')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Ketik nama atau NIS siswa',
                suffixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _searchDatabase,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: selectedSiswa == null
                  ? ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final siswa = searchResults[index];
                        return ListTile(
                          title: Text(siswa['Nama'].toString()),
                          subtitle: Text(
                            'Kelas: ${siswa['kelas']} | NIS: ${siswa['NIS'] ?? '-'}',
                          ),
                          onTap: () => setState(() => selectedSiswa = siswa),
                        );
                      },
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => selectedSiswa = null),
                            icon: const Icon(Icons.arrow_back, size: 18),
                            label: const Text('Kembali ke pencarian'),
                          ),
                          const SizedBox(height: 8),

                          // ----- Kartu ID yang akan di-export -----
                          RepaintBoundary(
                            key: _cardKey,
                            child: Container(
                              width: 320,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.indigo),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'KARTU ABSENSI SISWA',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _activeQr == null
                                      ? const SizedBox(
                                          height: 160,
                                          child: Center(
                                            child: Text(
                                              'Belum ada QR aktif.\nTekan "Generate QR" di bawah.',
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        )
                                      : QrImageView(
                                          data: _activeQr!,
                                          version: QrVersions.auto,
                                          size: 160,
                                        ),
                                  const SizedBox(height: 12),
                                  Text(
                                    selectedSiswa!['Nama'].toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text('Kelas: ${selectedSiswa!['kelas']}'),
                                  Text(
                                    'NIS: ${selectedSiswa!['NIS'] ?? '-'}',
                                  ),
                                  Text(
                                    'Jenis Kelamin: ${selectedSiswa!['Jenis Kelamin']}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ----- Tombol aksi -----
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _isBusy ? null : _generateBaru,
                                icon: const Icon(Icons.autorenew),
                                label: Text(
                                  _activeQr == null
                                      ? 'Generate QR'
                                      : 'Generate Ulang',
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _activeQr == null || _isBusy
                                    ? null
                                    : _exportKartu,
                                icon: const Icon(Icons.ios_share),
                                label: const Text('Cetak / Bagikan'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _isBusy ? null : _lihatRiwayat,
                                icon: const Icon(Icons.history),
                                label: const Text('Riwayat'),
                              ),
                            ],
                          ),
                          if (_isBusy) ...[
                            const SizedBox(height: 12),
                            const CircularProgressIndicator(),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


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
    // Bersihkan seluruh stack navigator dan pasang ulang RoleRouter,
    // supaya logout selalu benar-benar kembali ke halaman login, tidak
    // cuma mengandalkan reaktivitas provider (yang bisa putus kalau
    // layar ini dibuka lewat push/pushReplacement dari layar lain).
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleRouter()),
      (route) => false,
    );
  }
}