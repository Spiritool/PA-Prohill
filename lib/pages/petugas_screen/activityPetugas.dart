import 'package:dlh_project/pages/petugas_screen/mapPetugas.dart';
import 'package:dlh_project/pages/petugas_screen/sampah.dart';
import 'package:dlh_project/pages/petugas_screen/detail_daur_ulang.dart';
import 'package:dlh_project/pages/petugas_screen/detail_liar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

class ActivityPetugasPage extends StatefulWidget {
  const ActivityPetugasPage({super.key});

  @override
  _ActivityPetugasPageState createState() => _ActivityPetugasPageState();
}

String _status = 'ready'; // Default value

// Tambahkan state variables untuk menyimpan jumlah data
Map<String, int> sampahCounts = {
  'proses': 0,
  'pending': 0,
};

Map<String, int> sampahLiarCounts = {
  'proses_liar': 0,
  'proses_kontainer': 0,
  'pending_liar': 0,
  'pending_kontainer': 0,
};

Future<http.Response> fetchWithRetry(String url, {int retries = 3}) async {
  for (int attempt = 1; attempt <= retries; attempt++) {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return response;
    } else if (response.statusCode == 429) {
      print('⚠️ Attempt $attempt: Too Many Requests. Retrying in 3 seconds...');
      await Future.delayed(const Duration(seconds: 3));
    } else {
      throw Exception(
          'Failed to load data from $url (Status: ${response.statusCode})');
    }
  }

  throw Exception('Max retries exceeded for $url');
}

Future<Map<String, List<SampahData>>> fetchSampahData() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id') ?? 0;

  if (userId == 0) {
    throw Exception('User ID not found in SharedPreferences');
  }

  final urls = {
    'riwayat_done': [
      '$baseipapi/api/pengangkutan-sampah/history/by-petugas/$userId/done'
    ],
    'riwayat_failed': [
      '$baseipapi/api/pengangkutan-sampah/history/by-petugas/$userId/failed'
    ],
    'proses': [
      '$baseipapi/api/pengangkutan-sampah/history/by-petugas/$userId/proses'
    ],
    'pending': [
      '$baseipapi/api/pengangkutan-sampah/history/by-petugas/$userId/pending'
    ],
  };

  final Map<String, List<SampahData>> categorizedData = {
    'riwayat': [],
    'proses': [],
    'pending': [],
  };

  for (var category in urls.keys) {
    for (var url in urls[category]!) {
      await Future.delayed(const Duration(seconds: 2));

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body)['data'];
        List<SampahData> sampahList = data.map((item) {
          // Tentukan status berdasarkan kategori URL
          String status;
          if (category == 'riwayat_done') {
            status = 'done';
          } else if (category == 'riwayat_failed') {
            status = 'failed';
          } else {
            status = category; // 'proses' atau 'pending'
          }
          
          // Tambahkan status ke JSON sebelum parsing
          item['status'] = status;
          return SampahData.fromJson(item);
        }).toList();
        
        // Gabungkan riwayat_done dan riwayat_failed ke dalam 'riwayat'
        if (category == 'riwayat_done' || category == 'riwayat_failed') {
          categorizedData['riwayat']!.addAll(sampahList);
        } else {
          categorizedData[category]!.addAll(sampahList);
        }
      } else if (response.statusCode == 429) {
        print('⚠️ Too Many Requests! Menunggu 5 detik sebelum mencoba lagi...');
        await Future.delayed(const Duration(seconds: 5));
        continue;
      } else {
        throw Exception('Failed to load data from $url');
      }
    }
  }

  return categorizedData;
}
Future<Map<String, List<SampahLiarData>>> fetchSampahLiarData() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id') ?? 0;

  if (userId == 0) {
    throw Exception('User ID not found in SharedPreferences');
  }

  final urls = {
    'riwayat_done': [
      '$baseipapi/api/pengangkutan-sampah-liar/history/by-petugas/$userId/done'
    ],
    'riwayat_failed': [
      '$baseipapi/api/pengangkutan-sampah-liar/history/by-petugas/$userId/failed'
    ],
    'proses': [
      '$baseipapi/api/pengangkutan-sampah-liar/history/by-petugas/$userId/proses'
    ],
    'pending': [
      '$baseipapi/api/pengangkutan-sampah-liar/history/by-petugas/$userId/pending'
    ],
  };

  final Map<String, List<SampahLiarData>> categorizedData = {
    'riwayat': [],
    'proses': [],
    'pending': [],
  };

  for (var category in urls.keys) {
    for (var url in urls[category]!) {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body)['data'];
        List<SampahLiarData> sampahList = data.map((item) {
          // Tentukan status berdasarkan kategori URL
          String status;
          if (category == 'riwayat_done') {
            status = 'done';
          } else if (category == 'riwayat_failed') {
            status = 'failed';
          } else {
            status = category; // 'proses' atau 'pending'
          }
          
          // Tambahkan status ke JSON sebelum parsing
          item['status'] = status;
          return SampahLiarData.fromJson(item);
        }).toList();
        
        // Gabungkan riwayat_done dan riwayat_failed ke dalam 'riwayat'
        if (category == 'riwayat_done' || category == 'riwayat_failed') {
          categorizedData['riwayat']!.addAll(sampahList);
        } else {
          categorizedData[category]!.addAll(sampahList);
        }
      } else {
        print("Error fetching $url: ${response.body}");
        throw Exception('Failed to load data from $url');
      }
    }
  }

  return categorizedData;
}
// Fungsi untuk memisahkan sampah liar dan sampah kontainer
Map<String, List<SampahLiarData>> separateSampahLiarAndKontainer(
    Map<String, List<SampahLiarData>> originalData) {
  final Map<String, List<SampahLiarData>> separatedData = {
    'riwayat_liar': [],
    'proses_liar': [],
    'pending_liar': [],
    'riwayat_kontainer': [],
    'proses_kontainer': [],
    'pending_kontainer': [],
  };

  // Pisahkan data berdasarkan email
  for (var category in ['riwayat', 'proses', 'pending']) {
    final dataList = originalData[category] ?? [];

    for (var item in dataList) {
      if (item.email == 'admin@gmail.com') {
        // Masukkan ke kategori kontainer
        separatedData['${category}_kontainer']!.add(item);
      } else {
        // Masukkan ke kategori liar
        separatedData['${category}_liar']!.add(item);
      }
    }
  }

  return separatedData;
}

class _ActivityPetugasPageState extends State<ActivityPetugasPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  int selectedDataType =
      0; // 0: Daur Ulang, 1: Sampah Liar, 2: Sampah Kontainer

  late Future<Map<String, List<SampahData>>> futureSampahData;
  late Future<Map<String, List<SampahLiarData>>> futureSampahLiarData;

  // Orange color scheme
  static const Color primaryOrange = Color(0xFFFF8C00);
  static const Color lightOrange = Color(0xFFFFA500);
  static const Color darkOrange = Color(0xFFFF6600);
  static const Color paleOrange = Color(0xFFFFE4B5);
  static const Color deepOrange = Color(0xFFFF4500);
  static const Color containerOrange =
      Color(0xFFFF7043); // Warna untuk sampah kontainer

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    _loadUserStatus();

    // Inisialisasi Future Data dan hitung jumlah setelah data dimuat
    _loadDataAndCounts();
  }

  void _loadDataAndCounts() async {
    futureSampahData = fetchSampahData();
    futureSampahLiarData = fetchSampahLiarData();

    // Tunggu kedua future selesai dan update counts
    try {
      final sampahData = await futureSampahData;
      final sampahLiarData = await futureSampahLiarData;

      final separatedData = separateSampahLiarAndKontainer(sampahLiarData);

      setState(() {
        sampahCounts['proses'] = sampahData['proses']?.length ?? 0;
        sampahCounts['pending'] = sampahData['pending']?.length ?? 0;

        sampahLiarCounts['proses_liar'] =
            separatedData['proses_liar']?.length ?? 0;
        sampahLiarCounts['proses_kontainer'] =
            separatedData['proses_kontainer']?.length ?? 0;
        sampahLiarCounts['pending_liar'] =
            separatedData['pending_liar']?.length ?? 0;
        sampahLiarCounts['pending_kontainer'] =
            separatedData['pending_kontainer']?.length ?? 0;
      });
    } catch (e) {
      print('Error loading data: $e');
    }
  }

// Update method untuk update counts
  void _updateCounts() async {
    try {
      final sampahData = await futureSampahData;
      final sampahLiarData = await futureSampahLiarData;

      final separatedData = separateSampahLiarAndKontainer(sampahLiarData);

      setState(() {
        sampahCounts['proses'] = sampahData['proses']?.length ?? 0;
        sampahCounts['pending'] = sampahData['pending']?.length ?? 0;

        sampahLiarCounts['proses_liar'] =
            separatedData['proses_liar']?.length ?? 0;
        sampahLiarCounts['proses_kontainer'] =
            separatedData['proses_kontainer']?.length ?? 0;
        sampahLiarCounts['pending_liar'] =
            separatedData['pending_liar']?.length ?? 0;
        sampahLiarCounts['pending_kontainer'] =
            separatedData['pending_kontainer']?.length ?? 0;
      });
    } catch (e) {
      print('Error updating counts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: darkOrange,
        title: const Text(
          'Activity Petugas',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: darkOrange,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: primaryOrange,
              unselectedLabelColor: const Color(0xFF7F8C8D),
              indicatorColor: primaryOrange,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  icon: const Icon(Icons.history, size: 20),
                  text: 'Riwayat',
                ),
                Tab(
                  child: _buildTabWithBadge(
                    Icons.hourglass_empty,
                    'Proses',
                    _getTotalCount('proses'),
                  ),
                ),
                Tab(
                  child: _buildTabWithBadge(
                    Icons.pending_actions,
                    'Pending',
                    _getTotalCount('pending'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterButton(
                    'Daur Ulang',
                    Icons.recycling,
                    selectedDataType == 0,
                    primaryOrange,
                    () {
                      setState(() {
                        selectedDataType = 0;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterButton(
                    'Sampah Liar',
                    Icons.delete_outline,
                    selectedDataType == 1,
                    deepOrange,
                    () {
                      setState(() {
                        selectedDataType = 1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterButton(
                    'Kontainer',
                    Icons.delete_forever,
                    selectedDataType == 2,
                    containerOrange,
                    () {
                      setState(() {
                        selectedDataType = 2;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListSampah(0), // Tab Riwayat
                _buildListSampah(1), // Tab Dalam Proses
                _buildListSampah(2), // Tab Pending
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryOrange.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const mapPetugas()),
            );
          },
          backgroundColor: primaryOrange,
          icon: const Icon(Icons.map, color: Colors.white),
          label: const Text(
            'Lihat Peta',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String text, IconData icon, bool isSelected,
      Color color, VoidCallback onPressed) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color : Colors.white,
          foregroundColor: isSelected ? Colors.white : color,
          elevation: isSelected ? 4 : 1,
          shadowColor: color.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? color : color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListSampah(int selectedTab) {
    if (selectedDataType == 0) {
      // Sampah Daur Ulang
      return FutureBuilder<Map<String, List<SampahData>>>(
        future: futureSampahData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingWidget();
          } else if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          } else if (!snapshot.hasData) {
            return const Center(child: Text("Tidak ada data sampah."));
          }

          List<SampahData> sampahList;
          if (selectedTab == 0) {
            sampahList = snapshot.data!['riwayat'] ?? [];
          } else if (selectedTab == 1) {
            sampahList = snapshot.data!['proses'] ?? [];
          } else {
            sampahList = snapshot.data!['pending'] ?? [];
          }

          if (sampahList.isEmpty) {
            return _buildEmptyDataWidget(selectedTab, "Daur Ulang");
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: sampahList.length,
            itemBuilder: (context, index) {
              return _buildSampahCard(sampahList[index], selectedTab, index);
            },
          );
        },
      );
    } else {
      // Sampah Liar atau Kontainer
      return FutureBuilder<Map<String, List<SampahLiarData>>>(
        future: futureSampahLiarData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingWidget();
          } else if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          } else if (!snapshot.hasData) {
            return const Center(child: Text("Tidak ada data sampah."));
          }

          // Pisahkan data sampah liar dan kontainer
          final separatedData = separateSampahLiarAndKontainer(snapshot.data!);

          List<SampahLiarData> sampahList;
          String categoryKey;

          if (selectedDataType == 1) {
            // Sampah Liar
            categoryKey = selectedTab == 0
                ? 'riwayat_liar'
                : selectedTab == 1
                    ? 'proses_liar'
                    : 'pending_liar';
          } else {
            // Sampah Kontainer
            categoryKey = selectedTab == 0
                ? 'riwayat_kontainer'
                : selectedTab == 1
                    ? 'proses_kontainer'
                    : 'pending_kontainer';
          }

          sampahList = separatedData[categoryKey] ?? [];

          if (sampahList.isEmpty) {
            String jenisSampah = selectedDataType == 1 ? "Liar" : "Kontainer";
            return _buildEmptyDataWidget(selectedTab, jenisSampah);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: sampahList.length,
            itemBuilder: (context, index) {
              return _buildSampahCard(sampahList[index], selectedTab, index);
            },
          );
        },
      );
    }
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Memuat data...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF7F8C8D),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: deepOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.error_outline,
              color: deepOrange,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Terjadi kesalahan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF7F8C8D),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDataWidget(int selectedTab, String jenisSampah) {
    String tabName = selectedTab == 0
        ? "Riwayat"
        : selectedTab == 1
            ? "Dalam Proses"
            : "Pending";

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: lightOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              selectedTab == 0
                  ? Icons.history_edu
                  : selectedTab == 1
                      ? Icons.hourglass_empty
                      : Icons.pending_actions,
              color: lightOrange,
              size: 50,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Belum ada data",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tidak ada data sampah $jenisSampah\nuntuk tab $tabName",
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF7F8C8D),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

// 5. Ubah fungsi _buildSampahCard untuk menampilkan status yang benar
Widget _buildSampahCard(dynamic item, int selectedTab, int index) {
  // Determine card colors based on tab, type, and status
  Color cardColor;
  Color shadowColor;
  IconData cardIcon;
  String statusText;

  if (selectedTab == 0) {
    // Riwayat - Cek status untuk menentukan warna dan icon
    if (item.status == 'failed') {
      // Status Failed - Warna merah
      cardColor = Colors.red;
      cardIcon = Icons.cancel;
      statusText = 'Dibatalkan';
    } else {
      // Status Done - Warna hijau atau orange sesuai tipe
      if (selectedDataType == 0) {
        cardColor = Colors.green; // Atau bisa tetap primaryOrange
      } else if (selectedDataType == 1) {
        cardColor = Colors.green; // Atau bisa tetap deepOrange
      } else {
        cardColor = Colors.green; // Atau bisa tetap containerOrange
      }
      cardIcon = Icons.check_circle;
      statusText = 'Selesai';
    }
    shadowColor = cardColor.withOpacity(0.3);
  } else if (selectedTab == 1) {
    // Dalam Proses
    cardColor = lightOrange;
    shadowColor = cardColor.withOpacity(0.3);
    cardIcon = Icons.hourglass_empty;
    statusText = 'Proses';
  } else {
    // Pending
    cardColor = const Color(0xFFFFB366);
    shadowColor = cardColor.withOpacity(0.3);
    cardIcon = Icons.pending_actions;
    statusText = 'Menunggu';
  }

  return AnimatedContainer(
    duration: Duration(milliseconds: 200 + (index * 50)),
    curve: Curves.easeOutBack,
    child: GestureDetector(
      onTap: () async {
        bool? updated = false;

        if (selectedDataType == 0) {
          updated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailSampahDaurUlangPage(
                sampah: item as SampahData,
              ),
            ),
          );
        } else {
          updated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailSampahLiarPage(
                sampah: item as SampahLiarData,
              ),
            ),
          );
        }

        if (updated == true) {
          setState(() {
            futureSampahData = fetchSampahData();
            futureSampahLiarData = fetchSampahLiarData();
          });
          _updateCounts();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: cardColor,
                  width: 5,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          cardIcon,
                          color: cardColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedDataType == 0
                                  ? (item as SampahData).name
                                  : (item as SampahLiarData).email,
                              style: const TextStyle(
                                color: Color(0xFF2C3E50),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cardColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                selectedDataType == 0
                                    ? 'Daur Ulang'
                                    : selectedDataType == 1
                                        ? 'Sampah Liar'
                                        : 'Sampah Kontainer',
                                style: TextStyle(
                                  color: cardColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: const Color(0xFF95A5A6),
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.deskripsi,
                    style: const TextStyle(
                      color: Color(0xFF5D6D7E),
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
  children: [
    Icon(
      Icons.access_time,
      color: const Color(0xFF95A5A6),
      size: 14,
    ),
    const SizedBox(width: 4),
    Text(
      DateFormat('dd MMM yyyy • HH:mm').format(item.tanggal),
      style: const TextStyle(
        color: Color(0xFF95A5A6),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  ],
),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText, // Menggunakan statusText yang sudah disesuaikan
                          style: TextStyle(
                            color: cardColor,
                            fontSize: 10,
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
        ),
      ),
    ),
  );
}
  Future<void> _loadUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _status = prefs.getString('status') ?? 'tidak_ready';

    if (_status == 'tidak_ready') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAktifkanAkunDialog();
      });
    }
  }

  void _showAktifkanAkunDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 10,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, paleOrange.withOpacity(0.3)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: lightOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: lightOrange,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Akun Tidak Aktif',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Akun Anda dalam status tidak tersedia. Silakan aktifkan di halaman akun agar bisa menerima laporan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF7F8C8D),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: primaryOrange.withOpacity(0.3),
                    ),
                    child: const Text(
                      'Mengerti',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabWithBadge(IconData icon, String text, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 2),
            Text(text),
          ],
        ),
        if (count > 0)
          Positioned(
            right: -8,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  int _getTotalCount(String tabType) {
    int total = 0;

    if (selectedDataType == 0) {
      // Daur Ulang
      total = sampahCounts[tabType] ?? 0;
    } else if (selectedDataType == 1) {
      // Sampah Liar
      total = sampahLiarCounts['${tabType}_liar'] ?? 0;
    } else {
      // Sampah Kontainer
      total = sampahLiarCounts['${tabType}_kontainer'] ?? 0;
    }

    return total;
  }
}
