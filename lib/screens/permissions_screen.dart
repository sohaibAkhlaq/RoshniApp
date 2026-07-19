import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/permission_service.dart';
import '../widgets/primary_button.dart';

class PermissionsScreen extends StatefulWidget {
  final VoidCallback? onContinue;

  const PermissionsScreen({super.key, this.onContinue});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final PermissionService _permissionService = PermissionService();
  bool _isLoading = false;
  bool _needsCamera = true;
  bool _needsMic = true;
  bool _hasPermanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final cam = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    if (!mounted) return;
    setState(() {
      _needsCamera = cam != PermissionStatus.granted && cam != PermissionStatus.limited;
      _needsMic = mic != PermissionStatus.granted && mic != PermissionStatus.limited;
      _hasPermanentlyDenied =
          cam == PermissionStatus.permanentlyDenied ||
          mic == PermissionStatus.permanentlyDenied;
    });
  }

  Future<void> _requestSingle(Permission perm) async {
    final status = await perm.request();
    if (!mounted) return;
    setState(() {
      if (perm == Permission.camera) {
        _needsCamera = status != PermissionStatus.granted &&
                       status != PermissionStatus.limited;
      } else if (perm == Permission.microphone) {
        _needsMic = status != PermissionStatus.granted &&
                    status != PermissionStatus.limited;
      }
      if (status == PermissionStatus.permanentlyDenied) {
        _hasPermanentlyDenied = true;
      }
    });
  }

  Future<void> _handleContinue() async {
    setState(() => _isLoading = true);

    if (_hasPermanentlyDenied) {
      await _permissionService.openSettings();
      await _refreshStatus();
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (!_hasPermanentlyDenied && !_needsCamera && !_needsMic) {
        widget.onContinue?.call();
      }
      return;
    }

    final results = await _permissionService.requestAll();
    if (!mounted) return;

    final allGranted = results.values
        .every((s) => s == PermissionStatus.granted || s == PermissionStatus.limited);

    if (allGranted) {
      widget.onContinue?.call();
    } else {
      final anyPermanentlyDenied =
          results.values.any((s) => s == PermissionStatus.permanentlyDenied);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasPermanentlyDenied = anyPermanentlyDenied;
        _needsCamera = results[Permission.camera] != PermissionStatus.granted &&
                       results[Permission.camera] != PermissionStatus.limited;
        _needsMic = results[Permission.microphone] != PermissionStatus.granted &&
                    results[Permission.microphone] != PermissionStatus.limited;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_hasPermanentlyDenied) {
      return _buildPermanentlyDenied(theme);
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.security_rounded, size: 72, color: theme.primaryColor),
              const SizedBox(height: 32),
              const Text(
                'Permissions Required',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Roshni needs a few permissions to help you see the world.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildPermissionRow(
                context,
                icon: Icons.camera_alt_rounded,
                title: 'Camera',
                subtitle: 'Detect objects, read text, describe scenes',
                isDenied: _needsCamera,
                onRequest: () => _requestSingle(Permission.camera),
              ),
              const SizedBox(height: 16),
              _buildPermissionRow(
                context,
                icon: Icons.mic_rounded,
                title: 'Microphone',
                subtitle: 'Voice commands and audio feedback',
                isDenied: _needsMic,
                onRequest: () => _requestSingle(Permission.microphone),
              ),
              const SizedBox(height: 16),
              _buildPermissionRow(
                context,
                icon: Icons.volume_up_rounded,
                title: 'Speaker',
                subtitle: 'Voice readouts and sound cues',
                isDenied: false,
                onRequest: null,
              ),
              const Spacer(),
              PrimaryButton(
                label: _needsCamera || _needsMic
                    ? 'Grant Permissions'
                    : 'Allow & Continue',
                onPressed: _isLoading ? () {} : _handleContinue,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDenied,
    required VoidCallback? onRequest,
  }) {
    final theme = Theme.of(context);
    final bool granted = !isDenied;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: granted ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: granted
                  ? const Color(0xFFD1FAE5)
                  : theme.primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: granted ? const Color(0xFF10B981) : theme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (granted) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (isDenied && onRequest != null)
            Semantics(
              button: true,
              label: 'Grant $title permission',
              child: GestureDetector(
                onTap: onRequest,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Allow',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPermanentlyDenied(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.settings_suggest_rounded, size: 56, color: Color(0xFFDC2626)),
              ),
              const SizedBox(height: 32),
              const Text(
                'Permissions Blocked',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Camera or Microphone permission was permanently denied. '
                'To use Roshni, please enable them in App Settings.',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Open App Settings',
                onPressed: _permissionService.openSettings,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
