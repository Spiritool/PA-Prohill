import 'package:dlh_project/pages/warga_screen/historySampah.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

Future<List<SampahData>> fetchSampahData() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id') ?? 0;

  if (userId == 0) {
    throw Exception('User ID not found in SharedPreferences');
  }

  final urls = [
    'https://jera.kerissumenep.com/api/pengangkutan-sampah/history/$userId/proses',
    'https://jera.kerissumenep.com/api/pengangkutan-sampah/history/$userId/done',
    'https://jera.kerissumenep.com/api/pengangkutan-sampah/history/$userId/pending',
    'https://jera.kerissumenep.com/api/pengangkutan-sampah/history/$userId/failed',
  ];

  List<SampahData> allData = [];

  for (String url in urls) {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body)['data'];
      allData.addAll(data.map((item) => SampahData.fromJson(item)).toList());
    } else {
      throw Exception('Failed to load data from $url');
    }
  }

  // Balikkan daftar agar data terbaru tampil di atas
  allData.sort((a, b) => b.id.compareTo(a.id));

  return allData;
}

class History extends StatefulWidget {
  const History({super.key});

  @override
  _HistoryState createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  late Future<List<SampahData>> futureSampahData;

  @override
  void initState() {
    super.initState();
    futureSampahData = fetchSampahData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Riwayat Sampah',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FutureBuilder<List<SampahData>>(
              future: futureSampahData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Tidak ada data Riwayat.'));
                } else {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      SampahData data = snapshot.data![index];
                      Color statusColor;

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

                      return _buildOuterCard(
                        index: index + 1,
                        name: data.nama,
                        phone: data.noHp,
                        status: data.status,
                        namaUpt: data.namaUpt,
                        location:
                            '${data.alamat.kelurahan}, ${data.alamat.kecamatan}, ${data.alamat.deskripsi}',
                        description: data.deskripsi,
                        mapUrl: data.alamat.kordinat,
                        idSampah: data.id,
                        statusColor: statusColor,
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOuterCard({
    required int index,
    required String name,
    required String phone,
    required String status,
    required String namaUpt,
    required String location,
    required String description,
    required String mapUrl,
    required int idSampah,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Card(
        color: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInnerCard(
                name: name,
                phone: phone,
                status: status,
                namaUpt: namaUpt,
                location: location,
                description: description,
                mapUrl: mapUrl,
                idSampah: idSampah,
                statusColor: statusColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInnerCard({
    required String name,
    required String phone,
    required String status,
    required String namaUpt,
    required String location,
    required String description,
    required String mapUrl,
    required int idSampah,
    required Color statusColor,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nama      : $name',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No. Hp    : $phone',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Status     : ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    status == 'failed' ? 'Dibatalkan' : status,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'UPT         : $namaUpt',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Alamat    : $location',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Deskripsi : $description',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _openMap(mapUrl),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Lihat Lokasi '),
            ),
            const SizedBox(height: 8),
          ],
        ),
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
