import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/permission_service.dart';
import 'permissions_screen.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onPermissionsGranted;

  const SplashScreen({super.key, required this.onPermissionsGranted});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PermissionService _permissionService = PermissionService();
  bool _showPermissions = false;

  @override
  void initState() {
    super.initState();
    _initFirestore();
    _checkPermissions();
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

  Future<void> _checkPermissions() async {
    final alreadyGranted = await _permissionService.areAllGranted();
    if (!mounted) return;
    if (alreadyGranted) {
      widget.onPermissionsGranted();
    } else {
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() => _showPermissions = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: const Text(
                'R',
                style: TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
