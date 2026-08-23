class Guru {
  final String email;
  final String nama;
  final String status;
  final String password;

  Guru({
    required this.email,
    required this.nama,
    required this.status,
    required this.password,
  });

  factory Guru.fromRow(List<dynamic> row) {
    return Guru(
      email: row.isNotEmpty ? row[0].toString() : '',
      nama: row.length > 1 ? row[1].toString() : '',
      status: row.length > 2 ? row[2].toString() : 'Aktif',
      password: row.length > 3 ? row[3].toString() : '',
    );
  }

  List<dynamic> toRow() => [email, nama, status, password];
}
