import 'package:flutter/material.dart';

class PointScreen extends StatefulWidget {
  @override
  _PointScreenState createState() => _PointScreenState();
}

// Dummy data list (sementara)
final List<Map<String, dynamic>> redeemItems = [
  {
    'image': 'https://picsum.photos/200/150?random=1',
    'title': 'Hotlink Unlimited',
    'point': 10,
  },
  {
    'image': 'https://picsum.photos/200/150?random=2',
    'title': 'Free Coffee Voucher',
    'point': 20,
  },
];

class _PointScreenState extends State<PointScreen> {
  bool isMyPointActive = true; // state tab aktif

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // warna utama putih
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(
            Icons.chevron_left,
            color: Colors.black,
            size: 30,
          ),
        ),
        title: Text(
          'Point',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tab Switch
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  // My Point Tab
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isMyPointActive = true;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isMyPointActive
                              ? Colors.orange
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'My Point',
                          style: TextStyle(
                            color: isMyPointActive
                                ? Colors.white
                                : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Redeem Tab
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isMyPointActive = false;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isMyPointActive
                              ? Colors.transparent
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Redeem',
                          style: TextStyle(
                            color: isMyPointActive
                                ? Colors.grey[600]
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Konten Tab dengan AnimatedCrossFade untuk transisi halus
          Expanded(
            child: AnimatedCrossFade(
              duration: Duration(milliseconds: 300),
              firstChild: _buildMyPointSection(),
              secondChild: _buildRedeemSection(),
              crossFadeState: isMyPointActive
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
            ),
          ),
        ],
      ),
    );
  }

  // My Point Section
  Widget _buildMyPointSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: Color(0xFFF9F9F9),
          margin: EdgeInsets.only(top: 10),
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                child: Image.asset('assets/icons/money 4.png'),
              ),
              SizedBox(height: 10),
              Text(
                'Total Point',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 4),
              Text(
                '1',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // My History Section
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(
            'My History',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[400]),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: EdgeInsets.all(16),
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
            child: Row(
              children: [
                // Kiri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⭐ Waste & get Point',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Electrical Waste',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '27-04-2021  09:00 AM',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Coin
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/icons/money 4.png', // coin image sesuai upload kamu
                        width: 20,
                        height: 20,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '1',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Redeem Section
  Widget _buildRedeemSection() {
    return redeemItems.isEmpty
        ? Center(
            child: Text(
              'No redeem',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(20),
            itemCount: redeemItems.length,
            itemBuilder: (context, index) {
              final item = redeemItems[index];
              return Container(
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(
                        item['image'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] ?? 'Promo Title',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'Point Needed: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Image.asset(
                                'assets/icons/money 4.png',
                                width: 20,
                                height: 20,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '${item['point']}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }
}
