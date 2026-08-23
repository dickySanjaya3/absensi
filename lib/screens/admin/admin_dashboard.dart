import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/sheets_services.dart';
import 'crud_assignment_screen.dart';
import 'crud_guru_screen.dart';
import 'crud_kelas_screen.dart';
import 'crud_siswa_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Admin')),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Menu Admin')),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('CRUD Guru'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrudGuruScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.class_),
              title: const Text('Kelola Kelas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrudKelasScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('CRUD Siswa'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrudSiswaScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Kelola Assignment'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CrudAssignmentScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.badge),
              title: const Text('Kartu ID / Barcode'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GenerateQRScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: const Center(child: Text('Selamat Datang, Admin!')),
    );
  }
}

// Flowchart: Ketik Nama -> Cari Database -> Pilih -> Lihat/Generate QR -> Cetak Kartu
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
                labelText: 'Ketik nama atau NIM siswa',
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
                            'Kelas: ${siswa['kelas']} | ID: ${siswa['ID']}',
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
                                  Text('ID: ${selectedSiswa!['ID']}'),
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