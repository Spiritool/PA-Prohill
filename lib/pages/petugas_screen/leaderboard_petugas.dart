import 'package:flutter/material.dart';

class LeaderboardPagePetugas extends StatelessWidget {
  final List<Map<String, dynamic>> users = [
    {"name": "Davis Curtis", "score": 2569, "avatar": "👑",},
    {"name": "Alena Donin", "score": 1469, "avatar": "👩‍🦰",},
    {"name": "Craig Gouse", "score": 1053, "avatar": "👨🏽‍🦱",},
    {"name": "You", "score": 999, "avatar": "🧑"},
    {"name": "Liam Smith", "score": 980, "avatar": "👦"},
    {"name": "Emma Johnson", "score": 950, "avatar": "👧"},
    {"name": "Noah Brown", "score": 910, "avatar": "🧑‍🦱"},
    {"name": "Olivia Jones", "score": 890, "avatar": "👩"},
    {"name": "Elijah Garcia", "score": 850, "avatar": "🧔"},
    {"name": "Sophia Miller", "score": 830, "avatar": "👱‍♀️"},
  ];

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
      body: Column(
        children: [
          // Tab Switcher
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16),
          //   child: Container(
          //     height: 40,
          //     decoration: BoxDecoration(
          //       color: Colors.white24,
          //       borderRadius: BorderRadius.circular(30),
          //     ),
          //     child: Row(
          //       children: [
          //         Expanded(
          //           child: Container(
          //             alignment: Alignment.center,
          //             decoration: BoxDecoration(
          //               color: Colors.white,
          //               borderRadius: BorderRadius.circular(30),
          //             ),
          //             child: const Text(
          //               "Weekly",
          //               style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
          //             ),
          //           ),
          //         ),
          //         Expanded(
          //           child: Center(
          //             child: Text("All Time", style: TextStyle(color: Colors.white70)),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          // const SizedBox(height: 16),

          // Top 3 Podium
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildPodium(user: users[1], rank: 2, height: 110),
              buildPodium(user: users[0], rank: 1, height: 140),
              buildPodium(user: users[2], rank: 3, height: 100),
            ],
          ),

          const SizedBox(height: 24),

          // Current user (fixed)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple[400],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text("#4", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                const CircleAvatar(
                  radius: 20,
                  child: Text("🧑"),
                  backgroundColor: Colors.white,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text("You", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const Text("999 pts", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // List ranking dari posisi 5 ke bawah
          Expanded(
            child: ListView.builder(
              itemCount: users.length - 3, // sisa user setelah top 3
              itemBuilder: (context, index) {
                final user = users[index + 3];
                final rank = index + 4;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Text("#$rank", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 16),
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Text(user['avatar'], style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(user['name'], style: const TextStyle(color: Colors.white)),
                      ),
                      Text("${user['score']} pts", style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPodium({required Map<String, dynamic> user, required int rank, required double height}) {
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
            Text(user['name'], style: const TextStyle(color: Colors.white, fontSize: 14)),
            if (user.containsKey('flag')) ...[
              const SizedBox(width: 4),
              Text(user['flag'], style: const TextStyle(fontSize: 16)),
            ],
          ],
        ),
        Text("${user['score']} pts", style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
