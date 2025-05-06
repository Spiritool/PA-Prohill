import 'package:flutter/material.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1E),
      body: Stack(
        children: [
          // Background dua warna
          Column(
            children: [
              Container(
                height: 300,
                color: const Color(0xFF1A1A1E),
              ),
            ],
          ),

          // Isi konten atas
          SafeArea(
            child: Column(
              children: const [
                Header(),
                SizedBox(height: 5),
                TopThreeUsers(),
              ],
            ),
          ),

          // Daftar leaderboard (melengkung)
          Positioned(
            top: 290,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0C0B1D),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: LeaderboardList(),
            ),
          ),
        ],
      ),
    );
  }
}

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFB6FF6C)),
            onPressed: () {
              Navigator.pop(context); // kembali ke halaman sebelumnya
            },
          ),
          const Spacer(),
          const Text(
            'Leaderboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

class TopThreeUsers extends StatelessWidget {
  const TopThreeUsers({super.key});

  @override
  Widget build(BuildContext context) {
    final users = [
      {'name': 'Meghan Jes...', 'points': 40, 'rank': 2},
      {'name': 'Bryan Wolf', 'points': 43, 'rank': 1},
      {'name': 'Alex Turner', 'points': 38, 'rank': 3},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: users.map((user) {
        final isCenter = user['rank'] == 1;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCenter)
              const Icon(Icons.emoji_events,
                  size: 32, color: Color(0xFFB6FF6C)),
            // Avatar + Badge Rank
            Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: isCenter ? 40 : 32,
                  backgroundImage:
                      const NetworkImage('https://via.placeholder.com/150'),
                ),
                Positioned(
                  bottom: 4, // dinaikkan agar badge menempel ke avatar
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF2C2C34),
                    ),
                    child: Text(
                      '${user['rank']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              user['name'] as String,
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_florist,
                    size: 14, color: Color(0xFFB6FF6C)),
                const SizedBox(width: 4),
                Text('${user['points']} pts',
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ],
        );
      }).toList(),
    );
  }
}

class LeaderboardList extends StatelessWidget {
  const LeaderboardList({super.key});

  @override
  Widget build(BuildContext context) {
    final users = [
      {'rank': 4, 'name': 'Marsha Fisher', 'points': 36},
      {'rank': 5, 'name': 'Juanita Cormier', 'points': 35},
      {'rank': 6, 'name': 'You', 'points': 34, 'highlight': true},
      {'rank': 7, 'name': 'Tamara Schmidt', 'points': 33},
      {'rank': 8, 'name': 'Ricardo Veum', 'points': 32},
      {'rank': 9, 'name': 'Gary Sanford', 'points': 31},
      {'rank': 10, 'name': 'Becky Bartell', 'points': 30},
    ];

    return ListView.builder(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isHighlighted = user['highlight'] == true;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isHighlighted
                ? const Color(0xFF6B7E2D)
                : const Color(0xFF2C2C34),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Text(
                '${user['rank']}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              const CircleAvatar(
                backgroundImage:
                    NetworkImage('https://via.placeholder.com/150'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${user['name']}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${user['points']} pts',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }
}
