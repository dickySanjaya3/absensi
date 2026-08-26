import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/auth_service.dart';
import '../../services/sheets_services.dart';
import '../../widgets/admin_widgets.dart';
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
    final adminEmail = context.watch<AuthService>().currentUser?.email ?? '';
    final adminName = context.watch<AuthService>().currentUser?.nama ?? 'Admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Curved Header dengan user info
            CurvedHeader(
              greeting: 'HALLO ADMIN!',
              subtitle: adminEmail.isNotEmpty ? adminEmail : adminName,
              onLogout: () => _confirmLogout(context),
            ),
            
            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadStats,
                color: const Color(0xFF087BB9),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Stats Section
                    Text(
                      'Statistik',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: StatBox(
                            label: 'GURU',
                            value: _totalGuru,
                            color: const Color(0xFF2F6FED),
                            icon: Icons.person_outline,
                            loading: _loadingStats,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatBox(
                            label: 'SISWA',
                            value: _totalSiswa,
                            color: const Color(0xFF1FA97A),
                            icon: Icons.people_outline,
                            loading: _loadingStats,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: StatBox(
                            label: 'KELAS',
                            value: _totalKelas,
                            color: const Color(0xFFE7A008),
                            icon: Icons.school_outlined,
                            loading: _loadingStats,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatBox(
                            label: 'ASSIGNMENT',
                            value: 0,
                            color: const Color(0xFF7C3AED),
                            icon: Icons.assignment_outlined,
                            loading: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Menu Section
                    Text(
                      'Menu Manajemen',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Menu Cards
                    MenuCard(
                      icon: Icons.person_outline,
                      iconColor: const Color(0xFF2F6FED),
                      title: 'Manajemen Guru',
                      subtitle: 'Tambah, edit, dan hapus data guru.',
                      badge: _loadingStats ? '...' : '${_totalGuru ?? 0} Guru',
                      onTap: () => _bukaHalaman(const CrudGuruScreen()),
                    ),
                    const SizedBox(height: 16),

                    MenuCard(
                      icon: Icons.people_outline,
                      iconColor: const Color(0xFF1FA97A),
                      title: 'Manajemen Siswa',
                      subtitle: 'Kelola data siswa dan pemetaan kelas.',
                      badge: _loadingStats ? '...' : '${_totalSiswa ?? 0} Siswa',
                      onTap: () => _bukaHalaman(const CrudSiswaScreen()),
                    ),
                    const SizedBox(height: 16),

                    MenuCard(
                      icon: Icons.school_outlined,
                      iconColor: const Color(0xFFE7A008),
                      title: 'Manajemen Kelas',
                      subtitle: 'Atur kelas dan daftar per kelas.',
                      badge: _loadingStats ? '...' : '${_totalKelas ?? 0} Kelas',
                      onTap: () => _bukaHalaman(const CrudKelasScreen()),
                    ),
                    const SizedBox(height: 16),

                    MenuCard(
                      icon: Icons.assignment_outlined,
                      iconColor: const Color(0xFF7C3AED),
                      title: 'Kelola Assignment',
                      subtitle: 'Atur penugasan guru ke kelas & mapel.',
                      onTap: () => _bukaHalaman(const CrudAssignmentScreen()),
                    ),
                    const SizedBox(height: 16),

                    MenuCard(
                      icon: Icons.qr_code_2_rounded,
                      iconColor: const Color(0xFFE0587A),
                      title: 'Kartu ID / Barcode',
                      subtitle: 'Generate & cetak kartu QR siswa.',
                      onTap: () => _bukaHalaman(const GenerateQRScreen()),
                    ),
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const CurvedAppBar(
        title: 'Kartu ID / Barcode Siswa',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Ketik nama atau NIS siswa',
                labelStyle: GoogleFonts.inter(),
                suffixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _searchDatabase,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: selectedSiswa == null
                  ? searchResults.isEmpty && _searchController.text.isNotEmpty
                      ? EmptyStateWidget(
                          icon: Icons.search_off,
                          title: 'Tidak ditemukan',
                          subtitle:
                              'Coba cari dengan nama atau NIS yang berbeda',
                        )
                      : ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final siswa = searchResults[index];
                            return ModernCard(
                              padding: const EdgeInsets.all(12),
                              onTap: () =>
                                  setState(() => selectedSiswa = siswa),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF087BB9)
                                          .withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        siswa['Nama']
                                            .toString()[0]
                                            .toUpperCase(),
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF087BB9),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          siswa['Nama'].toString(),
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'Kelas: ${siswa['kelas']} | NIS: ${siswa['NIS'] ?? '-'}',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Color(0xFF64748B),
                                  ),
                                ],
                              ),
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
                            label: Text(
                              'Kembali ke pencarian',
                              style: GoogleFonts.inter(),
                            ),
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
                                border: Border.all(
                                  color: const Color(0xFF087BB9),
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'KARTU ABSENSI SISWA',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _activeQr == null
                                      ? Container(
                                          height: 160,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF087BB9)
                                                .withValues(alpha: 0.05),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Belum ada QR aktif.\nTekan "Generate QR" di bawah.',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFF64748B),
                                              ),
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
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Kelas: ${selectedSiswa!['kelas']}',
                                    style: GoogleFonts.inter(),
                                  ),
                                  Text(
                                    'NIS: ${selectedSiswa!['NIS'] ?? '-'}',
                                    style: GoogleFonts.inter(),
                                  ),
                                  Text(
                                    'Jenis Kelamin: ${selectedSiswa!['Jenis Kelamin']}',
                                    style: GoogleFonts.inter(),
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
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF087BB9),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _activeQr == null || _isBusy
                                    ? null
                                    : _exportKartu,
                                icon: const Icon(Icons.ios_share),
                                label: Text(
                                  'Cetak / Bagikan',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF087BB9),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _isBusy ? null : _lihatRiwayat,
                                icon: const Icon(Icons.history),
                                label: Text(
                                  'Riwayat',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF087BB9),
                                ),
                              ),
                            ],
                          ),
                          if (_isBusy) ...[
                            const SizedBox(height: 12),
                            const LoadingOverlay(),
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