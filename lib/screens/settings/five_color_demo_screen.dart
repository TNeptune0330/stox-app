import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/five_color_theme.dart';

/// Demo screen showing the 5-color design system in action
class FiveColorDemoScreen extends StatelessWidget {
  const FiveColorDemoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final fiveColor = themeProvider.fiveColorTheme;
        
        return Scaffold(
          backgroundColor: fiveColor.background,
          appBar: AppBar(
            title: const Text('5-Color Design System'),
            backgroundColor: fiveColor.backgroundHigh,
            foregroundColor: fiveColor.isDark ? Colors.white : Colors.black,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Color Palette Display
                _buildColorPalette(fiveColor),
                const SizedBox(height: 24),
                
                // Theme Selection
                _buildThemeSelection(context, themeProvider),
                const SizedBox(height: 24),
                
                // UI Components Demo
                _buildComponentsDemo(fiveColor),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorPalette(FiveColorTheme fiveColor) {
    return Card(
      color: fiveColor.backgroundHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '5-Color Palette: ${fiveColor.name}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: fiveColor.isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildColorSwatch('Background', fiveColor.background),
                const SizedBox(width: 8),
                _buildColorSwatch('Background High', fiveColor.backgroundHigh),
                const SizedBox(width: 8),
                _buildColorSwatch('Theme', fiveColor.theme),
                const SizedBox(width: 8),
                _buildColorSwatch('Theme High', fiveColor.themeHigh),
                const SizedBox(width: 8),
                _buildColorSwatch('Contrast', fiveColor.contrast),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSwatch(String name, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelection(BuildContext context, ThemeProvider themeProvider) {
    final themes = FiveColorTheme.getAllThemes();
    
    return Card(
      color: themeProvider.backgroundHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Themes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: themes.map((theme) => _buildThemeChip(
                context,
                theme,
                themeProvider.selectedTheme == _getThemeKey(theme),
                () => _setTheme(context, theme),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeChip(BuildContext context, FiveColorTheme theme, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.theme : theme.backgroundHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.theme,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: theme.theme,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              theme.name,
              style: TextStyle(
                color: isSelected 
                  ? (theme.isDark ? Colors.white : Colors.black)
                  : theme.theme,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentsDemo(FiveColorTheme fiveColor) {
    return Card(
      color: fiveColor.backgroundHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UI Components',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: fiveColor.isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: fiveColor.theme,
                      foregroundColor: fiveColor.isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () {},
                    child: const Text('Primary Button'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: fiveColor.theme),
                      foregroundColor: fiveColor.theme,
                    ),
                    onPressed: () {},
                    child: const Text('Secondary'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Status indicators
            Row(
              children: [
                _buildStatusChip('Success', Colors.green, fiveColor),
                const SizedBox(width: 8),
                _buildStatusChip('Error', fiveColor.contrast, fiveColor),
                const SizedBox(width: 8),
                _buildStatusChip('Info', fiveColor.themeHigh, fiveColor),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress indicator
            LinearProgressIndicator(
              value: 0.7,
              backgroundColor: fiveColor.background,
              valueColor: AlwaysStoppedAnimation<Color>(fiveColor.theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color, FiveColorTheme fiveColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _getThemeKey(FiveColorTheme theme) {
    if (theme == FiveColorTheme.darkBlue) return 'darkBlue';
    if (theme == FiveColorTheme.lightBlue) return 'lightBlue';
    if (theme == FiveColorTheme.darkGreen) return 'darkGreen';
    if (theme == FiveColorTheme.lightGreen) return 'lightGreen';
    if (theme == FiveColorTheme.darkPurple) return 'darkPurple';
    if (theme == FiveColorTheme.lightPurple) return 'lightPurple';
    return 'custom';
  }

  void _setTheme(BuildContext context, FiveColorTheme theme) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final themeKey = _getThemeKey(theme);
    themeProvider.setTheme(themeKey);
  }
}