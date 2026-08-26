import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/sheets_services.dart';
import '../../widgets/admin_widgets.dart';

class CrudGuruScreen extends StatefulWidget {
  const CrudGuruScreen({super.key});

  @override
  State<CrudGuruScreen> createState() => _CrudGuruScreenState();
}

class _CrudGuruScreenState extends State<CrudGuruScreen> {
  final SheetsService _sheetsService = SheetsService();
  List<Map<String, dynamic>> _gurus = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGurus();
  }

  Future<void> _loadGurus() async {
    final gurus = await _sheetsService.getGurus();
    if (!mounted) return;
    setState(() {
      _gurus = gurus;
      _isLoading = false;
    });
  }

  Future<void> _showFormDialog({Map<String, dynamic>? guru, int? index}) async {
    // 🔧 BUAT FOCUS NODE UNTUK SETIAP FIELD
    final emailFocus = FocusNode();
    final passwordFocus = FocusNode();
    final namaFocus = FocusNode();
    final statusFocus = FocusNode();

    final emailCtrl = TextEditingController(
      text: guru?['Email']?.toString() ?? '',
    );
    final passwordCtrl = TextEditingController(
      text: guru?['Password']?.toString() ?? '',
    );
    final namaCtrl = TextEditingController(
      text: guru?['Nama Guru']?.toString() ?? '',
    );
    final statusCtrl = TextEditingController(
      text: guru?['Status']?.toString() ?? 'Aktif',
    );
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // 🔧 FOCUS OTOMATIS KE EMAIL
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (emailFocus.canRequestFocus) {
            emailFocus.requestFocus();
          }
        });

        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(guru == null ? 'Tambah Akun Guru' : 'Edit Akun Guru'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: emailCtrl,
                      focusNode: emailFocus,
                      enabled: !isSaving,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) =>
                          _required(value) ??
                          (value!.contains('@') ? null : 'Email tidak valid'),
                      onFieldSubmitted: (_) {
                        // Pindah ke password saat tekan Done
                        passwordFocus.requestFocus();
                      },
                    ),
                    TextFormField(
                      controller: passwordCtrl,
                      focusNode: passwordFocus,
                      enabled: !isSaving,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) => value == null || value.length < 6
                          ? 'Minimal 6 karakter'
                          : null,
                      onFieldSubmitted: (_) {
                        namaFocus.requestFocus();
                      },
                    ),
                    TextFormField(
                      controller: namaCtrl,
                      focusNode: namaFocus,
                      enabled: !isSaving,
                      decoration: const InputDecoration(labelText: 'Nama Guru'),
                      validator: _required,
                      onFieldSubmitted: (_) {
                        statusFocus.requestFocus();
                      },
                    ),
                    TextFormField(
                      controller: statusCtrl,
                      focusNode: statusFocus,
                      enabled: !isSaving,
                      decoration: const InputDecoration(labelText: 'Status'),
                      validator: _required,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving
                    ? null
                    : () {
                        // 🔧 UNFOCUS SEMUA FOCUS NODE
                        emailFocus.unfocus();
                        passwordFocus.unfocus();
                        namaFocus.unfocus();
                        statusFocus.unfocus();
                        // 🔧 DISPOSE FOCUS NODE
                        emailFocus.dispose();
                        passwordFocus.dispose();
                        namaFocus.dispose();
                        statusFocus.dispose();
                        // 🔧 GUNAKAN addPostFrameCallback
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (ctx.mounted) {
                            Navigator.pop(ctx, null);
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
                        // 🔧 UNFOCUS SEMUA
                        emailFocus.unfocus();
                        passwordFocus.unfocus();
                        namaFocus.unfocus();
                        statusFocus.unfocus();
                        await Future.delayed(const Duration(milliseconds: 100));
                        if (!ctx.mounted) return;
                        setDialogState(() => isSaving = true);
                        final saved = index == null
                            ? await _sheetsService.addGuru(
                                email: emailCtrl.text.trim(),
                                nama: namaCtrl.text.trim(),
                                password: passwordCtrl.text,
                                status: statusCtrl.text.trim(),
                              )
                            : await _sheetsService.updateGuru(
                                rowNumber: (_gurus[index]['_rowNumber'] as num)
                                    .toInt(),
                                email: emailCtrl.text.trim(),
                                nama: namaCtrl.text.trim(),
                                password: passwordCtrl.text,
                                status: statusCtrl.text.trim(),
                              );
                        if (!ctx.mounted) return;
                        // 🔧 DISPOSE FOCUS NODE
                        emailFocus.dispose();
                        passwordFocus.dispose();
                        namaFocus.dispose();
                        statusFocus.dispose();
                        // 🔧 GUNAKAN addPostFrameCallback
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (ctx.mounted) {
                            Navigator.pop(ctx, saved);
                          }
                        });
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
    emailCtrl.dispose();
    passwordCtrl.dispose();
    namaCtrl.dispose();
    statusCtrl.dispose();

    if (result == true) {
      await _loadGurus();
      if (mounted) _message('Data guru tersimpan');
    } else if (result == false && mounted) {
      _message('Data tidak tersimpan. Email mungkin sudah digunakan.');
    }
  }

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi' : null;

  Future<void> _deleteGuru(int index) async {
    // 🔧 BUAT FOCUS NODE
    final focusNode = FocusNode();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus akun guru?'),
        content: Text(
          'Akun ${_gurus[index]['Email']} akan dihapus dari tab Guru.',
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
    final rowNumber = (_gurus[index]['_rowNumber'] as num).toInt();
    if (await _sheetsService.deleteGuru(rowNumber)) {
      await _loadGurus();
    } else if (mounted) {
      _message('Gagal menghapus data guru');
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const CurvedAppBar(title: 'Kelola Akun Guru'),
      floatingActionButton: ModernFAB(
        onPressed: () => _showFormDialog(),
        icon: Icons.add,
        label: 'Tambah Guru',
      ),
      body: _isLoading
          ? const LoadingOverlay(message: 'Memuat data guru...')
          : RefreshIndicator(
              onRefresh: _loadGurus,
              color: const Color(0xFF087BB9),
              child: _gurus.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: const [
                        SizedBox(height: 60),
                        EmptyStateWidget(
                          icon: Icons.person_add_outlined,
                          title: 'Belum ada akun guru',
                          subtitle:
                              'Tekan tombol "Tambah Guru"\nuntuk menambahkan akun guru baru.',
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _gurus.length,
                      itemBuilder: (ctx, index) {
                        final guru = _gurus[index];
                        return _GuruListItem(
                          guru: guru,
                          onEdit: () => _showFormDialog(guru: guru, index: index),
                          onDelete: () => _deleteGuru(index),
                        );
                      },
                    ),
            ),
    );
  }
}

/// ==================== GURU LIST ITEM ====================
class _GuruListItem extends StatelessWidget {
  final Map<String, dynamic> guru;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GuruListItem({
    required this.guru,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final nama = guru['Nama Guru']?.toString() ?? '-';
    final email = guru['Email']?.toString() ?? '-';
    final status = guru['Status']?.toString() ?? '-';
    final initial = nama.isNotEmpty ? nama[0].toUpperCase() : '?';

    final statusColor = status.toLowerCase() == 'aktif'
        ? const Color(0xFF1FA97A)
        : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ModernCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar with initial
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF2F6FED).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF2F6FED),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

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
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            EditIconButton(onPressed: onEdit),
            DeleteIconButton(onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}