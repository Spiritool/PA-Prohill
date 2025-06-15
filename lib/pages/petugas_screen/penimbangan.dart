import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dlh_project/pages/petugas_screen/home.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

class Penimbangan extends StatefulWidget {
  final int idSampah;

  const Penimbangan({super.key, required this.idSampah});

  @override
  _PenimbanganState createState() => _PenimbanganState();
}

class _PenimbanganState extends State<Penimbangan> {
  List<dynamic> _hargaBarang = [];
  List<Map<String, dynamic>> _selectedItems = [];
  double _totalPendapatan = 0.0;
  
  // Format rupiah
  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchHargaBarang();
  }

  Future<void> _fetchHargaBarang() async {
    final response = await http.get(Uri.parse('$baseipapi/api/harga-barang'));
    if (response.statusCode == 200) {
      setState(() {
        _hargaBarang = jsonDecode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal memuat data harga barang'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  void _showPilihBarangDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Pilih Barang',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _hargaBarang.length,
              itemBuilder: (context, index) {
                final barang = _hargaBarang[index];
                final sudahDipilih = _selectedItems.any((e) => e['ID'] == barang['ID']);
                
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: sudahDipilih ? Colors.green : Colors.deepOrange,
                      child: Icon(
                        sudahDipilih ? Icons.check : Icons.inventory_2,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      barang['Nama_Barang'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: sudahDipilih ? Colors.grey : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      '${currencyFormat.format(double.tryParse(barang['Harga_Beli'].toString()) ?? 0)} / kg',
                      style: TextStyle(
                        color: Colors.deepOrange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(
                      sudahDipilih ? Icons.check_circle : Icons.add_circle_outline,
                      color: sudahDipilih ? Colors.green : Colors.deepOrange,
                    ),
                    onTap: sudahDipilih ? null : () {
                      setState(() {
                        _selectedItems.add({...barang, 'jumlah': 0.0});
                      });
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Tutup',
                style: TextStyle(color: Colors.deepOrange.shade700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _hitungTotalPendapatan() {
    double total = 0.0;
    for (var item in _selectedItems) {
      total += item['jumlah'] * (double.tryParse(item['Harga_Beli'].toString()) ?? 0.0);
    }
    setState(() {
      _totalPendapatan = total;
    });
  }

  // Validasi apakah semua item memiliki berat yang valid
  bool _validateWeights() {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih minimal satu barang untuk ditimbang'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    List<String> invalidItems = [];
    for (var item in _selectedItems) {
      double weight = item['jumlah'] ?? 0.0;
      if (weight <= 0) {
        invalidItems.add(item['Nama_Barang']);
      }
    }

    if (invalidItems.isNotEmpty) {
      String itemNames = invalidItems.length > 1 
        ? invalidItems.take(invalidItems.length - 1).join(', ') + ' dan ' + invalidItems.last
        : invalidItems.first;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Harap masukkan berat yang valid untuk: $itemNames'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _submitData() async {
    // Validasi terlebih dahulu
    if (!_validateWeights()) {
      return;
    }

    final listString = _selectedItems
        .map((item) => "${item['Nama_Barang']}: ${item['jumlah']}kg")
        .join(", ");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
            ),
            const SizedBox(height: 16),
            const Text('Menyimpan data...'),
          ],
        ),
      ),
    );

    try {
      final response = await http.post(
        Uri.parse('$baseipapi/api/pengangkutan-sampah/penimbangan-sampah/${widget.idSampah}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'list': listString,
          'pendapatan': _totalPendapatan,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.of(context, rootNavigator: true).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data berhasil disimpan'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePetugasPage(initialIndex: 1)),
          (route) => false,
        );
      } else {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal submit: ${response.reasonPhrase}'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Fungsi untuk mengecek apakah tombol submit bisa ditekan
  bool _canSubmit() {
    if (_selectedItems.isEmpty) return false;
    
    for (var item in _selectedItems) {
      double weight = item['jumlah'] ?? 0.0;
      if (weight <= 0) return false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Data Penimbangan",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepOrange.shade400, Colors.deepOrange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.scale,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Total Pendapatan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(_totalPendapatan),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Items Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Barang Terpilih',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Tambah Barang'),
                  onPressed: _showPilihBarangDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Selected Items List
            if (_selectedItems.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada barang yang dipilih',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap "Tambah Barang" untuk memulai',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._selectedItems.map((item) {
                final hargaPerKg = double.tryParse(item['Harga_Beli'].toString()) ?? 0.0;
                final jumlah = item['jumlah'] ?? 0.0;
                final total = jumlah * hargaPerKg;
                final hasValidWeight = jumlah > 0;
                
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: !hasValidWeight ? BorderSide(color: Colors.orange.shade300, width: 1) : BorderSide.none,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item['Nama_Barang'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (!hasValidWeight)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange.shade300),
                                ),
                                child: Text(
                                  'Belum diinput',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _selectedItems.remove(item);
                                  _hitungTotalPendapatan();
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Harga: ${currencyFormat.format(hargaPerKg)} / kg',
                          style: TextStyle(
                            color: Colors.deepOrange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Berat (kg)',
                                  labelStyle: TextStyle(
                                    color: !hasValidWeight ? Colors.orange.shade700 : Colors.deepOrange.shade700,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: !hasValidWeight ? Colors.orange.shade300 : Colors.grey.shade400,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: !hasValidWeight ? Colors.orange.shade700 : Colors.deepOrange.shade700,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.orange.shade700, width: 1),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  hintText: 'Masukkan berat',
                                  hintStyle: TextStyle(color: Colors.grey.shade500),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    item['jumlah'] = double.tryParse(value) ?? 0.0;
                                    _hitungTotalPendapatan();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: hasValidWeight ? Colors.deepOrange.shade50 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: hasValidWeight ? Colors.deepOrange.shade200 : Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Subtotal',
                                      style: TextStyle(
                                        color: hasValidWeight ? Colors.deepOrange.shade700 : Colors.grey.shade600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format(total),
                                      style: TextStyle(
                                        color: hasValidWeight ? Colors.deepOrange.shade800 : Colors.grey.shade700,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
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
              }).toList(),
            
            const SizedBox(height: 24),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit() ? _submitData : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSubmit() ? Colors.deepOrange : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _canSubmit() ? 3 : 0,
                ),
                child: Text(
                  _selectedItems.isEmpty 
                    ? 'Pilih Barang Terlebih Dahulu'
                    : !_canSubmit() 
                      ? 'Lengkapi Berat Semua Barang'
                      : 'Simpan Data Penimbangan',
                  style: const TextStyle(
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
  }
}