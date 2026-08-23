import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/sheets_services.dart';
import 'guru_dashboard.dart';

class OnboardingKelasMapelScreen extends StatefulWidget {
  const OnboardingKelasMapelScreen({super.key});

  @override
  State<OnboardingKelasMapelScreen> createState() =>
      _OnboardingKelasMapelScreenState();
}

class _OnboardingKelasMapelScreenState
    extends State<OnboardingKelasMapelScreen> {
  String? selectedKelas;
  String? selectedMapel;
  final SheetsService _sheetsService = SheetsService();
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final email = context.read<AuthService>().currentUser?.email;
    if (email != null) _loadAssignments(email);
  }

  Future<void> _loadAssignments(String email) async {
    final assignments = await _sheetsService.getAssignments(email);
    if (!mounted) return;
    setState(() {
      _assignments = assignments;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final listKelas = _assignments
      .map((item) => item['Kelas'].toString())
      .toSet()
      .toList();
    final mapelPerKelas = <String, List<String>>{};
    for (final assignment in _assignments) {
      mapelPerKelas
          .putIfAbsent(assignment['Kelas'].toString(), () => [])
          .add(assignment['Mata Pelajaran'].toString());
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Kelas & Mapel')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (_assignments.isEmpty)
                    const Text('Belum ada assignment untuk akun ini'),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Pilih Kelas'),
                    initialValue: selectedKelas,
                    items: listKelas
                        .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedKelas = val;
                        selectedMapel = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (selectedKelas != null)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Pilih Mata Pelajaran',
                      ),
                      initialValue: selectedMapel,
                      items: mapelPerKelas[selectedKelas]!
                          .toSet()
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => selectedMapel = val),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: (selectedKelas != null && selectedMapel != null)
                        ? () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GuruDashboard(
                                  kelas: selectedKelas!,
                                  mapel: selectedMapel!,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: const Text('Lanjutkan ke Dashboard'),
                  ),
                ],
              ),
            ),
    );
  }
}
