import 'package:dlh_project/pages/warga_screen/historySampah.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
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
  int prosesCount = 0;
  int doneCount = 0;
  int pendingCount = 0;
  int failedCount = 0;
  String selectedDateRange = "all"; // atau 'weekly', 'monthly'
  String selectedStatus = "all";
  DateTime? startDate;
  DateTime? endDate;
  bool showSampahData = true;
  int? selectedMonthIndex;
  int selectedYear = DateTime.now().year;

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

  List<SampahData> filteredDataByStatusAndDate = [];

  @override
  void initState() {
    super.initState();
    futureSampahData = fetchSampahData();
    futureSampahData.then((data) {
      _calculateStatusCounts(data);
      _applyFilters(data); // panggil juga langsung setelah fetch
    });
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
                itemDate.isAfter(startDate!.subtract(const Duration(days: 1)))) &&
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
                      color: Colors.blue,
                    ),
                ],
              ),
            ),
          );
        }),
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
    Map<String, int> countPerDate = {};
    for (var item in filteredDataByStatusAndDate) {
      final dateStr = DateFormat('dd-MM-yyyy').format(item
          .tanggalFormatted); // atau item.tanggalFormatted kalau itu DateTime
      countPerDate[dateStr] = (countPerDate[dateStr] ?? 0) + 1;
    }

    final sortedKeys = countPerDate.keys.toList()
      ..sort((a, b) {
        return DateFormat('dd-MM-yyyy')
            .parse(a)
            .compareTo(DateFormat('dd-MM-yyyy').parse(b));
      });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: countPerDate.values.isNotEmpty
                ? (countPerDate.values
                        .reduce((a, b) => a > b ? a : b)
                        .toDouble() +
                    1)
                : 5,
            barGroups: List.generate(sortedKeys.length, (index) {
              final date = sortedKeys[index];
              final count = countPerDate[date]!;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: count.toDouble(),
                    color: Colors.blue,
                    width: 20,
                  )
                ],
              );
            }),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() < sortedKeys.length) {
                      return Text(
                        sortedKeys[value.toInt()].substring(0, 5),
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
              PopupMenuButton<String>(
                onSelected: (String status) {
                  _filterByStatus(status);
                },
                itemBuilder: (BuildContext context) => [
                  _buildPopupMenuItem(
                    'All',
                    prosesCount + doneCount + pendingCount + failedCount,
                    Colors.blue,
                  ),
                  _buildPopupMenuItem('Proses', prosesCount, Colors.yellow),
                  _buildPopupMenuItem('Done', doneCount, Colors.green),
                  _buildPopupMenuItem(
                      'Pending', pendingCount, Colors.orange.shade300),
                  _buildPopupMenuItem('Failed', failedCount, Colors.red),
                ],
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
            _buildStatusChart(),
            _buildStatusSummary(),
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
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'Tidak ada data Riwayat.',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  );
                } else {
                  final rawData = snapshot.data!;
                  final filteredData = rawData.where((data) {
                    final matchesStatus = selectedStatus == 'all' ||
                        data.status.toLowerCase() == selectedStatus;

                    final matchesMonth = selectedMonthIndex == null ||
                        (data.tanggal.month == selectedMonthIndex! + 1 &&
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
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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
                        tanggalFormatted: formattedDate,
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
    required String tanggalFormatted,
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
                tanggalFormatted: tanggalFormatted,
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
    required String tanggalFormatted,
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
            Text('Tanggal: $tanggalFormatted'),
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
