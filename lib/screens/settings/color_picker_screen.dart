import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/harmonious_palettes.dart';
import '../../models/five_color_theme.dart';
import '../../widgets/simple_color_wheel.dart';

class ColorPickerScreen extends StatefulWidget {
  const ColorPickerScreen({super.key});

  @override
  State<ColorPickerScreen> createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {
  Color _selectedPrimaryColor = const Color(0xFF2196F3);
  bool _isDarkMode = true;
  String _harmonyType = 'complementary';
  
  @override
  void initState() {
    super.initState();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _selectedPrimaryColor = themeProvider.theme;
    _isDarkMode = themeProvider.isDark;
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Generate preview palette based on current settings
    final previewPalette = _generatePreviewPalette();
    
    return Scaffold(
      backgroundColor: themeProvider.background,
      appBar: AppBar(
        title: Text(
          'Custom Theme Creator',
          style: TextStyle(color: themeProvider.contrast),
        ),
        backgroundColor: themeProvider.backgroundHigh,
        iconTheme: IconThemeData(color: themeProvider.contrast),
        actions: [
          TextButton(
            onPressed: _saveCustomTheme,
            child: Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeProvider.backgroundHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeProvider.theme.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎨 Custom Theme Creator',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Pick a primary color and we\'ll automatically generate a harmonious 5-color palette using color theory principles.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Color Wheel
            const Text(
              'Primary Color',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            Center(
              child: SimpleColorWheel(
                initialColor: _selectedPrimaryColor,
                size: 220,
                onColorChanged: (color) {
                  setState(() {
                    _selectedPrimaryColor = color;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Theme Options
            const Text(
              'Theme Style',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildOptionTile(
                    title: 'Dark Mode',
                    subtitle: 'Dark backgrounds',
                    isSelected: _isDarkMode,
                    onTap: () => setState(() => _isDarkMode = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOptionTile(
                    title: 'Light Mode',
                    subtitle: 'Light backgrounds',
                    isSelected: !_isDarkMode,
                    onTap: () => setState(() => _isDarkMode = false),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Harmony Type
            const Text(
              'Color Harmony',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            Column(
              children: [
                _buildHarmonyOption(
                  'complementary',
                  'Complementary',
                  'Opposite colors for high contrast',
                ),
                _buildHarmonyOption(
                  'triadic',
                  'Triadic',
                  'Three colors evenly spaced',
                ),
                _buildHarmonyOption(
                  'analogous',
                  'Analogous',
                  'Adjacent colors for harmony',
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Color Preview
            const Text(
              'Color Preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeProvider.backgroundHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeProvider.theme.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Generated Palette',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Color swatches
                  Row(
                    children: [
                      _buildColorSwatch('Background', previewPalette.background),
                      _buildColorSwatch('Surface', previewPalette.backgroundHigh),
                      _buildColorSwatch('Primary', previewPalette.theme),
                      _buildColorSwatch('Accent', previewPalette.themeHigh),
                      _buildColorSwatch('Contrast', previewPalette.contrast),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? themeProvider.theme.withOpacity(0.2)
              : themeProvider.backgroundHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? themeProvider.theme
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHarmonyOption(String value, String title, String description) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isSelected = _harmonyType == value;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: RadioListTile<String>(
        value: value,
        groupValue: _harmonyType,
        onChanged: (newValue) {
          if (newValue != null) {
            setState(() {
              _harmonyType = newValue;
            });
          }
        },
        activeColor: themeProvider.theme,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        tileColor: isSelected 
            ? themeProvider.theme.withOpacity(0.1)
            : themeProvider.backgroundHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected 
                ? themeProvider.theme.withOpacity(0.5)
                : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
    );
  }
  
  Widget _buildColorSwatch(String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24, width: 1),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  FiveColorTheme _generatePreviewPalette() {
    switch (_harmonyType) {
      case 'triadic':
        return HarmoniousPalettes.generateTriadic(
          _selectedPrimaryColor,
          isDark: _isDarkMode,
          name: 'Custom Triadic',
        );
      case 'analogous':
        return HarmoniousPalettes.generateAnalogous(
          _selectedPrimaryColor,
          isDark: _isDarkMode,
          name: 'Custom Analogous',
        );
      default:
        return HarmoniousPalettes.generateFromPrimary(
          _selectedPrimaryColor,
          isDark: _isDarkMode,
          name: 'Custom Theme',
        );
    }
  }
  
  void _saveCustomTheme() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final customPalette = _generatePreviewPalette();
    
    // Save the custom theme
    themeProvider.setFiveColorTheme(customPalette);
    
    // Update user profile with custom theme
    authProvider.updateProfile(colorTheme: 'custom');
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Custom theme saved successfully!'),
        backgroundColor: themeProvider.themeHigh,
      ),
    );
    
    // Navigate back
    Navigator.of(context).pop();
  }
}