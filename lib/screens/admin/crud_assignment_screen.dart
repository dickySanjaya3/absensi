import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/sheets_services.dart';
import '../../widgets/admin_widgets.dart';

class CrudAssignmentScreen extends StatefulWidget {
  const CrudAssignmentScreen({super.key});

  @override
  State<CrudAssignmentScreen> createState() => _CrudAssignmentScreenState();
}

class _CrudAssignmentScreenState extends State<CrudAssignmentScreen> {
  final SheetsService _service = SheetsService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _service.getAssignments('');
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _form({Map<String, dynamic>? assignment, int? index}) async {
    // 🔧 BUAT FOCUS NODE UNTUK SETIAP FIELD
    final emailFocus = FocusNode();
    final kelasFocus = FocusNode();
    final mapelFocus = FocusNode();

    final email = TextEditingController(
      text: assignment?['Email Guru']?.toString() ?? '',
    );
    final kelas = TextEditingController(
      text: assignment?['Kelas']?.toString() ?? '',
    );
    final mapel = TextEditingController(
      text: assignment?['Mata Pelajaran']?.toString() ?? '',
    );
    final key = GlobalKey<FormState>();
    bool isSaving = false;

    final saved = await showDialog<bool>(
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
            title: Text(
              assignment == null ? 'Tambah Assignment' : 'Edit Assignment',
            ),
            content: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: email,
                    focusNode: emailFocus,
                    enabled: !isSaving,
                    decoration: const InputDecoration(labelText: 'Email Guru'),
                    validator: _required,
                    onFieldSubmitted: (_) {
                      kelasFocus.requestFocus();
                    },
                  ),
                  TextFormField(
                    controller: kelas,
                    focusNode: kelasFocus,
                    enabled: !isSaving,
                    decoration: const InputDecoration(labelText: 'Kelas'),
                    validator: _required,
                    onFieldSubmitted: (_) {
                      mapelFocus.requestFocus();
                    },
                  ),
                  TextFormField(
                    controller: mapel,
                    focusNode: mapelFocus,
                    enabled: !isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Mata Pelajaran',
                    ),
                    validator: _required,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving
                    ? null
                    : () {
                        // 🔧 UNFOCUS SEMUA FOCUS NODE
                        emailFocus.unfocus();
                        kelasFocus.unfocus();
                        mapelFocus.unfocus();
                        // 🔧 DISPOSE FOCUS NODE
                        emailFocus.dispose();
                        kelasFocus.dispose();
                        mapelFocus.dispose();
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
                        if (!key.currentState!.validate()) return;
                        // 🔧 UNFOCUS SEMUA
                        emailFocus.unfocus();
                        kelasFocus.unfocus();
                        mapelFocus.unfocus();
                        await Future.delayed(const Duration(milliseconds: 100));
                        if (!ctx.mounted) return;
                        setDialogState(() => isSaving = true);
                        final result = index == null
                            ? await _service.addAssignment(
                                emailGuru: email.text.trim(),
                                kelas: kelas.text.trim(),
                                mapel: mapel.text.trim(),
                              )
                            : await _service.updateAssignment(
                                rowNumber: (_items[index]['_rowNumber'] as num)
                                    .toInt(),
                                emailGuru: email.text.trim(),
                                kelas: kelas.text.trim(),
                                mapel: mapel.text.trim(),
                              );
                        if (!ctx.mounted) return;
                        // 🔧 DISPOSE FOCUS NODE
                        emailFocus.dispose();
                        kelasFocus.dispose();
                        mapelFocus.dispose();
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
    email.dispose();
    kelas.dispose();
    mapel.dispose();

    if (saved == true) {
      await _load();
      if (mounted) _message('Assignment tersimpan');
    } else if (saved == false && mounted) {
      _message('Assignment gagal disimpan atau sudah ada');
    }
  }

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi' : null;

  Future<void> _delete(int index) async {
    // 🔧 BUAT FOCUS NODE
    final focusNode = FocusNode();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus assignment?'),
        content: Text(
          'Assignment ${_items[index]['Kelas']} - ${_items[index]['Mata Pelajaran']} akan dihapus.',
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
    final rowNumber = (_items[index]['_rowNumber'] as num).toInt();
    if (await _service.deleteAssignment(rowNumber)) {
      await _load();
    } else if (mounted) {
      _message('Assignment gagal dihapus');
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const CurvedAppBar(title: 'Kelola Assignment'),
      floatingActionButton: ModernFAB(
        onPressed: () => _form(),
        icon: Icons.add,
        label: 'Tambah Assignment',
      ),
      body: _loading
          ? const LoadingOverlay(message: 'Memuat data assignment...')
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF087BB9),
              child: _items.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: const [
                        SizedBox(height: 60),
                        EmptyStateWidget(
                          icon: Icons.assignment_outlined,
                          title: 'Belum ada assignment',
                          subtitle:
                              'Tekan tombol "Tambah Assignment"\nuntuk menambahkan penugasan baru.',
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return _AssignmentCard(
                          assignment: item,
                          onEdit: () => _form(assignment: item, index: index),
                          onDelete: () => _delete(index),
                        );
                      },
                    ),
            ),
    );
  }
}

/// ==================== ASSIGNMENT CARD ====================
class _AssignmentCard extends StatefulWidget {
  final Map<String, dynamic> assignment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AssignmentCard({
    required this.assignment,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<_AssignmentCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final kelas = widget.assignment['Kelas']?.toString() ?? '-';
    final mapel = widget.assignment['Mata Pelajaran']?.toString() ?? '-';
    final email = widget.assignment['Email Guru']?.toString() ?? '-';

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
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.06),
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? const Color(0xFF7C3AED).withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _isHovered ? 12 : 4,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(
                    alpha: _isHovered ? 0.2 : 0.15,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Color(0xFF7C3AED),
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
                      '$kelas - $mapel',
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