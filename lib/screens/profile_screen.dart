import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartexpense/services/auth_service.dart';
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
    if (_user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF1C1C23) : const Color(0xFFF4F5F7);
    final cardColor = isDarkMode ? const Color(0xFF2A2A35) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).primaryColor,
                backgroundImage: _profileImage != null
                    ? FileImage(File(_profileImage!.path)) as ImageProvider<Object>
                    : (_user?.photoURL != null && _user!.photoURL!.isNotEmpty
                        ? NetworkImage(_user!.photoURL!) as ImageProvider<Object>
                        : null),
                child: _profileImage == null && (_user?.photoURL == null || _user!.photoURL!.isEmpty)
                    ? Text(
                        _getUserInitials(),
                        style: const TextStyle(fontSize: 32, color: Colors.white),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _nameController.text.isNotEmpty ? _nameController.text : (_user?.displayName ?? 'User'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _user?.email ?? 'No email',
              style: TextStyle(
                fontSize: 16,
                color: textColor.withAlpha(180),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child: const Text('Update Profile'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('User ID', _user?.uid ?? 'N/A', textColor),
                  _buildInfoRow('Email', _user?.email ?? 'N/A', textColor),
                  _buildInfoRow('Email Verified', _user?.emailVerified ?? false ? 'Yes' : 'No', textColor),
                  if (!(_user?.emailVerified ?? true))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ElevatedButton(
                        onPressed: _sendVerificationEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          minimumSize: const Size(double.infinity, 40),
                        ),
                        child: const Text('Send Verification Email'),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Account Created', _user?.metadata.creationTime?.toString().substring(0, 10) ?? 'N/A', textColor),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_circle, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Account Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // -------------------- HELPER METHODS --------------------
  // Paste these INSIDE _ProfileScreenState, before the last '}'

  Widget _buildInfoRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor.withAlpha(179), 
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
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
