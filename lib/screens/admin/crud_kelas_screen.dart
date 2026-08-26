import 'package:flutter/material.dart';

import '../../services/sheets_services.dart';
import 'crud_siswa_screen.dart';
import 'import_siswa_screen.dart';

/// Layar "Kelola Kelas": admin bisa menambah kelas baru, menghapusnya dari
/// daftar, dan menekan satu kelas untuk masuk ke CRUD siswa kelas tsb.
class CrudKelasScreen extends StatefulWidget {
  const CrudKelasScreen({super.key});

  @override
  State<CrudKelasScreen> createState() => _CrudKelasScreenState();
}

class _CrudKelasScreenState extends State<CrudKelasScreen> {
  final SheetsService _sheetsService = SheetsService();
  List<String> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    final classes = await _sheetsService.getClasses();
    if (!mounted) return;
    setState(() {
      _classes = classes;
      _isLoading = false;
    });
  }

  Future<void> _sinkronkanKelas() async {
    setState(() => _isLoading = true);
    final ditemukan = await _sheetsService.syncKelasFromSheets();
    if (!mounted) return;
    await _loadClasses();
    if (!mounted) return;
    if (ditemukan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal sinkronisasi. Coba lagi.')),
      );
    } else if (ditemukan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kelas di spreadsheet sudah terdaftar.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${ditemukan.length} kelas lama ditemukan & didaftarkan: ${ditemukan.join(', ')}'),
        ),
      );
    }
  }

  Future<void> _tambahKelas() async {
    // 🔧 BUAT FOCUS NODE SENDIRI
    final focusNode = FocusNode();
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    final namaKelas = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // 🔧 FOCUS DITANGANI DI SINI
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (focusNode.canRequestFocus) {
            focusNode.requestFocus();
          }
        });

        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Tambah Kelas'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: ctrl,
                focusNode: focusNode, // 🔧 PAKAI FOCUS NODE SENDIRI
                enabled: !isSaving,
                decoration: const InputDecoration(
                  labelText: 'Nama Kelas',
                  hintText: 'Contoh: 1A, 2B, 6C',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving
                    ? null
                    : () {
                        // 🔧 UNFOCUS DAN DISPOSE FOCUS NODE
                        focusNode.unfocus();
                        focusNode.dispose();
                        // 🔧 GUNAKAN addPostFrameCallback AGAR POP SETELAH UNFOCUS
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                        });
                      },
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        // 🔧 UNFOCUS DULU
                        focusNode.unfocus();
                        // 🔧 TUNGGU SEBENTAR
                        await Future.delayed(const Duration(milliseconds: 100));
                        if (!ctx.mounted) return;
                        setDialogState(() => isSaving = true);
                        final error = await _sheetsService.addClass(
                          ctrl.text.trim(),
                        );
                        if (!ctx.mounted) return;
                        if (error == null) {
                          focusNode.dispose();
                          // 🔧 GUNAKAN addPostFrameCallback
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (ctx.mounted) {
                              Navigator.pop(ctx, ctrl.text.trim());
                            }
                          });
                        } else {
                          setDialogState(() => isSaving = false);
                          ScaffoldMessenger.of(
                            ctx,
                          ).showSnackBar(SnackBar(content: Text(error)));
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan'),
              ),
            ],
          ),
        );
      },
    );

    // 🔧 DISPOSE CONTROLLER
    ctrl.dispose();
    // 🔧 PASTIKAN FOCUS NODE DI-DISPOSE
    focusNode.dispose();

    if (namaKelas != null) {
      await _loadClasses();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kelas "$namaKelas" ditambahkan')));
      }
    }
  }

  Future<void> _hapusKelas(String namaKelas) async {
    // 🔧 BUAT FOCUS NODE UNTUK DIALOG HAPUS
    final focusNode = FocusNode();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus kelas?'),
        content: Text(
          '"$namaKelas" akan dihapus dari daftar kelas. '
          'Data siswa di tab kelas ini TIDAK ikut terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              focusNode.unfocus();
              focusNode.dispose();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (ctx.mounted) Navigator.pop(ctx, false);
              });
            },
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              focusNode.unfocus();
              focusNode.dispose();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (ctx.mounted) Navigator.pop(ctx, true);
              });
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    focusNode.dispose();

    if (confirmed != true) return;

    final ok = await _sheetsService.deleteClass(namaKelas);
    if (!mounted) return;
    if (ok) {
      await _loadClasses();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal menghapus kelas')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kelas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sinkronkan dari Spreadsheet',
            onPressed: _sinkronkanKelas,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'import_massal',
            onPressed: () async {
              final imported = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const ImportSiswaScreen()),
              );
              if (imported == true) _loadClasses();
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Import Massal'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.indigo,
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'tambah_kelas',
            onPressed: _tambahKelas,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Kelas'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadClasses,
              child: _classes.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 160),
                        Center(child: Text('Belum ada kelas. Tambah dulu yuk.')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: _classes.length,
                      itemBuilder: (ctx, i) {
                        final kelas = _classes[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFEDEBFF),
                              foregroundColor: Colors.indigo,
                              child: Icon(Icons.class_),
                            ),
                            title: Text(
                              kelas,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text('Ketuk untuk kelola data siswa'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _hapusKelas(kelas),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CrudSiswaScreen(initialKelas: kelas),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}