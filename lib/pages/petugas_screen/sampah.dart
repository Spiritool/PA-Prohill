// Updated SampahData model dengan rating langsung (tanpa class terpisah)
class SampahData {
  final int id;
  final String namaUpt;
  final String name;
  final String noHp;
  final String status;
  final String fotoSampah;
  final String list;
  final String namaHadiah;
  final int? hadiahId;
  final String deskripsi;
  final Alamat alamat;
  final DateTime tanggal;
  final int? ratingBintang; // Rating bintang (1-5)
  final String? ratingDeskripsi; // Deskripsi rating
  final int pendapatan;

  SampahData({
    required this.id,
    required this.namaUpt,
    required this.name,
    required this.noHp,
    required this.status,
    required this.fotoSampah,
    required this.list,
    required this.namaHadiah,
    this.hadiahId,
    required this.deskripsi,
    required this.alamat,
    required this.tanggal,
    this.ratingBintang,
    this.ratingDeskripsi,
    required this.pendapatan,
  });

  factory SampahData.fromJson(Map<String, dynamic> json) {
    // Ambil data dari poin_tukar array (jika ada)
    String namaHadiah = '';
    int? hadiahId;

    if (json['poin_tukar'] != null && json['poin_tukar'].isNotEmpty) {
      namaHadiah = json['poin_tukar'][0]['nama_hadiah'] ?? '';
      hadiahId = json['poin_tukar'][0]['id'];
    }

    // Parse rating langsung (jika ada)
    int? ratingBintang;
    String? ratingDeskripsi;

    if (json['rating'] != null) {
      ratingBintang = json['rating']['bintang'];
      ratingDeskripsi = json['rating']['deskripsi'];
    }

    return SampahData(
      id: json['id'],
      namaUpt: json['upt']['nama_upt'],
      name: json['warga']['nama'],
      noHp: json['warga']['no_hp'],
      status: json['status'],
      fotoSampah: json['foto_sampah'],
      namaHadiah: namaHadiah,
      hadiahId: hadiahId,
      list: json['list'] ?? '',
      deskripsi: json['deskripsi'],
      alamat: Alamat.fromJson(json['warga']['alamat'][0]),
      tanggal: DateTime.parse(json['created_at']),
      ratingBintang: ratingBintang,
      ratingDeskripsi: ratingDeskripsi,
      pendapatan: json['pendapatan'] ?? 0,
    );
  }
}

// Jika Anda ingin membuat model terpisah untuk PoinTukar
class PoinTukar {
  final int id;
  final int userId;
  final int hadiahId;
  final String createdAt;
  final String? updatedAt;
  final String status;
  final String namaHadiah;

  PoinTukar({
    required this.id,
    required this.userId,
    required this.hadiahId,
    required this.createdAt,
    this.updatedAt,
    required this.status,
    required this.namaHadiah,
  });

  factory PoinTukar.fromJson(Map<String, dynamic> json) {
    return PoinTukar(
      id: json['id'],
      userId: json['user_id'],
      hadiahId: json['hadiah_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      status: json['status'],
      namaHadiah: json['nama_hadiah'],
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
  final DateTime tanggal;
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
    required this.tanggal,
    this.petugas,
  });

  factory SampahLiarData.fromJson(Map<String, dynamic> json) {
    return SampahLiarData(
      id: json['id'] ?? 0,
      idUserPetugas: json['id_user_petugas'] != null
          ? int.tryParse(json['id_user_petugas'].toString())
          : null, // Parse if needed
      idKecamatan: json['id_kecamatan'] != null
          ? json['id_kecamatan'].toString() // Ubah int menjadi String
          : '', // Default ke string kosong jika null
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
      tanggal: DateTime.parse(json['created_at']), // Parsing tanggal
    );
  }
}
