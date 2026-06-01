import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;


class AuthService with ChangeNotifier {
  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;
  GoogleSignInAccount? _googleSignInAccount;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleSignInSubscription;

  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;
  GoogleSignInAccount? get googleSignInAccount => _googleSignInAccount;

  bool _isSendingVerification = false;
  bool get isSendingVerification => _isSendingVerification;
  set isSendingVerification(bool value) {
    if (_isSendingVerification != value) {
      _isSendingVerification = value;
      notifyListeners();
    }
  }

  AuthService() {
    // Initialize Firebase Auth only if Firebase is initialized
    try {
      _auth = FirebaseAuth.instance;
    } catch (e) {
      debugPrint('Firebase Auth not available: $e');
      _auth = null;
    }
    if (!kIsWeb && !Platform.isLinux) {
      try {
        _googleSignIn = GoogleSignIn.instance;

        // Initialize Google Sign-In
        _googleSignIn!.initialize().then((_) {
          debugPrint('Google Sign-In initialized successfully');
          // Listen to authentication events
          _googleSignInSubscription = _googleSignIn!.authenticationEvents.listen(
            _handleAuthenticationEvent,
            onError: (error) {
              debugPrint('Google Sign-In authentication error: $error');
            },
          );

          // Attempt lightweight authentication (silent sign-in)
          _googleSignIn!.attemptLightweightAuthentication()!.catchError((e) {
            debugPrint('Lightweight authentication failed: $e');
            return null;
          });
        }).catchError((e) {
          debugPrint('Google Sign-In initialization failed: $e');
        });
      } catch (e) {
        debugPrint('Google Sign-In setup failed: $e');
        _googleSignIn = null;
      }
    } else {
      if (Platform.isLinux) {
        debugPrint('Google Sign-In disabled for Linux platform');
      } else {
        debugPrint('Google Sign-In disabled for web platform');
      }
      _googleSignIn = null;
    }
  }

  void _handleAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn():
        _googleSignInAccount = event.user;
        notifyListeners();
        break;
      case GoogleSignInAuthenticationEventSignOut():
        _googleSignInAccount = null;
        notifyListeners();
        break;
    }
  }

  @override
  void dispose() {
    _googleSignInSubscription?.cancel();
    super.dispose();
  }

  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? Stream.value(null);

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (_googleSignIn == null) {
        debugPrint('Google Sign-In not available');
        throw Exception('Google Sign-In not available on this platform');
      }

      debugPrint('Starting Google Sign-In flow...');

      // Authenticate with Google
      GoogleSignInAccount googleUser;
      try {
        googleUser = await _googleSignIn!.authenticate();
        debugPrint('Google Sign-In authenticate() completed successfully');
      } on GoogleSignInException catch (e) {
        debugPrint('GoogleSignInException caught: code=${e.code}');
        if (e.code == GoogleSignInExceptionCode.canceled) {
          debugPrint('Google Sign-In canceled by user');
          return null;
        }
        rethrow;
      } catch (e) {
        debugPrint('Unexpected error during Google Sign-In authenticate(): $e');
        rethrow;
      }
      
      
      // Request Drive scope authorization
      await googleUser.authorizationClient.authorizeScopes([
        drive.DriveApi.driveFileScope,
      ]);

      _googleSignInAccount = googleUser;
      debugPrint('Google user selected: ${googleUser.email}');
      
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      debugPrint('Google auth obtained - idToken: ${googleAuth.idToken != null}');

      if (googleAuth.idToken == null) {
        throw Exception('Failed to obtain Google authentication tokens');
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      debugPrint('Signing in with Firebase...');
      
      final result = await _auth!.signInWithCredential(credential);
      debugPrint('Firebase sign-in successful: ${result.user?.email}');
      
      return result;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      if (e is FirebaseAuthException) {
        debugPrint('FirebaseAuthException code: ${e.code}');
        debugPrint('FirebaseAuthException message: ${e.message}');
      }
      rethrow;
    }
  }

  Future<drive.DriveApi?> getDriveApi() async {
    if (_googleSignInAccount == null) {
      debugPrint('Google user not signed in for Drive API access.');
      return null;
    }
    
    try {
      // Get authorization headers for Drive API scope
      final authHeaders = await _googleSignInAccount!.authorizationClient
          .authorizationHeaders([drive.DriveApi.driveFileScope]);
      
      if (authHeaders == null || authHeaders.isEmpty) {
        debugPrint('No auth headers available');
        return null;
      }

      final client = GoogleAuthClient(authHeaders);
      // The caller is now responsible for the client's lifecycle.
      return drive.DriveApi(client);
      
    } catch (e) {
      debugPrint('Error creating Drive API client: $e');
      return null;
    }
  }

  // Check if user is properly authenticated for Drive access
  Future<bool> isDriveAccessAvailable() async {
    if (_googleSignInAccount == null) return false;
    
    try {
      final authHeaders = await _googleSignInAccount!.authorizationClient
          .authorizationHeaders([drive.DriveApi.driveFileScope]);
      return authHeaders != null && authHeaders.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking Drive access: $e');
      return false;
    }
  }

  // Get detailed error message for sync failures
  String getSyncErrorMessage(dynamic error) {
    if (error.toString().contains('network')) {
      return 'Network connection error. Please check your internet connection.';
    } else if (error.toString().contains('auth') || error.toString().contains('401')) {
      return 'Authentication error. Please sign out and sign in again.';
    } else if (error.toString().contains('403')) {
      return 'Permission denied. Please sign out and sign in again to grant proper Google Drive permissions.';
    } else if (error.toString().contains('quota')) {
      return 'Google Drive quota exceeded. Please free up space.';
    } else {
      return 'Sync failed: ${error.toString()}';
    }
  }

  // Force re-authentication to get updated scopes
  Future<UserCredential?> reAuthenticateWithGoogle() async {
    try {
      debugPrint('Re-authenticating with Google to get updated permissions...');

      // First, sign out completely to ensure all tokens are cleared.
      await signOut();
      
      // Now, sign in again to get fresh permissions.
      return await signInWithGoogle();
    } catch (e) {
      debugPrint('Re-authentication failed: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    if (_auth == null) {
      debugPrint('Firebase Auth not available on this platform');
      return null;
    }
    try {
      return await _auth!.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint('Email/Password Sign-In Error: $e');
      return null;
    }
  }

  Future<UserCredential?> createUserWithEmailPassword(String email, String password) async {
    if (_auth == null) {
      debugPrint('Firebase Auth not available on this platform');
      return null;
    }
    try {
      return await _auth!.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint('Email/Password Registration Error: $e');
      return null;
    }
  }

  Future<UserCredential?> signInAnonymously() async {
    if (_auth == null) {
      debugPrint('Firebase Auth not available on this platform');
      return null;
    }
    try {
      return await _auth!.signInAnonymously();
    } catch (e) {
      debugPrint('Anonymous Sign-In Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      // Sign out from Google first
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
      }

      // Then sign out from Firebase
      if (_auth != null) {
        await _auth!.signOut();
      }

      // Clear local state
      _googleSignInAccount = null;

      // Notify listeners
      notifyListeners();

      debugPrint('Successfully signed out');
    } catch (e) {
      debugPrint('Error during sign out: $e');
      // Even if there's an error, clear local state
      _googleSignInAccount = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> verifyEmail() async {
    if (_auth == null) {
      debugPrint('Firebase Auth not available on this platform');
      return;
    }
    final user = _auth!.currentUser;
    if (user != null) {
      // Check if user signed in with Google (Google users are automatically verified)
      final isGoogleUser = user.providerData.any((provider) => provider.providerId == 'google.com');

      if (isGoogleUser) {
        throw FirebaseAuthException(
          code: 'google-user-verified',
          message: 'Google accounts are automatically verified and do not need email verification.',
        );
      }

      if (!user.emailVerified) {
        await user.sendEmailVerification();
      } else {
        throw FirebaseAuthException(
          code: 'already-verified',
          message: 'Email is already verified.',
        );
      }
    }
  }

  Future<void> resetPassword(String email) async {
    if (_auth == null) {
      debugPrint('Firebase Auth not available on this platform');
      return;
    }
    if (email.isNotEmpty) {
      await _auth!.sendPasswordResetEmail(email: email);
    }
  }

  Future<void> changeEmail(String newEmail, String password) async {
    if (_auth == null) {
      debugPrint('Firebase Auth not available on this platform');
      return;
    }
    final user = _auth!.currentUser;
    if (user != null) {
      final credential = EmailAuthProvider.credential(
        email: user.email ?? '',
        password: password
      );

      await user.reauthenticateWithCredential(credential);
      await user.verifyBeforeUpdateEmail(newEmail);
    }
  }

  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    if (_auth == null) {
      debugPrint('Firebase Auth not available on this platform');
      return;
    }
    final user = _auth!.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);
      await user.reload();
      notifyListeners();
    }
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // Add all authentication headers
    request.headers.addAll(_headers);
    
    // Add locale header to prevent X-Firebase-Locale warnings
    if (!request.headers.containsKey('X-Firebase-Locale')) {
      request.headers['X-Firebase-Locale'] = 'en';
    }
    
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}
