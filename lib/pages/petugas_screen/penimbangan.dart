import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dlh_project/pages/petugas_screen/home.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
        const SnackBar(content: Text('Gagal memuat data harga barang')),
      );
    }
  }

  void _showPilihBarangDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Pilih Barang'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _hargaBarang.length,
              itemBuilder: (context, index) {
                final barang = _hargaBarang[index];
                return ListTile(
                  title: Text(barang['Nama_Barang']),
                  subtitle: Text('Rp${barang['Harga_Beli']} / kg'),
                  onTap: () {
                    final sudahDipilih = _selectedItems.any((e) => e['ID'] == barang['ID']);
                    if (!sudahDipilih) {
                      setState(() {
                        _selectedItems.add({...barang, 'jumlah': 0.0});
                      });
                    }
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
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

  Future<void> _submitData() async {
    final listString = _selectedItems
        .map((item) => "${item['Nama_Barang']}: ${item['jumlah']}kg")
        .join(", ");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
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
          const SnackBar(content: Text('Data berhasil disimpan')),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePetugasPage(initialIndex: 1)),
          (route) => false,
        );
      } else {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal submit: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Penimbangan"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Barang yang Dipilih:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._selectedItems.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(item['Nama_Barang'])),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'kg'),
                        onChanged: (value) {
                          setState(() {
                            item['jumlah'] = double.tryParse(value) ?? 0.0;
                            _hitungTotalPendapatan();
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: Text(
                                               'Rp${((item['jumlah'] ?? 1.0) * (double.tryParse(item['Harga_Beli'].toString()) ?? 0.0)).toStringAsFixed(0)}',

                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _selectedItems.remove(item);
                          _hitungTotalPendapatan();
                        });
                      },
                    )
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Barang'),
                  onPressed: _showPilihBarangDialog,
                ),
                Text(
                  'Total: Rp${_totalPendapatan.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _selectedItems.isEmpty ? null : _submitData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text(
                  'Simpan Data Penimbangan',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

