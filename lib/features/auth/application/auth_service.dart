import 'dart:developer' as dev;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
/// Wraps [FirebaseAuth] operations with meaningful error handling.
///
/// All methods throw a human-readable [String] message on failure so the
/// UI can display it directly without parsing [FirebaseAuthException] codes.
class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  // ── Auth state ────────────────────────────────────────────────────────────

  /// Stream of authentication state changes.
  /// Emits [User] when signed in and `null` when signed out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in user, or `null` if unauthenticated.
  User? get currentUser => _auth.currentUser;

  // ── Email / Password ──────────────────────────────────────────────────────

  /// Signs in an existing user with [email] and [password].
  ///
  /// Throws a human-readable [String] on failure.
  Future<UserCredential> signInWithEmailPassword(
      String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      dev.log('AuthService: signed in as ${cred.user?.email}', name: 'Auth');
      return cred;
    } on FirebaseAuthException catch (e) {
      throw _friendlyMessage(e);
    } catch (e) {
      throw 'Sign-in failed: $e';
    }
  }

  /// Creates a new account with [email] and [password].
  ///
  /// Throws a human-readable [String] on failure.
  Future<UserCredential> signUp(String email, String password, String name, String phone) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      
      final user = cred.user;
      if (user != null) {
        await user.updateDisplayName(name.trim());
        
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': name.trim(),
          'phone': phone.trim(),
          'email': email.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      
      dev.log('AuthService: registered ${user?.email}', name: 'Auth');
      return cred;
    } on FirebaseAuthException catch (e) {
      throw _friendlyMessage(e);
    } catch (e) {
      throw 'Registration failed: $e';
    }
  }

  /// Updates the user's profile details.
  Future<void> updateProfile(String name, String phone) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Not signed in.';
      
      await user.updateDisplayName(name.trim());
      
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'phone': phone.trim(),
      }, SetOptions(merge: true));
      
      dev.log('AuthService: updated profile for ${user.email}', name: 'Auth');
    } catch (e) {
      throw 'Failed to update profile: $e';
    }
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_guest');
      await _auth.signOut();
      dev.log('AuthService: signed out', name: 'Auth');
    } catch (e) {
      dev.log('AuthService: sign-out error — $e', name: 'Auth');
    }
  }

  /// Sends a password-reset email to [email].
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _friendlyMessage(e);
    } catch (e) {
      throw 'Password reset failed: $e';
    }
  }

  /// Sends a password-reset email via EmailJS.
  Future<void> sendPasswordResetViaEmailJS(
    String email, {
    required String serviceId,
    required String templateId,
    required String publicKey,
  }) async {
    try {
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'user_email': email.trim(),
          }
        }),
      );
      
      if (response.statusCode != 200) {
        throw 'EmailJS Error: ${response.body}';
      }
      
      dev.log('AuthService: EmailJS reset sent to $email', name: 'Auth');
    } catch (e) {
      throw 'Failed to send reset email via EmailJS: $e';
    }
  }

  // ── Error helpers ─────────────────────────────────────────────────────────

  String _friendlyMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for that email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Please choose a stronger password (min. 6 characters).';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'Authentication error (${e.code}).';
    }
  }
}
