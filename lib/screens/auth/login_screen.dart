import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../data/db_helper.dart';
import '../cashier/cashier_shell.dart';
import '../owner/owner_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _attemptLogin() async {
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text.trim();
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter username and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final user = await DBHelper.instance.verifyLogin(username, password);

    if (!mounted) return;
    setState(() => _loading = false);

    if (user == null) {
      setState(() => _error = 'Invalid username or password.');
      _passCtrl.clear();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => user.role == 'owner'
            ? OwnerShell(fullName: user.fullName)
            : CashierShell(fullName: user.fullName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    IconButton(
                      alignment: Alignment.centerLeft,
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    BistroCard(
                      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset('assets/images/logo.jpg', width: 64, height: 64),
                          ),
                          const SizedBox(height: 14),
                          Text("Filipee's Bistro", style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 4),
                          const Text('MANAGEMENT SYSTEM',
                              style: TextStyle(
                                  color: AppColors.accent2,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  letterSpacing: 1.4)),
                          const SizedBox(height: 2),
                          const Text('Poblacion Branch',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 20),
                          _LabeledField(
                            label: 'Username',
                            controller: _userCtrl,
                            hint: 'Enter username...',
                          ),
                          const SizedBox(height: 14),
                          _LabeledField(
                            label: 'Password',
                            controller: _passCtrl,
                            hint: 'Enter password...',
                            obscure: _obscure,
                            suffix: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility_off : Icons.visibility,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text('⚠  $_error',
                                style: const TextStyle(color: AppColors.accentRed, fontSize: 12)),
                          ],
                          const SizedBox(height: 20),
                          GradientButton(
                            text: _loading ? 'Logging in...' : 'Login',
                            icon: _loading ? null : Icons.login,
                            onPressed: _loading ? null : _attemptLogin,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final bool obscure;
  final Widget? suffix;
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
        ),
      ],
    );
  }
}
