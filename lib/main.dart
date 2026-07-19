import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/auth_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_account_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };

  debugPrint("Starting app...");
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint("Firebase initialized successfully.");
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }
  debugPrint("App is about to run.");

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService _authService = AuthService();
  int _screenIndex = 0;

  void _goToHome() => setState(() => _screenIndex = 3);
  void _goToLogin() => setState(() => _screenIndex = 2);
  void _goToCreateAccount() => setState(() => _screenIndex = 4);

  Future<void> _onPermissionsDone() async {
    try {
      final loggedIn = await _authService.isLoggedIn();
      final skipped = await _authService.isSkipped();
      if (!mounted) return;
      if (loggedIn || skipped) {
        _goToHome();
      } else {
        _goToLogin();
      }
    } catch (e) {
      debugPrint("Permission check error: $e");
      if (!mounted) return;
      _goToLogin();
    }
  }

  Future<void> _onSkip() async {
    await _authService.setSkipped();
    _goToHome();
  }

  Future<void> _onLoginSuccess() async {
    await _authService.clearSkipped();
    _goToHome();
  }

  Future<void> _onLogout() async {
    await _authService.signOut();
    await _authService.clearSkipped();
    _goToLogin();
  }

  void _onLoginRequestedFromSettings() {
    _goToLogin();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roshni App',
      theme: AppTheme.lightTheme,
      home: _buildScreen(),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _buildScreen() {
    switch (_screenIndex) {
      case 1:
        return SplashScreen(
          onPermissionsGranted: _onPermissionsDone,
        );
      case 2:
        return LoginScreen(
          onLogin: _onLoginSuccess,
          onSkip: _onSkip,
          onCreateAccount: _goToCreateAccount,
        );
      case 3:
        return HomeScreen(
          onLogout: _onLogout,
          onLoginRequested: _onLoginRequestedFromSettings,
        );
      case 4:
        return CreateAccountScreen(
          onSignUp: _goToLogin,
          onBack: _goToLogin,
        );
      case 0:
      default:
        return SplashScreen(
          onPermissionsGranted: _onPermissionsDone,
        );
    }
  }
}
