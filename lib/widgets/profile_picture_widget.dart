import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/profile_picture_service.dart';

class ProfilePictureWidget extends StatefulWidget {
  final double size;
  final bool showEditButton;
  final VoidCallback? onImageChanged;
  
  const ProfilePictureWidget({
    Key? key,
    this.size = 80,
    this.showEditButton = false,
    this.onImageChanged,
  }) : super(key: key);

  @override
  State<ProfilePictureWidget> createState() => _ProfilePictureWidgetState();
}

class _ProfilePictureWidgetState extends State<ProfilePictureWidget> with SingleTickerProviderStateMixin {
  bool _isUploading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AuthProvider>(
      builder: (context, themeProvider, authProvider, child) {
        final user = authProvider.user;
        final avatarUrl = user?.avatarUrl;
        
        return GestureDetector(
          onTapDown: widget.showEditButton ? (_) => _animationController.forward() : null,
          onTapUp: widget.showEditButton ? (_) => _animationController.reverse() : null,
          onTapCancel: widget.showEditButton ? () => _animationController.reverse() : null,
          onTap: widget.showEditButton ? _showImageSourceDialog : null,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
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
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: themeProvider.backgroundHigh,
                      border: Border.all(
                        color: themeProvider.contrast.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Profile Picture or Placeholder
                        ClipOval(
                          child: _isUploading
                              ? _buildLoadingIndicator(themeProvider)
                              : avatarUrl != null && avatarUrl.isNotEmpty
                                  ? _buildNetworkImage(avatarUrl, themeProvider)
                                  : _buildPlaceholder(themeProvider, user?.username ?? user?.email ?? 'U'),
                        ),
                        
                        // Edit Button
                        if (widget.showEditButton)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: widget.size * 0.3,
                              height: widget.size * 0.3,
                              decoration: BoxDecoration(
                                color: themeProvider.theme,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: themeProvider.backgroundHigh,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: themeProvider.contrast.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: widget.size * 0.15,
                                color: themeProvider.isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        
                        // Upload Progress Indicator
                        if (_isUploading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: themeProvider.background.withOpacity(0.8),
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: widget.size * 0.4,
                                  height: widget.size * 0.4,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(themeProvider.theme),
                                    backgroundColor: themeProvider.themeHigh.withOpacity(0.3),
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNetworkImage(String url, ThemeProvider themeProvider) {
    return CachedNetworkImage(
      imageUrl: url,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildLoadingIndicator(themeProvider),
      errorWidget: (context, url, error) => _buildErrorPlaceholder(themeProvider),
    );
  }

  Widget _buildPlaceholder(ThemeProvider themeProvider, String initials) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeProvider.themeHigh.withOpacity(0.3),
            themeProvider.theme.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials.substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontSize: widget.size * 0.4,
            fontWeight: FontWeight.bold,
            color: themeProvider.theme,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeProvider themeProvider) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: themeProvider.backgroundHigh,
      ),
      child: Center(
        child: SizedBox(
          width: widget.size * 0.4,
          height: widget.size * 0.4,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(themeProvider.theme),
            backgroundColor: themeProvider.themeHigh.withOpacity(0.3),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(ThemeProvider themeProvider) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: themeProvider.contrast.withOpacity(0.1),
      ),
      child: Icon(
        Icons.error_outline,
        size: widget.size * 0.4,
        color: themeProvider.contrast,
      ),
    );
  }

  void _showImageSourceDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: themeProvider.backgroundHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: themeProvider.theme.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              'Select Profile Picture',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () => _pickAndUploadImage(ImageSource.camera),
                  themeProvider: themeProvider,
                ),
                _buildSourceOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () => _pickAndUploadImage(ImageSource.gallery),
                  themeProvider: themeProvider,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeProvider themeProvider,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: themeProvider.theme.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: themeProvider.theme.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: themeProvider.theme,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: themeProvider.isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    Navigator.pop(context); // Close the bottom sheet
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null) {
      _showMessage('Please sign in to update your profile picture');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Pick image
      final imageFile = await ProfilePictureService.pickImage(source: source);
      if (imageFile == null) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Upload and update profile
      final newAvatarUrl = await ProfilePictureService.updateProfilePicture(
        userId: user.id,
        imageFile: imageFile,
        oldAvatarUrl: user.avatarUrl,
      );

      if (newAvatarUrl != null) {
        // Update user in AuthProvider
        await authProvider.updateProfile(avatarUrl: newAvatarUrl);
        
        _showMessage('Profile picture updated successfully!');
        widget.onImageChanged?.call();
      } else {
        _showMessage('Failed to upload profile picture');
      }
    } catch (e) {
      print('Error updating profile picture: $e');
      _showMessage('Error updating profile picture');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Provider.of<ThemeProvider>(context, listen: false).theme,
        ),
      );
    }
  }
}