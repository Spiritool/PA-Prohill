class SampahData {
  final int id;
  final String namaUpt;
  final String nama;
  final String noHp;
  final String status;
  final String deskripsi;
  final Alamat alamat;
  final DateTime tanggal;
   final DateTime tanggalFormatted; // ⬅️ tambah ini

  SampahData({
    required this.id,
    required this.namaUpt,
    required this.nama,
    required this.noHp,
    required this.status,
    required this.deskripsi,
    required this.alamat,
    required this.tanggal,
    required this.tanggalFormatted, // ⬅️ jangan lupa tambahkan juga di constructor
  });

  factory SampahData.fromJson(Map<String, dynamic> json) {
    var alamatJson = (json['warga']?['alamat'] as List?)?.first ?? {};

    return SampahData(
      id: json['id'] ?? 0,
      namaUpt: json['upt']?['nama_upt'] ?? 'Unknown UPT',
      nama: json['warga']?['nama'] ?? 'Unknown',
      noHp: json['warga']?['no_hp'] ?? 'No Phone Number',
      status: json['status'] ?? 'Unknown Status',
      deskripsi: json['deskripsi'] ?? 'No Description',
      alamat: Alamat.fromJson(alamatJson),
      tanggal: DateTime.parse(json['created_at']), 
      tanggalFormatted: DateTime.parse(json['created_at']), // ⬅️ pastikan format ISO (yyyy-MM-ddTHH:mm:ss)
      
    );
  }
}

class Alamat {
  final int id;
  final String deskripsi;
  final String kecamatan;
  final String kelurahan;
  final String kordinat;

  Alamat({
    required this.id,
    required this.deskripsi,
    required this.kordinat,
    required this.kecamatan,
    required this.kelurahan,
  });

  factory Alamat.fromJson(Map<String, dynamic> json) {
    return Alamat(
      id: json['id'] ?? 0,
      deskripsi: json['deskripsi'] ?? 'Tidak ada Deskripsi',
      kecamatan: json['kecamatan'] ?? 'Tidak ada Kecamatan',
      kelurahan: json['kelurahan'] ?? 'Tidak ada Kelurahan',
      kordinat: json['kordinat'] ?? 'Tidak ada Kordinat',
    );
  }
}