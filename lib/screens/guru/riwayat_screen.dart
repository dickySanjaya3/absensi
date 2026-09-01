import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/auth_service.dart';
import '../../services/sheets_services.dart';
import '../../widgets/admin_widgets.dart';

class RiwayatScreen extends StatefulWidget {
  final String kelas;
  final String mapel;

  const RiwayatScreen({super.key, required this.kelas, required this.mapel});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final SheetsService _service = SheetsService();
  List<Map<String, dynamic>> _attendance = [];
  bool _loading = true;
  bool _isExporting = false;

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
    final attendance = await _service.getAttendance(
      emailGuru: email,
      kelas: widget.kelas,
      mapel: widget.mapel,
    );
    if (!mounted) return;
    setState(() {
      _attendance = attendance;
      _loading = false;
    });
  }

  Future<void> _pilihBulanLaluExport() async {
    final now = DateTime.now();
    int selectedYear = now.year;
    int selectedMonth = now.month;

    final confirmed = await showModernDialog<bool>(
      context: context,
      title: 'Unduh Rekap Bulanan',
      backgroundColor: const Color(0xFF087BB9),
      builder: (ctx, isSaving, setDialogState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bulan Dropdown
            DropdownButtonFormField<int>(
              value: selectedMonth,
              decoration: InputDecoration(
                labelText: 'Bulan',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              items: List.generate(12, (i) => i + 1)
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(_namaBulan(m)),
                    ),
                  )
                  .toList(),
              onChanged: isSaving
                  ? null
                  : (v) => setDialogState(() => selectedMonth = v ?? selectedMonth),
            ),
            const SizedBox(height: 14),
            // Tahun Dropdown
            DropdownButtonFormField<int>(
              value: selectedYear,
              decoration: InputDecoration(
                labelText: 'Tahun',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              items: List.generate(5, (i) => now.year - i)
                  .map(
                    (y) => DropdownMenuItem(
                      value: y,
                      child: Text(y.toString()),
                    ),
                  )
                  .toList(),
              onChanged: isSaving
                  ? null
                  : (v) => setDialogState(() => selectedYear = v ?? selectedYear),
            ),
          ],
        );
      },
      onConfirm: (ctx, setDialogState) async {
        return true;
      },
      confirmText: 'Unduh',
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final email = context.read<AuthService>().currentUser?.email;
    if (email == null) return;

    final yearMonth =
        '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}';

    setState(() => _isExporting = true);
    final result = await _service.exportMonthlyRecap(
      emailGuru: email,
      kelas: widget.kelas,
      mapel: widget.mapel,
      yearMonth: yearMonth,
    );
    if (!mounted) return;
    setState(() => _isExporting = false);

    // Debug logging
    debugPrint('Export result: $result');
    debugPrint('URL: ${result['url']}');
    debugPrint('Error: ${result['error']}');

    if (result['url'] != null && result['url']!.isNotEmpty) {
      _showResultDialog(result['url']!);
    } else {
      showModernToast(
        context: context,
        message: result['error'] ?? 'Gagal membuat rekap',
        type: ToastType.error,
      );
    }
  }

  void _showResultDialog(String url) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon success dengan background hijau
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF1FA97A),
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
                'Rekap Berhasil Dibuat!',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              
              // Message
              Text(
                'Spreadsheet rekap bulanan sudah tersimpan di Google Sheets',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              
              // URL Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      color: Color(0xFF1FA97A),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        url.length > 40 ? '${url.substring(0, 40)}...' : url,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF475569),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: url));
                        if (!mounted) return;
                        showModernToast(
                          context: context,
                          message: 'Link berhasil disalin',
                          type: ToastType.success,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1FA97A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.copy_rounded,
                          color: Color(0xFF1FA97A),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Buttons - Stack vertical untuk space lebih
              Column(
                children: [
                  // Button Buka
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final uri = Uri.parse(url);
                          debugPrint('Attempting to launch URL: $url');
                          
                          // Launch URL dengan mode externalApplication
                          bool launched = await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                          
                          debugPrint('Launch result: $launched');
                          
                          if (!launched) {
                            // Jika gagal, copy ke clipboard sebagai fallback
                            await Clipboard.setData(ClipboardData(text: url));
                            if (!mounted) return;
                            Navigator.of(context).pop();
                            showModernToast(
                              context: context,
                              message: 'Link disalin ke clipboard. Silakan paste di browser.',
                              type: ToastType.info,
                            );
                          } else {
                            Navigator.of(context).pop();
                          }
                        } catch (e) {
                          debugPrint('Error launching URL: $e');
                          // Fallback: copy to clipboard
                          await Clipboard.setData(ClipboardData(text: url));
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          showModernToast(
                            context: context,
                            message: 'Link disalin ke clipboard. Silakan paste di browser.',
                            type: ToastType.info,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1FA97A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.open_in_browser_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Buka Spreadsheet',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Button Tutup
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Tutup',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _namaBulan(int m) {
    const nama = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return nama[m - 1];
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
        return const Color(0xFF9CA3AF);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Hadir':
        return Icons.check_circle;
      case 'Izin':
        return Icons.info;
      case 'Sakit':
        return Icons.local_hospital;
      case 'Alpa':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Header info dengan download button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riwayat Presensi',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.kelas} • ${widget.mapel}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005DA7)),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF005DA7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.download_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _pilihBulanLaluExport,
                          tooltip: 'Unduh Rekap Bulanan',
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFF005DA7),
                      size: 20,
                    ),
                    onPressed: _load,
                    tooltip: 'Muat ulang',
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005DA7)),
                    ),
                  )
                : _attendance.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.history_rounded,
                                size: 48,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada riwayat presensi',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Riwayat akan muncul setelah melakukan scan QR',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _attendance.length,
                        itemBuilder: (context, index) {
                          final item = _attendance[index];
                          final nama = (item['nama'] ?? item['siswaId'] ?? '-').toString();
                          final nis = item['nis']?.toString() ?? '';
                          final timestamp = (item['timestamp'] ?? '').toString();
                          final status = (item['status'] ?? 'Belum').toString();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: _statusColor(status).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: _statusColor(status),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nama,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (nis.isNotEmpty)
                                          Text(
                                            'NIS: $nis',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: const Color(0xFF64748B),
                                            ),
                                          ),
                                        if (timestamp.isNotEmpty)
                                          Text(
                                            _formatTimestamp(timestamp),
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: const Color(0xFF94A3B8),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Status badge (read-only)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _statusIcon(status),
                                          size: 16,
                                          color: _statusColor(status),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          status,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _statusColor(status),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}