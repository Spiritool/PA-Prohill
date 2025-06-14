import 'package:dlh_project/pages/warga_screen/historySampah.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

// Fungsi untuk mengambil data user points
Future<int> fetchUserPoints() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      print('WARNING: user_id tidak ditemukan di SharedPreferences');
      return 0;
    }

    print('Mengambil poin dari API untuk user ID: $userId');

    final response = await http.get(
      Uri.parse('$baseipapi/api/user/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('=== FETCH USER POINTS FROM API ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('=== END FETCH USER POINTS FROM API ===');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      // Sesuaikan dengan struktur response API Anda
      int poin = 0;
      if (responseData is Map) {
        // Jika response berbentuk {"data": {"poin": 100}} atau {"poin": 100}
        if (responseData.containsKey('data') && responseData['data'] is Map) {
          poin = responseData['data']['poin'] ?? 0;
        } else if (responseData.containsKey('poin')) {
          poin = responseData['poin'] ?? 0;
        }
        // Bisa juga struktur lain seperti {"user": {"poin": 100}}
        else if (responseData.containsKey('user') &&
            responseData['user'] is Map) {
          poin = responseData['user']['poin'] ?? 0;
        }
      }

      print('Poin dari API: $poin');

      // Update SharedPreferences dengan poin terbaru dari API
      await prefs.setInt('poin', poin);

      return poin;
    } else {
      print(
          'ERROR: Failed to load user points - Status: ${response.statusCode}');
      // Fallback ke SharedPreferences jika API gagal
      return prefs.getInt('poin') ?? 0;
    }
  } catch (e) {
    print('ERROR saat fetch user points dari API: $e');
    // Fallback ke SharedPreferences jika terjadi error
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('poin') ?? 0;
  }
}

// Fungsi untuk fetch data rewards dari backend
Future<List<Map<String, dynamic>>> fetchRewards() async {
  try {
    final response = await http.get(
      Uri.parse('$baseipapi/api/hadiah'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('=== FETCH REWARDS RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('=== END FETCH REWARDS RESPONSE ===');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      // Jika response berupa array langsung
      if (responseData is List) {
        return List<Map<String, dynamic>>.from(responseData);
      }

      // Jika response berupa object dengan key 'data'
      if (responseData is Map && responseData.containsKey('data')) {
        return List<Map<String, dynamic>>.from(responseData['data']);
      }

      return [];
    } else {
      print('ERROR: Failed to load rewards - Status: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('ERROR saat fetch rewards: $e');
    return [];
  }
}

// Fungsi untuk tukar poin
Future<Map<String, dynamic>> tukarPoin({
  required int userId,
  required int poin_tukar,
  required String jenisReward,
  required String namaReward,
  required int hadiahId,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseipapi/api/tukar-poin'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'jumlah_poin': poin_tukar,
        'jenis_reward': jenisReward,
        'nama_reward': namaReward,
        'hadiah_id': hadiahId,
      }),
    );

    print('=== TUKAR POIN RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('=== END TUKAR POIN RESPONSE ===');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      // // Update poin di SharedPreferences jika berhasil
      // if (responseData['success'] == true) {
      //   final prefs = await SharedPreferences.getInstance();
      //   final currentPoin = prefs.getInt('poin') ?? 0;
      //   final newPoin = currentPoin - poin_tukar;
      //   await prefs.setInt('poin', newPoin);
      //   print('Poin berhasil diupdate: $currentPoin -> $newPoin');
      // }

      return responseData;
    } else {
      return {
        'success': false,
        'message': 'Gagal menukar poin. Status: ${response.statusCode}',
        'data': null
      };
    }
  } catch (e) {
    print('ERROR saat tukar poin: $e');
    return {'success': false, 'message': 'Terjadi kesalahan: $e', 'data': null};
  }
}

// Fungsi untuk mengambil riwayat penukaran
Future<List<Map<String, dynamic>>> fetchPenukaranHistory(int userId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseipapi/api/penukaran/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('=== FETCH PENUKARAN HISTORY ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('=== END FETCH PENUKARAN HISTORY ===');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        return List<Map<String, dynamic>>.from(responseData['data']);
      }
    }
    return [];
  } catch (e) {
    print('ERROR saat fetch penukaran history: $e');
    return [];
  }
}

Future<List<SampahData>> fetchSampahData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;

    if (userId == 0) {
      throw Exception('User ID not found in SharedPreferences');
    }

    print('Fetching data for user ID: $userId'); // Debug log

    final response = await http.get(
      Uri.parse('$baseipapi/api/pengangkutan-sampah/history/$userId/done'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('Response status: ${response.statusCode}'); // Debug log
    print('Response body: ${response.body}'); // Debug log

    if (response.statusCode == 200) {
      // Parse JSON response dengan error handling
      late Map<String, dynamic> jsonResponse;
      try {
        var decodedResponse = jsonDecode(response.body);

        // Pastikan response adalah Map
        if (decodedResponse is Map<String, dynamic>) {
          jsonResponse = decodedResponse;
        } else {
          throw Exception('Response is not a valid JSON object');
        }
      } catch (e) {
        print('JSON decode error: $e');
        throw Exception('Failed to parse JSON response: $e');
      }

      // Ekstrak data array
      List<dynamic> rawData = [];
      if (jsonResponse.containsKey('data')) {
        var dataField = jsonResponse['data'];
        if (dataField is List) {
          rawData = dataField;
        } else {
          throw Exception('Data field is not an array');
        }
      } else {
        throw Exception('Response does not contain data field');
      }

      print('Raw data length: ${rawData.length}'); // Debug log

      // Parse setiap item dengan error handling
      List<SampahData> sampahDataList = [];
      for (int i = 0; i < rawData.length; i++) {
        try {
          var item = rawData[i];

          // Pastikan item adalah Map
          if (item is! Map) {
            print('Item $i is not a Map, skipping');
            continue;
          }

          // Cast ke Map<String, dynamic> dengan aman
          Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);

          // Parse ke SampahData
          SampahData sampahData = SampahData.fromJson(itemMap);
          sampahDataList.add(sampahData);
        } catch (e) {
          print('Error parsing item $i: $e');
          print('Item data: ${rawData[i]}');
          // Skip item yang error dan lanjutkan
          continue;
        }
      }

      print('Successfully parsed ${sampahDataList.length} items'); // Debug log

      // Sort berdasarkan ID (terbaru di atas)
      sampahDataList.sort((a, b) => b.id.compareTo(a.id));

      return sampahDataList;
    } else if (response.statusCode == 404) {
      // Tidak ada data
      return <SampahData>[];
    } else {
      throw Exception(
          'Failed to load data. Status: ${response.statusCode}, Body: ${response.body}');
    }
  } catch (e) {
    print('Exception in fetchSampahData: $e');

    // Jika error karena network atau parsing, return list kosong atau rethrow
    if (e.toString().contains('SocketException') ||
        e.toString().contains('TimeoutException')) {
      throw Exception('Network error: Please check your internet connection');
    }

    rethrow;
  }
}

class PointScreen extends StatefulWidget {
  const PointScreen({super.key});

  @override
  _PointScreenState createState() => _PointScreenState();
}

class _PointScreenState extends State<PointScreen> {
  late Future<List<SampahData>> futureSampahData;
  late Future<int> futureUserPoints;
  late Future<List<Map<String, dynamic>>> futureRewards; // Tambahkan ini
  late Future<List<Map<String, dynamic>>>
      futurePenukaranHistory; // Tambahkan ini
  int prosesCount = 0;
  DateTime? startDate;
  DateTime? endDate;
  bool showSampahData = true;
  bool isMyPointActive = true;
  Set<int> expandedCards = {};
  int currentUserPoints = 0;
  int? currentUserId;
  int selectedTabIndex = 0;
  // Tambahkan variabel untuk toggle antara sampah history dan penukaran history
  bool showSampahHistory = true;

  // Fungsi untuk menghitung poin berdasarkan status sampah
  int calculatePoints(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return 5; // Status selesai mendapat 5 poin
      case 'pending':
      case 'proses':
      case 'failed':
        return 0; // Status pending, proses, atau failed mendapat 0 poin
      default:
        return 0; // Default 0 poin untuk status tidak dikenal
    }
  }

  @override
  void initState() {
    super.initState();
    print('=== INIT STATE PointScreen ===');

    // Log SharedPreferences saat initState
    _logSharedPreferences();
    _loadUserData();

    futureSampahData = fetchSampahData();
    futureUserPoints = fetchUserPoints();
    futureRewards = fetchRewards(); // Tambahkan ini

    // Inisialisasi future untuk history penukaran
    futurePenukaranHistory = _loadPenukaranHistory();
  }

  // Fungsi untuk load penukaran history
  Future<List<Map<String, dynamic>>> _loadPenukaranHistory() async {
    if (currentUserId != null) {
      return await fetchPenukaranHistory(currentUserId!);
    }
    return [];
  }

// Function untuk update status penukaran
  Future<void> _updateStatusPenukaran(String penukaranId) async {
    print('========== UPDATE STATUS PENUKARAN ==========');
    print('Penukaran ID: $penukaranId');
    print('Timestamp: ${DateTime.now()}');

    try {
      final String apiUrl = '$baseipapi/api/penukaran/$penukaranId/status';
      final Map<String, dynamic> requestBody = {
        'status': 'terkirim',
      };

      print('API URL: $apiUrl');
      print('Request Body: ${json.encode(requestBody)}');
      print('Headers: Content-Type: application/json');

      print('Mengirim request ke server...');
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          // Jika menggunakan authentication
        },
        body: json.encode(requestBody),
      );

      print('Response diterima:');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ UPDATE BERHASIL');
        print(
            'Status penukaran ID $penukaranId berhasil diubah menjadi "terkirim"');

        // Berhasil update status
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status berhasil diupdate menjadi terkirim'),
            backgroundColor: Colors.green,
          ),
        );

        print('Memanggil _refreshData() untuk refresh UI...');
        // Refresh data untuk menampilkan perubahan
        _refreshData();
      } else {
        print('❌ UPDATE GAGAL');
        print('Status code tidak 200: ${response.statusCode}');
        print('Error response body: ${response.body}');
        throw Exception(
            'Gagal mengupdate status - Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ EXCEPTION OCCURRED');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: ${e.toString()}');
      print('Stack trace: ${StackTrace.current}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    print('========== END UPDATE STATUS ==========\n');
  }

  // Function untuk konfirmasi update status
  void _showConfirmUpdateStatus(String penukaranId, String namaReward) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: Text(
            'Apakah Anda yakin ingin mengkonfirmasi bahwa reward "$namaReward" telah diterima?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateStatusPenukaran(penukaranId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Ya, Sudah Diterima'),
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk load data user
  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    setState(() {
      currentUserId = userId;
    });

    // Refresh poin dari API
    if (userId != null) {
      final latestPoints = await fetchUserPoints();
      setState(() {
        currentUserPoints = latestPoints;
      });

      // Refresh penukaran history
      setState(() {
        futurePenukaranHistory = fetchPenukaranHistory(userId);
      });
    }
  }

  // Fungsi untuk refresh data
  void _refreshData() async {
    setState(() {
      futureSampahData = fetchSampahData();
      futureUserPoints = fetchUserPoints(); // Ini akan ambil dari API
      if (currentUserId != null) {
        futurePenukaranHistory = fetchPenukaranHistory(currentUserId!);
      }
    });

    // Update currentUserPoints juga
    if (currentUserId != null) {
      final latestPoints = await fetchUserPoints();
      setState(() {
        currentUserPoints = latestPoints;
      });
    }
  }

  // Fungsi untuk log semua data di SharedPreferences
  void _logSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      print('=== SHARED PREFERENCES DEBUG ===');
      print('Semua keys yang tersimpan: $keys');

      for (String key in keys) {
        final value = prefs.get(key);
        print('$key: $value (type: ${value.runtimeType})');
      }

      // Khusus untuk user_id
      final userId = prefs.getInt('user_id');
      print('Spesifik user_id: $userId');

      // Cek juga kemungkinan key lain yang mirip
      final userIdString = prefs.getString('user_id');
      final id = prefs.getInt('id');
      final idString = prefs.getString('id');

      print('user_id (string): $userIdString');
      print('id (int): $id');
      print('id (string): $idString');
      print('=== END SHARED PREFERENCES DEBUG ===');
    } catch (e) {
      print('ERROR saat mengakses SharedPreferences: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchRewards() async {
    try {
      final response = await http.get(
        Uri.parse('$baseipapi/api/hadiah'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is List) {
          return List<Map<String, dynamic>>.from(responseData);
        }
        if (responseData is Map && responseData.containsKey('data')) {
          return List<Map<String, dynamic>>.from(responseData['data']);
        }
      }
      return [];
    } catch (e) {
      print('ERROR saat fetch rewards: $e');
      return [];
    }
  }

  Future<void> _openMap(String mapUrl) async {
    final Uri mapUri = Uri.parse(mapUrl);
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri);
    } else {
      throw 'Could not launch $mapUrl';
    }
  }

  void _showRedeemDialog(Map<String, dynamic> item) {
    // Pastikan semua field ada nilai default
    final String title = item['nama_barang']?.toString() ?? 'Reward';
    final String description =
        item['deskripsi']?.toString() ?? 'Tidak ada deskripsi';
    final int pointTukar = item['poin_tukar'] ?? 0;
    final int itemId = item['id'] ?? 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Konfirmasi Penukaran',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Apakah Anda yakin ingin menukar poin untuk:'),
              const SizedBox(height: 8),
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Poin yang dibutuhkan: '),
                  Image.asset('assets/icons/money 4.png',
                      width: 16, height: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$pointTukar',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Poin Anda saat ini: '),
                  Image.asset('assets/icons/money 4.png',
                      width: 16, height: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$currentUserPoints',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (currentUserPoints < pointTukar)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Poin Anda tidak mencukupi!',
                    style: TextStyle(
                        color: Colors.red[600], fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: currentUserPoints >= pointTukar
                  ? () {
                      Navigator.of(context).pop();
                      _processRedeemPoin(item);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Tukar'),
            ),
          ],
        );
      },
    );
  }

// Perbaiki fungsi _processRedeemPoin
  void _processRedeemPoin(Map<String, dynamic> item) async {
    if (currentUserId == null) {
      _showSnackbar('Error: User ID tidak ditemukan', isError: true);
      return;
    }

    final String title = item['nama_barang']?.toString() ?? 'Reward';
    final int pointTukar = item['poin_tukar'] ?? 0;
    final int itemId = item['id'] ?? 0;

    // Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Memproses penukaran...'),
            ],
          ),
        );
      },
    );

    try {
      final result = await tukarPoin(
        userId: currentUserId!,
        poin_tukar: pointTukar,
        jenisReward: 'hadiah',
        namaReward: title,
        hadiahId: itemId,
      );

      // Tutup loading dialog
      Navigator.of(context).pop();

      if (result['success'] == true) {
        // Refresh poin dari API (bukan mengurangi manual)
        final latestPoints = await fetchUserPoints();

        setState(() {
          currentUserPoints = latestPoints;
          futureUserPoints = fetchUserPoints(); // Refresh future
          // Refresh history penukaran juga
          if (currentUserId != null) {
            futurePenukaranHistory = fetchPenukaranHistory(currentUserId!);
          }
        });

        _showSuccessDialog(item);
      } else {
        _showSnackbar(
          result['message'] ?? 'Gagal menukar poin',
          isError: true,
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showSnackbar('Terjadi kesalahan: $e', isError: true);
    }
  }

// Perbaiki fungsi _showSuccessDialog
  void _showSuccessDialog(Map<String, dynamic> item) {
    final String title = item['nama_barang']?.toString() ?? 'Reward';
    final int pointTukar = item['poin_tukar'] ?? 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 28),
              const SizedBox(width: 8),
              const Text(
                'Berhasil!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Penukaran poin berhasil!'),
              const SizedBox(height: 8),
              Text(
                'Anda telah menukar $pointTukar poin untuk:',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: const Text(
                  'Reward akan dikirim ke rumah anda. Periksa Jika Menampilakn History Penukaran',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Tampilkan snackbar
  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.chevron_left,
            color: Colors.black,
            size: 30,
          ),
        ),
        title: const Text(
          'Point',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isMyPointActive = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isMyPointActive
                              ? Colors.orange
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'My Point',
                          style: TextStyle(
                            color: isMyPointActive
                                ? Colors.white
                                : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isMyPointActive = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isMyPointActive
                              ? Colors.transparent
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Redeem',
                          style: TextStyle(
                            color: isMyPointActive
                                ? Colors.grey[600]
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              firstChild: SizedBox.expand(child: _buildMyPointSection()),
              secondChild: SizedBox.expand(child: _buildRedeemSection()),
              crossFadeState: isMyPointActive
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPointSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: const Color(0xFFF9F9F9),
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Image.asset('assets/icons/money 4.png'),
              ),
              const SizedBox(height: 10),
              Text('Total Point',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 4),
              // Display total points from user.point
              FutureBuilder<int>(
                future: futureUserPoints,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('...',
                        style: TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold));
                  } else if (snapshot.hasError) {
                    return Column(
                      children: [
                        const Text('0',
                            style: TextStyle(
                                fontSize: 32, fontWeight: FontWeight.bold)),
                        Text('Error: ${snapshot.error}',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.red)),
                      ],
                    );
                  } else if (!snapshot.hasData) {
                    return const Text('0',
                        style: TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold));
                  }

                  // Update currentUserPoints ketika data berhasil dimuat
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (currentUserPoints != snapshot.data!) {
                      setState(() {
                        currentUserPoints = snapshot.data!;
                      });
                    }
                  });

                  return Text(snapshot.data.toString(),
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold));
                },
              ),
            ],
          ),
        ),

        // Toggle button untuk history
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            children: [
              const Text(
                'My History',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          showSampahHistory = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: showSampahHistory
                              ? Colors.orange
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Sampah',
                          style: TextStyle(
                            color: showSampahHistory
                                ? Colors.white
                                : Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          showSampahHistory = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: !showSampahHistory
                              ? Colors.orange
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Penukaran',
                          style: TextStyle(
                            color: !showSampahHistory
                                ? Colors.white
                                : Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bagian bawah: putih, penuh sisa layar
        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Expanded(
                  child: showSampahHistory
                      ? _buildSampahHistoryList()
                      : _buildPenukaranHistoryList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget untuk menampilkan history sampah
  Widget _buildSampahHistoryList() {
    return FutureBuilder<List<SampahData>>(
      future: futureSampahData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _refreshData,
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Tidak ada data Riwayat.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

        // FILTER: Sembunyikan status 'pending', 'proses', dan 'failed'
        final filteredData = snapshot.data!
            .where((data) => !['pending', 'proses', 'failed']
                .contains(data.status.toLowerCase()))
            .toList();

        if (filteredData.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Belum ada riwayat sampah yang selesai.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: filteredData.length,
          itemBuilder: (context, index) {
            SampahData data = filteredData[index];
            Color statusColor = Colors.green;
            String formattedDate =
                DateFormat('dd-MM-yyyy').format(data.tanggal);

            final isExpanded = expandedCards.contains(index);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    expandedCards.remove(index);
                  } else {
                    expandedCards.add(index);
                  }
                });
              },
              child: _buildSampahCard(
                index: index + 1,
                name: data.nama,
                FotoSampah: data.fotoSampah,
                phone: data.noHp,
                status: data.status,
                namaUpt: data.namaUpt,
                location:
                    '${data.alamat.kelurahan}, ${data.alamat.kecamatan}, ${data.alamat.deskripsi}',
                description: data.deskripsi,
                mapUrl: data.alamat.kordinat,
                idSampah: data.id,
                statusColor: statusColor,
                tanggalFormatted: formattedDate,
                // ratingPetugas: data.ratingPetugas,
                catatanPetugas: data.catatanPetugas,
                isExpanded: isExpanded,
              ),
            );
          },
        );
      },
    );
  }

// Widget untuk menampilkan history penukaran
  Widget _buildPenukaranHistoryList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: futurePenukaranHistory,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Gagal memuat riwayat penukaran',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _refreshData,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        final penukaranList = snapshot.data ?? [];

        if (penukaranList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Belum ada riwayat penukaran',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tukar poin Anda dengan reward menarik!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        // Urutkan berdasarkan tanggal terbaru
        penukaranList.sort((a, b) {
          final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
              DateTime.now();
          final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
              DateTime.now();
          return dateB.compareTo(dateA);
        });

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: penukaranList.length,
          itemBuilder: (context, index) {
            final penukaran = penukaranList[index];
            return _buildPenukaranCard(penukaran, index);
          },
        );
      },
    );
  }

  // Widget untuk card penukaran
  Widget _buildPenukaranCard(Map<String, dynamic> penukaran, int index) {
    final String namaReward = penukaran['nama_hadiah']?.toString() ?? 'Reward';
    final int jumlahPoin = penukaran['poin_hadiah'] ?? 0;
    final String jenisReward = penukaran['nama_hadiah']?.toString() ?? 'hadiah';
    final String createdAt = penukaran['created_at']?.toString() ?? '';
    final String status = penukaran['status']?.toString() ?? 'pending';
    final String penukaranId = penukaran['id']?.toString() ?? '';

    // Format tanggal
    String formattedDate = '';
    if (createdAt.isNotEmpty) {
      try {
        final DateTime date = DateTime.parse(createdAt);
        formattedDate = DateFormat('dd-MM-yyyy').format(date);
      } catch (e) {
        formattedDate = createdAt;
      }
    }

    // Warna berdasarkan status
    Color statusColor;
    String statusText;
    bool canConfirmDelivery = false;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'selesai':
      case 'terkirim':
        statusColor = Colors.green;
        statusText = 'Terkirim';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case 'diantar':
        statusColor = Colors.blue;
        statusText = 'Diantar';
        canConfirmDelivery = true;
        break;
      case 'cancelled':
      case 'dibatalkan':
        statusColor = Colors.red;
        statusText = 'Dibatalkan';
        break;
      default:
        statusColor = Colors.blue;
        statusText = status;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Icon reward
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.card_giftcard,
                    color: Colors.orange[600],
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),

                // Info reward
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaReward,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Poin yang ditukar
            Row(
              children: [
                const Text(
                  'Poin ditukar: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Image.asset(
                  'assets/icons/money 4.png',
                  width: 16,
                  height: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '$jumlahPoin',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),

            // Jenis reward
            const SizedBox(height: 4),
            Text(
              'Jenis: ${jenisReward.toUpperCase()}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),

            // Pesan tambahan berdasarkan status
            if (status.toLowerCase() == 'completed' ||
                status.toLowerCase() == 'selesai' ||
                status.toLowerCase() == 'terkirim')
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Reward telah diterima',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (status.toLowerCase() == 'pending')
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.orange[600],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Penukaran sedang diproses',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (status.toLowerCase() == 'diantar')
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_shipping,
                          color: Colors.blue[600],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Reward sedang dalam perjalanan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canConfirmDelivery
                            ? () => _showConfirmUpdateStatus(
                                penukaranId, namaReward)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text(
                          'Konfirmasi Sudah Diterima',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Rename fungsi _buildOuterCard menjadi _buildSampahCard
  Widget _buildSampahCard({
    required int index,
    required String name,
    required String FotoSampah,
    required String phone,
    required String status,
    required String namaUpt,
    required String location,
    required String description,
    required String mapUrl,
    required int idSampah,
    required Color statusColor,
    required String tanggalFormatted,
    // required double? ratingPetugas,
    required String? catatanPetugas,
    required bool isExpanded,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: _buildInnerCard(
        name: name,
        phone: phone,
        fotoSampah: FotoSampah,
        status: status,
        namaUpt: namaUpt,
        location: location,
        description: description,
        mapUrl: mapUrl,
        idSampah: idSampah,
        statusColor: statusColor,
        tanggalFormatted: tanggalFormatted,
        // ratingPetugas: ratingPetugas,
        catatanPetugas: catatanPetugas,
        isExpanded: isExpanded,
      ),
    );
  }

  Widget _buildInnerCard({
    required String name,
    required String phone,
    required String fotoSampah,
    required String status,
    required String namaUpt,
    required String location,
    required String description,
    required String mapUrl,
    required int idSampah,
    required Color statusColor,
    required String tanggalFormatted,
    // required double? ratingPetugas,
    required String? catatanPetugas,
    required bool isExpanded,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris atas: Deskripsi + Point + Expand Icon
          Row(
            children: [
              // Kiri: informasi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⭐ Sampah Terpilah',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tanggalFormatted,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Coin dan expand icon
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/icons/money 4.png',
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          calculatePoints(status).toString(),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              )
            ],
          ),

          // Detail isi ketika expanded
          if (isExpanded) ...[
            const SizedBox(height: 16),
            Text('Nama      : $name'),
            Row(
              children: [
                const Text('Status     : '),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    status == 'failed' ? 'Dibatalkan' : status,
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
            Text('UPT         : $namaUpt'),
            Text('Alamat    : $location'),
            if (catatanPetugas != null) Text('Catatan   : $catatanPetugas'),
            const SizedBox(height: 12),
            if (fotoSampah.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  '$baseipapi/storage/foto-sampah/$fotoSampah',
                  errorBuilder: (context, error, stackTrace) =>
                      const Text('Gambar tidak dapat ditampilkan'),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              )
            else
              const Text('Tidak ada foto tersedia.'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => _openMap(mapUrl),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Lihat Lokasi'),
                ),
                // Column(
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     if (status == 'done' && ratingPetugas == null)
                //       ElevatedButton(
                //         onPressed: () {
                //           // Tampilkan dialog rating
                //         },
                //         child: const Text('Rating Petugas'),
                //       ),
                //     if (status == 'done' && ratingPetugas != null)
                //       Text('Rating: $ratingPetugas ⭐️'),
                //   ],
                // ),
              ],
            ),
          ],
        ],
      ),
    );
  }

// Perbaiki bagian GridView.builder dalam _buildRedeemSection
  Widget _buildRedeemSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: futureRewards,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Gagal memuat data rewards',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final rewards = snapshot.data ?? [];

        if (rewards.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.card_giftcard_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Belum ada rewards tersedia',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header dengan info poin user
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Poin Anda',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Image.asset(
                            'assets/icons/money 4.png',
                            width: 27,
                            height: 27,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$currentUserPoints',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.card_giftcard,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),

            // Grid redeem items dari backend
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    childAspectRatio: 1.5,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: rewards.length,
                  itemBuilder: (context, index) {
                    final reward = rewards[index];

                    // Pastikan semua field ada nilai default
                    final int pointTukar = reward['poin_tukar'] ?? 0;
                    final String namaBarang =
                        reward['nama_barang']?.toString() ?? 'Reward';
                    final String gambar = reward['gambar']?.toString() ?? '';
                    final String createdAt =
                        reward['created_at']?.toString() ?? '';
                    final bool canAfford = currentUserPoints >= pointTukar;

                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image section
                          Expanded(
                            flex: 3,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                  child: gambar.isNotEmpty
                                      ? Image.network(
                                          gambar,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return _buildImagePlaceholder();
                                          },
                                        )
                                      : _buildImagePlaceholder(),
                                ),
                                // Overlay jika tidak bisa afford
                                if (!canAfford)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Poin Tidak Cukup',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Content section
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  Text(
                                    namaBarang,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),

                                  // Created date
                                  if (createdAt.isNotEmpty)
                                    Text(
                                      'Tersedia sejak: ${_formatDate(createdAt)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                  const Spacer(),

                                  // Point dan button
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Point needed
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: canAfford
                                              ? Colors.green[50]
                                              : Colors.red[50],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: canAfford
                                                ? Colors.green[200]!
                                                : Colors.red[200]!,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Image.asset(
                                              'assets/icons/money 4.png',
                                              width: 16,
                                              height: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$pointTukar',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: canAfford
                                                    ? Colors.green[700]
                                                    : Colors.red[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Redeem button
                                      ElevatedButton(
                                        onPressed: canAfford
                                            ? () => _showRedeemDialog(reward)
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: canAfford
                                              ? Colors.orange
                                              : Colors.grey[300],
                                          foregroundColor: canAfford
                                              ? Colors.white
                                              : Colors.grey[600],
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          elevation: canAfford ? 2 : 0,
                                        ),
                                        child: Text(
                                          canAfford ? 'Tukar' : 'Locked',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Widget untuk placeholder gambar
  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey,
          size: 50,
        ),
      ),
    );
  }

  // Fungsi untuk format tanggal
  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
