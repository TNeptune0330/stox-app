import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../main_navigation.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  final ImagePicker _imagePicker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _usernameController = TextEditingController(
      text: authProvider.user?.username ?? '',
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppBarTitle(
            title: 'Edit Profile',
            actions: [
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return TextButton(
                    onPressed: authProvider.isLoading ? null : _saveProfile,
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  );
                },
              ),
            ],
          ),
          
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Picture
                      Center(
                        child: Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundImage: authProvider.user?.avatarUrl != null
                                      ? NetworkImage(authProvider.user!.avatarUrl!)
                                      : null,
                                  child: authProvider.user?.avatarUrl == null
                                      ? Text(
                                          authProvider.user?.username?.substring(0, 1).toUpperCase() ?? 
                                          authProvider.user?.email.substring(0, 1).toUpperCase() ?? 'U',
                                          style: const TextStyle(fontSize: 24),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                                      onPressed: _pickImage,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Username Field
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a username';
                          }
                          if (value.trim().length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Email Field (Read-only)
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return TextFormField(
                            initialValue: authProvider.user?.email ?? '',
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                            readOnly: true,
                            style: TextStyle(
                              color: Theme.of(context).disabledColor,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // Account Information
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          if (authProvider.user == null) return const SizedBox.shrink();
                          
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Account Information',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(
                                    'Cash Balance',
                                    '\$${authProvider.user!.cashBalance.toStringAsFixed(2)}',
                                  ),
                                  _buildInfoRow(
                                    'Account Created',
                                    _formatDate(authProvider.user!.createdAt),
                                  ),
                                  _buildInfoRow(
                                    'Last Updated',
                                    _formatDate(authProvider.user!.updatedAt),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 400,
        maxHeight: 400,
      );

      if (image != null) {
        // TODO: Upload image to Supabase Storage
        // For now, just show a placeholder message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image upload coming soon!'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateProfile(
        username: _usernameController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: const Color(0xFF3B82F6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}