import 'package:dlh_project/pages/petugas_screen/inputFotoSampah.dart';
import 'package:dlh_project/pages/petugas_screen/penimbangan.dart';
import 'package:dlh_project/pages/petugas_screen/sampah.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

Future<List<SampahData>> fetchSampahData() async {
  final prefs = await SharedPreferences.getInstance();
  final uptIdString = prefs.getString('upt_id');
  final uptId = int.tryParse(uptIdString ?? '0');

  if (uptId == 0) {
    throw Exception('User ID not found in SharedPreferences');
  }

  final urls = [
    'https://jera.kerissumenep.com/api/pengangkutan-sampah/history/by-upt/$uptId/pending',
    'https://jera.kerissumenep.com/api/pengangkutan-sampah/history/by-upt/$uptId/proses',
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
        .where((item) => item.status == 'pending' || item.status == 'proses')
        .toList();

    return filteredData;
  } else {
    throw Exception('Failed to load sampah liar data');
  }
}

Future<void> updateStatus(
    int idSampah, int idUserPetugas, String action) async {
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('token');

  final String apiUrl =
      'https://jera.kerissumenep.com/api/pengangkutan-sampah/proses/$idSampah';

  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  final Map<String, dynamic> body = {
    'id_user_petugas': idUserPetugas,
  };

  try {
    // Send the POST request
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      print('Status updated successfully.');
    } else {
      // Handle the error
      final errorMessage =
          jsonDecode(response.body)['message'] ?? 'Unknown error';
      throw Exception('Failed to update status: $errorMessage');
    }
  } catch (e) {
    // Handle any exceptions
    throw Exception('Error updating status: $e');
  }
}

Future<void> updateStatusSampahLiar(
    int idSampah, int idUserPetugas, String action) async {
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('token');

  final String apiUrl =
      'https://jera.kerissumenep.com/api/pengangkutan-sampah-liar/proses/$idSampah';

  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  final Map<String, dynamic> body = {
    'id_user_petugas': idUserPetugas,
  };

  try {
    // Send the POST request
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      print('Status updated successfully.');
    } else {
      // Handle the error
      final errorMessage =
          jsonDecode(response.body)['message'] ?? 'Unknown error';
      throw Exception('Failed to update status: $errorMessage');
    }
  } catch (e) {
    // Handle any exceptions
    throw Exception('Error updating status: $e');
  }
}

Future<void> updateStatusFailed(int idSampah, int idUserPetugas) async {
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('token');

  final String apiUrl =
      'https://jera.kerissumenep.com/api/pengangkutan-sampah/failed/$idSampah';

  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  final Map<String, dynamic> body = {
    'id_user_petugas': idUserPetugas,
  };

  try {
    // Send the POST request
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      print('Status updated successfully.');
    } else {
      // Handle the error
      final errorMessage =
          jsonDecode(response.body)['message'] ?? 'Unknown error';
      throw Exception('Failed to update status: $errorMessage');
    }
  } catch (e) {
    // Handle any exceptions
    throw Exception('Error updating status: $e');
  }
}

Future<void> updateStatusFailedSampahLiar(
    int idSampah, int idUserPetugas) async {
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('token');

  final String apiUrl =
      'https://jera.kerissumenep.com/api/pengangkutan-sampah-liar/failed/$idSampah';

  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  final Map<String, dynamic> body = {
    'id_user_petugas': idUserPetugas,
  };

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      print('Status updated successfully.');
    } else {
      final errorMessage =
          jsonDecode(response.body)['message'] ?? 'Unknown error';
      throw Exception('Failed to update status: $errorMessage');
    }
  } catch (e) {
    throw Exception('Error updating status: $e');
  }
}

class HomeKontenPetugas extends StatefulWidget {
  final String userName;
  final int userId;

  const HomeKontenPetugas({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  _HomeKontenPetugasState createState() => _HomeKontenPetugasState();
}

class _HomeKontenPetugasState extends State<HomeKontenPetugas> {
  late Future<List<SampahData>> futureSampahData;
  bool showSampahData = true;

  @override
  void initState() {
    super.initState();
    futureSampahData = fetchSampahData();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 27, left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: "Selamat Datang, ",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: widget.userName ?? 'Guest',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const TextSpan(
                          text: "!",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                  return const Center(
                      child: Text('Tidak ada data Sampah Terpilah.'));
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
                        case 'pending':
                          statusColor = Colors.orange.shade300;
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
                        idUserPetugas: widget.userId,
                        statusColor: statusColor,
                      );
                    },
                  );
                }
              },
            )
          else
            FutureBuilder<List<SampahLiarData>>(
              future: fetchSampahLiarData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('Tidak ada data sampah liar.'));
                } else {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      SampahLiarData data = snapshot.data![index];
                      Color statusColor;

                      switch (data.status.toLowerCase()) {
                        case 'proses':
                          statusColor = Colors.yellow;
                          break;
                        case 'pending':
                          statusColor = Colors.orange.shade300;
                          break;
                        default:
                          statusColor = Colors.grey;
                      }

                      return _buildOuterCardSampahLiar(
                        // name: data.petugas,
                        namaUpt: data.idKecamatan,
                        FotoSampah: data.fotoSampah,
                        phone: data.noHp,
                        email: data.email,
                        status: data.status,
                        lokasi: data.kordinat,
                        description: data.deskripsi,
                        mapUrl: data.kordinat,
                        idSampah: data.id,
                        idUserPetugas: widget.userId,
                        statusColor: statusColor,
                      );
                    },
                  );
                }
              },
            ),
        ],
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
    required int idUserPetugas,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sampah Terpilah',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _showDeleteConfirmationDialog(
                            context, idSampah, idUserPetugas, status);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        'Batalkan',
                        style: TextStyle(color: Colors.yellow),
                      ),
                    ),
                  ],
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
                idUserPetugas: idUserPetugas,
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
    required String status,
    required String lokasi,
    required String email,
    required String description,
    required String mapUrl,
    required int idSampah,
    required int idUserPetugas,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sampah Liar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        showCancelConfirmationDialog(
                            context, idSampah, idUserPetugas);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.yellow,
                      ),
                      child: const Text(
                        'Batalkan',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildInnerCardSampahLiar(
                fotoSampah: FotoSampah,
                phone: phone,
                status: status,
                description: description,
                mapUrl: mapUrl,
                email: email,
                idSampah: idSampah,
                idUserPetugas: idUserPetugas,
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
    required int idUserPetugas,
    required Color statusColor,
  }) {
    // Determine button text and onPressed function based on status
    String buttonText;
    void Function()? buttonOnPressed;

    if (status.toLowerCase() == 'pending') {
      buttonText = 'Proses';
      buttonOnPressed = () => _showConfirmationDialog(
            context,
            idSampah,
            idUserPetugas,
            'proses',
          );
    } else if (status.toLowerCase() == 'proses') {
      buttonText = 'Done';
      buttonOnPressed = () => _showConfirmationDialog(
            context,
            idSampah,
            idUserPetugas,
            'done',
          );
    } else {
      buttonText = 'Status Unknown';
      buttonOnPressed = null;
    }

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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: ElevatedButton(
                      onPressed: () => _openMap(mapUrl),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text(
                        'Buka Map',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ElevatedButton(
                      onPressed: buttonOnPressed,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        buttonText,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInnerCardSampahLiar({
    // required String name,
    // required String namaUpt,
    required String fotoSampah,
    required String phone,
    required String status,
    required String description,
    required String mapUrl,
    required String email,
    required int idSampah,
    required int idUserPetugas,
    required Color statusColor,
  }) {
    // Determine button text and onPressed function based on status
    String buttonText;
    void Function()? buttonOnPressed;

    if (status.toLowerCase() == 'pending') {
      buttonText = 'Proses';
      buttonOnPressed = () => _showConfirmationDialogSampahLiar(
            context,
            idSampah,
            idUserPetugas,
            'proses',
          );
    } else if (status.toLowerCase() == 'proses') {
      buttonText = 'Done';
      buttonOnPressed = () => _showConfirmationDialogSampahLiar(
            context,
            idSampah,
            idUserPetugas,
            'done',
          );
    } else {
      buttonText = 'Status Unknown';
      buttonOnPressed = null;
    }

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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: ElevatedButton(
                      onPressed: () => _openMap(mapUrl),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text(
                        'Buka Map',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ElevatedButton(
                      onPressed: buttonOnPressed,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        buttonText,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog(
      BuildContext context, int idSampah, int idUserPetugas, String action) {
    String dialogTitle;
    String dialogContent;

    switch (action) {
      case 'proses':
        dialogTitle = 'Konfirmasi Proses';
        dialogContent =
            'Apakah Anda yakin ingin mengupdate status menjadi proses?';
        break;
      case 'done':
        dialogTitle = 'Konfirmasi Done';
        dialogContent =
            'Apakah Anda yakin ingin mengupdate status menjadi done? Pastikan data penimbangan sudah diisi.';
        break;
      default:
        dialogTitle = 'Konfirmasi';
        dialogContent = 'Apakah Anda yakin ingin melanjutkan tindakan ini?';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(dialogTitle),
          content: Text(dialogContent),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Ya'),
              onPressed: () async {
                Navigator.of(context).pop();

                if (action == 'done') {
                  // Navigate to Penimbangan screen
                  bool isDataFilled = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Penimbangan(idSampah: idSampah),
                    ),
                  );

                  if (!isDataFilled) {
                    // Show a message if data is not filled
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Silakan isi data penimbangan terlebih dahulu.'),
                      ),
                    );
                    return;
                  }
                }

                // Show a loading snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Memproses pembaruan status...'),
                  ),
                );

                try {
                  // Perform the status update based on action
                  if (action == 'proses') {
                    await updateStatus(idSampah, idUserPetugas, 'proses');
                  } else if (action == 'done') {
                    await updateStatus(idSampah, idUserPetugas, 'done');
                  }

                  // Show success snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Status berhasil diperbarui'),
                    ),
                  );

                  // Refresh data after status update
                  setState(() {
                    futureSampahData = fetchSampahData();
                  });
                } catch (e) {
                  // Show error snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal memperbarui status: $e'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialogSampahLiar(
      BuildContext context, int idSampah, int idUserPetugas, String action) {
    String dialogTitle;
    String dialogContent;

    switch (action) {
      case 'proses':
        dialogTitle = 'Konfirmasi Proses';
        dialogContent =
            'Apakah Anda yakin ingin mengupdate status menjadi proses?';
        break;
      case 'done':
        dialogTitle = 'Konfirmasi Done';
        dialogContent =
            'Apakah Anda yakin ingin mengupdate status menjadi done? Pastikan sudah isi foto sampah. ';
        break;
      default:
        dialogTitle = 'Konfirmasi';
        dialogContent = 'Apakah Anda yakin ingin melanjutkan tindakan ini?';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(dialogTitle),
          content: Text(dialogContent),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Ya'),
              onPressed: () async {
                Navigator.of(context).pop();

                if (action == 'done') {
                  // Navigate to Penimbangan screen
                  bool isDataFilled = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InputFotoSampah(idSampah: idSampah),
                    ),
                  );

                  if (!isDataFilled) {
                    // Show a message if data is not filled
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Silakan isi foto terlebih dahulu.'),
                      ),
                    );
                    return;
                  }
                }

                // Show a loading snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Memproses pembaruan status...'),
                  ),
                );

                try {
                  // Perform the status update based on action
                  if (action == 'proses') {
                    await updateStatusSampahLiar(
                        idSampah, idUserPetugas, 'proses');
                  } else if (action == 'done') {
                    await updateStatusSampahLiar(
                        idSampah, idUserPetugas, 'done');
                  }

                  // Show success snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Status berhasil diperbarui'),
                    ),
                  );

                  // Refresh data after status update
                  setState(() {
                    futureSampahData = fetchSampahData();
                  });
                } catch (e) {
                  // Show error snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal memperbarui status: $e'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _openMap(String mapUrl) async {
    final Uri url = Uri.parse(mapUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch map: $mapUrl')),
      );
    }
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, int idSampah, int idUserPetugas, String status) {
    if (status.toLowerCase() == 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal dibatalkan: Status harus proses!'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Batalkan'),
          content: const Text(
              'Apakah Anda yakin ingin batalkan permohonan sampah ini?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Tidak'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            ElevatedButton(
              child: const Text(
                'Benar',
              ),
              onPressed: () async {
                try {
                  await updateStatusFailed(idSampah, idUserPetugas);

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Memproses pembaruan status...'),
                    ),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data berhasil di Dibatalkan!'),
                      ),
                    );
                  }

                  // Refresh data after status update
                  setState(() {
                    futureSampahData = fetchSampahData();
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Update status failed: $e'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void showCancelConfirmationDialog(
      BuildContext context, int idSampah, int idUserPetugas) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Batalkan'),
          content: const Text(
              'Apakah Anda yakin ingin batalkan permohonan sampah ini?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Tidak'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            ElevatedButton(
              child: const Text(
                'Benar',
              ),
              onPressed: () async {
                Navigator.of(context)
                    .pop(); // Close the dialog before async call

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Memproses pembaruan status...'),
                  ),
                );

                try {
                  await updateStatusFailedSampahLiar(idSampah, idUserPetugas);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data berhasil dibatalkan!'),
                      ),
                    );

                    // Refresh data after status update
                    setState(() {
                      futureSampahData = fetchSampahData();
                    });
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Update status failed: $e'),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
