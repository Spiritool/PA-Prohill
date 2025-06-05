import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SampahData {
  final int id;
  final id_user_petugas; // Properti untuk menyimpan status sebelumnya
  final String namaUpt;
  final String nama;
  final String noHp;
  String status; // Status bisa berubah
  final String fotoSampah;
  final String deskripsi;
  final Alamat alamat;
  final DateTime tanggal;
  final DateTime tanggalFormatted;
  final double? ratingPetugas;
  final String? catatanPetugas;

  String? previousStatus;

  SampahData({
    required this.id,
    required this.id_user_petugas,
    required this.namaUpt,
    required this.nama,
    required this.noHp,
    required this.status,
    required this.fotoSampah,
    required this.deskripsi,
    required this.alamat,
    required this.tanggal,
    required this.tanggalFormatted,
    required this.ratingPetugas,
    required this.catatanPetugas,
  });

  factory SampahData.fromJson(Map<String, dynamic> json) {
    var alamatJson = (json['warga']?['alamat'] as List?)?.first ?? {};

    return SampahData(
      id: json['id'] ?? 0,
      id_user_petugas: json['id_user_petugas'] ?? 0,
      namaUpt: json['upt']?['nama_upt'] ?? 'Unknown UPT',
      nama: json['warga']?['nama'] ?? 'Unknown',
      noHp: json['warga']?['no_hp'] ?? 'No Phone Number',
      status: json['status'] ?? 'Unknown Status',
      fotoSampah: json['foto_sampah'],
      deskripsi: json['deskripsi'] ?? 'No Description',
      alamat: Alamat.fromJson(alamatJson),
      tanggal: DateTime.parse(json['created_at']),
      tanggalFormatted: DateTime.parse(json['created_at']),
      ratingPetugas: json['rating_petugas'] != null
          ? double.tryParse(json['rating_petugas'].toString())
          : null,
      catatanPetugas: json['catatan_petugas'],
    );
  }

  // Memeriksa jika status berubah dan mengirimkan notifikasi
  void checkStatusChange() {
    if (previousStatus != status) {
      previousStatus = status;
      _sendStatusChangeNotification(status);
    }
  }

  // Mengirimkan notifikasi perubahan status menggunakan FCM
  void _sendStatusChangeNotification(String newStatus) async {
    String title = 'Status Laporan Sampah';
    String body = 'Status laporan sampah Anda telah berubah menjadi $newStatus';

    // Mengirimkan notifikasi FCM ke perangkat target
    await sendPushNotification(title, body);
  }

  // Fungsi untuk mengirim notifikasi FCM
  Future<void> sendPushNotification(String title, String body) async {
    final String serverKey = 'YOUR_SERVER_KEY'; // Ganti dengan server key Anda
    final String fcmUrl = 'https://fcm.googleapis.com/fcm/send';

    // Pastikan Anda sudah mendapatkan token FCM perangkat yang sesuai
    String? deviceToken = await FirebaseMessaging.instance.getToken();

    if (deviceToken != null) {
      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: json.encode({
          "to":
              deviceToken, // Kirimkan ke deviceToken perangkat yang diinginkan
          "notification": {
            "title": title,
            "body": body,
          },
          "priority": "high",
        }),
      );

      if (response.statusCode == 200) {
        print('Notification sent!');
      } else {
        print('Failed to send notification. Response: ${response.body}');
      }
    }
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
