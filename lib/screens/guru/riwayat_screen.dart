import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/auth_service.dart';
import '../../services/sheets_services.dart';

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

  Future<void> _updateStatus(int index, String status) async {
    final item = _attendance[index];
    if (!await _service.updateAttendanceStatus(
      rowNumber: (item['_rowNumber'] as num).toInt(),
      status: status,
    )) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status gagal disimpan ke spreadsheet')),
        );
      }
      return;
    }
    setState(() => item['status'] = status);
  }

  Future<void> _pilihBulanLaluExport() async {
    final now = DateTime.now();
    int selectedYear = now.year;
    int selectedMonth = now.month;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Unduh Rekap Bulanan'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: selectedMonth,
                  decoration: const InputDecoration(labelText: 'Bulan'),
                  items: List.generate(12, (i) => i + 1)
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(_namaBulan(m)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedMonth = v ?? selectedMonth),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: selectedYear,
                  decoration: const InputDecoration(labelText: 'Tahun'),
                  items: List.generate(5, (i) => now.year - i)
                      .map(
                        (y) => DropdownMenuItem(
                          value: y,
                          child: Text(y.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedYear = v ?? selectedYear),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Unduh'),
            ),
          ],
        ),
      ),
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

    if (result['url'] != null) {
      _showResultDialog(result['url']!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Gagal membuat rekap')),
      );
    }
  }

  void _showResultDialog(String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rekap Berhasil Dibuat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rekap bulanan sudah tersimpan sebagai Google Sheet:'),
            const SizedBox(height: 8),
            SelectableText(
              url,
              style: const TextStyle(color: Colors.indigo, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Buka'),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.indigo.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Riwayat Presensi: ${widget.kelas} - ${widget.mapel}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.download_outlined,
                          color: Colors.indigo,
                        ),
                        onPressed: _pilihBulanLaluExport,
                        tooltip: 'Unduh Rekap Bulanan',
                      ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.indigo),
                  onPressed: _load,
                  tooltip: 'Muat ulang',
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _attendance.isEmpty
                ? const Center(child: Text('Belum ada riwayat presensi'))
                : ListView.builder(
                    itemCount: _attendance.length,
                    itemBuilder: (context, index) {
                      final item = _attendance[index];
                      return ListTile(
                        title: Text('Siswa: ${item['siswaId']}'),
                        subtitle: Text(item['timestamp'] ?? ''),
                        trailing: DropdownButton<String>(
                          value: item['status'],
                          items: ['Hadir', 'Izin', 'Sakit', 'Alpa', 'Belum']
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ),
                              )
                              .toList(),
                          onChanged: (status) {
                            if (status != null) _updateStatus(index, status);
                          },
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