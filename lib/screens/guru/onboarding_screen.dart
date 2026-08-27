import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/sheets_services.dart';
import '../role_router.dart';
import 'guru_dashboard.dart';

class OnboardingKelasMapelScreen extends StatefulWidget {
  const OnboardingKelasMapelScreen({super.key});

  @override
  State<OnboardingKelasMapelScreen> createState() =>
      _OnboardingKelasMapelScreenState();
}

class _OnboardingKelasMapelScreenState
    extends State<OnboardingKelasMapelScreen> {
  final SheetsService _sheetsService = SheetsService();

  List<Map<String, dynamic>> _assignments = [];
  Map<String, int> _jumlahSiswaPerKelas = {};
  bool _isLoading = true;

  // Kalau null -> masih di step pilih kelas.
  // Kalau terisi -> sudah masuk step pilih mapel untuk kelas ini.
  String? _selectedKelas;

  static const _kelasIcons = [
    (Icons.auto_stories_rounded, Color(0xFF6C63FF)),
    (Icons.menu_book_rounded, Color(0xFF00B8A9)),
    (Icons.groups_rounded, Color(0xFFF6A609)),
    (Icons.school_rounded, Color(0xFFEF5DA8)),
  ];

  static const Map<String, IconData> _mapelIcons = {
    'matematika': Icons.calculate_rounded,
    'fisika': Icons.science_rounded,
    'kimia': Icons.biotech_rounded,
    'biologi': Icons.eco_rounded,
    'bahasa inggris': Icons.language_rounded,
    'bahasa indonesia': Icons.menu_book_rounded,
    'sejarah': Icons.museum_rounded,
    'seni budaya': Icons.palette_rounded,
    'olahraga': Icons.sports_soccer_rounded,
    'pjok': Icons.sports_soccer_rounded,
    'agama': Icons.mosque_rounded,
    'ppkn': Icons.gavel_rounded,
    'geografi': Icons.public_rounded,
    'ekonomi': Icons.savings_rounded,
    'informatika': Icons.computer_rounded,
    'tik': Icons.computer_rounded,
  };

  static const _mapelColors = [
    Color(0xFF2F6FED),
    Color(0xFF1FA97A),
    Color(0xFFE7A008),
    Color(0xFFE0587A),
    Color(0xFF7C6AE0),
    Color(0xFF17A2B8),
  ];

  @override
  void initState() {
    super.initState();
    final email = context.read<AuthService>().currentUser?.email;
    if (email != null) {
      _loadAssignments(email);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAssignments(String email) async {
    final assignments = await _sheetsService.getAssignments(email);
    final listKelas = assignments
        .map((item) => item['Kelas'].toString())
        .toSet()
        .toList();

    final counts = <String, int>{};
    await Future.wait(listKelas.map((k) async {
      final siswa = await _sheetsService.getStudents(kelas: k);
      counts[k] = siswa.length;
    }));

    if (!mounted) return;
    setState(() {
      _assignments = assignments;
      _jumlahSiswaPerKelas = counts;
      _isLoading = false;
    });
  }

  void _goToDashboard(String kelas, String mapel) {
    // Set kelas yang sudah dipilih supaya saat back tetap di step pilih mapel
    setState(() => _selectedKelas = kelas);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuruDashboard(kelas: kelas, mapel: mapel),
      ),
    );
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
      // supaya logout selalu kembali ke halaman login dengan pasti -
      // tidak bergantung pada apakah layar ini masih terhubung ke
      // RoleRouter di root atau tidak (mis. kalau layar ini pernah
      // dibuka lewat push/pushReplacement dari layar lain).
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleRouter()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nama = context.watch<AuthService>().currentUser?.nama ?? '';
    final email = context.watch<AuthService>().currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildHeader(nama, email),
                  Expanded(
                    child: _selectedKelas == null
                        ? _buildKelasStep()
                        : _buildMapelStep(_selectedKelas!),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(String nama, String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF005DA7),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          if (_selectedKelas != null)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: () => setState(() => _selectedKelas = null),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF005DA7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                tooltip: 'Keluar',
                onPressed: () => _confirmLogout(context),
                padding: const EdgeInsets.all(8),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HALLO !',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email.isNotEmpty ? email : (nama.isNotEmpty ? nama : 'Guru'),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKelasStep() {
    final listKelas = _assignments
        .map((item) => item['Kelas'].toString())
        .toSet()
        .toList();

    if (listKelas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Belum ada kelas yang di-assign untuk akun ini.\nHubungi admin sekolah.',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 16,
              color: const Color(0xFF414751),
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(27, 24, 26, 24),
      children: [
        Text(
          'Pilih kelas anda',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF003974).withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pilih kelas untuk memulai absensi hari ini.',
          textAlign: TextAlign.center,
          style: GoogleFonts.beVietnamPro(
            fontSize: 16,
            color: const Color(0xFF414751),
          ),
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < listKelas.length; i++) ...[
          _KelasCard(
            nama: listKelas[i],
            jumlahSiswa: _jumlahSiswaPerKelas[listKelas[i]] ?? 0,
            icon: _kelasIcons[i % _kelasIcons.length].$1,
            warna: _kelasIcons[i % _kelasIcons.length].$2,
            onTap: () => setState(() => _selectedKelas = listKelas[i]),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildMapelStep(String kelas) {
    final listMapel = _assignments
        .where((item) => item['Kelas'].toString() == kelas)
        .map((item) => item['Mata Pelajaran'].toString())
        .toSet()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Text(
            'Pilih mata pelajaran',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Text(
            'Pilih mata pelajaran untuk absen di kelas $kelas!',
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),
        Expanded(
          child: listMapel.isEmpty
              ? const Center(
                  child: Text('Belum ada mata pelajaran untuk kelas ini'),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: listMapel.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.15,
                  ),
                  itemBuilder: (context, index) {
                    final mapel = listMapel[index];
                    final icon = _mapelIcons[mapel.toLowerCase()] ??
                        Icons.menu_book_rounded;
                    final warna = _mapelColors[index % _mapelColors.length];
                    return _MapelCard(
                      nama: mapel,
                      icon: icon,
                      warna: warna,
                      onTap: () => _goToDashboard(kelas, mapel),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _KelasCard extends StatelessWidget {
  final String nama;
  final int jumlahSiswa;
  final IconData icon;
  final Color warna;
  final VoidCallback onTap;

  const _KelasCard({
    required this.nama,
    required this.jumlahSiswa,
    required this.icon,
    required this.warna,
    required this.onTap,
  });

  String _getMapelName() {
    // Extract subject name from kelas if available
    // Default fallback based on kelas name
    if (nama.toUpperCase().contains('IPA')) {
      return 'Ilmu Pengetahuan Alam';
    } else if (nama.toUpperCase().contains('IPS')) {
      return 'Ilmu Pengetahuan Sosial';
    }
    return 'Mata Pelajaran';
  }

  Color _getActionColor() {
    // Different colors based on card color for variety
    if (warna == const Color(0xFF6C63FF)) {
      return const Color(0xFF005DA7); // Blue for first card
    } else if (warna == const Color(0xFF00B8A9)) {
      return const Color(0xFF00685B); // Teal for second card
    } else if (warna == const Color(0xFFF6A609)) {
      return const Color(0xFF735C00); // Yellow-brown for third card
    }
    return const Color(0xFF005DA7); // Default blue
  }

  @override
  Widget build(BuildContext context) {
    final actionColor = _getActionColor();
    final mapelName = _getMapelName();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 2.5,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: const Color(0xFF005DA7).withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and student count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: warna.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: warna, size: 22),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F0EF),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        '$jumlahSiswa Siswa',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 16,
                          color: const Color(0xFF414751),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Class name
                Text(
                  nama,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    color: const Color(0xFF151D1D),
                  ),
                ),
                const SizedBox(height: 4),
                
                // Subject name
                Text(
                  mapelName,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    color: const Color(0xFF414751),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Divider
                Container(
                  height: 2,
                  color: const Color(0xFFDBE4E4).withValues(alpha: 0.5),
                ),
                const SizedBox(height: 18),
                
                // Action row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Masuk Kelas',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 16,
                        color: actionColor,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: actionColor,
                      size: 17,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapelCard extends StatelessWidget {
  final String nama;
  final IconData icon;
  final Color warna;
  final VoidCallback onTap;

  const _MapelCard({
    required this.nama,
    required this.icon,
    required this.warna,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: warna,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                nama,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}