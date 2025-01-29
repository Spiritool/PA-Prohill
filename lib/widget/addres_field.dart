import 'dart:convert';
import 'package:http/http.dart' as http;

class AlamatService {
  final String baseUrl =
      "https://jera.kerissumenep.com/api/alamat/get-by-user/";

  Future<List<dynamic>> fetchAlamatByUser(int userId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl$userId"));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          return jsonData['data']; // Mengembalikan list alamat
        } else {
          throw Exception(jsonData['message']);
        }
      } else {
        throw Exception(
            "Gagal mengambil data. Kode status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }
}
