import 'package:flutter/material.dart';

class SopPetugasPage extends StatelessWidget {
  const SopPetugasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'SOP Petugas Lapangan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Header Section
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFF6B35),
                    const Color(0xFFFF6B35).withOpacity(0.1),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.assignment_outlined,
                              color: Color(0xFFFF6B35),
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 15),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Standar Operasional',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Panduan lengkap tugas lapangan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF7F8C8D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Content Section
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _modernSopCard(
                  icon: Icons.flag_outlined,
                  title: 'Tujuan',
                  content: 'Memberikan panduan operasional kepada petugas dalam menjalankan tugas pengangkutan sampah secara tertib, efisien, dan aman.',
                  color: const Color(0xFF3498DB),
                ),
                
                _modernSopCard(
                  icon: Icons.public_outlined,
                  title: 'Ruang Lingkup',
                  content: 'SOP ini berlaku untuk seluruh petugas pengangkut sampah di wilayah kerja yang telah ditentukan, khusus untuk sampah daur ulang dan sampah liar.',
                  color: const Color(0xFF9B59B6),
                ),
                
                _modernProcedureCard(),
                
                _modernSopCard(
                  icon: Icons.health_and_safety_outlined,
                  title: 'Keselamatan Kerja',
                  bullets: [
                    'Selalu gunakan APD lengkap (rompi, sepatu boots, sarung tangan, masker)',
                    'Hindari kontak langsung dengan limbah berbahaya atau tajam',
                    'Jangan mengangkat beban berlebih sendirian, minta bantuan',
                    'Laporkan segera kecelakaan kerja ke koordinator lapangan',
                    'Pastikan kendaraan dalam kondisi layak sebelum beroperasi',
                  ],
                  color: const Color(0xFFE74C3C),
                ),
                
                _modernSopCard(
                  icon: Icons.task_alt_outlined,
                  title: 'Tanggung Jawab Petugas',
                  bullets: [
                    'Menjalankan tugas sesuai SOP dan jadwal yang ditentukan',
                    'Menjaga kebersihan, ketertiban, dan keamanan lingkungan kerja',
                    'Bertanggung jawab penuh atas kendaraan dan peralatan kerja',
                    'Melaporkan status tugas secara real-time melalui aplikasi',
                    'Memberikan pelayanan terbaik kepada masyarakat',
                  ],
                  color: const Color(0xFF27AE60),
                ),
                
                _modernSopCard(
                  icon: Icons.warning_amber_outlined,
                  title: 'Sanksi Pelanggaran',
                  bullets: [
                    'Pelanggaran Ringan: Teguran lisan dan pembinaan',
                    'Pelanggaran Sedang: Teguran tertulis dan pengurangan poin',
                    'Pelanggaran Berat: Penangguhan tugas sementara',
                    'Pelanggaran Sangat Berat: Pemutusan kontrak kerja',
                  ],
                  color: const Color(0xFFF39C12),
                ),
                
                _emergencyContactCard(),
                
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernSopCard({
    required IconData icon,
    required String title,
    String? content,
    List<String>? bullets,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (content != null && content.isNotEmpty) ...[
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
                if (bullets != null && bullets.isNotEmpty) ...[
                  ...bullets.asMap().entries.map((entry) {
                    int index = entry.key;
                    String text = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              text,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernProcedureCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF27AE60).withOpacity(0.1),
                  const Color(0xFF2ECC71).withOpacity(0.1),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu_book_outlined,
                    color: Color(0xFF27AE60),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Text(
                    'Prosedur Operasional',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF27AE60),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _modernSubProcedure(
                  Icons.construction_outlined,
                  'Persiapan Sebelum Bertugas',
                  [
                    'Cek kondisi kendaraan (mesin, ban, bahan bakar)',
                    'Kenakan seragam kerja dan APD lengkap',
                    'Review jadwal dan rute melalui aplikasi',
                    'Pastikan alat komunikasi dalam kondisi aktif',
                    'Siapkan peralatan kerja yang diperlukan',
                  ],
                  const Color(0xFF3498DB),
                ),
                
                _modernSubProcedure(
                  Icons.route_outlined,
                  'Pelaksanaan Tugas',
                  [
                    'Ikuti rute yang telah ditentukan sistem',
                    'Proses sampah daur ulang: pilah → timbang → catat',
                    'Tangani sampah liar: foto → bersihkan → upload bukti',
                    'Jaga etika dan sopan santun dengan warga',
                    'Dilarang meminta atau menerima imbalan',
                    'Laporkan kendala melalui aplikasi',
                  ],
                  const Color(0xFF9B59B6),
                ),
                
                _modernSubProcedure(
                  Icons.done_all_outlined,
                  'Penyelesaian Tugas',
                  [
                    'Antar sampah ke TPA sesuai kategori',
                    'Update status tugas di aplikasi',
                    'Bersihkan dan periksa kendaraan',
                    'Logout dari aplikasi setelah selesai',
                    'Laporkan hasil kerja ke koordinator',
                  ],
                  const Color(0xFFE74C3C),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernSubProcedure(
    IconData icon,
    String title,
    List<String> bullets,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...bullets.map((text) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _emergencyContactCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE74C3C).withOpacity(0.1),
            const Color(0xFFC0392B).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE74C3C).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE74C3C).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emergency_outlined,
                    color: Color(0xFFE74C3C),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Text(
                    'Kontak Darurat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE74C3C),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _contactItem(Icons.supervisor_account, 'Koordinator Lapangan', '0812-3456-7890'),
            _contactItem(Icons.admin_panel_settings, 'Admin Aplikasi', '0821-1234-5678'),
            _contactItem(Icons.local_hospital, 'PMI/Ambulans', '119'),
            _contactItem(Icons.local_police, 'Polisi', '110'),
          ],
        ),
      ),
    );
  }

  Widget _contactItem(IconData icon, String label, String number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE74C3C), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE74C3C),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.phone,
            color: const Color(0xFFE74C3C).withOpacity(0.7),
            size: 20,
          ),
        ],
      ),
    );
  }
}