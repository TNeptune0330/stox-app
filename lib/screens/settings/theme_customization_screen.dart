import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/app_theme_model.dart';

class ThemeCustomizationScreen extends StatefulWidget {
  const ThemeCustomizationScreen({Key? key}) : super(key: key);

  @override
  State<ThemeCustomizationScreen> createState() => _ThemeCustomizationScreenState();
}

class _ThemeCustomizationScreenState extends State<ThemeCustomizationScreen> {
  late AppThemeModel _currentTheme;
  bool _isCustomizing = false;

  @override
  void initState() {
    super.initState();
    _currentTheme = context.read<ThemeProvider>().currentTheme;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Customization'),
        actions: [
          if (_isCustomizing)
            TextButton(
              onPressed: _saveTheme,
              child: const Text('Save'),
            ),
          IconButton(
            onPressed: _resetToDefault,
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to Default',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme preview card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Preview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildThemePreview(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Color categories
          _buildColorCategory('Primary Colors', [
            ColorOption('Primary', 'primary', _currentTheme.primaryColor),
            ColorOption('Secondary', 'secondary', _currentTheme.secondaryColor),
            ColorOption('Accent', 'accent', _currentTheme.accentColor),
          ]),
          
          _buildColorCategory('Background Colors', [
            ColorOption('Background', 'background', _currentTheme.backgroundColor),
            ColorOption('Surface', 'surface', _currentTheme.surfaceColor),
            ColorOption('Card', 'card', _currentTheme.cardColor),
            ColorOption('App Bar', 'appBar', _currentTheme.appBarColor),
            ColorOption('Bottom Nav', 'bottomNav', _currentTheme.bottomNavColor),
            ColorOption('Modal', 'modal', _currentTheme.modalColor),
          ]),
          
          _buildColorCategory('Text Colors', [
            ColorOption('Text', 'text', _currentTheme.textColor),
            ColorOption('Subtitle', 'subtitle', _currentTheme.subtitleColor),
            ColorOption('Icon', 'icon', _currentTheme.iconColor),
          ]),
          
          _buildColorCategory('Interactive Colors', [
            ColorOption('Button', 'button', _currentTheme.buttonColor),
            ColorOption('Chip', 'chip', _currentTheme.chipColor),
            ColorOption('Highlight', 'highlight', _currentTheme.highlightColor),
            ColorOption('Disabled', 'disabled', _currentTheme.disabledColor),
          ]),
          
          _buildColorCategory('Status Colors', [
            ColorOption('Success', 'success', _currentTheme.successColor),
            ColorOption('Error', 'error', _currentTheme.errorColor),
            ColorOption('Warning', 'warning', _currentTheme.warningColor),
            ColorOption('Info', 'info', _currentTheme.infoColor),
            ColorOption('Positive', 'positive', _currentTheme.positiveColor),
            ColorOption('Negative', 'negative', _currentTheme.negativeColor),
          ]),
          
          _buildColorCategory('Structural Colors', [
            ColorOption('Divider', 'divider', _currentTheme.dividerColor),
            ColorOption('Border', 'border', _currentTheme.borderColor),
            ColorOption('Shadow', 'shadow', _currentTheme.shadowColor),
            ColorOption('Overlay', 'overlay', _currentTheme.overlayColor),
          ]),
          
          _buildColorCategory('Gradient Colors', [
            ColorOption('Gradient Start', 'gradientStart', _currentTheme.gradientStartColor),
            ColorOption('Gradient End', 'gradientEnd', _currentTheme.gradientEndColor),
          ]),
          
          const SizedBox(height: 24),
          
          // Preset themes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preset Themes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildPresetThemes(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _currentTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _currentTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _currentTheme.appBarColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'App Bar',
              style: TextStyle(
                color: _currentTheme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _currentTheme.cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Card Title',
                  style: TextStyle(
                    color: _currentTheme.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Card subtitle text',
                  style: TextStyle(color: _currentTheme.subtitleColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _currentTheme.buttonColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Primary Button',
                      style: TextStyle(
                        color: _currentTheme.isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentTheme.chipColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Chip',
                  style: TextStyle(color: _currentTheme.textColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusIndicator('Success', _currentTheme.successColor),
              _buildStatusIndicator('Error', _currentTheme.errorColor),
              _buildStatusIndicator('Warning', _currentTheme.warningColor),
              _buildStatusIndicator('Info', _currentTheme.infoColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: _currentTheme.textColor,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildColorCategory(String title, List<ColorOption> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: options.map((option) => _buildColorOption(option)).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildColorOption(ColorOption option) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(option.name),
          ),
          GestureDetector(
            onTap: () => _showColorPicker(option.key, option.color),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: option.color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetThemes() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ThemeProvider.themes.map((theme) {
            final isSelected = themeProvider.selectedTheme == theme['value'];
            return GestureDetector(
              onTap: () => _selectPresetTheme(theme['value']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? theme['color'] : null,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme['color'],
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      theme['icon'],
                      size: 16,
                      color: isSelected ? Colors.white : theme['color'],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      theme['name'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : theme['color'],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showColorPicker(String colorKey, Color initialColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose Color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: initialColor,
            onColorChanged: (color) {
              setState(() {
                _currentTheme = _updateThemeColor(colorKey, color);
                _isCustomizing = true;
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  AppThemeModel _updateThemeColor(String colorKey, Color color) {
    switch (colorKey) {
      case 'primary':
        return _currentTheme.copyWith(primaryColor: color);
      case 'secondary':
        return _currentTheme.copyWith(secondaryColor: color);
      case 'background':
        return _currentTheme.copyWith(backgroundColor: color);
      case 'surface':
        return _currentTheme.copyWith(surfaceColor: color);
      case 'card':
        return _currentTheme.copyWith(cardColor: color);
      case 'text':
        return _currentTheme.copyWith(textColor: color);
      case 'subtitle':
        return _currentTheme.copyWith(subtitleColor: color);
      case 'accent':
        return _currentTheme.copyWith(accentColor: color);
      case 'success':
        return _currentTheme.copyWith(successColor: color);
      case 'error':
        return _currentTheme.copyWith(errorColor: color);
      case 'warning':
        return _currentTheme.copyWith(warningColor: color);
      case 'info':
        return _currentTheme.copyWith(infoColor: color);
      case 'positive':
        return _currentTheme.copyWith(positiveColor: color);
      case 'negative':
        return _currentTheme.copyWith(negativeColor: color);
      case 'button':
        return _currentTheme.copyWith(buttonColor: color);
      case 'icon':
        return _currentTheme.copyWith(iconColor: color);
      case 'appBar':
        return _currentTheme.copyWith(appBarColor: color);
      case 'bottomNav':
        return _currentTheme.copyWith(bottomNavColor: color);
      case 'modal':
        return _currentTheme.copyWith(modalColor: color);
      case 'chip':
        return _currentTheme.copyWith(chipColor: color);
      case 'divider':
        return _currentTheme.copyWith(dividerColor: color);
      case 'border':
        return _currentTheme.copyWith(borderColor: color);
      case 'highlight':
        return _currentTheme.copyWith(highlightColor: color);
      case 'disabled':
        return _currentTheme.copyWith(disabledColor: color);
      case 'shadow':
        return _currentTheme.copyWith(shadowColor: color);
      case 'overlay':
        return _currentTheme.copyWith(overlayColor: color);
      case 'gradientStart':
        return _currentTheme.copyWith(gradientStartColor: color);
      case 'gradientEnd':
        return _currentTheme.copyWith(gradientEndColor: color);
      default:
        return _currentTheme;
    }
  }

  void _selectPresetTheme(String themeValue) {
    context.read<ThemeProvider>().setTheme(themeValue);
    setState(() {
      _currentTheme = context.read<ThemeProvider>().currentTheme;
      _isCustomizing = false;
    });
  }

  void _saveTheme() {
    context.read<ThemeProvider>().setCustomTheme(_currentTheme);
    setState(() {
      _isCustomizing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Theme saved successfully!')),
    );
  }

  void _resetToDefault() {
    context.read<ThemeProvider>().setTheme('darkBlue');
    setState(() {
      _currentTheme = context.read<ThemeProvider>().currentTheme;
      _isCustomizing = false;
    });
  }
}

class ColorOption {
  final String name;
  final String key;
  final Color color;

  ColorOption(this.name, this.key, this.color);
}

// Simple color picker widget
class BlockPicker extends StatelessWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const BlockPicker({
    Key? key,
    required this.pickerColor,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.black,
      Colors.white,
    ];

    return Container(
      width: 240,
      height: 240,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final color = colors[index];
          return GestureDetector(
            onTap: () => onColorChanged(color),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: pickerColor == color ? Colors.white : Colors.grey.shade300,
                  width: pickerColor == color ? 2 : 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}