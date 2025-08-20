import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/achievement_model.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

// Badge Types for _BadgeEmblem
enum BadgeType { red, orange, green, blue, purple }

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final achievementProvider = Provider.of<AchievementProvider>(context, listen: false);
      
      if (authProvider.user != null) {
        print('🏆 Initializing achievements for user: ${authProvider.user!.id}');
        achievementProvider.initialize(authProvider.user!.id);
      } else {
        print('🏆 Initializing achievements without user (demo mode)');
        achievementProvider.initialize();
      }
    });
  }

  List<Achievement> _getFilteredAchievements(List<Achievement> achievements) {
    if (_selectedCategory == 'all') {
      return achievements;
    }
    return achievements.where((a) => a.category == _selectedCategory).toList();
  }

  BadgeType _getBadgeType(Achievement achievement) {
    // Map achievement categories to badge colors
    switch (achievement.category.toLowerCase()) {
      case 'trading':
        return BadgeType.green;
      case 'portfolio':
        return BadgeType.blue;
      case 'milestone':
        return BadgeType.purple;
      case 'special':
        return BadgeType.orange;
      default:
        return BadgeType.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.background,
          body: CustomScrollView(
            slivers: [
              // Simple app bar
              SliverAppBar(
                backgroundColor: themeProvider.background,
                elevation: 0,
                pinned: true,
                title: Text(
                  'Achievements',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),

              Consumer2<AchievementProvider, AuthProvider>(
                builder: (context, achievementProvider, authProvider, child) {
                  // Remove the loading check since AchievementProvider doesn't have isLoading
                  final filteredAchievements = _getFilteredAchievements(
                    achievementProvider.achievements
                  );

                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Filter chips
                        _buildFilterChips(themeProvider),
                        const SizedBox(height: 24),
                        
                        // Achievements grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.9,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredAchievements.length,
                          itemBuilder: (context, index) {
                            final achievement = filteredAchievements[index];
                            return _buildAchievementCard(
                              themeProvider, 
                              achievement, 
                              achievement.isUnlocked
                            );
                          },
                        ),
                        
                        const SizedBox(height: 100), // Bottom padding for nav bar
                      ]),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips(ThemeProvider themeProvider) {
    final categories = ['all', 'trading', 'portfolio', 'milestone', 'special'];
    final categoryNames = {
      'all': 'All',
      'trading': 'Trading',
      'portfolio': 'Portfolio', 
      'milestone': 'Milestone',
      'special': 'Special',
    };

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected 
                    ? themeProvider.theme 
                    : themeProvider.backgroundHigh,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected 
                      ? themeProvider.theme 
                      : themeProvider.contrast.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.24),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ] : null,
              ),
              child: Text(
                categoryNames[category] ?? category,
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white 
                      : themeProvider.contrast,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAchievementCard(ThemeProvider themeProvider, Achievement achievement, bool unlocked) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.backgroundHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: unlocked 
              ? achievement.color.withOpacity(0.3)
              : themeProvider.contrast.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Lock overlay for locked achievements
          if (!unlocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          
          // Main content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge emblem
                _BadgeEmblem(
                  type: _getBadgeType(achievement),
                  unlocked: unlocked,
                  size: 72,
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  achievement.title,
                  style: TextStyle(
                    color: unlocked 
                        ? themeProvider.contrast 
                        : themeProvider.contrast.withOpacity(0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Description
                Expanded(
                  child: Text(
                    achievement.description,
                    style: TextStyle(
                      color: unlocked 
                          ? themeProvider.contrast.withOpacity(0.7) 
                          : themeProvider.contrast.withOpacity(0.4),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Progress or completion status
                if (achievement.currentProgress != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: unlocked 
                          ? themeProvider.theme.withOpacity(0.2) 
                          : themeProvider.contrast.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unlocked 
                          ? 'Completed!' 
                          : '${achievement.currentProgress}/${achievement.requiredValue}',
                      style: TextStyle(
                        color: unlocked 
                            ? themeProvider.theme 
                            : themeProvider.contrast.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
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

// Private _BadgeEmblem widget as specified in requirements
class _BadgeEmblem extends StatelessWidget {
  final BadgeType type;
  final bool unlocked;
  final double size;

  const _BadgeEmblem({
    required this.type,
    required this.unlocked,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      BadgeType.red    => const Color(0xFFEF4444),
      BadgeType.orange => const Color(0xFFF59E0B),
      BadgeType.green  => const Color(0xFF22C55E),
      BadgeType.blue   => const Color(0xFF3B82F6),
      BadgeType.purple => const Color(0xFF8B5CF6),
    };

    return Container(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer hexagon
          CustomPaint(
            size: Size(size, size),
            painter: HexagonPainter(
              color: unlocked ? color : color.withOpacity(0.3),
              unlocked: unlocked,
            ),
          ),
          
          // Inner highlight
          if (unlocked)
            Container(
              width: size * 0.6,
              height: size * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.3),
              ),
            ),
          
          // Badge icon
          Icon(
            _getIconForType(type),
            color: unlocked ? Colors.white : Colors.white.withOpacity(0.6),
            size: size * 0.4,
          ),
          
          // Lock overlay for locked badges
          if (!unlocked)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock,
                  color: Colors.white,
                  size: size * 0.15,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForType(BadgeType type) {
    switch (type) {
      case BadgeType.red:
        return Icons.error;
      case BadgeType.orange:
        return Icons.star;
      case BadgeType.green:
        return Icons.trending_up;
      case BadgeType.blue:
        return Icons.account_balance_wallet;
      case BadgeType.purple:
        return Icons.emoji_events;
    }
  }
}

// Custom painter for hexagon badge shape
class HexagonPainter extends CustomPainter {
  final Color color;
  final bool unlocked;

  HexagonPainter({required this.color, required this.unlocked});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Create hexagon path
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60.0 - 30.0) * (pi / 180.0);
      final x = center.dx + radius * 0.9 * cos(angle);
      final y = center.dy + radius * 0.9 * sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);

    // Add inner highlight if unlocked
    if (unlocked) {
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      final highlightPath = Path();
      for (int i = 0; i < 6; i++) {
        final angle = (i * 60.0 - 30.0) * (pi / 180.0);
        final x = center.dx + radius * 0.6 * cos(angle);
        final y = center.dy + radius * 0.6 * sin(angle);
        
        if (i == 0) {
          highlightPath.moveTo(x, y);
        } else {
          highlightPath.lineTo(x, y);
        }
      }
      highlightPath.close();

      canvas.drawPath(highlightPath, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}