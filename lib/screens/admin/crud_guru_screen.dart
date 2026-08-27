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
  List<Map<String, dynamic>> _filteredGurus = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadGurus();
    _searchController.addListener(_filterGurus);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterGurus() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredGurus = _gurus;
      } else {
        _filteredGurus = _gurus.where((guru) {
          final nama = guru['Nama Guru']?.toString().toLowerCase() ?? '';
          final email = guru['Email']?.toString().toLowerCase() ?? '';
          return nama.contains(_searchQuery) || email.contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _loadGurus() async {
    final gurus = await _sheetsService.getGurus();
    if (!mounted) return;
    setState(() {
      _gurus = gurus;
      _filteredGurus = gurus;
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
          : Column(
              children: [
                // Search Bar
                if (_gurus.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari guru berdasarkan nama atau email...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF9CA3AF),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF64748B),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Color(0xFF64748B),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF087BB9),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                // Results count
                if (_gurus.isNotEmpty && _searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          'Ditemukan ${_filteredGurus.length} dari ${_gurus.length} guru',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),

                // List
                Expanded(
                  child: RefreshIndicator(
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
                        : _filteredGurus.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  const SizedBox(height: 60),
                                  EmptyStateWidget(
                                    icon: Icons.search_off,
                                    title: 'Tidak ditemukan',
                                    subtitle:
                                        'Guru dengan kata kunci "$_searchQuery"\ntidak ditemukan.',
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredGurus.length,
                                itemBuilder: (ctx, index) {
                                  final guru = _filteredGurus[index];
                                  final originalIndex = _gurus.indexOf(guru);
                                  return _GuruListItem(
                                    guru: guru,
                                    onEdit: () => _showFormDialog(
                                      guru: guru,
                                      index: originalIndex,
                                    ),
                                    onDelete: () => _deleteGuru(originalIndex),
                                  );
                                },
                              ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// ==================== GURU LIST ITEM ====================
class _GuruListItem extends StatefulWidget {
  final Map<String, dynamic> guru;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GuruListItem({
    required this.guru,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_GuruListItem> createState() => _GuruListItemState();
}

class _GuruListItemState extends State<_GuruListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final nama = widget.guru['Nama Guru']?.toString() ?? '-';
    final email = widget.guru['Email']?.toString() ?? '-';
    final status = widget.guru['Status']?.toString() ?? '-';
    final initial = nama.isNotEmpty ? nama[0].toUpperCase() : '?';

    final statusColor = status.toLowerCase() == 'aktif'
        ? const Color(0xFF1FA97A)
        : const Color(0xFF64748B);

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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFF2F6FED).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.06),
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? const Color(0xFF2F6FED).withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _isHovered ? 12 : 4,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar with initial
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F6FED).withValues(
                    alpha: _isHovered ? 0.2 : 0.15,
                  ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
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
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isHovered ? 1.0 : 0.7,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EditIconButton(onPressed: widget.onEdit),
                    DeleteIconButton(onPressed: widget.onDelete),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}