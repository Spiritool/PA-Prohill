import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Terms & Conditions',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'Roboto',
      ),
      home: TermsAndConditionsPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TermsAndConditionsPage extends StatefulWidget {
  @override
  _TermsAndConditionsPageState createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.shade50,
              Colors.white,
              Colors.orange.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade200,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.description,
              color: Colors.white,
              size: 30,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Syarat dan Ketentuan Layanan',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      margin: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                '1. Penerimaan Syarat',
                'Dengan menggunakan layanan ini, Anda menyetujui untuk terikat oleh syarat dan ketentuan yang berlaku. Jika Anda tidak setuju dengan syarat-syarat ini, mohon untuk tidak menggunakan layanan kami.',
                Icons.check_circle,
              ),
              _buildSection(
                '2. Penggunaan Layanan',
                'Layanan ini disediakan untuk penggunaan pribadi dan komersial yang sah. Anda dilarang menggunakan layanan untuk aktivitas ilegal, merugikan, atau yang melanggar hak pihak ketiga.',
                Icons.security,
              ),
              _buildSection(
                '3. Privasi dan Data',
                'Kami menghormati privasi Anda dan berkomitmen melindungi data pribadi. Informasi yang dikumpulkan akan digunakan sesuai dengan kebijakan privasi kami dan tidak akan dibagikan tanpa persetujuan.',
                Icons.privacy_tip,
              ),
              _buildSection(
                '4. Hak Kekayaan Intelektual',
                'Semua konten, merek dagang, dan hak kekayaan intelektual dalam layanan ini adalah milik kami atau pemberi lisensi. Penggunaan tanpa izin dilarang keras.',
                Icons.copyright,
              ),
              _buildSection(
                '5. Batasan Tanggung Jawab',
                'Layanan disediakan "sebagaimana adanya". Kami tidak bertanggung jawab atas kerugian langsung, tidak langsung, atau konsekuensial yang timbul dari penggunaan layanan.',
                Icons.warning,
              ),
              _buildSection(
                '6. Perubahan Syarat',
                'Kami berhak mengubah syarat dan ketentuan ini sewaktu-waktu. Perubahan akan diberitahukan melalui platform kami dan berlaku setelah publikasi.',
                Icons.update,
              ),
              _buildSection(
                '7. Penghentian Layanan',
                'Kami dapat menghentikan atau menangguhkan akses Anda ke layanan jika terjadi pelanggaran terhadap syarat dan ketentuan ini.',
                Icons.block,
              ),
              _buildSection(
                '8. Kontak',
                'Jika Anda memiliki pertanyaan tentang syarat dan ketentuan ini, silakan hubungi tim dukungan kami melalui email atau formulir kontak yang tersedia.',
                Icons.contact_support,
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.orange.shade600,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.only(left: 40),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }
}
