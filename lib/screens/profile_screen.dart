import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../core/auth_service.dart';
import 'scan_history_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  UserData? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await _authService.getCurrentUserData();
    if (!mounted) return;
    setState(() {
      _userData = data;
      _isLoading = false;
    });
  }

  String get _initials {
    if (_userData == null) return '?';
    final parts = _userData!.name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _userData!.name.isNotEmpty ? _userData!.name[0].toUpperCase() : '?';
  }

  bool get _isLoggedIn => _userData != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primaryColor,
                              theme.primaryColor.withAlpha(204),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withAlpha(64),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _userData?.name ?? 'Guest User',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _userData?.phone ?? '',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    PrimaryButton(
                      label: 'Scan History',
                      icon: Icons.history_rounded,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ScanHistoryScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Settings & Shortcuts',
                      icon: Icons.tune_rounded,
                      onPressed: () {
                        Navigator.of(context).push<String>(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        ).then((result) {
                          if (result == 'login' && context.mounted) {
                            Navigator.of(context).pop('login');
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_isLoggedIn)
                      PrimaryButton(
                        label: 'Log out',
                        isSecondary: true,
                        borderColor: Colors.red.shade200,
                        textColor: Colors.red.shade700,
                        icon: Icons.logout_rounded,
                        onPressed: () {
                          Navigator.of(context).pop('logout');
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
