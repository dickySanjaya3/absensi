class Assignment {
  final String emailGuru;
  final String kelas;
  final String mapel;

  Assignment({
    required this.emailGuru,
    required this.kelas,
    required this.mapel,
  });

  factory Assignment.fromRow(List<dynamic> row) {
    return Assignment(
      emailGuru: row.isNotEmpty ? row[0].toString() : '',
      kelas: row.length > 1 ? row[1].toString() : '',
      mapel: row.length > 2 ? row[2].toString() : '',
    );
  }

  List<dynamic> toRow() => [emailGuru, kelas, mapel];
}