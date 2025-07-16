import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/leaderboard_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/leaderboard_service.dart';
import '../main_navigation.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<LeaderboardEntry> _leaderboard = [];
  bool _isLoading = true;
  final LeaderboardService _leaderboardService = LeaderboardService();

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final leaderboardData = await _leaderboardService.getLeaderboard(limit: 100);
      
      final leaderboardEntries = leaderboardData.map((data) {
        return LeaderboardEntry(
          id: data['user_id'],
          username: data['users']['username'] ?? 'Unknown',
          avatarUrl: data['users']['avatar_url'],
          netWorth: (data['net_worth'] as num?)?.toDouble() ?? 0.0,
          totalPnL: (data['total_pnl'] as num?)?.toDouble() ?? 0.0,
          totalPnLPercentage: (data['total_pnl_percentage'] as num?)?.toDouble() ?? 0.0,
          totalTrades: (data['users']['total_trades'] as int?) ?? 0,
          rank: data['rank'] ?? 0,
          lastUpdated: DateTime.tryParse(data['updated_at'] ?? '') ?? DateTime.now(),
        );
      }).toList();

      setState(() {
        _leaderboard = leaderboardEntries;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading leaderboard: $e');
      setState(() {
        _leaderboard = [];
        _isLoading = false;
      });
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
              Color(0xFF1a1a2e),
              Color(0xFF0f1419),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7209b7)),
                ),
              )
            : _leaderboard.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.leaderboard_outlined,
                          size: 64,
                          color: Colors.white54,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No leaderboard data available',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start trading to see rankings!',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
            // Game-like Header
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7209b7), Color(0xFF533483)],
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 48,
                          color: Color(0xFFf39c12),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'GLOBAL LEADERBOARD',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Top 3 Podium
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1a2e),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFf39c12).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (_leaderboard.length > 1) _buildPodiumItem(_leaderboard[1], 2),
                    if (_leaderboard.isNotEmpty) _buildPodiumItem(_leaderboard[0], 1),
                    if (_leaderboard.length > 2) _buildPodiumItem(_leaderboard[2], 3),
                  ],
                ),
              ),
            ),
            
            // Rest of the leaderboard
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final actualIndex = index + 3;
                  if (actualIndex >= _leaderboard.length) return null;
                  
                  final entry = _leaderboard[actualIndex];
                  return _buildLeaderboardTile(entry);
                },
                childCount: _leaderboard.length > 3 ? _leaderboard.length - 3 : 0,
              ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildPodiumItem(LeaderboardEntry entry, int position) {
    final colors = {
      1: const Color(0xFFf39c12), // Gold
      2: const Color(0xFF95a5a6), // Silver
      3: const Color(0xFFcd7f32), // Bronze
    };

    final heights = {1: 80.0, 2: 60.0, 3: 40.0};

    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: colors[position],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text(
              entry.username.substring(0, 2).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: heights[position],
          decoration: BoxDecoration(
            color: colors[position],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Text(
              '#$position',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          entry.username,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          entry.formattedNetWorth,
          style: TextStyle(
            color: colors[position],
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTile(LeaderboardEntry entry) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCurrentUser = authProvider.user?.username == entry.username;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser 
            ? const Color(0xFF7209b7).withOpacity(0.2)
            : const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser 
              ? const Color(0xFF7209b7)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFf39c12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#${entry.rank}',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF533483),
            child: Text(
              entry.username.substring(0, 2).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${entry.totalTrades} trades',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.formattedNetWorth,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                entry.formattedPnL,
                style: TextStyle(
                  color: entry.totalPnL >= 0 
                      ? const Color(0xFF27ae60)
                      : const Color(0xFFe74c3c),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}