import 'package:flutter/material.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> _users = [
      {'name': 'Raja_Batam', 'points': 4500, 'avatar': 'assets/images/mascot/avatar1.png'}, // Rank 1
      {'name': 'John Doe', 'points': 4100, 'avatar': 'assets/images/mascot/avatar2.png'}, // Rank 2
      {'name': 'Siti Traveler', 'points': 3900, 'avatar': 'assets/images/mascot/avatar3.png'}, // Rank 3
      {'name': 'Alex_99', 'points': 3200, 'avatar': 'assets/images/mascot/avatar4.png'},
      {'name': 'Maria Explorer', 'points': 2800, 'avatar': 'assets/images/mascot/avatar5.png'},
      {'name': 'Budi Santos', 'points': 2500, 'avatar': 'assets/images/mascot/avatar6.png'},
      {'name': 'Kurniawan', 'points': 2100, 'avatar': 'assets/images/mascot/avatar7.png'},
      {'name': 'Anna.J', 'points': 1950, 'avatar': 'assets/images/mascot/avatar1.png'},
      {'name': 'David.W', 'points': 1700, 'avatar': 'assets/images/mascot/avatar2.png'},
      {'name': 'Clara', 'points': 1500, 'avatar': 'assets/images/mascot/avatar3.png'},
    ];
    
    // Top 3 users
    final rank1 = _users[0];
    final rank2 = _users[1];
    final rank3 = _users[2];
    
    // Remaining users
    final remainingUsers = _users.sublist(3);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7D9240),
        foregroundColor: Colors.white,
        title: const Text(
          'Leaderboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ==========================================
          // PODIUM SECTION (Top 3)
          // ==========================================
          Container(
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF7D9240).withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // RANK 2 (Silver)
                _buildPodiumBlock(
                  rank: 2,
                  name: rank2['name'],
                  points: rank2['points'],
                  avatar: rank2['avatar'],
                  height: 120,
                  color: const Color(0xFFC0C0C0), // Silver
                ),
                
                // RANK 1 (Gold)
                _buildPodiumBlock(
                  rank: 1,
                  name: rank1['name'],
                  points: rank1['points'],
                  avatar: rank1['avatar'],
                  height: 160,
                  color: const Color(0xFFFFD700), // Gold
                  isCenter: true,
                ),
                
                // RANK 3 (Bronze)
                _buildPodiumBlock(
                  rank: 3,
                  name: rank3['name'],
                  points: rank3['points'],
                  avatar: rank3['avatar'],
                  height: 90,
                  color: const Color(0xFFCD7F32), // Bronze
                ),
              ],
            ),
          ),
          
          // ==========================================
          // RANK 4-10 LIST
          // ==========================================
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: remainingUsers.length,
              itemBuilder: (context, index) {
                final user = remainingUsers[index];
                final actualRank = index + 4; // Start from rank 4
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Rank Number
                      SizedBox(
                        width: 32,
                        child: Text(
                          '$actualRank',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 12),
                      

                      // Name
                      Expanded(
                        child: Text(
                          user['name'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E3A2F),
                          ),
                        ),
                      ),
                      
                      // Points
                      Text(
                        '${user['points']} pts',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7D9240),
                        ),
                      ),
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

  Widget _buildPodiumBlock({
    required int rank,
    required String name,
    required int points,
    required String avatar,
    required double height,
    required Color color,
    bool isCenter = false,
  }) {
    return Container(
      width: 100,
      margin: EdgeInsets.symmetric(horizontal: isCenter ? 8 : 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Avatar
          Image.asset(
            avatar,
            width: 60,
            height: 60,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          // Name
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A2F),
            ),
          ),
          const SizedBox(height: 4),
          // Points
          Text(
            '$points pts',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          
          // Podium Block
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 12,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
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
