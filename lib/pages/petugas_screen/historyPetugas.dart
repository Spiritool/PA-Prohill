import 'package:dlh_project/pages/petugas_screen/sampah.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    'https://jera.kerissumenep.com/api/pengangkutan-sampah/history/by-petugas/$userId/done',
    'https://jera.kerissumenep.com/api/pengangkutan-sampah/history/by-petugas/$userId/failed',
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

  // Sort the list by id in descending order
  allData.sort((a, b) => b.id.compareTo(a.id));

  return allData;
}

Future<List<SampahLiarData>> fetchSampahLiarData() async {
  final prefs = await SharedPreferences.getInstance();
  final idUser = prefs.getInt('user_id') ?? 0;

  if (idUser == 0) {
    throw Exception('User ID not found in SharedPreferences');
  }

  final response = await http.get(Uri.parse(
      'https://jera.kerissumenep.com/api/pengangkutan-sampah-liar/history/by-kecamatan/$idUser'));

  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body)['data'];

    // Map and filter the data based on status
    List<SampahLiarData> sampahLiarDataList =
        data.map((item) => SampahLiarData.fromJson(item)).toList();

    // Filter to include only status 'pending' and 'proses'
    List<SampahLiarData> filteredData = sampahLiarDataList
        .where((item) => item.status == 'failed' || item.status == 'done')
        .toList();

    // Sort by id in descending order
    filteredData.sort((a, b) => b.id.compareTo(a.id));

    return filteredData;
  } else {
    throw Exception('Failed to load sampah liar data');
  }
}

class HistoryPetugas extends StatefulWidget {
  const HistoryPetugas({
    super.key,
  });

  @override
  _HistoryPetugasState createState() => _HistoryPetugasState();
}

class _HistoryPetugasState extends State<HistoryPetugas> {
  late Future<List<SampahData>> futureSampahData;
  late Future<List<SampahLiarData>> futureSampahLiarData;
  bool showSampahData = true;

  @override
  void initState() {
    super.initState();
    futureSampahData = fetchSampahData();
    futureSampahLiarData = fetchSampahLiarData();
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
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showSampahData = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor:
                            showSampahData ? Colors.white : Colors.black,
                        backgroundColor:
                            showSampahData ? Colors.blue : Colors.grey,
                        elevation: showSampahData ? 5 : 2,
                      ),
                      child: const Text('Sampah Terpilah'),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showSampahData = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor:
                            !showSampahData ? Colors.white : Colors.black,
                        backgroundColor:
                            !showSampahData ? Colors.red : Colors.grey,
                        elevation: !showSampahData ? 5 : 2,
                      ),
                      child: const Text('Sampah Liar'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (showSampahData)
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
                          case 'done':
                            statusColor = Colors.green;
                            break;
                          case 'failed':
                            statusColor = Colors.red;
                            break;
                          default:
                            statusColor = Colors.grey;
                        }

                        return _buildOuterCard(
                          name: data.name,
                          namaUpt: data.namaUpt,
                          FotoSampah: data.fotoSampah,
                          phone: data.noHp,
                          status: data.status,
                          lokasi:
                              '${data.alamat.kelurahan}, ${data.alamat.kecamatan}, ${data.alamat.deskripsi}',
                          description: data.deskripsi,
                          mapUrl: data.alamat.kordinat,
                          idSampah: data.id,
                          // idUserPetugas: widget.userId,
                          statusColor: statusColor,
                        );
                      },
                    );
                  }
                },
              )
            else
              FutureBuilder<List<SampahLiarData>>(
                future: futureSampahLiarData,
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
                        SampahLiarData data = snapshot.data![index];
                        Color statusColor;
                        switch (data.status.toLowerCase()) {
                          case 'done':
                            statusColor = Colors.green;
                            break;
                          case 'failed':
                            statusColor = Colors.red;
                            break;
                          default:
                            statusColor = Colors.grey;
                        }

                        return _buildOuterCardSampahLiar(
                          namaUpt: data.namaUpt,
                          FotoSampah: data.fotoSampah,
                          phone: data.noHp,
                          status: data.status,
                          email: data.email,
                          lokasi: data.kordinat,
                          description: data.deskripsi,
                          mapUrl: data.kordinat,
                          idSampah: data.id,
                          statusColor: statusColor,
                        );
                      },
                    );
                  }
                },
              )
          ],
        ),
      ),
    );
  }

  Widget _buildOuterCard({
    required String name,
    required String namaUpt,
    // ignore: non_constant_identifier_names
    required String FotoSampah,
    required String phone,
    required String status,
    required String lokasi,
    required String description,
    required String mapUrl,
    required int idSampah,
    // required int idUserPetugas,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Card(
        color: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 8,
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sampah Terpilah',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              _buildInnerCard(
                name: name,
                fotoSampah: FotoSampah,
                namaUpt: namaUpt,
                phone: phone,
                status: status,
                lokasi: lokasi,
                description: description,
                mapUrl: mapUrl,
                idSampah: idSampah,
                // idUserPetugas: idUserPetugas,
                statusColor: statusColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOuterCardSampahLiar({
    // required String name,
    required String namaUpt,
    // ignore: non_constant_identifier_names
    required String FotoSampah,
    required String phone,
    required String email,
    required String status,
    required String lokasi,
    required String description,
    required String mapUrl,
    required int idSampah,
    // required int idUserPetugas,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Card(
        color: Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 8,
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sampah Liar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              _buildInnerCardSampahLiar(
                // name: name,
                fotoSampah: FotoSampah,
                namaUpt: namaUpt,
                phone: phone,
                email: email,
                status: status,
                description: description,
                mapUrl: mapUrl,
                idSampah: idSampah,
                // idUserPetugas: idUserPetugas,
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
    required String namaUpt,
    required String fotoSampah,
    required String phone,
    required String status,
    required String lokasi,
    required String description,
    required String mapUrl,
    required int idSampah,
    // required int idUserPetugas,
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
              'Nama       : $name',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'UPT          : $namaUpt',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            Row(
              children: [
                Text(
                  'No. Hp     : $phone',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(
                  width: 5,
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final Uri whatsappUrl = Uri.parse("https://wa.me/$phone");
                    launchUrl(whatsappUrl);
                  },
                  icon: const FaIcon(
                    FontAwesomeIcons.whatsapp,
                    color: Colors.white,
                    size: 16, // Smaller icon size
                  ),
                  label: const Text(
                    'Chat via WA',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 7),
                    minimumSize: const Size(30, 30),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Status      : ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                Flexible(
                  child: Container(
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
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Lokasi      : $lokasi',
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
            const SizedBox(height: 8),
            if (fotoSampah.isNotEmpty)
              Image.network(
                'https://jera.kerissumenep.com/storage/foto-sampah/$fotoSampah',
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Gambar tidak dapat ditampilkan');
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
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
                  child: const Text('Buka Map'),
                ),
                const SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildInnerCardSampahLiar({
    required String namaUpt,
    required String fotoSampah,
    required String phone,
    required String status,
    required String email,
    required String description,
    required String mapUrl,
    required int idSampah,
    // required int idUserPetugas,
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
              'Petugas   : $namaUpt',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Text(
                'No. Hp     : $phone',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final Uri whatsappUrl = Uri.parse("https://wa.me/$phone");
                  launchUrl(whatsappUrl);
                },
                icon: const FaIcon(
                  FontAwesomeIcons.whatsapp,
                  color: Colors.white,
                  size: 16, // Smaller icon size
                ),
                label: const Text(
                  'Chat via WA',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 7),
                  minimumSize: const Size(30, 30),
                ),
              )
            ]),
            const SizedBox(height: 8),
            Text(
              'Email       : $email',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            Row(
              children: [
                const Text(
                  'Status      : ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                Flexible(
                  child: Container(
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
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Deskripsi : $description',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            if (fotoSampah.isNotEmpty)
              Image.network(
                'https://jera.kerissumenep.com/storage/foto-sampah/$fotoSampah',
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Gambar tidak dapat ditampilkan');
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
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
                  child: const Text('Buka Map'),
                ),
                const SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openMap(String mapUrl) async {
    final Uri url = Uri.parse(mapUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw Exception('Could not launch $mapUrl');
    }
  }
}
