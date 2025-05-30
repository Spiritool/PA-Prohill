import 'package:flutter/material.dart';

class SopPetugasPage extends StatelessWidget {
  const SopPetugasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SOP Petugas Pengangkut Sampah',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sopCard(
            icon: Icons.flag,
            title: '1. Tujuan',
            content:
                'Memberikan panduan operasional kepada petugas dalam menjalankan tugas pengangkutan sampah secara tertib, efisien, dan aman.',
          ),
          _sopCard(
            icon: Icons.public,
            title: '2. Ruang Lingkup',
            content:
                'SOP ini berlaku untuk seluruh petugas pengangkut sampah di wilayah kerja yang telah ditentukan, khusus untuk sampah daur ulang dan sampah liar.',
          ),
          _procedureCard(),
          _sopCard(
            icon: Icons.health_and_safety,
            title: '4. Keselamatan Kerja',
            content: '',
            bullets: [
              'Selalu gunakan APD.',
              'Hindari kontak langsung dengan limbah berbahaya.',
              'Jangan mengangkat beban berlebih sendirian.',
              'Laporkan kecelakaan ke koordinator.',
            ],
          ),
          _sopCard(
            icon: Icons.task_alt,
            title: '5. Tanggung Jawab',
            bullets: [
              'Menjalankan tugas sesuai SOP dan jadwal.',
              'Menjaga kebersihan, ketertiban, dan keamanan.',
              'Bertanggung jawab atas kendaraan dan peralatan.',
            ],
          ),
          _sopCard(
            icon: Icons.warning,
            title: '6. Sanksi Pelanggaran',
            bullets: [
              'Teguran Lisan/Tertulis.',
              'Pengurangan Poin Keaktifan.',
              'Penangguhan Tugas.',
              'Pemutusan Kerja untuk pelanggaran berat.',
            ],
          ),
          _sopCard(
            icon: Icons.phone_in_talk,
            title: '7. Kontak Darurat',
            bullets: [
              'Koordinator Lapangan: 0812-3456-7890',
              'Admin Aplikasi: 0821-1234-5678',
              'PMI/Ambulans: 119',
            ],
          ),
        ],
      ),
    );
  }

  Widget _sopCard({
    required IconData icon,
    required String title,
    String? content,
    List<String>? bullets,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
          if (content != null && content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 15)),
          ],
          if (bullets != null && bullets.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...bullets.map((text) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("• ", style: TextStyle(fontSize: 15)),
                      Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
                    ],
                  ),
                )),
          ]
        ],
      ),
    );
  }

  Widget _procedureCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text(
                '3. Prosedur Umum',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _subProcedure(Icons.construction, 'A. Persiapan Sebelum Bertugas', [
            'Memastikan kendaraan dalam kondisi baik dan bahan bakar cukup.',
            'Mengenakan seragam kerja dan APD: rompi, sepatu boots, sarung tangan, dan masker.',
            'Mengecek jadwal dan rute dari aplikasi petugas.',
            'Membawa alat komunikasi aktif seperti ponsel.',
          ]),
          _subProcedure(Icons.route, 'B. Saat Bertugas', [
            'Mengikuti rute yang ditentukan oleh sistem.',
            'Mengambil dan memproses sampah sesuai kategori:',
            '♻️ Sampah Daur Ulang: Dipilah dan dicatat total berat sampahnya.',
            '⚠️ Sampah Liar: Dokumentasi → pembersihan → upload bukti ke sistem.',
            'Menjaga etika saat berinteraksi dengan warga.',
            'Tidak menerima atau meminta imbalan dari warga.',
            'Melaporkan kendala di lapangan melalui aplikasi.',
          ]),
          _subProcedure(Icons.done_all, 'C. Setelah Bertugas', [
            'Mengantar sampah ke TPA sesuai jenisnya.',
            'Melaporkan status tugas via aplikasi.',
            'Membersihkan dan memeriksa kendaraan.',
            'Logout dari aplikasi jika tugas selesai.',
          ]),
        ],
      ),
    );
  }

  Widget _subProcedure(IconData icon, String title, List<String> bullets) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(thickness: 1),
          Row(
            children: [
              Icon(icon, color: Colors.green[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...bullets.map((text) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ", style: TextStyle(fontSize: 15)),
                    Expanded(
                        child: Text(text, style: const TextStyle(fontSize: 15))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
