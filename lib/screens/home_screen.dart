import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../core/auth_service.dart';
import '../widgets/feature_card.dart';
import '../widgets/gesture_bar.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
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
  final FlutterTts _tts = FlutterTts();
  final List<GlobalKey> _cardKeys = List.generate(5, (_) => GlobalKey());
  int? _hoveredIndex;
  String _initials = 'R';

  final List<String> _urduAudioPrompts = [
    "آس پاس کی چیزیں پہچاننے کا نظام۔ اپنے ارد گرد موجود میز، کرسی، دروازہ یا راستہ جاننے کے لیے ڈبل ٹیپ کریں",
    "اردو لکھائی اور تحریر پڑھنے کا نظام۔ کسی بھی کتاب، سائن بورڈ یا پرچی پر لکھی اردو سننے کے لیے ڈبل ٹیپ کریں",
    "پاکستانی نوٹ پہچاننے کا نظام۔ 10 روپے سے لے کر 5000 تک کے کسی بھی نوٹ کی تصدیق کے لیے ڈبل ٹیپ کریں",
    "بل اور ضروری کاغذات پڑھنے کا نظام۔ بجلی یا گیس کا بل، رسید اور انگریزی تحریر پڑھنے کے لیے ڈبل ٹیپ کریں",
    "تصویر اور ماحول کا منظر جاننے کا نظام۔ کیمرے کے سامنے موجود منظر یا تصویر کی مکمل تفصیل سننے کے لیے ڈبل ٹیپ کریں",
  ];

  final List<String> _openingPrompts = [
    "آس پاس کی چیزیں پہچاننے کا نظام کھل رہا ہے",
    "اردو لکھائی پڑھنے کا نظام کھل رہا ہے",
    "نوٹ پہچاننے کا نظام کھل رہا ہے",
    "بل اور کاغذات پڑھنے کا نظام کھل رہا ہے",
    "منظر جاننے کا نظام کھل رہا ہے",
  ];

  @override
  void initState() {
    super.initState();
    _loadInitials();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ur-PK');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
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

  void _onExploreCard(int index) {
    if (_hoveredIndex == index) return;
    setState(() => _hoveredIndex = index);
    HapticFeedback.selectionClick();
    _tts.stop();
    _tts.speak(_urduAudioPrompts[index]);
  }

  void _openFeature(int index) {
    _tts.stop();
    HapticFeedback.mediumImpact();
    _tts.speak(_openingPrompts[index]);
    Widget? screen;
    switch (index) {
      case 0:
        screen = const ObjectDetectionScreen();
        break;
      case 1:
        screen = const UrduOCRScreen();
        break;
      case 2:
        screen = const CurrencyScreen();
        break;
      case 3:
        screen = const DocumentScreen();
        break;
      case 4:
        screen = const PhotoDescriptionScreen();
        break;
    }
    if (screen != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen!));
    }
  }

  void _handlePointerMove(Offset globalPosition) {
    for (int i = 0; i < _cardKeys.length; i++) {
      final context = _cardKeys[i].currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && box.attached) {
          final rect = box.localToGlobal(Offset.zero) & box.size;
          if (rect.contains(globalPosition)) {
            _onExploreCard(i);
            break;
          }
        }
      }
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

  void _openSettings(BuildContext context) {
    Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
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
            onPressed: () => _openSettings(context),
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
              child: Listener(
                onPointerDown: (event) => _handlePointerMove(event.position),
                onPointerMove: (event) => _handlePointerMove(event.position),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onDoubleTap: () {
                    if (_hoveredIndex != null) {
                      _openFeature(_hoveredIndex!);
                    }
                  },
                  child: ListView(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 40),
                    children: [
                      FeatureCard(
                        key: _cardKeys[0],
                        number: 1,
                        title: 'آس پاس کی چیزیں (Things Around Me)',
                        subtitle: 'کمرے یا راستے کی اشیاء پہچانیں',
                        isSelected: _hoveredIndex == 0,
                        onTap: () => _hoveredIndex == 0 ? _openFeature(0) : _onExploreCard(0),
                      ),
                      FeatureCard(
                        key: _cardKeys[1],
                        number: 2,
                        title: 'اردو لکھائی پڑھیں (Read Urdu Writing)',
                        subtitle: 'کتاب، بورڈ یا کاغذ کی تحریر',
                        isSelected: _hoveredIndex == 1,
                        onTap: () => _hoveredIndex == 1 ? _openFeature(1) : _onExploreCard(1),
                      ),
                      FeatureCard(
                        key: _cardKeys[2],
                        number: 3,
                        title: 'پاکستانی نوٹ پہچانیں (Rupee Notes)',
                        subtitle: '10 سے 5000 تک کا نوٹ جانیں',
                        isSelected: _hoveredIndex == 2,
                        onTap: () => _hoveredIndex == 2 ? _openFeature(2) : _onExploreCard(2),
                      ),
                      FeatureCard(
                        key: _cardKeys[3],
                        number: 4,
                        title: 'بل اور کاغذات پڑھیں (Read Bills)',
                        subtitle: 'بجلی کا بل، رسید یا انگریزی تحریر',
                        isSelected: _hoveredIndex == 3,
                        onTap: () => _hoveredIndex == 3 ? _openFeature(3) : _onExploreCard(3),
                      ),
                      FeatureCard(
                        key: _cardKeys[4],
                        number: 5,
                        title: 'تصویر کا منظر جانیں (Scene Details)',
                        subtitle: 'تصویر یا ماحول کا مکمل حال سنیں',
                        isSelected: _hoveredIndex == 4,
                        onTap: () => _hoveredIndex == 4 ? _openFeature(4) : _onExploreCard(4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const GestureBar(),
          ],
        ),
      ),
    );
  }
}
