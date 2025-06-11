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
  bool isAccepted = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  ScrollController _scrollController = ScrollController();
  bool canAccept = false;

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

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 100) {
        setState(() {
          canAccept = true;
        });
      }
    });
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
                _buildFooter(),
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
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.orange.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: Colors.orange.shade600,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Gulir ke bawah untuk mengaktifkan tombol persetujuan',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
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

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isAccepted ? Colors.orange : Colors.grey,
                    width: 2,
                  ),
                  color: isAccepted ? Colors.orange : Colors.transparent,
                ),
                child: Checkbox(
                  value: isAccepted,
                  onChanged: canAccept
                      ? (value) {
                          setState(() {
                            isAccepted = value ?? false;
                          });
                        }
                      : null,
                  activeColor: Colors.transparent,
                  checkColor: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Saya telah membaca dan menyetujui syarat dan ketentuan',
                  style: TextStyle(
                    fontSize: 14,
                    color: canAccept ? Colors.grey.shade700 : Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showDialog('Dibatalkan', 'Anda telah membatalkan persetujuan.');
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                flex: 2,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  child: ElevatedButton(
                    onPressed: (canAccept && isAccepted)
                        ? () {
                            _showDialog('Berhasil!', 'Terima kasih telah menyetujui syarat dan ketentuan kami.');
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (canAccept && isAccepted)
                          ? Colors.orange.shade500
                          : Colors.grey.shade300,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: (canAccept && isAccepted) ? 3 : 0,
                    ),
                    child: Text(
                      'Setuju dan Lanjutkan',
                      style: TextStyle(
                        color: (canAccept && isAccepted) ? Colors.white : Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(
                title.contains('Berhasil') ? Icons.check_circle : Icons.info,
                color: title.contains('Berhasil') ? Colors.green : Colors.orange,
              ),
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.orange.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}