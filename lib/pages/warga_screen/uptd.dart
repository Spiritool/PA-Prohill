import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Uptd extends StatefulWidget {
  const Uptd({super.key});

  @override
  _UptdState createState() => _UptdState();
}

class _UptdState extends State<Uptd> {
  final String baseUrl = "https://jera.kerissumenep.com/api/kecamatan";
  late Future<List<Map<String, dynamic>>> _kecamatanData;

  @override
  void initState() {
    super.initState();
    _kecamatanData = fetchKecamatanData();
  }

  Future<List<Map<String, dynamic>>> fetchKecamatanData() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'].map((item) => {
              'id': item['id'],
              'nama_kecamatan': item['nama_kecamatan'],
              'upt': item['upt']['nama_upt'],
            }));
      } else {
        throw Exception('Failed to load kecamatan data');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 57, 87, 254),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Text(
          'Daftar Wilayah\nUPTD/TPS',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, List<String> items) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            for (var item in items)
              Text(
                item,
                style: const TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> kecamatanList) {
    Map<String, List<String>> groupedKecamatan = {};

    for (var kecamatan in kecamatanList) {
      final upt = kecamatan['upt'];
      final namaKecamatan = kecamatan['nama_kecamatan'];

      if (!groupedKecamatan.containsKey(upt)) {
        groupedKecamatan[upt] = [];
      }

      groupedKecamatan[upt]!.add(namaKecamatan);
    }

    return ListView.builder(
      itemCount: groupedKecamatan.length,
      itemBuilder: (context, index) {
        final upt = groupedKecamatan.keys.elementAt(index);
        final kecamatanNames = groupedKecamatan[upt]!;
        return _buildCard(upt, kecamatanNames);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'UPTD/TPS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _kecamatanData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No data available'));
                  }

                  return _buildListView(snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
