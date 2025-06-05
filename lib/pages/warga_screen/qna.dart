import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

class QnAPage extends StatefulWidget {
  const QnAPage({super.key});

  @override
  State<QnAPage> createState() => _QnAPageState();
}

class _QnAPageState extends State<QnAPage> {
  final String baseUrl = 'http:/192.168.1.15:8000';
  List<Map<String, String>> _faqData = [];
  List<bool> _isExpanded = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFAQ();
  }

  Future<void> fetchFAQ() async {
    try {
      final response = await http.get(Uri.parse('$baseipapi/qna/show-all'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          _faqData = data
              .map<Map<String, String>>((item) => {
                    'judul': item['judul'].toString(),
                    'deskripsi': item['deskripsi'].toString(),
                  })
              .toList();

          _isExpanded = List.filled(_faqData.length, false);
          _isLoading = false;
        });
      } else {
        throw Exception('Gagal mengambil FAQ dari server');
      }
    } catch (e) {
      print('Error fetching FAQ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header dengan gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF6600),
                    Color(0xFFFF8C42),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Frequently Asked Questions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Search FAQ...',
                          hintStyle: TextStyle(color: Colors.grey),
                          prefixIcon:
                              Icon(Icons.search, color: Color(0xFFFF6600)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // FAQ List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFFF6600),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Loading FAQ...',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _faqData.length,
                        itemBuilder: (context, index) {
                          final item = _faqData[index];
                          final isExpanded = _isExpanded[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Column(
                                children: [
                                  // Question Header
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _isExpanded[index] = !isExpanded;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFFFF6600),
                                                    Color(0xFFFF8C42),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'Q',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Text(
                                                item['judul'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color: Color(0xFF2C3E50),
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            AnimatedRotation(
                                              turns: isExpanded ? 0.5 : 0,
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFF6600)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.keyboard_arrow_down,
                                                  color: Color(0xFFFF6600),
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Answer Section
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    height: isExpanded ? null : 0,
                                    curve: Curves.easeInOut,
                                    child: isExpanded
                                        ? Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8F9FA),
                                              border: Border(
                                                top: BorderSide(
                                                  color: Colors.grey
                                                      .withOpacity(0.1),
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            padding: const EdgeInsets.all(20),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFFF6600),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: const Center(
                                                    child: Text(
                                                      'A',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: AnimatedOpacity(
                                                    opacity:
                                                        isExpanded ? 1.0 : 0.0,
                                                    duration: const Duration(
                                                        milliseconds: 300),
                                                    child: Text(
                                                      item['deskripsi'] ?? '',
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        height: 1.6,
                                                        color:
                                                            Color(0xFF5A6C7D),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
