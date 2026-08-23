import 'package:flutter/material.dart';

import '../../services/sheets_services.dart';

class CrudSiswaScreen extends StatefulWidget {
  const CrudSiswaScreen({super.key});

  @override
  State<CrudSiswaScreen> createState() => _CrudSiswaScreenState();
}

class _CrudSiswaScreenState extends State<CrudSiswaScreen> {
  final SheetsService _sheetsService = SheetsService();
  List<Map<String, dynamic>> _students = [];
  List<String> _classes = [];
  String? _selectedKelas;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final classes = await _sheetsService.getClasses();
    if (!mounted) return;
    setState(() {
      _classes = classes;
      _selectedKelas = classes.isNotEmpty ? classes.first : null;
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
      _isLoading = false;
    });
  }

  Future<void> _showFormDialog({
    Map<String, dynamic>? student,
    int? index,
  }) async {
    final idCtrl = TextEditingController(
      text: student?['ID']?.toString() ?? '',
    );
    final namaCtrl = TextEditingController(
      text: student?['Nama']?.toString() ?? '',
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
      builder: (ctx) => StatefulBuilder(
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
                    enabled: !isSaving,
                    decoration: const InputDecoration(labelText: 'ID Siswa'),
                    validator: _required,
                  ),
                  TextFormField(
                    controller: namaCtrl,
                    enabled: !isSaving,
                    decoration: const InputDecoration(labelText: 'Nama Siswa'),
                    validator: _required,
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
                    enabled: !isSaving && student == null,
                    decoration: const InputDecoration(labelText: 'Barcode'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);
                      final result = index == null
                          ? await _sheetsService.addStudent(
                              id: idCtrl.text.trim(),
                              nama: namaCtrl.text.trim(),
                              kelas: kelas,
                              jenisKelamin: jenisKelaminCtrl.text,
                              barcode: barcodeCtrl.text.trim(),
                            )
                          : await _sheetsService.updateStudent(
                              kelas: kelas,
                              rowNumber: (_students[index]['_rowNumber'] as num)
                                  .toInt(),
                              id: idCtrl.text.trim(),
                              nama: namaCtrl.text.trim(),
                              jenisKelamin: jenisKelaminCtrl.text,
                              barcode: barcodeCtrl.text.trim(),
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
    idCtrl.dispose();
    namaCtrl.dispose();
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus siswa?'),
        content: Text(
          '${_students[index]['Nama']} akan dihapus dari tab Siswa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
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
      appBar: AppBar(title: const Text('CRUD Data Siswa')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadClasses,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedKelas,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Kelas',
                        border: OutlineInputBorder(),
                      ),
                      items: _classes
                          .map(
                            (kelas) => DropdownMenuItem(
                              value: kelas,
                              child: Text(kelas),
                            ),
                          )
                          .toList(),
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
                  Expanded(
                    child: _selectedKelas == null
                        ? const Center(child: Text('Belum ada data kelas'))
                        : _students.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 160),
                              Center(
                                child: Text(
                                  'Belum ada data siswa di tab Siswa',
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            itemCount: _students.length,
                            itemBuilder: (ctx, index) {
                              final student = _students[index];
                              return ListTile(
                                title: Text(student['Nama'].toString()),
                                subtitle: Text(
                                  'ID: ${student['ID']} | Jenis Kelamin: ${student['Jenis Kelamin']}',
                                ),
                                isThreeLine: true,
                                trailing: Wrap(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () => _showFormDialog(
                                        student: student,
                                        index: index,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteStudent(index),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
