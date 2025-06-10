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
    'riwayat': [
      '$baseipapi/api/pengangkutan-sampah/history/by-petugas/$userId/done',
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
      await Future.delayed(
          const Duration(seconds: 2)); // Tambahkan delay sebelum request

      final response = await http.get(Uri.parse(url));

      print('Fetching: $url');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}'); // Debugging response

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body)['data'];
        List<SampahData> sampahList =
            data.map((item) => SampahData.fromJson(item)).toList();
        categorizedData[category]!.addAll(sampahList);
      } else if (response.statusCode == 429) {
        print('⚠️ Too Many Requests! Menunggu 5 detik sebelum mencoba lagi...');
        await Future.delayed(
            const Duration(seconds: 5)); // Tunggu sebelum mencoba lagi
        continue; // Lewati loop, jangan langsung throw error
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
    'riwayat': [
      '$baseipapi/api/pengangkutan-sampah-liar/history/by-petugas/$userId/done',
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
      print("Fetching: $url"); // Debugging URL
      final response = await http.get(Uri.parse(url));
      print("Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body)['data'];
        List<SampahLiarData> sampahList =
            data.map((item) => SampahLiarData.fromJson(item)).toList();
        categorizedData[category]!.addAll(sampahList);
      } else {
        print("Error fetching $url: ${response.body}");
        throw Exception('Failed to load data from $url');
      }
    }
  }

  print("Final Sampah Liar Data: $categorizedData"); // Debugging output akhir
  return categorizedData;
}

class _ActivityPetugasPageState extends State<ActivityPetugasPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  bool showSampahData = true;

  late Future<Map<String, List<SampahData>>> futureSampahData;
  late Future<Map<String, List<SampahLiarData>>> futureSampahLiarData;

  // Orange color scheme
  static const Color primaryOrange = Color(0xFFFF8C00);
  static const Color lightOrange = Color(0xFFFFA500);
  static const Color darkOrange = Color(0xFFFF6600);
  static const Color paleOrange = Color(0xFFFFE4B5);
  static const Color deepOrange = Color(0xFFFF4500);

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

    // Inisialisasi Future Data
    futureSampahData = fetchSampahData();
    futureSampahLiarData = fetchSampahLiarData();
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
                  icon: const Icon(Icons.hourglass_empty, size: 20),
                  text: 'Proses',
                ),
                Tab(
                  icon: const Icon(Icons.pending_actions, size: 20),
                  text: 'Pending',
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
                    'Sampah Daur Ulang',
                    Icons.recycling,
                    showSampahData,
                    primaryOrange,
                    () {
                      setState(() {
                        showSampahData = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFilterButton(
                    'Sampah Liar',
                    Icons.delete_outline,
                    !showSampahData,
                    deepOrange,
                    () {
                      setState(() {
                        showSampahData = false;
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
              MaterialPageRoute(
                  builder: (context) => const mapPetugas()),
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
        icon: Icon(icon, size: 18),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color : Colors.white,
          foregroundColor: isSelected ? Colors.white : color,
          elevation: isSelected ? 4 : 1,
          shadowColor: color.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
    return FutureBuilder<Map<String, List<dynamic>>>(
      future: showSampahData
          ? futureSampahData as Future<Map<String, List<dynamic>>>
          : futureSampahLiarData as Future<Map<String, List<dynamic>>>,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
        } else if (snapshot.hasError) {
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
                  "${snapshot.error}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7F8C8D),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData) {
          return const Center(child: Text("Tidak ada data sampah."));
        }

        // Tentukan kategori berdasarkan tab
        List<dynamic> sampahList;
        String jenisSampah = showSampahData ? "Daur Ulang" : "Liar";

        if (selectedTab == 0) {
          sampahList = snapshot.data!['riwayat'] ?? [];
        } else if (selectedTab == 1) {
          sampahList = snapshot.data!['proses'] ?? [];
        } else {
          sampahList = snapshot.data!['pending'] ?? [];
        }

        // Tampilkan pesan jika data kosong
        if (sampahList.isEmpty) {
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

        // Jika ada data, tampilkan daftar
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: sampahList.length,
          itemBuilder: (context, index) {
            final item = sampahList[index];
            if (showSampahData) {
              return _buildSampahCard(item as SampahData, selectedTab, index);
            } else {
              return _buildSampahCard(item as SampahLiarData, selectedTab, index);
            }
          },
        );
      },
    );
  }

  Widget _buildSampahCard(dynamic item, int selectedTab, int index) {
    // Determine card colors based on tab and type with orange theme
    Color cardColor;
    Color shadowColor;
    IconData cardIcon;
    
    if (selectedTab == 0) {
      // Riwayat - Success Green but with orange accent
      cardColor = showSampahData ? primaryOrange : deepOrange;
      shadowColor = cardColor.withOpacity(0.3);
      cardIcon = Icons.check_circle;
    } else if (selectedTab == 1) {
      // Dalam Proses - Orange
      cardColor = lightOrange;
      shadowColor = cardColor.withOpacity(0.3);
      cardIcon = Icons.hourglass_empty;
    } else {
      // Pending - Light Orange
      cardColor = const Color(0xFFFFB366);
      shadowColor = cardColor.withOpacity(0.3);
      cardIcon = Icons.pending_actions;
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.easeOutBack,
      child: GestureDetector(
        onTap: () async {
          bool? updated = false;

          // Navigasi ke halaman detail berdasarkan jenis sampah
          if (showSampahData) {
            // Sampah Daur Ulang
            updated = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailSampahDaurUlangPage(
                  sampah: item as SampahData,
                ),
              ),
            );
          } else {
            // Sampah Liar
            updated = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailSampahLiarPage(
                  sampah: item as SampahLiarData,
                ),
              ),
            );
          }

          // Jika status diperbarui, lakukan refresh pada daftar
          if (updated == true) {
            setState(() {
              futureSampahData = fetchSampahData();
              futureSampahLiarData = fetchSampahLiarData();
            });
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
                                showSampahData
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
                                  showSampahData ? 'Daur Ulang' : 'Sampah Liar',
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
                              Icons.calendar_today,
                              color: const Color(0xFF95A5A6),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(item.tanggal),
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
                            selectedTab == 0
                                ? 'Selesai'
                                : selectedTab == 1
                                    ? 'Proses'
                                    : 'Menunggu',
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
}