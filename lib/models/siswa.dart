class Siswa {
  final String id;
  final String nama;
  final String kelas;
  final String nim;
  final String jenisKelamin;

  Siswa({
    required this.id,
    required this.nama,
    required this.kelas,
    required this.nim,
    required this.jenisKelamin,
  });

  factory Siswa.fromRow(List<dynamic> row) {
    return Siswa(
      id: row.isNotEmpty ? row[0].toString() : '',
      nama: row.length > 1 ? row[1].toString() : '',
      kelas: row.length > 2 ? row[2].toString() : '',
      nim: row.length > 3 ? row[3].toString() : '',
      jenisKelamin: row.length > 4 ? row[4].toString() : 'L',
    );
  }

  List<dynamic> toRow() => [id, nama, kelas, nim, jenisKelamin];
}