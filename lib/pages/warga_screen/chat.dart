import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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
  final Set<String> _existingMessages = {};
  final ScrollController _scrollController = ScrollController();

  final String _baseUrl = 'http://192.168.229.205:8000';
  late String _userId;
  late String _receiver;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId.toString();
    _receiver = '1';

    _loadMessages();
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
        final List<dynamic> messages = data['data'];

        if (messages.isNotEmpty) {
          setState(() {
            for (var msg in messages) {
              final key = "${msg['id']}";
              if (!_existingMessages.contains(key)) {
                _messages.add(
                  _ChatMessage(
                    sender: msg['idpengirim'].toString(),
                    receiver: msg['idpenerima'].toString(),
                    text: msg['pesan'],
                    timestamp:
                        DateTime.tryParse(msg['created_at']) ?? DateTime.now(),
                  ),
                );
                _existingMessages.add(key);
              }
            }
            _messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          });
          _scrollToBottom();
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

    _messageController.clear();

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
        await _loadMessages(); // Hanya muat dari server
      } else {
        debugPrint('Gagal mengirim pesan. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error saat mengirim pesan: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _shouldShowAvatar(int index) {
    if (index == 0) return true;
    return _messages[index].sender != _messages[index - 1].sender;
  }

  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('dd MMM yyyy, HH:mm').format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text('Live Chat Admin'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.sender == _userId;
                final showAvatar = _shouldShowAvatar(index);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Row(
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
                                color:
                                    isUser ? Colors.orange[100] : Colors.white,
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.text,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTimestamp(msg.timestamp),
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[600]),
                                  ),
                                ],
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
  final DateTime timestamp;

  _ChatMessage({
    required this.sender,
    required this.receiver,
    required this.text,
    required this.timestamp,
  });
}
