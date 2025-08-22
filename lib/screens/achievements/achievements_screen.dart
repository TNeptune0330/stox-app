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
    // Show ALL achievements (both earned and unearned)
    if (_selectedCategory == 'all') {
      return achievements;
    }
    return achievements.where((a) => a.category == _selectedCategory).toList();
  }

  BadgeType _getBadgeType(Achievement achievement) {
    // Map achievement categories to badge colors
    switch (achievement.category.toLowerCase()) {
      case 'trading':
        return BadgeType.orange;
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

  bool get _reducedMotion => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  // Animated dialog helper
  Future<T?> _showAnimatedDialog<T>(BuildContext context, Widget child) {
    return showGeneralDialog<T>(
      context: context,
      barrierLabel: 'Dialog',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: _reducedMotion ? Motion.fast : Motion.med,
      pageBuilder: (_, __, ___) => SafeArea(child: child),
      transitionBuilder: (_, a, __, c) {
        final t = CurvedAnimation(parent: a, curve: Motion.easeOut);
        final scale = Tween(begin: 0.96, end: 1.0).animate(t);
        return FadeTransition(
          opacity: t,
          child: _reducedMotion 
              ? c 
              : ScaleTransition(scale: scale, child: c),
        );
      },
    );
  }

  void _showAchievementDetail(Achievement achievement) {
    _showAnimatedDialog(
      context,
      Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: themeProvider.backgroundHigh,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: achievement.color.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Large achievement badge
                    _BadgeEmblem(
                      type: _getBadgeType(achievement),
                      unlocked: achievement.isUnlocked,
                      size: 96,
                    ),
                    const SizedBox(height: 24),
                    
                    // Achievement title
                    Text(
                      achievement.title,
                      style: TextStyle(
                        color: themeProvider.contrast,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: achievement.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: achievement.color.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        achievement.category.toUpperCase(),
                        style: TextStyle(
                          color: achievement.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Achievement description
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeProvider.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: themeProvider.contrast.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        achievement.description,
                        style: TextStyle(
                          color: themeProvider.contrast.withOpacity(0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Progress or completion info
                    if (achievement.currentProgress != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: achievement.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: achievement.color.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              color: achievement.color,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Progress',
                                    style: TextStyle(
                                      color: achievement.color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${achievement.currentProgress}/${achievement.requiredValue}',
                                    style: TextStyle(
                                      color: themeProvider.contrast,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (achievement.isUnlocked)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: achievement.color,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'COMPLETED!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Unlock date if available
                    if (achievement.isUnlocked && achievement.unlockedAt != null) ...[
                      Text(
                        'Unlocked on ${_formatDate(achievement.unlockedAt!)}',
                        style: TextStyle(
                          color: themeProvider.contrast.withOpacity(0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.theme,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
                  
                  final unlockedCount = achievementProvider.getUnlockedCount();
                  final totalCount = achievementProvider.getTotalCount();
                  print('🏆 Debug: Total achievements: $totalCount, Unlocked: $unlockedCount');

                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Progress stats
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: themeProvider.backgroundHigh,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: themeProvider.theme.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: themeProvider.theme.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.emoji_events,
                                  color: themeProvider.theme,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Progress',
                                      style: TextStyle(
                                        color: themeProvider.contrast.withOpacity(0.7),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$unlockedCount / $totalCount Achievements',
                                      style: TextStyle(
                                        color: themeProvider.contrast,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: themeProvider.theme.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: themeProvider.theme.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '${((unlockedCount / totalCount) * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: themeProvider.theme,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Filter chips
                        _buildFilterChips(themeProvider),
                        const SizedBox(height: 24),
                        
                        // Achievements grid with animated switching
                        AnimatedSwitcher(
                          duration: _reducedMotion ? Motion.fast : Motion.med,
                          transitionBuilder: (child, anim) {
                            final curved = CurvedAnimation(parent: anim, curve: Motion.easeOut);
                            if (_reducedMotion) {
                              return FadeTransition(opacity: curved, child: child);
                            }
                            return FadeTransition(
                              opacity: curved,
                              child: SlideTransition(
                                position: Tween(begin: const Offset(0.02, 0), end: Offset.zero).animate(curved), 
                                child: child,
                              ),
                            );
                          },
                          child: GridView.builder(
                            key: ValueKey(_selectedCategory),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75, // Made taller to hold more content
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: filteredAchievements.length,
                            itemBuilder: (context, index) {
                            final achievement = filteredAchievements[index];
                            return _AnimatedGridItem(
                              index: index,
                              child: _Pressable(
                                onTap: () => _showAchievementDetail(achievement),
                                child: _buildAchievementCard(
                                  themeProvider, 
                                  achievement, 
                                  achievement.isUnlocked
                                ),
                              ),
                            );
                          },
                        ),
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
              duration: _reducedMotion ? Motion.fast : Motion.med,
              curve: Motion.easeOut,
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
    final cardContent = Container(
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
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
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
                  size: 64,
                ),
                const SizedBox(height: 12),
                
                // Title
                Text(
                  achievement.title,
                  style: TextStyle(
                    color: unlocked 
                        ? themeProvider.contrast 
                        : themeProvider.contrast.withOpacity(0.5),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                
                // Description
                Expanded(
                  child: Text(
                    achievement.description,
                    style: TextStyle(
                      color: unlocked 
                          ? themeProvider.contrast.withOpacity(0.7) 
                          : themeProvider.contrast.withOpacity(0.3),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Progress or completion status
                if (achievement.currentProgress != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: unlocked 
                          ? themeProvider.theme.withOpacity(0.2) 
                          : themeProvider.contrast.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unlocked 
                          ? 'Completed!' 
                          : '${achievement.currentProgress}/${achievement.requiredValue}',
                      style: TextStyle(
                        color: unlocked 
                            ? themeProvider.theme 
                            : themeProvider.contrast.withOpacity(0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                
                // Lock icon for locked achievements
                if (!unlocked)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.lock,
                      color: themeProvider.contrast.withOpacity(0.4),
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    // Apply grayscale filter only to locked achievements
    if (unlocked) {
      // Unlocked achievements display in full color
      return cardContent;
    } else {
      // Locked achievements display with grayscale filter
      return ColorFiltered(
        colorFilter: ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0, // Red
          0.2126, 0.7152, 0.0722, 0, 0, // Green  
          0.2126, 0.7152, 0.0722, 0, 0, // Blue
          0,      0,      0,      1, 0, // Alpha
        ]),
        child: cardContent,
      );
    }
  }
}

// Pressable button with micro-motion
class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _Pressable({super.key, required this.child, required this.onTap});
  @override State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    duration: Motion.fast, 
    vsync: this, 
    lowerBound: .98, 
    upperBound: 1.0,
  )..value = 1.0;
  
  @override void dispose() { _c.dispose(); super.dispose(); }
  
  @override Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    
    return GestureDetector(
      onTapDown: (_) => reducedMotion ? null : _c.reverse(),
      onTapUp:   (_) => reducedMotion ? null : _c.forward(),
      onTapCancel: () => reducedMotion ? null : _c.forward(),
      onTap: widget.onTap,
      child: reducedMotion 
          ? widget.child
          : ScaleTransition(scale: _c, child: widget.child),
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
      BadgeType.green  => const Color(0xFFEAB308),
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

// Animated grid item with staggered entry for achievements
class _AnimatedGridItem extends StatefulWidget {
  final Widget child;
  final int index;
  const _AnimatedGridItem({required this.child, required this.index});
  @override State<_AnimatedGridItem> createState() => _AnimatedGridItemState();
}

class _AnimatedGridItemState extends State<_AnimatedGridItem> 
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: Motion.med, // Will be updated after frame
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Motion.easeOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Motion.spring,
    ));
    
    // Delay initialization to avoid MediaQuery during initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        _controller.duration = reducedMotion ? Motion.fast : Motion.med;
        
        // Stagger the animations based on index
        Future.delayed(Duration(milliseconds: widget.index * 150), () {
          if (mounted) _controller.forward();
        });
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (reducedMotion) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: widget.child,
          );
        }
        
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}