import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

class LeaderboardPage extends StatefulWidget {
  @override
  LeaderboardPageState createState() => LeaderboardPageState();
}

class LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Map<String, dynamic> currentUser = {};
  int currentUserRank = 0;
  int currentUserId = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    fetchLeaderboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserIdAndFindCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getInt('user_id') ?? 0;

    for (int i = 0; i < users.length; i++) {
      if (users[i]['id'] == currentUserId) {
        currentUser = users[i];
        currentUserRank = i + 1;
        break;
      }
    }

    setState(() {});
  }

  Future<void> fetchLeaderboardData() async {
    try {
      final response = await http.get(Uri.parse('$baseipapi/api/user/all'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];

        setState(() {
          users = data
              .where((user) => user['role'] == 'warga')
              .map<Map<String, dynamic>>((user) => {
                    'name': user['nama'],
                    'score': user['poin'] ?? 0,
                    'avatar': getAvatarFromName(user['nama']),
                    // Tambahkan 'id' user supaya bisa cocokkan id user current
                    'id': user['id'],
                  })
              .toList();

          users.sort((a, b) => b['score'].compareTo(a['score']));
          isLoading = false;
        });

        // Panggil setelah setState agar data users sudah ada
        await _loadUserIdAndFindCurrentUser();

        _animationController.forward();
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('Failed to load leaderboard');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading leaderboard: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String getAvatarFromName(String name) {
    final code = name.codeUnitAt(0) % 5;
    return ['🧑', '👩', '👨', '🧔', '👧'][code];
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF6600),
              Color(0xFFFF8533),
              Color(0xFFFFB366),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: isLoading
                    ? _buildLoadingState()
                    : users.length < 3
                        ? _buildEmptyState()
                        : _buildLeaderboardContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          Expanded(
            child: Text(
              "🏆 Leaderboard",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 52),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Loading leaderboard...",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              "Not enough data",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Need at least 3 players to show leaderboard",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildPodiumSection(),
          const SizedBox(height: 24),
          if (users.length > 3) _buildRestOfList(),
        ],
      ),
    );
  }

  Widget _buildPodiumSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text(
            "Top 3 Champions",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildPodium(user: users[1], rank: 2, height: 120),
              _buildPodium(user: users[0], rank: 1, height: 160),
              _buildPodium(user: users[2], rank: 3, height: 100),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodium({
    required Map<String, dynamic> user,
    required int rank,
    required double height,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _getRankColor(rank),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user["avatar"],
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: height,
          width: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _getRankColor(rank),
                _getRankColor(rank).withOpacity(0.8),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                rank == 1 ? Icons.emoji_events : Icons.military_tech,
                color: rank == 1 ? const Color(0xFFB8860B) : Colors.white,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                "$rank",
                style: TextStyle(
                  color: rank == 1 ? const Color(0xFFB8860B) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxWidth: 80),
          child: Column(
            children: [
              Text(
                user['name'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${user['score']} pts",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRestOfList() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            if (currentUser.isNotEmpty)
              _buildCurrentUserCard(currentUser, currentUserRank),
            if (users.length > 3)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: users.length - 3,
                  itemBuilder: (context, index) {
                    final user = users[index + 3];
                    final rank = index + 4;
                    return _buildUserListTile(user, rank);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentUserCard(Map<String, dynamic> user, int rank) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF4500), Color(0xFFFF6B35)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              "#$rank",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              user['avatar'],
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Text(
                  "You're doing great!",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              "${user['score']} pts",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserListTile(Map<String, dynamic> user, int rank) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                "#$rank",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Text(
              user['avatar'],
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              user['name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "${user['score']} pts",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
