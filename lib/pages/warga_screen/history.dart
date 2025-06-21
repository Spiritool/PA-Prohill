import 'package:dlh_project/pages/warga_screen/historySampah.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async'; // untuk TimeoutException
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

// Updated fetchSampahData function with corrected rating integration
Future<List<SampahData>> fetchSampahData() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id') ?? 0;

  print('=== DEBUG LOG fetchSampahData ===');
  print('User ID untuk sampah data: $userId');

  if (userId == 0) {
    print(
        'ERROR: User ID tidak ditemukan di SharedPreferences untuk sampah data');
    throw Exception('User ID not found in SharedPreferences');
  }

  // First, fetch all rating data once
  final ratingMap = await _fetchAllRatingData(userId);
  print('Total rating data loaded: ${ratingMap.length}');

  final urls = [
    '$baseipapi/api/pengangkutan-sampah/history/by-petugas/$userId/proses',
    '$baseipapi/api/pengangkutan-sampah/history/by-petugas/$userId/done',
    '$baseipapi/api/pengangkutan-sampah/history/by-petugas/$userId/pending',
    '$baseipapi/api/pengangkutan-sampah/history/by-petugas/$userId/failed',
  ];

  print('URLs yang akan diakses:');
  urls.forEach((url) => print('- $url'));

  List<SampahData> allData = [];

  for (String url in urls) {
    try {
      print('Mengakses URL: $url');
      final response = await http.get(Uri.parse(url));
      print('Status Code untuk $url: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);

        if (decodedResponse is Map<String, dynamic> &&
            decodedResponse.containsKey('data')) {
          final dataList = decodedResponse['data'];

          if (dataList is List) {
            print('Data diterima dari $url: ${dataList.length} items');

            for (var item in dataList) {
              if (item is Map) {
                final Map<String, dynamic> itemMap =
                    Map<String, dynamic>.from(item);

                // Match rating data for completed tasks
                if (itemMap['status']?.toString().toLowerCase() == 'done') {
                  final sampahId = itemMap['id'];

                  // Try multiple possible keys for rating lookup
                  final possibleKeys = [
                    sampahId.toString(), // Direct sampah ID
                    '${sampahId}_$userId', // sampah_petugas combination
                    '${sampahId}_${itemMap['idpetugas']}', // sampah_actual_petugas
                  ];

                  bool ratingFound = false;

                  for (String key in possibleKeys) {
                    print('Trying rating key: $key');

                    if (ratingMap.containsKey(key)) {
                      final ratingData = ratingMap[key]!;
                      itemMap['rating_petugas'] =
                          ratingData['bintang']?.toDouble();
                      itemMap['catatan_petugas'] = ratingData['deskripsi'];
                      print(
                          '✅ Rating matched for sampah $sampahId with key $key: ${ratingData['bintang']} stars');
                      ratingFound = true;
                      break;
                    }
                  }

                  if (!ratingFound) {
                    print(
                        '❌ No rating found for sampah $sampahId with any key');
                    print('Available rating keys: ${ratingMap.keys.toList()}');
                    itemMap['rating_petugas'] = null;
                    itemMap['catatan_petugas'] = null;
                  }
                } else {
                  // For non-completed tasks, set rating to null
                  itemMap['rating_petugas'] = null;
                  itemMap['catatan_petugas'] = null;
                }

                allData.add(SampahData.fromJson(itemMap));
              }
            }
          } else {
            print('WARNING: Data from $url is not a List');
          }
        } else {
          print('WARNING: Invalid response structure from $url');
        }
      } else {
        print(
            'ERROR: Failed to load data from $url - Status: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load data from $url');
      }
    } catch (e) {
      print('EXCEPTION saat mengakses $url: $e');
      rethrow;
    }
  }

  // Sort by ID descending (newest first)
  allData.sort((a, b) => b.id.compareTo(a.id));
  print('Total data sampah yang berhasil diambil: ${allData.length}');

  // Debug: Print rating status for each item
  for (var item in allData) {
    if (item.status?.toLowerCase() == 'done') {
      print(
          'Sampah ID: ${item.id}, Status: ${item.status}, Rating: ${item.ratingPetugas}, Has Rating: ${hasRating(item.ratingPetugas)}');
    }
  }

  print('=== END DEBUG LOG fetchSampahData ===');

  return allData;
}

// Updated method to fetch all rating data with multiple key strategies
Future<Map<String, Map<String, dynamic>>> _fetchAllRatingData(
    int userId) async {
  Map<String, Map<String, dynamic>> ratingMap = {};

  try {
    final ratingUrl = '$baseipapi/api/rating/get-by-user/$userId';
    print('Fetching all rating data from: $ratingUrl');

    final response = await http.get(Uri.parse(ratingUrl));
    print('Rating API Status Code: ${response.statusCode}');
    print('Rating API Response: ${response.body}');

    if (response.statusCode == 200) {
      final ratingResponse = jsonDecode(response.body);

      if (ratingResponse is Map<String, dynamic> &&
          ratingResponse.containsKey('data')) {
        final ratingList = ratingResponse['data'];

        if (ratingList is List) {
          print('Found ${ratingList.length} rating records');

          for (var rating in ratingList) {
            if (rating is Map<String, dynamic>) {
              final idlaporan = rating['idlaporan'];
              final idpetugas = rating['idpetugas'];
              final bintang = rating['bintang'];
              final deskripsi = rating['deskripsi'];

              // Create multiple possible keys for better matching
              final keys = [
                idlaporan.toString(), // Direct laporan ID
                '${idlaporan}_$idpetugas', // laporan_petugas combination
                '${idlaporan}_$userId', // laporan_current_user combination
              ];

              final ratingData = {
                'bintang': bintang,
                'deskripsi': deskripsi,
                'idlaporan': idlaporan,
                'idpetugas': idpetugas,
              };

              // Store rating with multiple keys for better matching
              for (String key in keys) {
                ratingMap[key] = ratingData;
                print(
                    'Rating mapped - Key: $key, Bintang: $bintang, Deskripsi: $deskripsi');
              }
            }
          }
        } else {
          print('Rating data is not a List: ${ratingList.runtimeType}');
        }
      } else {
        print('Invalid rating response structure');
        print('Response keys: ${ratingResponse.keys.toList()}');
      }
    } else {
      print('Failed to fetch rating data: ${response.statusCode}');
      print('Error response: ${response.body}');
    }
  } catch (e, stackTrace) {
    print('Error fetching rating data: $e');
    print('Stack trace: $stackTrace');
  }

  return ratingMap;
}

// Top-level helper function to check if a rating exists
bool hasRating(double? ratingPetugas) {
  final hasRating = ratingPetugas != null && ratingPetugas > 0;
  print('Checking rating: $ratingPetugas, has rating: $hasRating');
  return hasRating;
}

class History extends StatefulWidget {
  const History({super.key});

  @override
  _HistoryState createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  late Future<List<SampahData>> futureSampahData;
  int prosesCount = 0;
  int doneCount = 0;
  int pendingCount = 0;
  int failedCount = 0;
  String selectedDateRange = "all";
  String selectedStatus = "all";
  DateTime? startDate;
  DateTime? endDate;
  bool showSampahData = true;
  int? selectedMonthIndex;
  int selectedYear = DateTime.now().year;
  double? ratingPetugas;
  String? catatanPetugas;

  // Fungsi untuk parsing list sampah dari string API
  List<Map<String, dynamic>> parseSampahList(String? listString) {
    if (listString == null || listString.isEmpty) return [];

    List<Map<String, dynamic>> sampahItems = [];

    // Split berdasarkan koma untuk memisahkan item
    List<String> items = listString.split(',');

    for (String item in items) {
      String trimmedItem = item.trim();

      // Split berdasarkan ':' untuk memisahkan nama dan berat
      List<String> parts = trimmedItem.split(':');
      if (parts.length == 2) {
        String nama = parts[0].trim();
        String beratStr = parts[1].trim();

        // Extract angka dari string berat (misal: "20.0kg" -> 20.0)
        RegExp regExp = RegExp(r'(\d+\.?\d*)');
        Match? match = regExp.firstMatch(beratStr);
        double berat = 0.0;
        if (match != null) {
          berat = double.tryParse(match.group(1) ?? '0') ?? 0.0;
        }

        sampahItems.add({'nama': nama, 'berat': berat, 'satuan': 'kg'});
      }
    }

    return sampahItems;
  }

  // Fungsi untuk menghitung total berat dari list sampah
  double getTotalBerat(String? listString) {
    List<Map<String, dynamic>> items = parseSampahList(listString);
    return items.fold(0.0, (sum, item) => sum + (item['berat'] as double));
  }

  // Fungsi untuk menghitung poin berdasarkan status sampah
  int calculatePoints(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return 5;
      case 'pending':
      case 'proses':
      case 'failed':
        return 0;
      default:
        return 0;
    }
  }

  // Fungsi untuk mendapatkan poin dari data yang sudah difilter
  int getFilteredPoints(List<SampahData> filteredDataList) {
    return filteredDataList
        .map((data) => calculatePoints(data.status))
        .reduce((a, b) => a + b);
  }

  List<String> monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des'
  ];

  Color _getColorByStatus(String status) {
    switch (status) {
      case 'done':
        return Colors.green;
      case 'proses':
        return Colors.yellow.shade700;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color _getBarColor() {
    switch (selectedStatus) {
      case 'done':
        return Colors.green;
      case 'proses':
        return Colors.yellow.shade700;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Set<int> expandedCards = {};
  List<SampahData> filteredDataByStatusAndDate = [];
  @override
  void initState() {
    super.initState();
    futureSampahData = fetchSampahData();
    futureSampahData.then((data) {
      _calculateStatusCounts(data);
      // Dapatkan bulan dan tahun sekarang
      final now = DateTime.now();
      selectedMonthIndex = now.month - 1;
      selectedYear = now.year;
      startDate = DateTime(selectedYear, now.month, 1);
      endDate = DateTime(selectedYear, now.month + 1, 0);
      selectedDateRange = 'monthly'; // set sebagai bulanan
      _applyFilters(data); // panggil juga langsung setelah fetch
      // // 🔥 Tambahkan baris ini:
      // checkAndAutoRate(data);
    });
  }

// Updated refresh method with better error handling
  Future<void> _refreshData() async {
    try {
      setState(() {
        futureSampahData = fetchSampahData();
      });

      // Small delay to show loading indicator
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      print('Error refreshing data: $e');
      _showErrorSnackBar('Gagal memuat ulang data');
    }
  }

  // Function untuk load data (sesuaikan dengan implementasi Anda)
  Future<List<SampahData>> _loadSampahData() async {
    // Implementasi sesuai dengan cara Anda mengambil data
    // Contoh:
    // return await ApiService.getSampahData();

    // Untuk sementara return empty list
    return [];
  }

// Updated _submitRating method with longer delay for data refresh
  Future<void> _submitRating(
      int idlaporan, int idpetugas, int? bintang, String? deskripsi) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6600).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFFF6600)),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Mengirim rating...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mohon tunggu sebentar',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final idwarga = prefs.getInt('user_id') ?? 0;

      print('=== SUBMIT RATING DEBUG ===');
      print('User ID: $idwarga');
      print('Id petugas: $idpetugas');
      print('Id laporan: $idlaporan');
      print('bintang: $bintang');
      print('deskripsi: ${deskripsi ?? "kosong"}');

      if (idwarga == 0) {
        Navigator.of(context).pop();
        _showErrorSnackBar('User ID tidak ditemukan');
        return;
      }

      final url = '$baseipapi/api/rating/store';
      final requestBody = {
        'idwarga': idwarga,
        "idpetugas": idpetugas,
        'idlaporan': idlaporan,
        'bintang': bintang,
        'deskripsi': deskripsi ?? "",
      };

      print('URL API: $url');
      print('Request Body: ${jsonEncode(requestBody)}');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw TimeoutException('Request timeout - silakan coba lagi'),
          );

      // Close loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Rating berhasil dikirim ke API');

        // Show success message immediately
        _showSuccessSnackBar('Rating berhasil dikirim!');

        // Longer delay to ensure API has processed the rating
        await Future.delayed(const Duration(seconds: 2));

        // Force refresh data multiple times to ensure rating is loaded
        setState(() {
          futureSampahData = fetchSampahData();
          expandedCards.clear();
        });

        // Additional refresh after another delay
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          futureSampahData = fetchSampahData();
        });
      } else {
        String errorMessage = 'Gagal mengirim rating';
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['message'] != null) {
            errorMessage = responseData['message'];
          }
        } catch (_) {}

        _showErrorSnackBar('$errorMessage (${response.statusCode})');
      }
    } catch (e, stackTrace) {
      print('❌ Exception: $e');
      print('Stack trace: $stackTrace');

      // Make sure loading dialog is closed
      try {
        Navigator.of(context).pop();
      } catch (_) {}

      String userErrorMessage = 'Terjadi kesalahan saat mengirim rating';
      if (e is TimeoutException || e.toString().contains('timeout')) {
        userErrorMessage = 'Koneksi timeout - silakan coba lagi';
      } else if (e.toString().contains('SocketException')) {
        userErrorMessage = 'Tidak ada koneksi internet';
      }

      _showErrorSnackBarWithRetry(userErrorMessage, () {
        _showRatingDialog(idlaporan, idpetugas);
      });
    }

    print('=== END SUBMIT RATING DEBUG ===\n');
  }

// Alternative method to directly fetch rating for specific sampah (use this as backup)
  Future<Map<String, dynamic>?> _fetchSpecificRating(
      int idlaporan, int idpetugas) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;

      final url = '$baseipapi/api/rating/get-by-user/$userId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['data'] is List) {
          final ratings = responseData['data'] as List;

          // Find rating that matches both idlaporan and idpetugas
          for (var rating in ratings) {
            if (rating['idlaporan'] == idlaporan &&
                rating['idpetugas'] == idpetugas) {
              return {
                'bintang': rating['bintang'],
                'deskripsi': rating['deskripsi'],
              };
            }
          }

          // If not found with exact match, try with just idlaporan
          for (var rating in ratings) {
            if (rating['idlaporan'] == idlaporan) {
              return {
                'bintang': rating['bintang'],
                'deskripsi': rating['deskripsi'],
              };
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching specific rating: $e');
    }

    return null;
  }

// Helper method to show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

// Helper method to show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

// Helper method to show error snackbar with retry option
  void _showErrorSnackBarWithRetry(String message, VoidCallback onRetry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Coba Lagi',
          textColor: Colors.white,
          backgroundColor: Colors.white.withOpacity(0.2),
          onPressed: onRetry,
        ),
      ),
    );
  }

  void _showRatingDialog(int idlaporan, int idpetugas) {
    double selectedRating = 3.0;
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              elevation: 16,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      const Color(0xFFFF6600).withOpacity(0.02),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFF6600),
                              const Color(0xFFFF6600).withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6600).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    const Center(
                      child: Text(
                        'Beri Rating Petugas',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Center(
                      child: Text(
                        'Seberapa puas Anda dengan layanan petugas?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Rating Stars
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6600).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFF6600).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: RatingBar.builder(
                          initialRating: 3,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: false,
                          itemCount: 5,
                          itemSize: 36,
                          itemPadding:
                              const EdgeInsets.symmetric(horizontal: 4.0),
                          itemBuilder: (context, _) => const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFF6600),
                          ),
                          unratedColor: Colors.grey[300],
                          onRatingUpdate: (rating) {
                            selectedRating = rating;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Comment Section
                    const Text(
                      'Komentar (opsional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: commentController,
                        maxLines: 3,
                        enabled: !isSubmitting,
                        decoration: InputDecoration(
                          hintText: 'Tuliskan komentar Anda...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFFF6600), width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isSubmitting
                                ? null
                                : () {
                                    Navigator.of(dialogContext).pop();
                                  },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Batal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    setState(() {
                                      isSubmitting = true;
                                    });

                                    try {
                                      Navigator.of(dialogContext).pop();
                                      await _submitRating(
                                          idlaporan,
                                          idpetugas,
                                          selectedRating.round(),
                                          commentController.text.trim());
                                    } catch (e) {
                                      print('Error in dialog submit: $e');
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.error_outline,
                                                  color: Colors.white),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                  child: Text(
                                                      'Terjadi kesalahan: $e')),
                                            ],
                                          ),
                                          backgroundColor: Colors.red[600],
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                        ),
                                      );
                                    } finally {
                                      isSubmitting = false;
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6600),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor:
                                  const Color(0xFFFF6600).withOpacity(0.4),
                            ),
                            child: isSubmitting
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Mengirim...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send_rounded, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Kirim Rating',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// Method to check if rating exists (unchanged but with better logging)
  bool _hasRating(double? ratingPetugas) {
    final hasRating = ratingPetugas != null && ratingPetugas > 0;
    print('Checking rating: $ratingPetugas, has rating: $hasRating');
    return hasRating;
  }

  void _calculateStatusCounts(List<SampahData> data) {
    setState(() {
      prosesCount =
          data.where((s) => s.status.toLowerCase() == 'proses').length;
      doneCount = data.where((s) => s.status.toLowerCase() == 'done').length;
      pendingCount =
          data.where((s) => s.status.toLowerCase() == 'pending').length;
      failedCount =
          data.where((s) => s.status.toLowerCase() == 'failed').length;
    });
  }

  void _applyFilters(List<SampahData> data) {
    setState(() {
      filteredDataByStatusAndDate = data.where((item) {
        final itemDate = item.tanggalFormatted;
        final matchesStatus = selectedStatus == 'all' ||
            item.status.toLowerCase() == selectedStatus;
        final matchesDate = (startDate == null ||
                itemDate
                    .isAfter(startDate!.subtract(const Duration(days: 1)))) &&
            (endDate == null ||
                itemDate.isBefore(endDate!.add(const Duration(days: 1))));
        return matchesStatus && matchesDate;
      }).toList();
    });
  }

  void _filterByStatus(String status) {
    setState(() {
      selectedStatus = status;
    });
    futureSampahData.then((data) {
      _applyFilters(data);
    });
  }

  void _filterByDateRange(String rangeType) {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end;

    if (rangeType == 'weekly') {
      start = now.subtract(Duration(days: now.weekday - 1)); // Senin minggu ini
      end = start.add(const Duration(days: 6)); // Minggu minggu ini
    } else if (rangeType == 'monthly') {
      start = DateTime(now.year, now.month, 1); // Awal bulan
      end = DateTime(now.year, now.month + 1, 0); // Akhir bulan
    } else {
      start = null;
      end = null;
    }

    setState(() {
      selectedDateRange = rangeType;
      startDate = start;
      endDate = end;
    });

    futureSampahData.then((data) {
      _applyFilters(data);
    });
  }

  void _filterByMonth(int month, int year) {
    setState(() {
      selectedDateRange = 'monthly';
      selectedMonthIndex = month - 1;
      selectedYear = year;
      startDate = DateTime(year, month, 1);
      endDate = DateTime(year, month + 1, 0);
    });

    futureSampahData.then((data) {
      _applyFilters(data);
    });
  }

  Widget _buildMonthTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(12, (index) {
          final isSelected = selectedMonthIndex == index;
          final monthName = monthNames[index];

          return GestureDetector(
            onTap: () => _filterByMonth(index + 1, selectedYear),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
              child: Column(
                children: [
                  Text(
                    monthName,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.black : Colors.grey,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      height: 2,
                      width: 20,
                      color: _getBarColor(),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildChartLegend() {
    final legends = [
      {'label': 'Done', 'color': Colors.green},
      {'label': 'Proses', 'color': Colors.yellow.shade700},
      {'label': 'Pending', 'color': Colors.orange},
      {'label': 'Failed', 'color': Colors.red},
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: legends.map((legend) {
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: legend['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    legend['label'] as String,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, int count, Color color) {
    return GestureDetector(
      onTap: () => _filterByStatus(title.toLowerCase()),
      child: Card(
        color: selectedStatus == title.toLowerCase() ? Colors.black : color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 5),
              Text(
                count.toString(),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChart() {
    // Map dengan key tanggal -> status -> jumlah
    Map<String, Map<String, int>> groupedData = {};

    for (var item in filteredDataByStatusAndDate) {
      final dateStr = DateFormat('dd-MM-yyyy').format(item.tanggalFormatted);
      final status = item.status.toLowerCase();

      groupedData[dateStr] ??= {};
      groupedData[dateStr]![status] = (groupedData[dateStr]![status] ?? 0) + 1;
    }

    final sortedDates = groupedData.keys.toList()
      ..sort((a, b) {
        return DateFormat('dd-MM-yyyy').parse(a).compareTo(
              DateFormat('dd-MM-yyyy').parse(b),
            );
      });

    final statusOrder = ['done', 'proses', 'pending', 'failed'];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: groupedData.values.expand((m) => m.values).fold<double>(
                    0, (prev, val) => val > prev ? val.toDouble() : prev) +
                1,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    rod.toY.toInt().toString(),
                    const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
            barGroups: List.generate(sortedDates.length, (i) {
              final date = sortedDates[i];
              final statusMap = groupedData[date]!;

              List<BarChartRodData> rods = [];
              for (int j = 0; j < statusOrder.length; j++) {
                final status = statusOrder[j];
                final count = statusMap[status] ?? 0;
                rods.add(
                  BarChartRodData(
                    toY: count.toDouble(),
                    color: _getColorByStatus(status),
                    width: 8,
                    borderRadius: BorderRadius.circular(0),
                  ),
                );
              }

              return BarChartGroupData(
                x: i,
                barsSpace: 4,
                barRods: rods,
                // HAPUS showingTooltipIndicators supaya angka ga muncul otomatis
              );
            }),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() < sortedDates.length) {
                      return Text(
                        sortedDates[value.toInt()].substring(0, 5),
                        style: const TextStyle(fontSize: 10),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) =>
                      Text(value.toInt().toString()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYearToggle() {
    int currentYear = DateTime.now().year;
    List<int> years = List.generate(3, (index) => currentYear - index);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: years.map((year) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: _buildYearButton(year),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildYearButton(int year) {
    bool isSelected = selectedYear == year;

    return OutlinedButton(
      onPressed: () {
        setState(() {
          selectedYear = year;
          selectedMonthIndex = 11; // Set ke Desember langsung
          startDate = DateTime(year, 12, 1);
          endDate = DateTime(year, 12 + 1, 0); // Akhir bulan Desember
        });
        futureSampahData.then((data) {
          _applyFilters(data);
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Colors.black : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        side: BorderSide(
          color: isSelected ? Colors.black : Colors.grey,
        ),
      ),
      child: Text(year.toString()),
    );
  }

  Widget _buildStatusSummary() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Tab Bulan (Expandable)
              Expanded(child: _buildMonthTabs()),

              const SizedBox(width: 10),

              // Filter Button (Popup Status)
              PopupMenuButton<int>(
                offset: const Offset(0, 40),
                onSelected: (year) {
                  setState(() {
                    selectedYear = year;
                    if (year != DateTime.now().year) {
                      // Tahun beda dari sekarang, otomatis pilih Desember
                      selectedMonthIndex = 11;
                    } else {
                      // Tahun sekarang, biarkan bulan tetap seperti sebelumnya (atau set ke bulan sekarang)
                      // Contoh set ke bulan sekarang:
                      selectedMonthIndex = DateTime.now().month - 1;
                    }

                    startDate =
                        DateTime(selectedYear!, selectedMonthIndex! + 1, 1);
                    endDate =
                        DateTime(selectedYear!, selectedMonthIndex! + 2, 0);
                  });

                  futureSampahData.then((data) {
                    _applyFilters(data);
                  });
                },
                itemBuilder: (BuildContext context) {
                  return [
                    // Menampilkan tahun-tahun yang tersedia untuk dipilih
                    for (var year in List.generate(
                        3, (index) => DateTime.now().year - index))
                      PopupMenuItem<int>(
                        value: year,
                        child: Row(
                          children: [
                            Text(year.toString(),
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ];
                },
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.filter_list,
                      color: Colors.black, size: 16),
                  label: const Text(
                    "Filter",
                    style: TextStyle(color: Colors.black, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    side: const BorderSide(color: Colors.grey),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(0, 36),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
      String title, int count, Color color) {
    return PopupMenuItem<String>(
      value: title.toLowerCase(),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 14),
          const SizedBox(width: 8),
          Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(count.toString(),
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFFFF6600),
        centerTitle: true,
        title: const Text(
          'Riwayat Sampah',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        color: Color(0xFFFF6600), // Warna refresh indicator
        backgroundColor: Colors.white,
        onRefresh: _refreshData, // Function untuk refresh data
        child: Column(
          children: [
            // Bagian atas: abu-abu dengan fixed tinggi
            Container(
              color: Color(0xFFF2F2F2), // abu-abu muda
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  _buildStatusChart(),
                  _buildChartLegend(),
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
                    // Ini fixed, tidak scroll
                    _buildStatusSummary(),

                    // Spacer kecil jika perlu
                    SizedBox(height: 8),

                    // Bagian daftar yang scroll
                    Expanded(
                      child: FutureBuilder<List<SampahData>>(
                        future: futureSampahData,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFFF6600),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Memuat data...',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            Color.fromARGB(255, 190, 185, 181)),
                                  ),
                                ],
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text(
                                  'Tidak ada data Riwayat.',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            );
                          } else {
                            final rawData = snapshot.data!;
                            final filteredData = rawData.where((data) {
                              final matchesStatus = selectedStatus == 'all' ||
                                  data.status.toLowerCase() == selectedStatus;

                              final matchesMonth = selectedMonthIndex == null ||
                                  (data.tanggal.month ==
                                          selectedMonthIndex! + 1 &&
                                      data.tanggal.year == selectedYear);

                              return matchesStatus && matchesMonth;
                            }).toList();

                            if (filteredData.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Text(
                                    'Tidak ada data Riwayat untuk bulan ini.',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: filteredData.length,
                              itemBuilder: (context, index) {
                                SampahData data = filteredData[index];
                                Color statusColor;
                                String formattedDate = DateFormat('dd-MM-yyyy')
                                    .format(data.tanggal);

                                switch (data.status.toLowerCase()) {
                                  case 'proses':
                                    statusColor = Colors.yellow;
                                    break;
                                  case 'done':
                                    statusColor = Colors.green;
                                    break;
                                  case 'pending':
                                    statusColor = Colors.orange.shade300;
                                    break;
                                  case 'failed':
                                    statusColor = Colors.red;
                                    break;
                                  default:
                                    statusColor = Colors.grey;
                                }

                                final isExpanded =
                                    expandedCards.contains(index);

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
                                  child: _buildOuterCard(
                                    index: index + 1,
                                    name: data.nama,
                                    FotoSampah: data.fotoSampah,
                                    phone: data.noHp,
                                    list: data.list,
                                    status: data.status,
                                    namaUpt: data.namaUpt,
                                    location:
                                        '${data.alamat.kelurahan}, ${data.alamat.kecamatan}, ${data.alamat.deskripsi}',
                                    description: data.deskripsi,
                                    // list: data.list,
                                    mapUrl: data.alamat.kordinat,
                                    idSampah: data.id,
                                    idpetugas: data.id_user_petugas,
                                    statusColor: statusColor,
                                    tanggalFormatted: formattedDate,
                                    ratingPetugas: data.ratingPetugas,
                                    catatanPetugas: data.catatanPetugas,
                                    isExpanded: isExpanded,
                                  ),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOuterCard({
    required int index,
    required String name,
    required String FotoSampah,
    required String phone,
    required String status,
    required String namaUpt,
    required String location,
    required String list,
    required String description,
    required String mapUrl,
    required int idSampah,
    required int idpetugas,
    required Color statusColor,
    required String tanggalFormatted,
    required double? ratingPetugas,
    required String? catatanPetugas,
    required bool isExpanded, // tambah parameter ini
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
        list: list,
        description: description,
        mapUrl: mapUrl,
        idSampah: idSampah,
        idpetugas: idpetugas,
        statusColor: statusColor,
        tanggalFormatted: tanggalFormatted,
        ratingPetugas: ratingPetugas,
        catatanPetugas: catatanPetugas,
        isExpanded: isExpanded, // teruskan ke inner card juga
      ),
    );
  }

// Helper function untuk menghitung total berat dari string list
  String _calculateTotalWeight(String list) {
    double total = 0.0;
    try {
      final items = list.split(',');
      for (String item in items) {
        final trimmedItem = item.trim();
        if (trimmedItem.contains(':')) {
          final parts = trimmedItem.split(':');
          if (parts.length == 2) {
            final weightStr = parts[1]
                .trim()
                .replaceAll(RegExp(r'[^\d.]'), ''); // Extract numbers only
            final weight = double.tryParse(weightStr) ?? 0.0;
            total += weight;
          }
        }
      }
    } catch (e) {
      return '0.0kg';
    }
    return '${total.toStringAsFixed(1)}kg';
  }

  Widget _buildInnerCard({
    required String name,
    required String phone,
    required String fotoSampah,
    required String status,
    required String namaUpt,
    required String location,
    required String list,
    required String description,
    required String mapUrl,
    required int idSampah,
    required int idpetugas,
    required Color statusColor,
    required String tanggalFormatted,
    required double? ratingPetugas,
    required String? catatanPetugas,
    required bool isExpanded,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
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
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
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
                          calculatePoints(status)
                              .toString(), // <- nanti bisa diganti dinamis kalau mau
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Icon(
                  //   isExpanded
                  //       ? Icons.keyboard_arrow_up
                  //       : Icons.keyboard_arrow_down,
                  //   color: Colors.grey,
                  // ),
                ],
              )
            ],
          ),

          // Detail isi ketika expanded
          if (isExpanded) ...[
            const SizedBox(height: 16),
            Text('Nama      : $name'),
            Text('No. HP    : $phone'),
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

            // Tambahan: Detail berat sampah - ditampilkan saat status selesai
            if (status.toLowerCase() == 'done' && list.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue[200]!,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.scale_rounded,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Detail Berat Sampah',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Parse dan tampilkan list sampah dengan format yang rapi
                    ...list.split(',').map((item) {
                      final trimmedItem = item.trim();
                      if (trimmedItem.isEmpty) return const SizedBox.shrink();

                      final parts = trimmedItem.split(':');
                      if (parts.length != 2) {
                        // Jika format tidak sesuai, tampilkan apa adanya
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.blue[600],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  trimmedItem,
                                  style: TextStyle(
                                    color: Colors.blue[900],
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final itemName = parts[0].trim();
                      final weight = parts[1].trim();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.blue[100]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Icon sampah
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 14,
                                  color: Colors.blue[700],
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Nama sampah
                              Expanded(
                                child: Text(
                                  itemName,
                                  style: TextStyle(
                                    color: Colors.blue[900],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              // Berat
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[700],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  weight,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),

                    // Total berat (opsional - bisa dihitung dari list)
                    if (list.contains(':')) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.blue[600]!,
                              Colors.blue[700]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calculate_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Total Berat',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _calculateTotalWeight(list),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

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
            // Bagian tombol dan rating
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Action buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location button with improved design
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _openMap(mapUrl),
                        icon: const Icon(Icons.location_on_rounded, size: 18),
                        label: const Text(
                          'Lihat Lokasi',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green[600],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),

                    // Rating button for completed tasks without rating
                    if (status.toLowerCase() == 'done' &&
                        !_hasRating(ratingPetugas))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6600).withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _showRatingDialog(idSampah, idpetugas),
                            icon: const Icon(Icons.star_rounded, size: 18),
                            label: const Text(
                              'Beri Rating',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFFFF6600),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // // Spacer
                // const SizedBox(width: 16),

                // Right side - Rating display (if exists)
                if (status.toLowerCase() == 'done' && _hasRating(ratingPetugas))
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.amber[50]!,
                            Colors.orange[50]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber[200]!,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Rating header with stars
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Rating',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: Colors.amber[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              // Rating value with stars
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6600),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF6600)
                                          .withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      ratingPetugas.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Rating stars visualization
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: List.generate(5, (index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 2),
                                  child: Icon(
                                    index < ratingPetugas!.round()
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: index < ratingPetugas!.round()
                                        ? Colors.amber[600]
                                        : Colors.grey[400],
                                    size: 16,
                                  ),
                                );
                              }),
                            ),
                          ),

                          // Comment section
                          if (catatanPetugas != null &&
                              catatanPetugas.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Komentar',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    catatanPetugas,
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            )
          ],
        ],
      ),
    );
  }

  Future<void> _openMap(String mapUrl) async {
    final Uri mapUri = Uri.parse(mapUrl);
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri);
    } else {
      throw 'Could not launch $mapUrl';
    }
  }
}
