import 'package:flutter/material.dart';

import '../../services/sheets_services.dart';

/// Layar "Import Massal Siswa": admin tempel (paste) data siswa yang disalin
/// dari file lain (PDF, Excel, Google Sheets, dsb) - 1 baris = 1 siswa,
/// dipisah TAB atau koma, urutan kolom: NIS, Nama, Jenis Kelamin.
/// Contoh baris valid:
///   18.1.659	AINUN MARDIAH LUBIS	Wanita
///   18.1.660,ANISA HANNUM,Wanita
class ImportSiswaScreen extends StatefulWidget {
  /// Kalau diisi (dibuka dari CRUD Siswa kelas tertentu), nama kelas
  /// dikunci ke nilai ini. Kalau null, admin isi manual (bisa kelas baru).
  final String? initialKelas;

  const ImportSiswaScreen({super.key, this.initialKelas});

  @override
  State<ImportSiswaScreen> createState() => _ImportSiswaScreenState();
}

class _ParsedSiswa {
  final String nis;
  final String nama;
  final String jenisKelamin;
  const _ParsedSiswa(this.nis, this.nama, this.jenisKelamin);
}

class _ImportSiswaScreenState extends State<ImportSiswaScreen> {
  final SheetsService _sheetsService = SheetsService();
  late final TextEditingController _kelasCtrl;
  final TextEditingController _dataCtrl = TextEditingController();

  List<_ParsedSiswa> _preview = [];
  List<String> _baris1KolomBermasalah = [];
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _kelasCtrl = TextEditingController(text: widget.initialKelas ?? '');
  }

  @override
  void dispose() {
    _kelasCtrl.dispose();
    _dataCtrl.dispose();
    super.dispose();
  }

  void _parse() {
    final lines = _dataCtrl.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty);

    final hasil = <_ParsedSiswa>[];
    final bermasalah = <String>[];

    for (final line in lines) {
      // Terima pemisah TAB (hasil copy dari PDF/Excel/Sheets), KOMA (CSV),
      // atau 2+ SPASI berturut-turut (banyak PDF viewer copy-paste kolom
      // pakai spasi rapat, bukan tab beneran - ini yang sering bikin data
      // ketuker/nyasar kalau cuma dicek tab/koma saja).
      List<String> parts;
      if (line.contains('\t')) {
        parts = line.split('\t');
      } else if (line.contains(',')) {
        parts = line.split(',');
      } else {
        parts = line.split(RegExp(r'\s{2,}'));
      }
      final cleaned = parts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();

      // Fallback terakhir: kalau masih ke-anggap 1 kolom besar (spasi
      // tunggal semua), coba pisah dari BELAKANG - asumsikan token
      // terakhir = Jenis Kelamin (Wanita/Pria/L/P), token PERTAMA = NIS
      // (angka/format kode), sisanya di tengah = Nama (boleh multi-kata).
      if (cleaned.length == 1) {
        final tokens = cleaned.first.split(RegExp(r'\s+'));
        if (tokens.length >= 3) {
          final kemungkinanJk = tokens.last.toLowerCase();
          final jkValid = [
            'wanita', 'pria', 'l', 'p', 'laki-laki', 'perempuan',
          ].contains(kemungkinanJk);
          if (jkValid) {
            final nis = tokens.first;
            final jk = tokens.last;
            final nama = tokens.sublist(1, tokens.length - 1).join(' ');
            hasil.add(_ParsedSiswa(nis, nama, jk));
            continue;
          }
        }
      }

      // Lewati baris header kalau ada ("Nis Nama Jenis Kelamin" dst).
      if (cleaned.isNotEmpty &&
          cleaned.first.toLowerCase().contains('nis') &&
          cleaned.length <= 3) {
        continue;
      }

      if (cleaned.length < 2) {
        bermasalah.add(line);
        continue;
      }

      // Urutan kolom: NIS, Nama, [Jenis Kelamin opsional]
      final nis = cleaned[0];
      final nama = cleaned[1];
      final jk = cleaned.length > 2 ? cleaned[2] : '';
      hasil.add(_ParsedSiswa(nis, nama, jk));
    }

    setState(() {
      _preview = hasil;
      _baris1KolomBermasalah = bermasalah;
    });
  }

  Future<void> _import() async {
    final kelas = _kelasCtrl.text.trim();
    if (kelas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama kelas wajib diisi')),
      );
      return;
    }
    if (_preview.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada data valid untuk diimport')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import siswa?'),
        content: Text(
          '${_preview.length} siswa akan ditambahkan ke kelas "$kelas". '
          'ID tiap siswa akan dibuat otomatis oleh sistem.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _importing = true);
    final count = await _sheetsService.addStudentsBatch(
      kelas: kelas,
      items: _preview
          .map(
            (s) => {
              'nama': s.nama,
              'nis': s.nis,
              'jenisKelamin': s.jenisKelamin,
            },
          )
          .toList(),
    );
    if (!mounted) return;
    setState(() => _importing = false);

    if (count != null) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal import. Coba lagi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Massal Siswa')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _kelasCtrl,
              enabled: widget.initialKelas == null,
              decoration: const InputDecoration(
                labelText: 'Nama Kelas',
                hintText: 'Contoh: 6A (boleh kelas baru)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tempel (paste) data siswa di bawah ini. 1 baris = 1 siswa, '
              'urutan: NIS, Nama, Jenis Kelamin (dipisah TAB kalau nyalin dari '
              'PDF/Excel/Sheets, atau koma kalau CSV).',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dataCtrl,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText:
                    '18.1.659\tAINUN MARDIAH LUBIS\tWanita\n18.1.660\tANISA HANNUM\tWanita',
              ),
              onChanged: (_) => _parse(),
            ),
            const SizedBox(height: 12),
            if (_baris1KolomBermasalah.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_baris1KolomBermasalah.length} baris dilewati karena '
                  'formatnya tidak dikenali (minimal harus ada NIS + Nama).',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'Pratinjau (${_preview.length} siswa terbaca)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._preview.map(
              (s) => Card(
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: ListTile(
                  dense: true,
                  title: Text(s.nama),
                  subtitle: Text(
                    'NIS: ${s.nis}${s.jenisKelamin.isNotEmpty ? ' | ${s.jenisKelamin}' : ''}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _importing ? null : _import,
            child: _importing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('Import ${_preview.length} Siswa'),
          ),
        ),
      ),
    );
  }
}