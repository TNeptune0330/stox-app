import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/achievement_model.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/theme_provider.dart';

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
      Provider.of<AchievementProvider>(context, listen: false).initialize();
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.background,
          body: Consumer<AchievementProvider>(
            builder: (context, achievementProvider, child) {
              final filteredAchievements = _getFilteredAchievements(achievementProvider.achievements);
              
              return CustomScrollView(
                slivers: [
                  // Header with 5-color theme
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: false,
                    pinned: true,
                    backgroundColor: themeProvider.backgroundHigh,
                    foregroundColor: themeProvider.contrast,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              themeProvider.theme,
                              themeProvider.themeHigh,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: themeProvider.theme.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: themeProvider.background.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.emoji_events,
                                  size: 36,
                                  color: themeProvider.contrast,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'ACHIEVEMENTS',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: themeProvider.contrast,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: themeProvider.background.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${achievementProvider.getUnlockedCount()} / ${achievementProvider.getTotalCount()} Unlocked',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: themeProvider.contrast,
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
                    margin: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip('all', 'All', themeProvider),
                          _buildCategoryChip('trading', 'Trading', themeProvider),
                          _buildCategoryChip('profit', 'Profit', themeProvider),
                          _buildCategoryChip('streak', 'Streaks', themeProvider),
                          _buildCategoryChip('special', 'Special', themeProvider),
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
                      return _buildAchievementCard(achievement, themeProvider);
                    },
                    childCount: filteredAchievements.length,
                  ),
                ),
              ],
            );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(String category, String label, ThemeProvider themeProvider) {
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
        selectedColor: themeProvider.themeHigh,
        backgroundColor: themeProvider.theme.withOpacity(0.05),
        side: BorderSide(
          color: isSelected ? themeProvider.themeHigh : themeProvider.contrast.withOpacity(0.3),
          width: 1,
        ),
        labelStyle: TextStyle(
          color: isSelected ? themeProvider.contrast : themeProvider.contrast.withOpacity(0.7),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: themeProvider.backgroundHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievement.isUnlocked 
              ? achievement.color 
              : themeProvider.theme.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: achievement.isUnlocked
            ? [
                BoxShadow(
                  color: achievement.color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: themeProvider.theme.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: achievement.isUnlocked 
                ? achievement.color 
                : themeProvider.contrast.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            achievement.icon,
            size: 28,
            color: themeProvider.contrast,
          ),
        ),
        title: Text(
          achievement.title,
          style: TextStyle(
            color: themeProvider.contrast,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              achievement.description,
              style: TextStyle(
                color: themeProvider.contrast,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: achievement.progress,
                    backgroundColor: themeProvider.contrast.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      achievement.isUnlocked ? achievement.color : themeProvider.contrast.withOpacity(0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  achievement.progressText,
                  style: TextStyle(
                    color: themeProvider.contrast,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: achievement.isUnlocked
            ? Icon(
                Icons.check_circle,
                color: themeProvider.themeHigh,
                size: 28,
              )
            : Icon(
                Icons.lock,
                color: themeProvider.contrast.withOpacity(0.5),
                size: 28,
              ),
      ),
    );
  }
}