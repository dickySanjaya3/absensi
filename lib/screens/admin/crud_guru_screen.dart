import 'package:flutter/material.dart';

import '../../services/sheets_services.dart';

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
      appBar: AppBar(title: const Text('Kelola Akun Guru')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadGurus,
              child: _gurus.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 160),
                        Center(child: Text('Belum ada akun guru')),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _gurus.length,
                      itemBuilder: (ctx, index) {
                        final guru = _gurus[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(guru['Nama Guru'].toString()),
                          subtitle: Text(
                            '${guru['Email']}\nStatus: ${guru['Status']}',
                          ),
                          isThreeLine: true,
                          trailing: Wrap(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.orange,
                                ),
                                onPressed: () =>
                                    _showFormDialog(guru: guru, index: index),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteGuru(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}