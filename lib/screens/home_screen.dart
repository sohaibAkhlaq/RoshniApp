import 'package:flutter/material.dart';
import '../core/auth_service.dart';
import '../widgets/feature_card.dart';
import '../widgets/gesture_bar.dart';
import 'profile_screen.dart';
import 'object_detection_screen.dart';
import 'urdu_ocr_screen.dart';
import 'currency_screen.dart';
import 'document_screen.dart';
import 'photo_description_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  final VoidCallback? onLoginRequested;

  const HomeScreen({super.key, this.onLogout, this.onLoginRequested});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  String _initials = 'R';

  @override
  void initState() {
    super.initState();
    _loadInitials();
  }

  Future<void> _loadInitials() async {
    final data = await _authService.getCurrentUserData();
    if (!mounted) return;
    if (data != null && data.name.isNotEmpty && data.name != data.phone) {
      final parts = data.name.split(' ');
      final init = parts.length >= 2
          ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
          : data.name[0].toUpperCase();
      setState(() => _initials = init);
    } else if (_authService.isLoggedInSync) {
      final phone = _authService.getCurrentUserPhone() ?? '';
      setState(() => _initials = phone.isNotEmpty ? phone.substring(phone.length - 2) : 'U');
    } else {
      setState(() => _initials = 'G');
    }
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    ).then((result) {
      if (!context.mounted || result == null) return;
      if (result == 'logout') {
        widget.onLogout?.call();
      } else if (result == 'login') {
        widget.onLoginRequested?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roshni'),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Semantics(
              button: true,
              label: "Open Profile Settings",
              child: InkWell(
                onTap: () => _openProfile(context),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.primaryColor, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.primaryColor,
                    child: Text(
                      _initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openProfile(context),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: theme.primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.primaryColor.withAlpha(38), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.light_mode, color: theme.primaryColor, size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'آپ کی روشنی، ہر وقت ساتھ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 40),
                children: [
                  FeatureCard(
                    number: 1,
                    title: 'Object Detection',
                    subtitle: 'Scan surroundings',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ObjectDetectionScreen()),
                      );
                    },
                  ),
                  FeatureCard(
                    number: 2,
                    title: 'Urdu OCR Reader',
                    subtitle: 'Read Text Aloud',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const UrduOCRScreen()),
                      );
                    },
                  ),
                  FeatureCard(
                    number: 3,
                    title: 'Currency Classifier',
                    subtitle: 'Identify rupee notes',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CurrencyScreen()),
                      );
                    },
                  ),
                  FeatureCard(
                    number: 4,
                    title: 'Document Reader',
                    subtitle: 'Bills & slips',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DocumentScreen()),
                      );
                    },
                  ),
                  FeatureCard(
                    number: 5,
                    title: 'Photo Description',
                    subtitle: 'Describe a scene',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PhotoDescriptionScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const GestureBar(),
          ],
        ),
      ),
    );
  }
}
