import 'package:flutter/material.dart';

import '../../services/sheets_services.dart';

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
      builder: (ctx) => StatefulBuilder(
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
                  enabled: !isSaving,
                  decoration: const InputDecoration(labelText: 'Email Guru'),
                  validator: _required,
                ),
                TextFormField(
                  controller: kelas,
                  enabled: !isSaving,
                  decoration: const InputDecoration(labelText: 'Kelas'),
                  validator: _required,
                ),
                TextFormField(
                  controller: mapel,
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
                      FocusScope.of(ctx).unfocus();
                      Navigator.pop(ctx, null);
                    },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!key.currentState!.validate()) return;
                      FocusScope.of(ctx).unfocus();
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
                      if (ctx.mounted) Navigator.pop(ctx, result);
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
      ),
    );
    email.dispose();
    kelas.dispose();
    mapel.dispose();
    if (saved == true) {
      await _load();
      if (mounted) _message('Assignment tersimpan');
    } else if (saved == false && mounted) {
      // false = proses simpan gagal; null (Batal) tidak masuk sini.
      _message('Assignment gagal disimpan atau sudah ada');
    }
  }

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi' : null;

  Future<void> _delete(int index) async {
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
      appBar: AppBar(title: const Text('Kelola Assignment')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _form(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 160),
                        Center(child: Text('Belum ada assignment')),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return ListTile(
                          leading: const Icon(Icons.assignment),
                          title: Text(
                            '${item['Kelas']} - ${item['Mata Pelajaran']}',
                          ),
                          subtitle: Text(item['Email Guru'].toString()),
                          trailing: Wrap(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.orange,
                                ),
                                onPressed: () =>
                                    _form(assignment: item, index: index),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _delete(index),
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