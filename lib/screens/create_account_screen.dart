import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_textfield.dart';
import '../core/auth_service.dart';

class CreateAccountScreen extends StatefulWidget {
  final VoidCallback onSignUp;
  final VoidCallback onBack;

  const CreateAccountScreen({
    super.key,
    required this.onSignUp,
    required this.onBack,
  });

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _languageController = TextEditingController(text: 'Urdu');
  final _authService = AuthService();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  String _cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  bool _isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    return digits.length >= 10;
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final phone = _cleanPhone(_phoneController.text.trim());
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final language = _languageController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter your full name.');
      return;
    }
    if (phone.isEmpty) {
      setState(() => _error = 'Please enter your phone number.');
      return;
    }
    if (!_isValidPhone(phone)) {
      setState(() => _error = 'Please enter a valid phone number (at least 10 digits).');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Please enter a password.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (language.isEmpty) {
      setState(() => _error = 'Please enter your preferred language.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _authService.signUp(
        name: name,
        phone: phone,
        password: password,
        language: language,
      );
      if (!mounted) return;
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please login.'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onBack();
      } else {
        final errorMsg = result.error ?? 'Sign up failed. Please try again.';
        setState(() {
          _isLoading = false;
          _error = errorMsg;
        });
      }
    } catch (e) {
      debugPrint("Signup screen error: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Take less than a minute',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Full Name',
                hint: 'e.g. Sohaib Akhlaq',
                prefixIcon: Icons.person_outline,
                controller: _nameController,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Phone Number',
                hint: '03xx-xxxxxxx',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                controller: _phoneController,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Password',
                hint: '********',
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                controller: _passwordController,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Confirm Password',
                hint: '********',
                obscureText: true,
                prefixIcon: Icons.lock_clock_outlined,
                controller: _confirmController,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Preferred Language',
                hint: 'Urdu',
                prefixIcon: Icons.translate_outlined,
                controller: _languageController,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 36),
              PrimaryButton(
                label: _isLoading ? 'Creating Account...' : 'Create Account',
                onPressed: _isLoading ? null : () => _handleSignUp(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1.5)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1.5)),
                ],
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Sign up with Google',
                isSecondary: true,
                borderColor: Colors.grey.shade300,
                textColor: Colors.black87,
                customIcon: Semantics(
                  label: 'Google logo',
                  excludeSemantics: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'G',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [Colors.blue, Colors.red, Colors.yellow, Colors.green],
                            ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                        ),
                      ),
                    ],
                  ),
                ),
                onPressed: () {},
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  Semantics(
                    button: true,
                    label: "Login",
                    child: GestureDetector(
                      onTap: _isLoading ? null : widget.onBack,
                      child: Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
