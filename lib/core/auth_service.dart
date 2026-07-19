import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserData {
  final String uid;
  final String name;
  final String phone;
  final String language;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  UserData({
    required this.uid,
    required this.name,
    required this.phone,
    required this.language,
    this.createdAt,
    this.lastLoginAt,
  });

  factory UserData.fromMap(String uid, Map<String, dynamic> map) {
    return UserData(
      uid: uid,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      language: map['language'] as String? ?? 'Urdu',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      lastLoginAt: (map['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _skipKey = 'roshni_skip_login';

  Future<bool> isSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_skipKey) ?? false;
  }

  Future<void> setSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipKey, true);
  }

  Future<void> clearSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_skipKey);
  }

  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  bool get isLoggedInSync => _auth.currentUser != null;

  String? getUserId() => _auth.currentUser?.uid;

  String? getCurrentUserPhone() {
    final email = _auth.currentUser?.email;
    if (email == null || !email.endsWith('@roshni.app')) return null;
    final local = email.split('@').first;
    return local;
  }

  Future<UserData?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        final phone = getCurrentUserPhone();
        return UserData(
          uid: user.uid,
          name: phone ?? 'User',
          phone: phone ?? '',
          language: 'Urdu',
        );
      }
      return UserData.fromMap(user.uid, doc.data()!);
    } catch (e) {
      debugPrint("getCurrentUserData error: $e");
      final phone = getCurrentUserPhone();
      return UserData(
        uid: user.uid,
        name: phone ?? 'User',
        phone: phone ?? '',
        language: 'Urdu',
      );
    }
  }

  Future<AuthResult> signUp({
    required String name,
    required String phone,
    required String password,
    required String language,
  }) async {
    try {
      final email = _emailFromPhone(phone);
      debugPrint("Signing up with email: $email");
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'phone': phone,
        'language': language,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      await _auth.signOut();
      return AuthResult.ok();
    } on FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException [${e.code}]: ${e.message}");
      return AuthResult.error(_friendlyMessage(e));
    } on FirebaseException catch (e) {
      debugPrint("FirebaseException [${e.code}]: ${e.message}");
      return AuthResult.error(_firebaseErrorMessage(e));
    } catch (e) {
      debugPrint("Auth signUp error: $e");
      return AuthResult.error('Something went wrong. Please try again.');
    }
  }

  Future<AuthResult> login({
    required String phone,
    required String password,
  }) async {
    try {
      final email = _emailFromPhone(phone);
      debugPrint("Logging in with email: $email");
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final uid = _auth.currentUser!.uid;

      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      return AuthResult.ok();
    } on FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException [${e.code}]: ${e.message}");
      return AuthResult.error(_friendlyMessage(e));
    } on FirebaseException catch (e) {
      debugPrint("FirebaseException [${e.code}]: ${e.message}");
      return AuthResult.error(_firebaseErrorMessage(e));
    } catch (e) {
      debugPrint("Auth login error: $e");
      return AuthResult.error('Something went wrong. Please try again.');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _emailFromPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    return '$cleaned@roshni.app';
  }

  String _friendlyMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'email-already-in-use':
        return 'This phone number is already registered. Please login.';
      case 'invalid-email':
        return 'Invalid phone number.';
      case 'user-not-found':
        return 'No account found with this phone number.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Incorrect phone number or password.';
      case 'internal-configuration-not-found':
        return 'Firebase not configured. Please check Firebase Console and ensure Email/Password auth is enabled.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled. Please enable it in Firebase Console.';
      default:
        return '${e.message ?? "Authentication failed."} (${e.code})';
    }
  }

  String _firebaseErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'internal-configuration-not-found':
        return 'Firebase not configured. Please ensure Firebase is properly set up in your project.';
      default:
        return '${e.message ?? "Firebase error occurred."} (${e.code})';
    }
  }
}

class AuthResult {
  final bool success;
  final String? error;

  AuthResult._({required this.success, this.error});

  factory AuthResult.ok() => AuthResult._(success: true);
  factory AuthResult.error(String error) => AuthResult._(success: false, error: error);
}
