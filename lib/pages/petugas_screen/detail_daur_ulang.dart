import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'sampah.dart'; // Import model SampahData

class DetailSampahDaurUlangPage extends StatelessWidget {
  final SampahData sampah;

  const DetailSampahDaurUlangPage({super.key, required this.sampah});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Sampah Daur Ulang')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nama: ${sampah.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Deskripsi: ${sampah.deskripsi}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Tanggal: ${DateFormat('dd-MM-yyyy').format(sampah.tanggal)}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text("Bukti:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            // _buildTabelBukti(sampah.bukti),
          ],
        ),
      ),
    );
  }

  Widget _buildTabelBukti(List<String> bukti) {
    return Table(
      border: TableBorder.all(),
      columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(3)},
      children: [
        const TableRow(children: [
          Padding(padding: EdgeInsets.all(8), child: Text("No.", style: TextStyle(fontWeight: FontWeight.bold))),
          Padding(padding: EdgeInsets.all(8), child: Text("Keterangan", style: TextStyle(fontWeight: FontWeight.bold))),
        ]),
        ...bukti.asMap().entries.map((entry) => TableRow(children: [
              Padding(padding: const EdgeInsets.all(8), child: Text("${entry.key + 1}")),
              Padding(padding: const EdgeInsets.all(8), child: Text(entry.value)),
            ]))
      ],
    );
  }
}
