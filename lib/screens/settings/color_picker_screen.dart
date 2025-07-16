import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class ColorPickerScreen extends StatefulWidget {
  const ColorPickerScreen({super.key});

  @override
  State<ColorPickerScreen> createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {
  Color _selectedPrimaryColor = Colors.blue;
  Color _selectedBackgroundColor = Colors.black;
  
  @override
  void initState() {
    super.initState();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _selectedPrimaryColor = themeProvider.customPrimaryColor;
    _selectedBackgroundColor = themeProvider.customBackgroundColor;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Colors'),
        actions: [
          TextButton(
            onPressed: _saveColors,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customize your app colors',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Primary Color Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _selectedPrimaryColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white54),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Primary Color',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Used for buttons, app bar, and accents',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _showColorPicker(
                        context,
                        _selectedPrimaryColor,
                        'Primary Color',
                        (color) => setState(() => _selectedPrimaryColor = color),
                      ),
                      child: const Text('Choose Primary Color'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Background Color Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _selectedBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white54),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Background Color',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Main background color for screens',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _showColorPicker(
                        context,
                        _selectedBackgroundColor,
                        'Background Color',
                        (color) => setState(() => _selectedBackgroundColor = color),
                      ),
                      child: const Text('Choose Background Color'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Preview Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: _selectedBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Column(
                        children: [
                          // Mock App Bar
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: _selectedPrimaryColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'App Preview',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          // Mock Content
                          Expanded(
                            child: Center(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _selectedPrimaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: null,
                                child: const Text('Sample Button'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Presets
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Presets',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPresetChip('Blue & Black', Colors.blue, Colors.black),
                        _buildPresetChip('Green & Dark', Colors.green, const Color(0xFF1a1a1a)),
                        _buildPresetChip('Purple & Dark', Colors.purple, const Color(0xFF0f1419)),
                        _buildPresetChip('Orange & Dark', Colors.orange, const Color(0xFF1a1a1a)),
                        _buildPresetChip('Red & Dark', Colors.red, const Color(0xFF1a1a1a)),
                        _buildPresetChip('Teal & Dark', Colors.teal, const Color(0xFF1a1a1a)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPresetChip(String name, Color primary, Color background) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPrimaryColor = primary;
          _selectedBackgroundColor = background;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showColorPicker(
    BuildContext context,
    Color currentColor,
    String title,
    Function(Color) onColorChanged,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ColorPicker(
                  pickerColor: currentColor,
                  onColorChanged: onColorChanged,
                  pickerAreaHeightPercent: 0.8,
                  enableAlpha: false,
                  displayThumbColor: true,
                  paletteType: PaletteType.hsvWithHue,
                ),
                const SizedBox(height: 16),
                // Material Color Palette
                const Text(
                  'Material Colors',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
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
                  ].map((color) => GestureDetector(
                    onTap: () {
                      onColorChanged(color);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white30,
                          width: 1,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  void _saveColors() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.setCustomColors(_selectedPrimaryColor, _selectedBackgroundColor);
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Custom colors saved successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}