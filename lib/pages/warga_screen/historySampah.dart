import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SampahData {
  final int id;
  final int id_user_petugas;
  final String namaUpt;
  final String nama;
  final String noHp;
  String status;
  final String fotoSampah;
  final String deskripsi;
  final Alamat alamat;
  final DateTime tanggal;
  final DateTime tanggalFormatted;
  final double? ratingPetugas;
  final String? catatanPetugas;
  final double? pendapatan;

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
    required this.pendapatan,
  });

  factory SampahData.fromJson(Map<String, dynamic> json) {
    try {
      // Safe parsing untuk nested objects
      Map<String, dynamic> wargaData = {};
      if (json['warga'] != null && json['warga'] is Map) {
        wargaData = Map<String, dynamic>.from(json['warga']);
      }

      Map<String, dynamic> uptData = {};
      if (json['upt'] != null && json['upt'] is Map) {
        uptData = Map<String, dynamic>.from(json['upt']);
      }

      // Safe parsing untuk alamat array
      Map<String, dynamic> alamatJson = {};
      if (wargaData['alamat'] != null) {
        if (wargaData['alamat'] is List &&
            (wargaData['alamat'] as List).isNotEmpty) {
          var alamatList = wargaData['alamat'] as List;
          if (alamatList.first is Map) {
            alamatJson = Map<String, dynamic>.from(alamatList.first);
          }
        } else if (wargaData['alamat'] is Map) {
          alamatJson = Map<String, dynamic>.from(wargaData['alamat']);
        }
      }

      // Parse datetime dengan error handling
      DateTime parsedDate = DateTime.now();
      try {
        if (json['created_at'] != null) {
          parsedDate = DateTime.parse(json['created_at'].toString());
        }
      } catch (e) {
        print('Error parsing date: $e');
      }

      return SampahData(
        id: _parseInt(json['id']),
        id_user_petugas: _parseInt(json['id_user_petugas']),
        namaUpt: uptData['nama_upt']?.toString() ?? 'Unknown UPT',
        nama: wargaData['nama']?.toString() ?? 'Unknown',
        noHp: wargaData['no_hp']?.toString() ?? 'No Phone Number',
        status: json['status']?.toString() ?? 'Unknown Status',
        fotoSampah: json['foto_sampah']?.toString() ?? '',
        deskripsi: json['deskripsi']?.toString() ?? 'No Description',
        alamat: Alamat.fromJson(alamatJson),
        tanggal: parsedDate,
        tanggalFormatted: parsedDate,
        ratingPetugas: _parseDouble(json['rating_petugas']),
        catatanPetugas: json['catatan_petugas']?.toString(),
        pendapatan: _parseDouble(json['pendapatan']) ?? 0.0,
      );
    } catch (e) {
      print('Error in SampahData.fromJson: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  // Helper functions untuk safe parsing
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
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
    try {
      final String serverKey =
          'YOUR_SERVER_KEY'; // Ganti dengan server key Anda
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
            "to": deviceToken,
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
    } catch (e) {
      print('Error sending push notification: $e');
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
    try {
      // Pastikan json tidak null dan cast dengan aman
      Map<String, dynamic> safeJson = {};
      if (json.isNotEmpty) {
        safeJson = Map<String, dynamic>.from(json);
      }

      return Alamat(
        id: SampahData._parseInt(safeJson['id']),
        deskripsi: safeJson['deskripsi']?.toString() ?? 'Tidak ada Deskripsi',
        kecamatan: safeJson['kecamatan']?.toString() ?? 'Tidak ada Kecamatan',
        kelurahan: safeJson['kelurahan']?.toString() ?? 'Tidak ada Kelurahan',
        kordinat: safeJson['kordinat']?.toString() ?? 'Tidak ada Kordinat',
      );
    } catch (e) {
      print('Error in Alamat.fromJson: $e');
      print('JSON data: $json');

      // Return default Alamat jika error
      return Alamat(
        id: 0,
        deskripsi: 'Tidak ada Deskripsi',
        kecamatan: 'Tidak ada Kecamatan',
        kelurahan: 'Tidak ada Kelurahan',
        kordinat: 'Tidak ada Kordinat',
      );
    }
  }
}
