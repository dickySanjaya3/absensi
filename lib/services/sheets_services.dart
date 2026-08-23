import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// GANTI dengan URL Web App hasil Deploy dari Apps Script kamu.
/// Contoh: https://script.google.com/macros/s/AKfycb.../exec
const String kAppsScriptUrl ='https://script.google.com/macros/s/AKfycbyjgTTLIRVoo2lbgQ3RMq0vkbPTriSgwm27YW9VJR4ovJeMaB-KdC4l5FvP-iQ2CfrW/exec';

class UserCredentials {
  final String email;
  final String role;
  final String nama;
  const UserCredentials({
    required this.email,
    required this.role,
    this.nama = '',
  });
}

class SheetsService {
  Future<Map<String, dynamic>> _call(
    String action,
    Map<String, dynamic> params,
  ) async {
    try {
      final bodyStr = jsonEncode({'action': action, 'params': params});

      // PENTING: Apps Script Web App SELALU membalas dengan 302 redirect
      // ke script.googleusercontent.com. Kalau memakai http.post() biasa,
      // redirect ini otomatis diikuti oleh package:http, dan sesuai standar
      // HTTP, method-nya ikut berubah dari POST menjadi GET (body ikut hilang).
      // Akibatnya doPost() di Apps Script tidak pernah terpanggil.
      // Solusinya: matikan auto-redirect, lalu follow manual sambil tetap
      // pakai POST + body yang sama.
      final client = http.Client();
      try {
        var request = http.Request('POST', Uri.parse(kAppsScriptUrl))
          ..followRedirects = false
          ..headers['Content-Type'] = 'application/json'
          ..body = bodyStr;

        var streamedResponse = await client.send(request);
        var response = await http.Response.fromStream(streamedResponse);

        // Ikuti redirect manual dengan GET (bukan POST!). Apps Script sudah
        // MEMPROSES doPost() dan menghitung hasilnya pada request pertama;
        // redirect 302 ini hanya menunjuk ke URL sementara berisi hasil JSON
        // yang sudah jadi, dan untuk MENGAMBILNYA harus pakai GET tanpa body.
        int redirectCount = 0;
        while (response.statusCode >= 300 &&
            response.statusCode < 400 &&
            response.headers['location'] != null &&
            redirectCount < 5) {
          final nextUrl = response.headers['location']!;
          response = await client.get(Uri.parse(nextUrl));
          redirectCount++;
        }

        debugPrint('SIABSEN action=$action STATUS: ${response.statusCode}');
        debugPrint('SIABSEN action=$action BODY: ${response.body}');

        if (response.statusCode != 200) {
          return {'ok': false, 'error': 'HTTP ${response.statusCode}'};
        }
        return jsonDecode(response.body) as Map<String, dynamic>;
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('SIABSEN action=$action ERROR: $e');
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<UserCredentials?> login(String email, String password) async {
    final res = await _call('login', {'email': email, 'password': password});
    if (res['ok'] != true) return null;
    return UserCredentials(
      email: res['email'] as String,
      role: res['role'] as String,
      nama: (res['nama'] ?? '') as String,
    );
  }

  Future<List<Map<String, dynamic>>> getStudents({String? kelas}) async {
    final res = await _call('getStudents', {'kelas': kelas});
    if (res['ok'] != true) return [];
    return (res['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<bool> addStudent({
    required String id,
    required String nama,
    required String kelas,
    required String nis,
    required String jenisKelamin,
    required String barcode,
  }) async {
    final res = await _call('addStudent', {
      'id': id,
      'nama': nama,
      'kelas': kelas,
      'nis': nis,
      'jenisKelamin': jenisKelamin,
      'barcode': barcode,
    });
    return res['ok'] == true;
  }

  Future<bool> updateStudent({
    required int rowNumber,
    required String kelas,
    required String id,
    required String nama,
    required String nis,
    required String jenisKelamin,
    required String barcode,
  }) async {
    final res = await _call('updateStudent', {
      'rowNumber': rowNumber,
      'kelas': kelas,
      'id': id,
      'nama': nama,
      'nis': nis,
      'jenisKelamin': jenisKelamin,
      'barcode': barcode,
    });
    return res['ok'] == true;
  }

  Future<bool> deleteStudent({
    required String kelas,
    required int rowNumber,
  }) async {
    final res = await _call('deleteStudent', {
      'kelas': kelas,
      'rowNumber': rowNumber,
    });
    return res['ok'] == true;
  }

  Future<List<String>> getClasses() async {
    final res = await _call('getClasses', {});
    if (res['ok'] != true) return [];
    return (res['data'] as List).map((e) => e.toString()).toList();
  }

  /// Tambah kelas baru. Backend otomatis menyiapkan tab siswa kosong
  /// untuk kelas ini. Return pesan error kalau gagal (mis. nama dobel),
  /// atau null kalau sukses.
  Future<String?> addClass(String namaKelas) async {
    final res = await _call('addClass', {'namaKelas': namaKelas});
    if (res['ok'] == true) return null;
    return res['error']?.toString() ?? 'Gagal menambah kelas';
  }

  /// Hapus kelas dari daftar (tab data siswanya TIDAK ikut terhapus).
  Future<bool> deleteClass(String namaKelas) async {
    final res = await _call('deleteClass', {'namaKelas': namaKelas});
    return res['ok'] == true;
  }

  Future<List<Map<String, dynamic>>> getAssignments(String emailGuru) async {
    final res = await _call('getAssignments', {'emailGuru': emailGuru});
    if (res['ok'] != true) return [];
    return (res['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<bool> addAssignment({
    required String emailGuru,
    required String kelas,
    required String mapel,
  }) async {
    final res = await _call('addAssignment', {
      'emailGuru': emailGuru,
      'kelas': kelas,
      'mapel': mapel,
    });
    return res['ok'] == true;
  }

  Future<bool> updateAssignment({
    required int rowNumber,
    required String emailGuru,
    required String kelas,
    required String mapel,
  }) async {
    final res = await _call('updateAssignment', {
      'rowNumber': rowNumber,
      'emailGuru': emailGuru,
      'kelas': kelas,
      'mapel': mapel,
    });
    return res['ok'] == true;
  }

  Future<bool> deleteAssignment(int rowNumber) async {
    final res = await _call('deleteAssignment', {'rowNumber': rowNumber});
    return res['ok'] == true;
  }

  Future<List<Map<String, dynamic>>> getAttendance({
    required String emailGuru,
    required String kelas,
    required String mapel,
  }) async {
    final res = await _call('getAttendance', {
      'emailGuru': emailGuru,
      'kelas': kelas,
      'mapel': mapel,
    });
    if (res['ok'] != true) return [];
    return (res['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<bool> writeAttendance({
    required String guruEmail,
    required String kelas,
    required String mapel,
    required String siswaId,
    required String status,
  }) async {
    final res = await _call('writeAttendance', {
      'guruEmail': guruEmail,
      'kelas': kelas,
      'mapel': mapel,
      'siswaId': siswaId,
      'status': status,
    });
    return res['ok'] == true;
  }

  /// Simpan absensi 1 kelas sekaligus (dipakai layar Tinjau Absensi).
  /// [items] = daftar {siswaId, status} untuk SEMUA siswa di kelas itu,
  /// baik yang sudah discan maupun yang diisi manual oleh guru.
  Future<bool> writeAttendanceBatch({
    required String guruEmail,
    required String kelas,
    required String mapel,
    required List<Map<String, String>> items,
  }) async {
    final res = await _call('writeAttendanceBatch', {
      'guruEmail': guruEmail,
      'kelas': kelas,
      'mapel': mapel,
      'items': items,
    });
    return res['ok'] == true;
  }

  Future<bool> updateAttendanceStatus({
    required int rowNumber,
    required String status,
  }) async {
    final res = await _call('updateAttendanceStatus', {
      'rowNumber': rowNumber,
      'status': status,
    });
    return res['ok'] == true;
  }

  Future<List<Map<String, dynamic>>> getGurus() async {
    final res = await _call('getGurus', {});
    if (res['ok'] != true) return [];
    return (res['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<bool> addGuru({
    required String email,
    required String nama,
    required String password,
    String status = 'Aktif',
  }) async {
    final res = await _call('addGuru', {
      'email': email,
      'nama': nama,
      'password': password,
      'status': status,
    });
    return res['ok'] == true;
  }

  Future<bool> updateGuru({
    required int rowNumber,
    required String email,
    required String nama,
    required String password,
    String status = 'Aktif',
  }) async {
    final res = await _call('updateGuru', {
      'rowNumber': rowNumber,
      'email': email,
      'nama': nama,
      'password': password,
      'status': status,
    });
    return res['ok'] == true;
  }

  Future<bool> deleteGuru(int rowNumber) async {
    final res = await _call('deleteGuru', {'rowNumber': rowNumber});
    return res['ok'] == true;
  }

  // ---------- BARCODE / KARTU ID (Tahap 2) ----------

  /// Generate barcode baru untuk siswa (menonaktifkan barcode lama).
  /// Return payload barcode baru, atau null kalau gagal.
  Future<String?> generateBarcode({
    required String kelas,
    required String siswaId,
  }) async {
    final res = await _call('generateBarcode', {
      'siswaId': siswaId,
      'kelas': kelas,
    });
    if (res['ok'] != true) return null;
    return res['qrCode'] as String?;
  }

  /// Reaktivasi barcode lama tertentu (dari histori) supaya jadi aktif kembali.
  Future<bool> reactivateBarcode({
    required String kelas,
    required String siswaId,
    required String barcodeLama,
  }) async {
    final res = await _call('reactivateBarcode', {
      'siswaId': siswaId,
      'kelas': kelas,
      'barcodeLama': barcodeLama,
    });
    return res['ok'] == true;
  }

  /// Ambil histori generate/reaktivasi barcode untuk satu siswa.
  Future<List<Map<String, dynamic>>> getBarcodeHistory(String siswaId) async {
    final res = await _call('getBarcodeHistory', {'siswaId': siswaId});
    if (res['ok'] != true) return [];
    return (res['data'] as List).cast<Map<String, dynamic>>();
  }

  // ---------- REKAP BULANAN ----------

  /// Generate rekap bulanan sebagai Google Spreadsheet baru.
  /// [yearMonth] format 'YYYY-MM', misal '2026-08'.
  /// Return {url, error} - kalau gagal, url null dan error berisi pesan.
  Future<Map<String, String?>> exportMonthlyRecap({
    required String emailGuru,
    required String kelas,
    required String mapel,
    required String yearMonth,
  }) async {
    final res = await _call('exportMonthlyRecap', {
      'emailGuru': emailGuru,
      'kelas': kelas,
      'mapel': mapel,
      'yearMonth': yearMonth,
    });
    if (res['ok'] == true) {
      return {'url': res['url'] as String?, 'error': null};
    }
    return {'url': null, 'error': res['error']?.toString() ?? 'Gagal export'};
  }
}