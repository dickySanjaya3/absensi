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
      showModernToast(
        context: context,
        message: 'Gagal sinkronisasi. Coba lagi.',
        type: ToastType.error,
      );
    } else if (ditemukan.isEmpty) {
      showModernToast(
        context: context,
        message: 'Semua kelas di spreadsheet sudah terdaftar.',
        type: ToastType.info,
      );
    } else {
      showModernToast(
        context: context,
        message: '${ditemukan.length} kelas lama ditemukan & didaftarkan: ${ditemukan.join(', ')}',
        type: ToastType.success,
      );
    }
  }

  Future<void> _tambahKelas() async {
    final ctrl = TextEditingController();

    final namaKelas = await showModernDialog<String>(
      context: context,
      title: 'Tambah Kelas',
      backgroundColor: const Color(0xFFE7A008),
      builder: (ctx, isSaving, setDialogState) {
        final formKey = GlobalKey<FormState>();

        return Form(
          key: formKey,
          child: ModernTextField(
            controller: ctrl,
            labelText: 'Nama Kelas',
            hintText: 'Contoh: 1A, 2B, 6C',
            enabled: !isSaving,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
          ),
        );
      },
      onConfirm: (ctx, setDialogState) async {
        final formKey = ctx.findAncestorStateOfType<FormState>();
        if (formKey != null && !formKey.validate()) return null;

        final error = await _sheetsService.addClass(ctrl.text.trim());
        if (error == null) {
          return ctrl.text.trim();
        } else {
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(error)),
            );
          }
          return null;
        }
      },
    );

    ctrl.dispose();

    if (namaKelas != null) {
      await _loadClasses();
      if (mounted) {
        showModernToast(
          context: context,
          message: 'Kelas "$namaKelas" ditambahkan',
          type: ToastType.success,
        );
      }
    }
  }

  Future<void> _hapusKelas(String namaKelas) async {
    final confirmed = await showModernConfirmDialog(
      context: context,
      title: 'Hapus kelas?',
      message:
          '"$namaKelas" akan dihapus dari daftar kelas. '
          'Data siswa di tab kelas ini TIDAK ikut terhapus.',
      confirmText: 'Hapus',
      backgroundColor: const Color(0xFFE7A008),
    );

    if (confirmed != true) return;

    final ok = await _sheetsService.deleteClass(namaKelas);
    if (!mounted) return;
    if (ok) {
      await _loadClasses();
    } else {
      if (mounted) {
        showModernToast(
          context: context,
          message: 'Gagal menghapus kelas',
          type: ToastType.error,
        );
      }
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
class _KelasManagementCard extends StatefulWidget {
  final String kelas;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _KelasManagementCard({
    required this.kelas,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_KelasManagementCard> createState() => _KelasManagementCardState();
}

class _KelasManagementCardState extends State<_KelasManagementCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -2.0 : 0.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFFE7A008).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.06),
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? const Color(0xFFE7A008).withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _isHovered ? 12 : 4,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Row(
              children: [
                // Icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7A008).withValues(
                      alpha: _isHovered ? 0.2 : 0.15,
                    ),
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
                        widget.kelas,
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
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isHovered ? 1.0 : 0.7,
                  child: DeleteIconButton(onPressed: widget.onDelete),
                ),

                // Arrow indicator
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isHovered ? 1.0 : 0.5,
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}