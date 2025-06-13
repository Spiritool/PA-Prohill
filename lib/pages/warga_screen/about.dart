import 'package:flutter/material.dart';

class JempolinApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JEMPOLIN',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: JempolinHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class JempolinHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF8C00), // Dark Orange
              Color(0xFFFF6B35), // Orange Red
              Color(0xFFFF4500), // Red Orange
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(),
                SizedBox(height: 30),

                // App Description
                _buildAppDescription(),
                SizedBox(height: 30),

                // Features Section
                _buildFeaturesSection(),
                SizedBox(height: 30),

                // Action Buttons
                // _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.delete_outline,
              size: 60,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'JEMPOLIN',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Aplikasi Pengangkutan Sampah Kota Cilegon',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppDescription() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tentang JEMPOLIN',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 15),
          Text(
            'Aplikasi JEMPOLIN (Pengelolaan Sampah Cilegon) dirancang untuk memudahkan masyarakat Kota Cilegon dalam melaporkan dan memantau pengangkutan sampah secara real-time. Dengan integrasi Google Maps yang akurat, pengguna dapat dengan mudah menentukan lokasi sampah liar atau lokasi sampah yang perlu diangkut oleh petugas.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'icon': Icons.report_problem_outlined,
        'title': 'Pelaporan Sampah Liar',
        'description':
            'Pengguna dapat melaporkan lokasi sampah liar yang ditemukan dengan mengirimkan foto dan titik koordinat melalui aplikasi.'
      },
      {
        'icon': Icons.track_changes,
        'title': 'Pelacakan Status Real-time',
        'description':
            'Pengguna dapat memantau status pengangkutan sampah yang dilaporkan, mulai dari status menunggu, dalam proses, hingga selesai diangkut.'
      },
      {
        'icon': Icons.map_outlined,
        'title': 'Integrasi Google Maps',
        'description':
            'Aplikasi ini dilengkapi dengan fitur Google Maps yang akurat untuk membantu pengguna menentukan lokasi sampah secara tepat.'
      },
      {
        'icon': Icons.notifications_outlined,
        'title': 'Notifikasi Pengangkutan',
        'description':
            'Pengguna akan mendapatkan notifikasi saat laporan mereka telah diterima, dalam proses, atau selesai dikerjakan.'
      },
      {
        'icon': Icons.favorite_outline,
        'title': 'Penyimpanan Lokasi Favorit',
        'description':
            'Pengguna dapat menyimpan beberapa lokasi favorit untuk pelaporan yang lebih cepat dan efisien.'
      },
      {
        'icon': Icons.security_outlined,
        'title': 'Data Pengguna Tersimpan Aman',
        'description':
            'Menggunakan autentikasi yang aman dan penyimpanan data terenkripsi untuk menjaga privasi pengguna.'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fitur Utama',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
            return Container(
              margin: EdgeInsets.only(bottom: 15),
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature['title'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          feature['description'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
