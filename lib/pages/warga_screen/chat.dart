import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  final int userId;
  final String userName;

  const ChatPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<_ChatMessage> _messages = [];
  final Set<String> _existingMessages = {}; // untuk mencegah duplikat

  final String _baseUrl = 'http://192.168.1.3:8000';
  late String _userId;
  late String _receiver;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId.toString();
    _receiver = '1'; // ID admin

    _loadMessages();

    // Refresh setiap 5 detik
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadMessages();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/contact/get-by-user/$_userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("🟠 DEBUG: Pesan dari API = $data");

        final List<dynamic> messages = data['data'];

        if (messages.isNotEmpty) {
          setState(() {
            // Menambahkan pesan baru ke daftar _messages tanpa membalikkan urutannya
            for (var msg in messages) {
              final sender = msg['idpengirim'].toString();
              final receiver = msg['idpenerima'].toString();
              final text = msg['pesan'];

              final key = "${msg['id']}";
              if (!_existingMessages.contains(key)) {
                _messages.add(_ChatMessage(
                  // Menambahkan pesan baru di bawah
                  sender: sender,
                  receiver: receiver,
                  text: text,
                ));
                _existingMessages.add(key);
              }
            }
          });
        }
      } else {
        debugPrint('Gagal memuat pesan: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages
          .add(_ChatMessage(sender: _userId, receiver: _receiver, text: text));
      _messageController.clear();
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/contact/store'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'idpengirim': _userId,
          'idpenerima': _receiver,
          'pesan': text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Pesan berhasil dikirim');
      } else {
        debugPrint('Gagal mengirim pesan. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error saat mengirim pesan: $e');
    }
  }

  bool _shouldShowAvatar(int index) {
    if (index == 0) return true;
    return _messages[index].sender != _messages[index - 1].sender;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Live Chat Admin'),
            Text(
              'User ID: ${widget.userId}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.sender == _userId;
                final showAvatar = _shouldShowAvatar(index);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (!isUser && showAvatar) ...[
                        CircleAvatar(
                          backgroundColor: Colors.grey[400],
                          child: const Icon(Icons.support_agent,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                      ] else if (!isUser)
                        const SizedBox(width: 40),
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.orange[100] : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isUser ? 16 : 0),
                              bottomRight: Radius.circular(isUser ? 0 : 16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            msg.text,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      if (isUser && showAvatar) ...[
                        const SizedBox(width: 6),
                        const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      ] else if (isUser)
                        const SizedBox(width: 40),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Ketik pesan...',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String sender;
  final String receiver;
  final String text;

  _ChatMessage({
    required this.sender,
    required this.receiver,
    required this.text,
  });
}
