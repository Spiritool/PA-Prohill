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

Future<List<SampahData>> fetchSampahData() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id') ?? 0;

  if (userId == 0) {
    throw Exception('User ID not found in SharedPreferences');
  }

  final urls = [
    '$baseipapi/api/pengangkutan-sampah/history/$userId/proses',
    '$baseipapi/api/pengangkutan-sampah/history/$userId/done',
    '$baseipapi/api/pengangkutan-sampah/history/$userId/pending',
    '$baseipapi/api/pengangkutan-sampah/history/$userId/failed',
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

class PointScreen extends StatefulWidget {
  const PointScreen({super.key});

  @override
  _PointScreenState createState() => _PointScreenState();
}

class _PointScreenState extends State<PointScreen> {
  late Future<List<SampahData>> futureSampahData;
  DateTime? startDate;
  DateTime? endDate;
  bool showSampahData = true;
  bool isMyPointActive = true; // dipindah ke sini
  Set<int> expandedCards = {};

  @override
  void initState() {
    super.initState();
    futureSampahData = fetchSampahData();
  }

  final List<Map<String, dynamic>> redeemItems = [
    {
      'image': 'https://picsum.photos/200/150?random=1',
      'title': 'Hotlink Unlimited',
      'point': 10,
    },
    {
      'image': 'https://picsum.photos/200/150?random=2',
      'title': 'Free Coffee Voucher',
      'point': 20,
    },
  ];

  Future<void> _openMap(String mapUrl) async {
    final Uri mapUri = Uri.parse(mapUrl);
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri);
    } else {
      throw 'Could not launch $mapUrl';
    }
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
          child: Icon(
            Icons.chevron_left,
            color: Colors.black,
            size: 30,
          ),
        ),
        title: Text(
          'Point',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFF2F2F2),
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
                        padding: EdgeInsets.symmetric(vertical: 12),
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
                        padding: EdgeInsets.symmetric(vertical: 12),
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
              duration: Duration(milliseconds: 300),
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
          color: Color(0xFFF9F9F9),
          margin: EdgeInsets.only(top: 10),
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Column(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Image.asset('assets/icons/money 4.png'),
              ),
              SizedBox(height: 10),
              Text('Total Point',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              SizedBox(height: 4),
              Text('1',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(
            'My History',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
          ),
        ),
        // Bagian bawah: putih, penuh sisa layar
        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                // Spacer kecil jika perlu
                const SizedBox(height: 8),

                // Bagian daftar yang scroll
                Expanded(
                  child: FutureBuilder<List<SampahData>>(
                    future: futureSampahData,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
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

                      final filteredData = snapshot.data!; // tanpa filter

                      if (filteredData.isEmpty) {
                        return const Center(
                            child: Text('Tidak ada data Riwayat.'));
                      }

                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: filteredData.length,
                        itemBuilder: (context, index) {
                          SampahData data = filteredData[index];
                          Color statusColor;
                          String formattedDate =
                              DateFormat('dd-MM-yyyy').format(data.tanggal);

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
                            child: _buildOuterCard(
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
                              ratingPetugas: data.ratingPetugas,
                              catatanPetugas: data.catatanPetugas,
                              isExpanded: isExpanded,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
    required String description,
    required String mapUrl,
    required int idSampah,
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
        description: description,
        mapUrl: mapUrl,
        idSampah: idSampah,
        statusColor: statusColor,
        tanggalFormatted: tanggalFormatted,
        ratingPetugas: ratingPetugas,
        catatanPetugas: catatanPetugas,
        isExpanded: isExpanded, // teruskan ke inner card juga
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
                      '⭐ Waste & get Point',
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
                        const Text(
                          '1', // <- nanti bisa diganti dinamis kalau mau
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (status == 'done' && ratingPetugas == null)
                      ElevatedButton(
                        onPressed: () {
                          // Tampilkan dialog rating
                        },
                        child: const Text('Rating Petugas'),
                      ),
                    if (status == 'done' && ratingPetugas != null)
                      Text('Rating: $ratingPetugas ⭐️'),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRedeemSection() {
    if (redeemItems.isEmpty) {
      return Center(
        child: Text(
          'No redeem',
          style: TextStyle(
              fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: redeemItems.length,
      itemBuilder: (context, index) {
        final item = redeemItems[index];
        return Container(
          margin: EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(item['image'],
                    fit: BoxFit.cover, width: double.infinity, height: 200),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'] ?? 'Promo Title',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Point Needed: ',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                        Image.asset('assets/icons/money 4.png',
                            width: 20, height: 20),
                        SizedBox(width: 6),
                        Text('${item['point']}',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
