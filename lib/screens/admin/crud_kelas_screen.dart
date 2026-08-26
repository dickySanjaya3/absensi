import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/sheets_services.dart';
import '../../widgets/admin_widgets.dart';
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: CurvedAppBar(
        title: 'Kelola Kelas',
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.white),
            tooltip: 'Sinkronkan dari Spreadsheet',
            onPressed: _sinkronkanKelas,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModernFAB(
            heroTag: 'import_massal',
            onPressed: () async {
              final imported = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const ImportSiswaScreen()),
              );
              if (imported == true) _loadClasses();
            },
            icon: Icons.upload_file,
            label: 'Import Massal',
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF087BB9),
          ),
          const SizedBox(height: 10),
          ModernFAB(
            heroTag: 'tambah_kelas',
            onPressed: _tambahKelas,
            icon: Icons.add,
            label: 'Tambah Kelas',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingOverlay(message: 'Memuat data kelas...')
          : RefreshIndicator(
              onRefresh: _loadClasses,
              color: const Color(0xFF087BB9),
              child: _classes.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: const [
                        SizedBox(height: 60),
                        EmptyStateWidget(
                          icon: Icons.class_outlined,
                          title: 'Belum ada kelas',
                          subtitle:
                              'Tekan tombol "Tambah Kelas"\nuntuk menambahkan kelas baru.',
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _classes.length,
                      itemBuilder: (ctx, i) {
                        final kelas = _classes[i];
                        return _KelasManagementCard(
                          kelas: kelas,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CrudSiswaScreen(initialKelas: kelas),
                              ),
                            );
                          },
                          onDelete: () => _hapusKelas(kelas),
                        );
                      },
                    ),
            ),
    );
  }
}

/// ==================== KELAS MANAGEMENT CARD ====================
class _KelasManagementCard extends StatelessWidget {
  final String kelas;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _KelasManagementCard({
    required this.kelas,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ModernCard(
        padding: const EdgeInsets.all(16),
        onTap: onTap,
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE7A008).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.class_outlined,
                color: Color(0xFFE7A008),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kelas,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ketuk untuk kelola data siswa',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Delete button
            DeleteIconButton(onPressed: onDelete),

            // Arrow indicator
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}