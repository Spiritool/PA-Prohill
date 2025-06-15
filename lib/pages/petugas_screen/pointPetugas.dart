import 'package:dlh_project/pages/petugas_screen/Sampah.dart';
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
      Uri.parse(
          '$baseipapi/api/pengangkutan-sampah/history/by-petugas/$userId/done'),
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

class PointScreenPetugas extends StatefulWidget {
  const PointScreenPetugas({super.key});

  @override
  _PointScreenPetugasState createState() => _PointScreenPetugasState();
}

class _PointScreenPetugasState extends State<PointScreenPetugas> {
  late Future<List<SampahData>> futureSampahData;
  late Future<int> futureUserPoints;
  late Future<List<Map<String, dynamic>>> futureRewards;
  late Future<List<Map<String, dynamic>>> futurePenukaranHistory;
  int prosesCount = 0;
  DateTime? startDate;
  DateTime? endDate;
  bool showSampahData = true;
  bool isMyPointActive = true;
  Set<int> expandedCards = {};
  int currentUserPoints = 0;
  int? currentUserId;
  int selectedTabIndex = 0;
  bool showSampahHistory = true;


  // Fungsi untuk menghitung poin berdasarkan status sampah
  int calculatePoints(SampahData data) {
    if (data.status.toLowerCase() == 'done' && data.ratingBintang != null) {
      return data.ratingBintang! * 3; // Rating dikali 3
    }
    return 0;
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

   Widget _buildRatingDisplay(int? ratingBintang, String? ratingDeskripsi) {
    if (ratingBintang == null) {
      return Row(
        children: [
          Icon(Icons.star_border, size: 16, color: Colors.grey),
          SizedBox(width: 4),
          Text('Belum ada rating', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Tampilkan bintang
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < ratingBintang ? Icons.star : Icons.star_border,
                  size: 16,
                  color: index < ratingBintang ? Colors.amber : Colors.grey,
                );
              }),
            ),
            SizedBox(width: 8),
            Text(
              '$ratingBintang/5',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.amber[700],
              ),
            ),
          ],
        ),
        if (ratingDeskripsi != null && ratingDeskripsi.isNotEmpty) ...[
          SizedBox(height: 4),
          Text(
            '"$ratingDeskripsi"',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  _buildPointDisplay(SampahData data) {
    final points = calculatePoints(data);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: points > 0 ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: points > 0 ? Colors.green[300]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/icons/money 4.png',
            width: 16,
            height: 16,
            color: points > 0 ? Colors.green[600] : Colors.grey[500],
          ),
          SizedBox(width: 4),
          Text(
            '$points',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: points > 0 ? Colors.green[700] : Colors.grey[600],
            ),
          ),
          if (data.ratingBintang != null) ...[
            SizedBox(width: 4),
            Text(
              '(${data.ratingBintang}★×3)',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
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
                  child:  _buildSampahHistoryList(),
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
                name: data.name,
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
                ratingBintang: data.ratingBintang,
                ratingDeskripsi: data.ratingDeskripsi,
                isExpanded: isExpanded,
              ),
            );
          },
        );
      },
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
  required int? ratingBintang,
  required String? ratingDeskripsi,
  required bool isExpanded,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Column(
      children: [
        // Header Card
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris pertama: Nama dan Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Informasi dasar
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    phone,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    tanggalFormatted,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // RATING DISPLAY - Tampilkan rating bintang dan deskripsi
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber[600]),
                        const SizedBox(width: 4),
                        const Text(
                          'Rating Layanan:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        _buildPointDisplay(SampahData(
                          id: idSampah,
                          name: name,
                          noHp: phone,
                          deskripsi: description,
                          status: status,
                          namaUpt: namaUpt,
                          tanggal: DateTime.now(), // Placeholder
                          alamat: Alamat( // Placeholder
                            kelurahan: '',
                            kecamatan: '',
                            deskripsi: '',
                            kordinat: '',
                          ),
                          list: '',
                          namaHadiah: '',
                          pendapatan: 0,

                          fotoSampah: FotoSampah,
                          ratingBintang: ratingBintang,
                          ratingDeskripsi: ratingDeskripsi,
                        )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildRatingDisplay(ratingBintang, ratingDeskripsi),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Indikator expand/collapse
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.blue[600],
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
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
                    final String fotoSampah = reward['fotoSampah']?.toString() ?? '';
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
                                  child: fotoSampah.isNotEmpty
                                      ? Image.network(
                                          fotoSampah,
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

  // Widget untuk placeholder fotoSampah
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
