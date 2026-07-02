// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _remember = true;

  @override
  Widget build(BuildContext context) {
    final isValid = _phoneController.text.length == 10;

    return Scaffold(
      backgroundColor: kCard,
      body: Column(
        children: [
          // Header
          Container(
            height: 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
              ),
            ),
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome Back',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Sign in to your workshop account',
                    style: TextStyle(fontSize: 14, color: Colors.blue[200])),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text('Mobile Number',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kForeground)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: kMuted,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: kBorder),
                        ),
                        child: const Row(
                          children: [
                            Text('🇮🇳 +91', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: kMutedForeground),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Enter mobile number',
                            hintStyle: const TextStyle(color: kMutedForeground),
                            counterText: '',
                            filled: true,
                            fillColor: kMuted,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: kBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: kBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: kPrimary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isValid ? () => context.go('/otp') : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: kPrimary.withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 4,
                        shadowColor: kPrimary.withOpacity(0.4),
                      ),
                      child: const Text('Send OTP', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),

                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => setState(() => _remember = !_remember),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _remember ? kPrimary : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _remember ? kPrimary : kBorder, width: 2),
                          ),
                          child: _remember
                              ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        const Text('Remember me on this device',
                            style: TextStyle(fontSize: 13, color: kMutedForeground)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: kBorder)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                      ),
                      const Expanded(child: Divider(color: kBorder)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.fingerprint_rounded, color: kPrimary),
                      label: const Text('Login with Biometrics',
                          style: TextStyle(color: kForeground, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        side: const BorderSide(color: kBorder),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}