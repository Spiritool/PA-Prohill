class SampahData {
  final int id;
  final String namaUpt;
  final String name;
  final String noHp;
  final String status;
  final String fotoSampah;
  final String deskripsi;
  final Alamat alamat;

  SampahData({
    required this.id,
    required this.namaUpt,
    required this.name,
    required this.noHp,
    required this.status,
    required this.fotoSampah,
    required this.deskripsi,
    required this.alamat,
  });

  factory SampahData.fromJson(Map<String, dynamic> json) {
    return SampahData(
      id: json['id'],
      namaUpt: json['upt']['nama_upt'],
      name: json['warga']['nama'],
      noHp: json['warga']['no_hp'],
      status: json['status'],
      fotoSampah: json['foto_sampah'],
      deskripsi: json['deskripsi'],
      alamat: Alamat.fromJson(json['warga']['alamat'][0]),
    );
  }
}

class Alamat {
  final String kelurahan;
  final String kecamatan;
  final String deskripsi;
  final String kordinat;

  Alamat({
    required this.kelurahan,
    required this.kecamatan,
    required this.deskripsi,
    required this.kordinat,
  });

  factory Alamat.fromJson(Map<String, dynamic> json) {
    return Alamat(
      kelurahan: json['kelurahan'],
      kecamatan: json['kecamatan'],
      deskripsi: json['deskripsi'],
      kordinat: json['kordinat'],
    );
  }
}

class SampahLiarData {
  final int id;
  final int? idUserPetugas; // Nullable
  final String idKecamatan; // Ensure this matches the API response
  final String noHp;
  final String kordinat;
  final String email;
  final String namaUpt;
  final String fotoSampah;
  final String deskripsi;
  final String status;
  final String? fotoPengangkutan; // Nullable
  final String createdAt;
  final String updatedAt;
  final String? petugas; // Nullable

  SampahLiarData({
    required this.id,
    this.idUserPetugas,
    required this.idKecamatan,
    required this.namaUpt,
    required this.noHp,
    required this.email,
    required this.kordinat,
    required this.fotoSampah,
    required this.deskripsi,
    required this.status,
    this.fotoPengangkutan,
    required this.createdAt,
    required this.updatedAt,
    this.petugas,
  });

  factory SampahLiarData.fromJson(Map<String, dynamic> json) {
    return SampahLiarData(
      id: json['id'] ?? 0,
      idUserPetugas: json['id_user_petugas'] != null
          ? int.tryParse(json['id_user_petugas'].toString())
          : null, // Parse if needed
      idKecamatan: json['id_kecamatan'] ?? '',
      noHp: json['no_hp'] ?? '',
      email: json['email'] ?? '',
      namaUpt: json['petugas'] != null ? json['petugas']['nama'] : '',
      kordinat: json['kordinat'] ?? '',
      fotoSampah: json['foto_sampah'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      status: json['status'] ?? '',
      fotoPengangkutan:
          json['foto_pengangkutan']?.toString(), // Handle nullable
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      petugas: json['petugas']?.toString(), // Handle nullable
    );
  }
}
