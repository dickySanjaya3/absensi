class Student {
  final String id;
  final String nama;
  final String nis;
  final String kelas;

  const Student({
    required this.id,
    required this.nama,
    required this.nis,
    required this.kelas,
  });

  factory Student.fromRow(List<dynamic> row) {
    return Student(
      id: row.isNotEmpty ? row[0].toString() : '',
      nama: row.length > 1 ? row[1].toString() : '',
      kelas: row.length > 2 ? row[2].toString() : '',
      nis: row.length > 3 ? row[3].toString() : '',
    );
  }

  List<dynamic> toRow() => [id, nama, kelas, nis];
}
