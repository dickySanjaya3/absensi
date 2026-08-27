import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/sheets_services.dart';
import '../../widgets/admin_widgets.dart';
import 'import_siswa_screen.dart';

class CrudSiswaScreen extends StatefulWidget {
  /// Kalau diisi, layar ini dibuka langsung untuk kelas tsb (dari layar
  /// Kelola Kelas) dan dropdown kelas dikunci ke nilai ini. Kalau null,
  /// admin bisa bebas pilih/pindah kelas seperti biasa.
  final String? initialKelas;

  const CrudSiswaScreen({super.key, this.initialKelas});

  @override
  State<CrudSiswaScreen> createState() => _CrudSiswaScreenState();
}

class _CrudSiswaScreenState extends State<CrudSiswaScreen> {
  final SheetsService _sheetsService = SheetsService();
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  List<String> _classes = [];
  String? _selectedKelas;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStudents() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students.where((student) {
          final nama = student['Nama']?.toString().toLowerCase() ?? '';
          final id = student['ID']?.toString().toLowerCase() ?? '';
          final nis = student['NIS']?.toString().toLowerCase() ?? '';
          return nama.contains(_searchQuery) ||
              id.contains(_searchQuery) ||
              nis.contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _loadClasses() async {
    final classes = await _sheetsService.getClasses();
    if (!mounted) return;
    setState(() {
      _classes = classes;
      _selectedKelas = widget.initialKelas != null &&
              classes.contains(widget.initialKelas)
          ? widget.initialKelas
          : (classes.isNotEmpty ? classes.first : null);
      _isLoading = false;
    });
    if (_selectedKelas != null) await _loadStudents();
  }

  Future<void> _loadStudents() async {
    final kelas = _selectedKelas;
    if (kelas == null) return;
    final students = await _sheetsService.getStudents(kelas: kelas);
    if (!mounted) return;
    setState(() {
      _students = students;
      _filteredStudents = students;
      _isLoading = false;
    });
  }

  Future<void> _showFormDialog({
    Map<String, dynamic>? student,
    int? index,
  }) async {
    // 🔧 BUAT FOCUS NODE UNTUK SETIAP FIELD
    final idFocus = FocusNode();
    final namaFocus = FocusNode();
    final nisFocus = FocusNode();
    final barcodeFocus = FocusNode();

    final idCtrl = TextEditingController(
      text: student?['ID']?.toString() ?? '',
    );
    final namaCtrl = TextEditingController(
      text: student?['Nama']?.toString() ?? '',
    );
    final nisCtrl = TextEditingController(
      text: student?['NIS']?.toString() ?? '',
    );
    final jenisKelamin = student?['Jenis Kelamin']?.toString() ?? '';
    final jenisKelaminCtrl = TextEditingController(text: jenisKelamin);
    final barcodeCtrl = TextEditingController(
      text: student?['Barcode']?.toString() ?? '',
    );
    final kelas = student?['kelas']?.toString() ?? _selectedKelas ?? '';
    if (kelas.isEmpty) {
      _message('Pilih kelas terlebih dahulu');
      return;
    }
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // 🔧 FOCUS OTOMATIS KE ID
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (idFocus.canRequestFocus) {
            idFocus.requestFocus();
          }
        });

        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(student == null ? 'Tambah Siswa' : 'Edit Siswa'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: idCtrl,
                      focusNode: idFocus,
                      enabled: !isSaving,
                      decoration: const InputDecoration(labelText: 'ID Siswa'),
                      validator: _required,
                      onFieldSubmitted: (_) {
                        namaFocus.requestFocus();
                      },
                    ),
                    TextFormField(
                      controller: namaCtrl,
                      focusNode: namaFocus,
                      enabled: !isSaving,
                      decoration: const InputDecoration(labelText: 'Nama Siswa'),
                      validator: _required,
                      onFieldSubmitted: (_) {
                        nisFocus.requestFocus();
                      },
                    ),
                    TextFormField(
                      controller: nisCtrl,
                      focusNode: nisFocus,
                      enabled: !isSaving,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'NIS'),
                      onFieldSubmitted: (_) {
                        barcodeFocus.requestFocus();
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: jenisKelaminCtrl.text.isEmpty
                          ? null
                          : jenisKelaminCtrl.text,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Kelamin',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'L', child: Text('L')),
                        DropdownMenuItem(value: 'P', child: Text('P')),
                      ],
                      onChanged: isSaving
                          ? null
                          : (value) => jenisKelaminCtrl.text = value ?? '',
                    ),
                    TextFormField(
                      controller: barcodeCtrl,
                      focusNode: barcodeFocus,
                      enabled: !isSaving && student == null,
                      decoration: const InputDecoration(labelText: 'Barcode'),
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
                        idFocus.unfocus();
                        namaFocus.unfocus();
                        nisFocus.unfocus();
                        barcodeFocus.unfocus();
                        // 🔧 DISPOSE FOCUS NODE
                        idFocus.dispose();
                        namaFocus.dispose();
                        nisFocus.dispose();
                        barcodeFocus.dispose();
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
                        idFocus.unfocus();
                        namaFocus.unfocus();
                        nisFocus.unfocus();
                        barcodeFocus.unfocus();
                        await Future.delayed(const Duration(milliseconds: 100));
                        if (!ctx.mounted) return;
                        setDialogState(() => isSaving = true);
                        final result = index == null
                            ? await _sheetsService.addStudent(
                                id: idCtrl.text.trim(),
                                nama: namaCtrl.text.trim(),
                                kelas: kelas,
                                nis: nisCtrl.text.trim(),
                                jenisKelamin: jenisKelaminCtrl.text,
                                barcode: barcodeCtrl.text.trim(),
                              )
                            : await _sheetsService.updateStudent(
                                kelas: kelas,
                                rowNumber: (_students[index]['_rowNumber'] as num)
                                    .toInt(),
                                id: idCtrl.text.trim(),
                                nama: namaCtrl.text.trim(),
                                nis: nisCtrl.text.trim(),
                                jenisKelamin: jenisKelaminCtrl.text,
                                barcode: barcodeCtrl.text.trim(),
                              );
                        if (!ctx.mounted) return;
                        // 🔧 DISPOSE FOCUS NODE
                        idFocus.dispose();
                        namaFocus.dispose();
                        nisFocus.dispose();
                        barcodeFocus.dispose();
                        // 🔧 GUNAKAN addPostFrameCallback
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (ctx.mounted) {
                            Navigator.pop(ctx, result);
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
    idCtrl.dispose();
    namaCtrl.dispose();
    nisCtrl.dispose();
    jenisKelaminCtrl.dispose();
    barcodeCtrl.dispose();

    if (saved == true) {
      await _loadStudents();
      if (mounted) _message('Data siswa tersimpan');
    } else if (saved == false && mounted) {
      _message('Gagal menyimpan. ID atau NIS mungkin sudah digunakan.');
    }
  }

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi' : null;

  Future<void> _deleteStudent(int index) async {
    // 🔧 BUAT FOCUS NODE
    final focusNode = FocusNode();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus siswa?'),
        content: Text(
          '${_students[index]['Nama']} akan dihapus dari tab Siswa.',
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
    final rowNumber = (_students[index]['_rowNumber'] as num).toInt();
    final kelas = _students[index]['kelas']?.toString() ?? _selectedKelas;
    if (kelas != null &&
        await _sheetsService.deleteStudent(
          kelas: kelas,
          rowNumber: rowNumber,
        )) {
      await _loadStudents();
    } else if (mounted) {
      _message('Gagal menghapus data siswa');
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: CurvedAppBar(
        title: widget.initialKelas != null
            ? 'Siswa Kelas ${widget.initialKelas}'
            : 'Kelola Data Siswa',
        actions: [
          if (_selectedKelas != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'repair') {
                  final n = await _sheetsService.repairKelasNamaJk(_selectedKelas!);
                  if (!mounted) return;
                  if (n == null) {
                    _message('Gagal memperbaiki data. Coba lagi.');
                  } else if (n == 0) {
                    _message('Tidak ada data yang perlu diperbaiki.');
                  } else {
                    _message(
                      '$n data diperbaiki. Kolom Jenis Kelamin dikosongkan, silakan isi ulang manual.',
                    );
                    await _loadStudents();
                  }
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(
                  value: 'repair',
                  child: Text('Perbaiki Nama/JK yang ketuker'),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedKelas != null)
            ModernFAB(
              heroTag: 'import_massal_siswa',
              onPressed: () async {
                final imported = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImportSiswaScreen(initialKelas: _selectedKelas),
                  ),
                );
                if (imported == true) await _loadStudents();
              },
              icon: Icons.upload_file,
              label: 'Import Massal',
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF087BB9),
            ),
          const SizedBox(height: 10),
          ModernFAB(
            heroTag: 'tambah_siswa',
            onPressed: () => _showFormDialog(),
            icon: Icons.add,
            label: 'Tambah Siswa',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingOverlay(message: 'Memuat data siswa...')
          : RefreshIndicator(
              onRefresh: _loadClasses,
              color: const Color(0xFF087BB9),
              child: Column(
                children: [
                  // Kelas Selector
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _KelasSelector(
                      selectedKelas: _selectedKelas,
                      classes: _classes,
                      onChanged: (kelas) async {
                        setState(() {
                          _selectedKelas = kelas;
                          _isLoading = true;
                        });
                        await _loadStudents();
                        if (mounted) setState(() => _isLoading = false);
                      },
                    ),
                  ),

                  // Student List
                  Expanded(
                    child: _selectedKelas == null
                        ? ListView(
                            padding: const EdgeInsets.all(16),
                            children: const [
                              SizedBox(height: 60),
                              EmptyStateWidget(
                                icon: Icons.class_outlined,
                                title: 'Belum ada data kelas',
                                subtitle: 'Silakan tambahkan kelas terlebih dahulu.',
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              // Search Bar
                              if (_students.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: 'Cari siswa (nama, ID, atau NIS)...',
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
                              if (_students.isNotEmpty && _searchQuery.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Ditemukan ${_filteredStudents.length} dari ${_students.length} siswa',
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
                                child: _students.isEmpty
                                    ? ListView(
                                        padding: const EdgeInsets.all(16),
                                        children: const [
                                          SizedBox(height: 60),
                                          EmptyStateWidget(
                                            icon: Icons.person_add_outlined,
                                            title: 'Belum ada data siswa',
                                            subtitle:
                                                'Tekan "Tambah Siswa" atau "Import Massal"\nuntuk menambahkan data siswa.',
                                          ),
                                        ],
                                      )
                                    : _filteredStudents.isEmpty
                                        ? ListView(
                                            padding: const EdgeInsets.all(16),
                                            children: [
                                              const SizedBox(height: 60),
                                              EmptyStateWidget(
                                                icon: Icons.search_off,
                                                title: 'Tidak ditemukan',
                                                subtitle:
                                                    'Siswa dengan kata kunci "$_searchQuery"\ntidak ditemukan.',
                                              ),
                                            ],
                                          )
                                        : ListView.builder(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            itemCount: _filteredStudents.length,
                                            itemBuilder: (ctx, index) {
                                              final student = _filteredStudents[index];
                                              final originalIndex =
                                                  _students.indexOf(student);
                                              return _SiswaListItem(
                                                student: student,
                                                onEdit: () => _showFormDialog(
                                                  student: student,
                                                  index: originalIndex,
                                                ),
                                                onDelete: () =>
                                                    _deleteStudent(originalIndex),
                                              );
                                            },
                                          ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// ==================== KELAS SELECTOR ====================
class _KelasSelector extends StatelessWidget {
  final String? selectedKelas;
  final List<String> classes;
  final ValueChanged<String?> onChanged;

  const _KelasSelector({
    required this.selectedKelas,
    required this.classes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      child: DropdownButtonFormField<String>(
        value: selectedKelas,
        decoration: InputDecoration(
          labelText: 'Pilih Kelas',
          labelStyle: GoogleFonts.inter(),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        items: classes
            .map(
              (kelas) => DropdownMenuItem(
                value: kelas,
                child: Text(
                  kelas,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

/// ==================== SISWA LIST ITEM ====================
class _SiswaListItem extends StatefulWidget {
  final Map<String, dynamic> student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SiswaListItem({
    required this.student,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_SiswaListItem> createState() => _SiswaListItemState();
}

class _SiswaListItemState extends State<_SiswaListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final nama = widget.student['Nama']?.toString() ?? '-';
    final id = widget.student['ID']?.toString() ?? '-';
    final nis = widget.student['NIS']?.toString() ?? '-';
    final jk = widget.student['Jenis Kelamin']?.toString() ?? '-';
    final initial = nama.isNotEmpty ? nama[0].toUpperCase() : '?';

    final jenisKelaminColor = jk == 'L'
        ? const Color(0xFF2F6FED)
        : jk == 'P'
            ? const Color(0xFFE0587A)
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
                  ? const Color(0xFF1FA97A).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.06),
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? const Color(0xFF1FA97A).withValues(alpha: 0.15)
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
                  color: const Color(0xFF1FA97A).withValues(
                    alpha: _isHovered ? 0.2 : 0.15,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1FA97A),
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
                      'ID: $id | NIS: $nis',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: jenisKelaminColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            jk,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: jenisKelaminColor,
                              fontWeight: FontWeight.w600,
                            ),
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