import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/modern_theme.dart';
import '../../models/achievement_model.dart';

class SimpleAchievementsScreen extends StatefulWidget {
  const SimpleAchievementsScreen({super.key});

  @override
  State<SimpleAchievementsScreen> createState() => _SimpleAchievementsScreenState();
}

class _SimpleAchievementsScreenState extends State<SimpleAchievementsScreen> {
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final achievementProvider = Provider.of<AchievementProvider>(context, listen: false);
      
      if (authProvider.user != null) {
        achievementProvider.initialize(authProvider.user!.id);
      } else {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundPrimary,
      resizeToAvoidBottomInset: false,
      body: Consumer2<AchievementProvider, AuthProvider>(
        builder: (context, achievementProvider, authProvider, child) {
          final filteredAchievements = _getFilteredAchievements(achievementProvider.achievements);
          final isAuthenticated = authProvider.isAuthenticated;
          
          Widget content = SafeArea(
            child: CustomScrollView(
              slivers: [
              // Header
              SliverAppBar(
                expandedHeight: 100,
                floating: false,
                pinned: true,
                backgroundColor: ModernTheme.backgroundPrimary,
                foregroundColor: ModernTheme.textPrimary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ModernTheme.accentPurple,
                          ModernTheme.accentBlue,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'ACHIEVEMENTS',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${achievementProvider.getUnlockedCount()} / ${achievementProvider.getTotalCount()} Unlocked',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Category Filter
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Row(
                      children: [
                        _buildCategoryChip('all', 'All'),
                        _buildCategoryChip('trading', 'Trading'),
                        _buildCategoryChip('profit', 'Profit'),
                        _buildCategoryChip('portfolio', 'Portfolio'),
                        _buildCategoryChip('special', 'Special'),
                      ],
                    ),
                  ),
                ),
              ),

              // Achievements List
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final achievement = filteredAchievements[index];
                    return _buildAchievementCard(achievement);
                  },
                  childCount: filteredAchievements.length,
                ),
              ),
            ],
            ),
          );
          
          // If user is not authenticated, blur the content and show sign-in prompt
          if (!isAuthenticated) {
            return Stack(
              children: [
                // Blurred content
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: content,
                ),
                // Sign-in overlay
                Container(
                  color: ModernTheme.backgroundPrimary.withOpacity(0.8),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: ModernTheme.backgroundCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: ModernTheme.borderLight),
                        boxShadow: ModernTheme.shadowCard,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 64,
                            color: ModernTheme.accentBlue,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sign In Required',
                            style: ModernTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sign in to view your achievements\nand track your trading progress',
                            style: ModernTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/login');
                            },
                            icon: const Icon(Icons.login),
                            label: const Text('Sign In'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          
          return content;
        },
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        selectedColor: ModernTheme.accentBlue.withOpacity(0.2),
        backgroundColor: ModernTheme.backgroundCard,
        side: BorderSide(
          color: isSelected ? ModernTheme.accentBlue : ModernTheme.borderLight,
          width: 1,
        ),
        labelStyle: TextStyle(
          color: isSelected ? ModernTheme.accentBlue : ModernTheme.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: ModernTheme.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievement.isUnlocked 
              ? achievement.color 
              : ModernTheme.borderLight,
          width: 2,
        ),
        boxShadow: achievement.isUnlocked
            ? [
                BoxShadow(
                  color: achievement.color.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : ModernTheme.shadowCard,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: achievement.isUnlocked 
                ? achievement.color.withOpacity(0.2)
                : ModernTheme.textMuted.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            achievement.icon,
            size: 28,
            color: achievement.isUnlocked 
                ? achievement.color 
                : ModernTheme.textMuted,
          ),
        ),
        title: Text(
          achievement.title,
          style: ModernTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              achievement.description,
              style: ModernTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: achievement.progress,
                    backgroundColor: ModernTheme.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      achievement.isUnlocked ? achievement.color : ModernTheme.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  achievement.progressText,
                  style: ModernTheme.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: achievement.isUnlocked
            ? Icon(
                Icons.check_circle,
                color: achievement.color,
                size: 28,
              )
            : Icon(
                Icons.lock,
                color: ModernTheme.textMuted,
                size: 28,
              ),
      ),
    );
  }
}