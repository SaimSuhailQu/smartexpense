import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartexpense/services/auth_service.dart';
import 'package:smartexpense/theme/app_colors.dart';
import 'package:smartexpense/theme/typography.dart';
import 'package:smartexpense/theme/spacing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  User? _user;
  final TextEditingController _nameController = TextEditingController();
  StreamSubscription<User?>? _authSubscription;
  XFile? _profileImage;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _user = user;
          if (user != null) {
            _nameController.text = user.displayName ?? user.email?.split('@')[0] ?? '';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  String _getUserInitials() {
    if (_profileImage != null) {
      return ''; // No initials if image is selected
    } else if (_user?.photoURL?.isNotEmpty == true) {
      return ''; // No initials if photoURL is available
    } else if (_user?.displayName?.isNotEmpty == true) {
      return _user!.displayName!.substring(0, 1).toUpperCase();
    } else if (_user?.email?.isNotEmpty == true) {
      return _user!.email!.substring(0, 1).toUpperCase();
    } else {
      return 'U';
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a display name')),
      );
      return;
    }

    try {
      String? photoURL;
      if (_profileImage != null) {
        // Upload image to Firebase Storage
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${_user!.uid}.jpg');
        await ref.putFile(File(_profileImage!.path));
        photoURL = await ref.getDownloadURL();
      }

      await _authService.updateProfile(displayName: _nameController.text.trim(), photoURL: photoURL);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        if (mounted) {
          setState(() {
            _user = user;
            _profileImage = null; // Clear picked image after upload
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  Future<void> _sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification email sent. Please check your inbox.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send verification email: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    if (_user == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      // Background color using theme-aware surface color
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: AppTypography.headingMedium(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            AppSpacing.verticalSpaceXL,
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    backgroundImage: _profileImage != null
                        ? FileImage(File(_profileImage!.path)) as ImageProvider<Object>
                        : (_user?.photoURL != null && _user!.photoURL!.isNotEmpty
                            ? NetworkImage(_user!.photoURL!) as ImageProvider<Object>
                            : null),
                    child: _profileImage == null && (_user?.photoURL == null || _user!.photoURL!.isEmpty)
                        ? Text(
                            _getUserInitials(),
                            style: AppTypography.headingXLarge(color: Colors.white),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.verticalSpaceLG,
            Text(
              _nameController.text.isNotEmpty ? _nameController.text : (_user?.displayName ?? 'User'),
              style: AppTypography.headingLarge(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            AppSpacing.verticalSpaceSM,
            Text(
              _user?.email ?? 'No email',
              style: AppTypography.bodyLarge(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            AppSpacing.verticalSpaceXXL,
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.getSurfaceColor(theme.brightness, 1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Information',
                    style: AppTypography.headingMedium(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  AppSpacing.verticalSpaceLG,
                  TextField(
                    controller: _nameController,
                    style: AppTypography.bodyMedium(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      labelStyle: AppTypography.labelMedium(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                      ),
                    ),
                  ),
                  AppSpacing.verticalSpaceLG,
                  ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                      ),
                    ),
                    child: Text(
                      'Update Profile',
                      style: AppTypography.buttonMedium(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.verticalSpaceXXL,
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.getSurfaceColor(theme.brightness, 1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Information',
                    style: AppTypography.headingMedium(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  AppSpacing.verticalSpaceLG,
                  _buildInfoRow('User ID', _user?.uid ?? 'N/A', isDark),
                  _buildInfoRow('Email', _user?.email ?? 'N/A', isDark),
                  _buildInfoRow('Email Verified', _user?.emailVerified ?? false ? 'Yes' : 'No', isDark),
                  if (!(_user?.emailVerified ?? true))
                    Padding(
                      padding: EdgeInsets.only(top: AppSpacing.md),
                      child: ElevatedButton(
                        onPressed: _sendVerificationEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                          ),
                        ),
                        child: Text(
                          'Send Verification Email',
                          style: AppTypography.buttonMedium(color: Colors.white),
                        ),
                      ),
                    ),
                  AppSpacing.verticalSpaceLG,
                  _buildInfoRow('Account Created', _user?.metadata.creationTime?.toString().substring(0, 10) ?? 'N/A', isDark),
                ],
              ),
            ),
            AppSpacing.verticalSpaceXXL,
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.getSurfaceColor(theme.brightness, 1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_circle, color: AppColors.primary),
                      AppSpacing.horizontalSpaceSM,
                      Text(
                        'Account Actions',
                        style: AppTypography.headingMedium(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      if (_user != null) ...[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor.withAlpha(25),
                            child: Text(
                              _user!.email![0].toUpperCase(),
                              style: TextStyle(color: Theme.of(context).primaryColor),
                            ),
                          ),
                          title: Text(
                            _user!.email!,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(color: textColor),
                          ),
                          subtitle: Text(
                            _user!.emailVerified ? 'Verified' : 'Not verified',
                            style: TextStyle(color: textColor.withAlpha(180)),
                          ),
                          trailing: _user!.emailVerified
                              ? const Icon(Icons.verified, color: Colors.green)
                              : const Icon(Icons.warning, color: Colors.orange),
                        ),
                        const Divider(),
                      ],
                      if (_user != null && !_user!.emailVerified)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.verified, color: Colors.green),
                          title: Text('Verify Email', style: TextStyle(color: textColor)),
                          subtitle: Text('Send verification email', style: TextStyle(color: textColor.withAlpha(180))),
                          onTap: () => _handleVerifyEmail(_authService, _user!),
                        ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.restart_alt, color: Colors.orange),
                        title: Text('Reset Password', style: TextStyle(color: textColor)),
                        subtitle: Text('Send password reset email', style: TextStyle(color: textColor.withAlpha(180))),
                        onTap: () => _handleResetPassword(_authService, _user),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.edit, color: Colors.blue),
                        title: Text('Change Email', style: TextStyle(color: textColor)),
                        subtitle: Text('Update your email address', style: TextStyle(color: textColor.withAlpha(180))),
                        onTap: () => _handleChangeEmail(_authService, _user),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: Text('Sign Out', style: TextStyle(color: textColor)),
                        subtitle: Text('Sign out of your account', style: TextStyle(color: textColor.withAlpha(180))),
                        onTap: () => _handleSignOut(_authService),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppSpacing.verticalSpaceLG,
            ElevatedButton(
              onPressed: () async {
                await _authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expenseNormal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                ),
              ),
              child: Text(
                'Sign Out',
                style: AppTypography.buttonLarge(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // -------------------- HELPER METHODS --------------------
  // Paste these INSIDE _ProfileScreenState, before the last '}'

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.labelLarge(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          AppSpacing.horizontalSpaceLG,
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: AppTypography.bodyMedium(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVerifyEmail(AuthService authService, User user) async {
    try {
      await user.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent. Please check your inbox.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleResetPassword(AuthService authService, User? user) async {
    if (user?.email == null) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'An error occurred';
        if (e.code == 'user-not-found') message = 'No user found with this email.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  Future<void> _handleChangeEmail(AuthService authService, User? user) async {
    if (user == null) return;
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'A verification email will be sent to the new address.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'New Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newEmail = controller.text.trim();
              if (newEmail.isEmpty || !newEmail.contains('@')) return;
              
              Navigator.pop(dialogContext); // Close dialog
              
              try {
                // Securely verify before updating
                await user.verifyBeforeUpdateEmail(newEmail);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Verification sent to $newEmail')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut(AuthService authService) async {
    try {
      await authService.signOut();
      if (mounted) {
        // Ensure you have a route named '/login' defined in your MaterialApp
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
  }

}
