import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'permissions_screen.dart';
import 'terms_screen.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onPermissionsGranted;

  const SplashScreen({super.key, required this.onPermissionsGranted});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PermissionService _permissionService = PermissionService();
  bool _showPermissions = false;
  bool _showTerms = false;

  @override
  void initState() {
    super.initState();
    _initFirestore();
    _checkTermsAndPermissions();
  }

  Future<void> _checkTermsAndPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAcceptedTerms = prefs.getBool('has_accepted_terms') ?? false;

    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      if (!hasAcceptedTerms) {
        setState(() => _showTerms = true);
        return;
      }
      
      final alreadyGranted = await _permissionService.areAllGranted();
      if (alreadyGranted) {
        widget.onPermissionsGranted();
      } else {
        setState(() => _showPermissions = true);
      }
    });
  }

  Future<void> _initFirestore() async {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint("Firestore settings configured.");
    } catch (e) {
      debugPrint("Firestore settings error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showTerms) {
      return TermsScreen(
        onAccepted: () async {
          setState(() => _showTerms = false);
          final alreadyGranted = await _permissionService.areAllGranted();
          if (alreadyGranted) {
            widget.onPermissionsGranted();
          } else {
            setState(() => _showPermissions = true);
          }
        },
      );
    }
    if (_showPermissions) {
      return PermissionsScreen(
        onContinue: widget.onPermissionsGranted,
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFD97706),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: 'Roshni App Logo',
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              label: 'App name Roshni meaning light',
              child: const Text(
                'Roshni',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: 'Tagline Your light always with you',
              child: const Text(
                'آپ کی روشنی، ہر وقت ساتھ',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
