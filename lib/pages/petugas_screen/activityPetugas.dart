import 'package:dlh_project/pages/petugas_screen/mapPetugas.dart';
import 'package:dlh_project/pages/petugas_screen/sampah.dart';
import 'package:dlh_project/pages/petugas_screen/detail_daur_ulang.dart';
import 'package:dlh_project/pages/petugas_screen/detail_liar.dart';
import 'package:dlh_project/backup/mapPetugas2.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ActivityPetugasPage extends StatefulWidget {
  const ActivityPetugasPage({super.key});

  @override
  _ActivityPetugasPageState createState() => _ActivityPetugasPageState();
}

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
    // 'riwayat': [
    //   'https://jera.kerissumenep.com/api/pengangkutan-sampah/history/by-petugas/$userId/done',
    //   'https://jera.kerissumenep.com/api/pengangkutan-sampah/history/by-petugas/$userId/failed'
    // ],
    // 'proses': [
    //   'https://jera.kerissumenep.com/api/pengangkutan-sampah/history/by-petugas/$userId/proses'
    // ],
    // 'pending': [
    //   'https://jera.kerissumenep.com/api/pengangkutan-sampah/history/by-petugas/$userId/pending'
    // ],
    'riwayat': [
      'https://prohildlhcilegon.id/api/pengangkutan-sampah/history/by-petugas/$userId/done',
      'https://prohildlhcilegon.id/api/pengangkutan-sampah/history/by-petugas/$userId/failed'
    ],
    'proses': [
      'https://prohildlhcilegon.id/api/pengangkutan-sampah/history/by-petugas/$userId/proses'
    ],
    'pending': [
      'https://prohildlhcilegon.id/api/pengangkutan-sampah/history/by-petugas/$userId/pending'
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
      'https://prohildlhcilegon.id/api/pengangkutan-sampah-liar/history/by-petugas/$userId/done',
      'https://prohildlhcilegon.id/api/pengangkutan-sampah-liar/history/by-petugas/$userId/failed'
    ],
    'proses': [
      'https://prohildlhcilegon.id/api/pengangkutan-sampah-liar/history/by-petugas/$userId/proses'
    ],
    'pending': [
      'https://prohildlhcilegon.id/api/pengangkutan-sampah-liar/history/by-petugas/$userId/pending'
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });

    // Inisialisasi Future Data
    futureSampahData = fetchSampahData();
    futureSampahLiarData = fetchSampahLiarData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Activity Petugas',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: 'Riwayat'),
            Tab(text: 'Dalam Proses'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterButton(
                    'Sampah Daur Ulang',
                    showSampahData,
                    Colors.blue,
                    () {
                      setState(() {
                        showSampahData = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFilterButton(
                    'Sampah Liar',
                    !showSampahData,
                    Colors.red,
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
                _buildListSampah(0), // ✅ Tab Riwayat
                _buildListSampah(1), // ✅ Tab Dalam Proses
                _buildListSampah(2), // ✅ Tab Pending
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const mapPetugas()), // Ganti MapPage sesuai nama file kamu
          );
        },
        backgroundColor: Colors.green,
        tooltip: 'Lihat Peta',
        child: const Icon(Icons.map),
      ),
    );
  }

  Widget _buildFilterButton(
      String text, bool isSelected, Color color, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color : Colors.grey.shade300,
          foregroundColor: isSelected ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildListSampah(int selectedTab) {
    return FutureBuilder<Map<String, List<dynamic>>>(
      // Pilih Future berdasarkan tombol yang ditekan
      future: showSampahData
          ? futureSampahData as Future<Map<String, List<dynamic>>>
          : futureSampahLiarData as Future<Map<String, List<dynamic>>>,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData) {
          return const Center(child: Text("Tidak ada data sampah."));
        }

        // Tentukan kategori berdasarkan tab
        List<dynamic> sampahList;
        if (selectedTab == 0) {
          sampahList = snapshot.data!['riwayat'] ?? [];
        } else if (selectedTab == 1) {
          sampahList = snapshot.data!['proses'] ?? [];
        } else {
          sampahList = snapshot.data!['pending'] ?? [];
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: sampahList.length,
          itemBuilder: (context, index) {
            final item = sampahList[index];

            // Jika Sampah Daur Ulang
            if (showSampahData) {
              final sampahItem = item as SampahData;
              return _buildSampahCard(sampahItem, selectedTab);
            }
            // Jika Sampah Liar
            else {
              final sampahLiarItem = item as SampahLiarData;
              return _buildSampahCard(sampahLiarItem, selectedTab);
            }
          },
        );
      },
    );
  }

  Widget _buildSampahCard(dynamic item, int selectedTab) {
    return GestureDetector(
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
            // Refresh data atau UI
            futureSampahData =
                fetchSampahData(); // Memanggil kembali data terbaru
            futureSampahLiarData = fetchSampahLiarData();
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selectedTab == 0
              ? (showSampahData ? Colors.blue : Colors.red)
              : (selectedTab == 1 ? Colors.orange : Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              showSampahData
                  ? (item as SampahData).name
                  : (item as SampahLiarData).email,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              item.deskripsi,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat('dd-MM-yyyy').format(item.tanggal),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
