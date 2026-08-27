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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

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
                  padding: EdgeInsets.symmetric(
                    horizontal: isWideScreen ? 24 : 16,
                    vertical: 20,
                  ),
                  children: [
                    // Stats Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Statistik',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        if (_loadingStats)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Stats Grid - 2x2 dengan spacing proporsional
                    _buildStatsGrid(),
                    
                    const SizedBox(height: 32),

                    // Menu Section
                    Text(
                      'Menu Manajemen',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Menu Cards dengan spacing lebih baik
                    _AnimatedMenuCard(
                      icon: Icons.person_outline,
                      iconColor: const Color(0xFF2F6FED),
                      title: 'Manajemen Guru',
                      subtitle: 'Tambah, edit, dan hapus data guru.',
                      badge: _loadingStats ? '...' : '${_totalGuru ?? 0} Guru',
                      onTap: () => _bukaHalaman(const CrudGuruScreen()),
                    ),
                    const SizedBox(height: 14),

                    _AnimatedMenuCard(
                      icon: Icons.people_outline,
                      iconColor: const Color(0xFF1FA97A),
                      title: 'Manajemen Siswa',
                      subtitle: 'Kelola data siswa dan pemetaan kelas.',
                      badge: _loadingStats ? '...' : '${_totalSiswa ?? 0} Siswa',
                      onTap: () => _bukaHalaman(const CrudSiswaScreen()),
                    ),
                    const SizedBox(height: 14),

                    _AnimatedMenuCard(
                      icon: Icons.school_outlined,
                      iconColor: const Color(0xFFE7A008),
                      title: 'Manajemen Kelas',
                      subtitle: 'Atur kelas dan daftar per kelas.',
                      badge: _loadingStats ? '...' : '${_totalKelas ?? 0} Kelas',
                      onTap: () => _bukaHalaman(const CrudKelasScreen()),
                    ),
                    const SizedBox(height: 14),

                    _AnimatedMenuCard(
                      icon: Icons.assignment_outlined,
                      iconColor: const Color(0xFF7C3AED),
                      title: 'Kelola Assignment',
                      subtitle: 'Atur penugasan guru ke kelas & mapel.',
                      onTap: () => _bukaHalaman(const CrudAssignmentScreen()),
                    ),
                    const SizedBox(height: 14),

                    _AnimatedMenuCard(
                      icon: Icons.qr_code_2_rounded,
                      iconColor: const Color(0xFFE0587A),
                      title: 'Kartu ID / Barcode',
                      subtitle: 'Generate & cetak kartu QR siswa.',
                      onTap: () => _bukaHalaman(const GenerateQRScreen()),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: _AnimatedStatBox(
                label: 'GURU',
                value: _totalGuru,
                color: const Color(0xFF2F6FED),
                icon: Icons.person_outline,
                loading: _loadingStats,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AnimatedStatBox(
                label: 'SISWA',
                value: _totalSiswa,
                color: const Color(0xFF1FA97A),
                icon: Icons.people_outline,
                loading: _loadingStats,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AnimatedStatBox(
                label: 'KELAS',
                value: _totalKelas,
                color: const Color(0xFFE7A008),
                icon: Icons.school_outlined,
                loading: _loadingStats,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AnimatedStatBox(
                label: 'TUGAS',
                value: 0,
                color: const Color(0xFF7C3AED),
                icon: Icons.assignment_outlined,
                loading: false,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// ==================== ANIMATED STAT BOX ====================
class _AnimatedStatBox extends StatefulWidget {
  final String label;
  final int? value;
  final Color color;
  final IconData? icon;
  final bool loading;

  const _AnimatedStatBox({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
    this.loading = false,
  });

  @override
  State<_AnimatedStatBox> createState() => _AnimatedStatBoxState();
}

class _AnimatedStatBoxState extends State<_AnimatedStatBox> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(_isHovered ? 1.03 : 1.0),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? widget.color.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.color.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _isHovered ? 12 : 4,
              offset: Offset(0, _isHovered ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: 20,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF9CA3AF),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            widget.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    widget.value?.toString() ?? '0',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                      height: 1,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

/// ==================== ANIMATED MENU CARD ====================
class _AnimatedMenuCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _AnimatedMenuCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  State<_AnimatedMenuCard> createState() => _AnimatedMenuCardState();
}

class _AnimatedMenuCardState extends State<_AnimatedMenuCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()
          ..translate(_isHovered ? 0.0 : 0.0, _isHovered ? -4.0 : 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? widget.iconColor.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.iconColor.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: _isHovered ? 16 : 4,
              offset: Offset(0, _isHovered ? 8 : 2),
            ),
            if (_isHovered)
              BoxShadow(
                color: widget.iconColor.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 12),
                spreadRadius: -4,
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.iconColor.withValues(
                        alpha: _isHovered ? 0.2 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badge
                  if (widget.badge != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.badge!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.iconColor,
                        ),
                      ),
                    ),
                  ],

                  // Arrow
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isHovered ? 0.0 : 0.0,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: widget.iconColor.withValues(
                        alpha: _isHovered ? 1.0 : 0.5,
                      ),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
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