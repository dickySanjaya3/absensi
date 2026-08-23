import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/sheets_services.dart';
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GuruDashboard(kelas: kelas, mapel: mapel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nama = context.watch<AuthService>().currentUser?.nama ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildHeader(nama),
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

  Widget _buildHeader(String nama) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          if (_selectedKelas != null)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() => _selectedKelas = null),
            )
          else
            const CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HALLO !',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  nama.isNotEmpty ? nama : 'Guru',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Belum ada kelas yang di-assign untuk akun ini.\nHubungi admin sekolah.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        const Text(
          'Pilih kelas anda',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pilih kelas untuk memulai absensi hari ini.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < listKelas.length; i++) ...[
          _KelasCard(
            nama: listKelas[i],
            jumlahSiswa: _jumlahSiswaPerKelas[listKelas[i]] ?? 0,
            icon: _kelasIcons[i % _kelasIcons.length].$1,
            warna: _kelasIcons[i % _kelasIcons.length].$2,
            onTap: () => setState(() => _selectedKelas = listKelas[i]),
          ),
          const SizedBox(height: 14),
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: warna.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: warna),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F2F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$jumlahSiswa Siswa',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                nama,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Masuk Kelas',
                    style: TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.indigo, size: 18),
                ],
              ),
            ],
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