import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

class LeaderboardPage extends StatefulWidget {
  @override
  LeaderboardPageState createState() => LeaderboardPageState();
}

class LeaderboardPageState extends State<LeaderboardPage> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLeaderboardData();
  }

  Future<void> fetchLeaderboardData() async {
    final response =
        await http.get(Uri.parse('$baseipapi/api/user/all'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> data = jsonResponse['data'];

      setState(() {
        users = data
            .map<Map<String, dynamic>>((user) => {
                  'name': user['nama'], // ganti dari 'name'
                  'score': user['poin'] ?? 0, // ganti dari 'score'
                  'avatar': getAvatarFromName(user['nama']),
                })
            .toList();

        users.sort((a, b) => b['score'].compareTo(a['score']));
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to load leaderboard');
    }
  }

  String getAvatarFromName(String name) {
    // Sementara avatar pakai emoji random tergantung huruf pertama
    final code = name.codeUnitAt(0) % 5;
    return ['🧑', '👩', '👨', '🧔', '👧'][code];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6C63FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Leaderboard", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : users.length < 3
              ? const Center(
                  child: Text("Not enough data",
                      style: TextStyle(color: Colors.white)))
              : Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        buildPodium(user: users[1], rank: 2, height: 110),
                        buildPodium(user: users[0], rank: 1, height: 140),
                        buildPodium(user: users[2], rank: 3, height: 100),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (users.length > 3) ...[
                      buildCurrentUserCard(users[3], 4),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: users.length - 4,
                          itemBuilder: (context, index) {
                            final user = users[index + 4];
                            final rank = index + 5;
                            return buildUserListTile(user, rank);
                          },
                        ),
                      ),
                    ]
                  ],
                ),
    );
  }

  Widget buildPodium(
      {required Map<String, dynamic> user,
      required int rank,
      required double height}) {
    return Column(
      children: [
        Text("${user["avatar"]}", style: const TextStyle(fontSize: 40)),
        const SizedBox(height: 8),
        Container(
          height: height,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              "$rank",
              style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(user['name'],
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            if (user.containsKey('flag')) ...[
              const SizedBox(width: 4),
              Text(user['flag'], style: const TextStyle(fontSize: 16)),
            ],
          ],
        ),
        Text("${user['score']} pts",
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

Widget buildCurrentUserCard(Map<String, dynamic> user, int rank) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.deepPurple[400],
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Text("#$rank",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(width: 16),
        CircleAvatar(
          radius: 20,
          child: Text(user['avatar']),
          backgroundColor: Colors.white,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(user['name'],
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        Text("${user['score']} pts",
            style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
}

Widget buildUserListTile(Map<String, dynamic> user, int rank) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white24,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Text("#$rank",
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(width: 16),
        CircleAvatar(
          backgroundColor: Colors.white,
          child: Text(user['avatar'], style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Text(user['name'], style: const TextStyle(color: Colors.white)),
        ),
        Text("${user['score']} pts",
            style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
}
