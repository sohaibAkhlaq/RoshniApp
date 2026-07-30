import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/primary_button.dart';
import 'dart:io';

class TermsScreen extends StatelessWidget {
  final VoidCallback onAccepted;

  const TermsScreen({super.key, required this.onAccepted});

  Future<void> _acceptTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_accepted_terms', true);
    onAccepted();
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Welcome to Roshni'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.shield_rounded, size: 80, color: Color(0xFFD97706)),
              const SizedBox(height: 24),
              const Text(
                'Terms & Privacy Policy',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Before you start using Roshni, please review and accept our Terms of Service and Privacy Policy. We are committed to protecting your data.',
                style: TextStyle(fontSize: 16, color: Color(0xFF4B5563), height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ListTile(
                leading: const Icon(Icons.description_rounded, color: Color(0xFFD97706)),
                title: const Text('Read Terms of Service', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                onTap: () => _launchUrl('https://roshni-app.vercel.app/terms.html'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.white,
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.privacy_tip_rounded, color: Color(0xFFD97706)),
                title: const Text('Read Privacy Policy', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                onTap: () => _launchUrl('https://roshni-app.vercel.app/privacy-policy.html'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.white,
              ),
              const Spacer(),
              PrimaryButton(
                label: 'I Accept',
                onPressed: _acceptTerms,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => exit(0),
                child: const Text(
                  'Decline and Exit',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
