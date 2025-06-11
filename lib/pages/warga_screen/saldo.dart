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

  // Hanya mengambil data dengan status "done"
  final response = await http.get(
      Uri.parse('$baseipapi/api/pengangkutan-sampah/history/$userId/done'));

  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body)['data'];
    List<SampahData> sampahDataList =
        data.map((item) => SampahData.fromJson(item)).toList();

    // Balikkan daftar agar data terbaru tampil di atas
    sampahDataList.sort((a, b) => b.id.compareTo(a.id));

    return sampahDataList;
  } else {
    throw Exception('Failed to load data');
  }
}

Future<double> fetchUserBalance() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id') ?? 0;
  final localSaldo = prefs.getInt('saldo');

  if (userId == 0) {
    throw Exception('User ID not found in SharedPreferences');
  }

  if (localSaldo != null) {
    print('Returning local saldo: $localSaldo');
    return localSaldo.toDouble();
  }

  try {
    final url = '$baseipapi/penarikan/$userId';
    print('Fetching saldo from: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Parsed balance data: $data');

      double safeToDouble(dynamic value) {
        if (value == null) return 0.0;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) {
          try {
            return double.parse(value);
          } catch (_) {
            return 0.0;
          }
        }
        return 0.0;
      }

      double totalBalance =
          data.containsKey('balance') ? safeToDouble(data['balance']) : 0.0;
      return totalBalance;
    } else {
      throw Exception('Failed to fetch balance: ${response.body}');
    }
  } catch (e) {
    print('Error fetching user balance: $e');
    rethrow;
  }
}

Future<bool> tarikSaldo(double jumlah, String metodePenarikan) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id') ?? 0;

  if (userId == 0) {
    throw Exception('User ID not found in SharedPreferences');
  }

  try {
    final url = '$baseipapi/api/tarik-saldo';
    final payload = {
      'user_id': userId,
      'jumlah': jumlah,
      'metode_penarikan': metodePenarikan,
    };

    print('Posting tarik saldo to: $url');
    print('Payload: $payload');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: jsonEncode(payload),
    );

    print('Tarik saldo response status: ${response.statusCode}');
    print('Tarik saldo response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      print('Parsed response: $responseData');
      return responseData['success'] ?? true;
    } else {
      final errorData = jsonDecode(response.body);
      print('Tarik saldo error: $errorData');
      throw Exception(
          errorData['message'] ?? 'Gagal melakukan penarikan saldo');
    }
  } catch (e) {
    print('Exception during tarikSaldo: $e');
    rethrow;
  }
}

Future<List<Map<String, dynamic>>> fetchPenarikanData() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id') ?? 0;

  if (userId == 0) {
    throw Exception('User ID not found in SharedPreferences');
  }

  final url = '$baseipapi/api/penarikan/$userId';
  print('Fetching penarikan data from: $url');

  final response = await http.get(Uri.parse(url));

  print('Penarikan data response status: ${response.statusCode}');
  print('Penarikan data response body: ${response.body}');

  if (response.statusCode == 200) {
    try {
      final jsonData = jsonDecode(response.body);
      final dataList = jsonData['data'] as List;
      return dataList
          .map<Map<String, dynamic>>((item) => item as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error parsing penarikan data: $e');
      rethrow;
    }
  } else {
    throw Exception('Failed to load penarikan history: ${response.body}');
  }
}

Set<int> expandedCards = {};

class SaldoSampahScreen extends StatefulWidget {
  const SaldoSampahScreen({super.key});

  @override
  _SaldoSampahScreenState createState() => _SaldoSampahScreenState();
}

class _SaldoSampahScreenState extends State<SaldoSampahScreen> {
  late Future<List<SampahData>> futureSampahData;
  late Future<double> futureUserBalance;
  late Future<List<Map<String, dynamic>>> futurePenarikanHistory;

  Set<int> expandedCards = <int>{};
  int selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    futureSampahData = fetchSampahData();
    futureUserBalance = fetchUserBalance();
    futurePenarikanHistory = fetchPenarikanData();
  }

  // Format currency untuk menampilkan saldo
  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  void _showTarikSaldoDialog() {
    final TextEditingController jumlahController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Color(0xFFFF6600),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tarik Saldo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Saldo saat ini
                  FutureBuilder<double>(
                    future: futureUserBalance,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFFFF6600).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.wallet,
                                color: Color(0xFFFF6600),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Saldo Tersedia: ${formatCurrency(snapshot.data!)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFF6600),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                  SizedBox(height: 16),

                  // Input jumlah
                  Text(
                    'Jumlah Penarikan',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: jumlahController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Masukkan jumlah (min. Rp 50.000)',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFFFF6600)),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final jumlahText = jumlahController.text.trim();
                    if (jumlahText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Masukkan jumlah penarikan'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final jumlah = double.tryParse(jumlahText);
                    if (jumlah == null || jumlah < 50000) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Jumlah minimum penarikan adalah Rp 50.000'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Cek saldo tersedia
                    try {
                      final currentBalance = await fetchUserBalance();
                      if (jumlah > currentBalance) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Saldo tidak mencukupi'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      Navigator.of(context).pop();

                      // Show loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFFF6600),
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                  Text('Memproses penarikan...'),
                                ],
                              ),
                            ),
                          );
                        },
                      );

                      // Proses penarikan (tanpa metode penarikan)
                      final success = await tarikSaldo(jumlah, 'Default');

                      // Close loading dialog
                      Navigator.of(context).pop();

                      if (success) {
                        // Refresh balance
                        _refreshBalance();

                        // Show success dialog
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 64,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Penarikan Berhasil!',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Penarikan sebesar ${formatCurrency(jumlah)} telah diproses.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              actions: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFFF6600),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'OK',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    } catch (e) {
                      // Close loading dialog if open
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop();
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF6600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Tarik Saldo',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _refreshBalance() {
    setState(() {
      futureUserBalance = fetchUserBalance();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Saldo Sampah',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Color(0xFFFF6600),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header dengan gradient - tetap sama
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6600), Color(0xFFFF8533)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  // Main Balance Card - tetap sama
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    padding: EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Saldo Anda',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                FutureBuilder<double>(
                                  future: futureUserBalance,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Text(
                                        'Loading...',
                                        style: TextStyle(
                                          color: Color(0xFFFF6600),
                                          fontSize: 42,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    } else if (snapshot.hasError) {
                                      return Text(
                                        'Kosong',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 42,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    } else {
                                      final balance = snapshot.data ?? 0.0;
                                      return Text(
                                        formatCurrency(balance),
                                        style: TextStyle(
                                          color: Color(0xFFFF6600),
                                          fontSize: 42,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Color(0xFFFF6600).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet,
                                color: Color(0xFFFF6600),
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),

            // Tab Section - BAGIAN BARU
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Tab Header
                  SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedTabIndex = 0;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedTabIndex == 0
                                    ? Color(0xFFFF6600)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Transaksi Selesai',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: selectedTabIndex == 0
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedTabIndex = 1;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedTabIndex == 1
                                    ? Color(0xFFFF6600)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Riwayat Penarikan',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: selectedTabIndex == 1
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Tab Content
                  if (selectedTabIndex == 0)
                    _buildTransaksiSelesaiTab()
                  else
                    _buildRiwayatPenarikanTab(),

                  SizedBox(height: 30),

                  // Withdraw Button - tetap sama
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showTarikSaldoDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF6600),
                        padding: EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        shadowColor: Color(0xFFFF6600).withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Tarik Saldo',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk tab Transaksi Selesai
  Widget _buildTransaksiSelesaiTab() {
    return FutureBuilder<List<SampahData>>(
      future: futureSampahData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
            child: const Center(
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
                        color: Color.fromARGB(255, 190, 185, 181)),
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Container(
            height: 100,
            child: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 100,
            child: const Center(
              child: Text(
                'Tidak ada transaksi yang selesai.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          );
        } else {
          final data = snapshot.data!;
          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: data.length,
            itemBuilder: (context, index) {
              SampahData sampahData = data[index];
              String formattedDate =
                  DateFormat('dd-MM-yyyy').format(sampahData.tanggal);
              Color statusColor = Colors.green;
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
                child: _buildTransactionCard(
                  name: sampahData.nama,
                  phone: sampahData.noHp,
                  fotoSampah: sampahData.fotoSampah,
                  status: sampahData.status,
                  namaUpt: sampahData.namaUpt,
                  location:
                      '${sampahData.alamat.kelurahan}, ${sampahData.alamat.kecamatan}, ${sampahData.alamat.deskripsi}',
                  description: sampahData.deskripsi,
                  mapUrl: sampahData.alamat.kordinat,
                  idSampah: sampahData.id,
                  idpetugas: sampahData.id_user_petugas,
                  statusColor: statusColor,
                  tanggalFormatted: formattedDate,
                  ratingPetugas: sampahData.ratingPetugas,
                  catatanPetugas: sampahData.catatanPetugas,
                  pendapatan: sampahData.pendapatan ?? 0.0,
                  isExpanded: isExpanded,
                ),
              );
            },
          );
        }
      },
    );
  }

  // Widget untuk tab Riwayat Penarikan
  Widget _buildRiwayatPenarikanTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: futurePenarikanHistory,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
            child: const Center(
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
                    'Memuat riwayat penarikan...',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 190, 185, 181)),
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Container(
            height: 100,
            child: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 100,
            child: const Center(
              child: Text(
                'Tidak ada riwayat penarikan.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          );
        } else {
          final penarikanList = snapshot.data!;
          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: penarikanList.length,
            itemBuilder: (context, index) {
              final item = penarikanList[index];
              final jumlah = item['jumlah']?.toString() ?? '0';
              final created_at = item['created_at'] ?? '';
              final metode = item['metode_penarikan'] ?? 'Tidak diketahui';

              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF6600).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.monetization_on,
                        color: Color(0xFFFF6600),
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rp $jumlah',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tanggal: $created_at',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Selesai',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildTransactionCard({
    required String name,
    required String phone,
    required String fotoSampah,
    required String status,
    required String namaUpt,
    required String location,
    required String description,
    required String mapUrl,
    required int idSampah,
    required int idpetugas,
    required Color statusColor,
    required String tanggalFormatted,
    required double? ratingPetugas,
    required String? catatanPetugas,
    required double pendapatan,
    required bool isExpanded,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
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

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet, // Wallet icon
                      size: 20,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Rp ${pendapatan.toStringAsFixed(0)}', // Format angka tanpa desimal
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ),
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
                    'done',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
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
            // Location button
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
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
