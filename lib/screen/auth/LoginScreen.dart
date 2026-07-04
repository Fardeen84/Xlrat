// lib/screen/auth/LoginScreen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xlrat/l10n/app_localizations.dart';

import '../../core/theme.dart';
import '../../core/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPinSet = false;
  bool _isLoading = true;
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _checkPinStatus() async {
    final hasPin = await AuthState.isPinSet();
    if (mounted) {
      setState(() {
        _isPinSet = hasPin;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAction() async {
    setState(() {
      _errorMessage = null;
    });

    final pin = _pinController.text;
    if (pin.length != 4) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.loginErrorLength;
      });
      return;
    }

    if (!_isPinSet) {
      final confirmPin = _confirmPinController.text;
      if (pin != confirmPin) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.loginErrorMismatch;
        });
        return;
      }
      await AuthState.savePin(pin);
      if (mounted) {
        context.go('/dashboard');
      }
    } else {
      final success = await AuthState.verifyPin(pin);
      if (success) {
        if (mounted) {
          context.go('/dashboard');
        }
      } else {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.loginErrorIncorrect;
          _pinController.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kCard,
        body: Center(
          child: CircularProgressIndicator(color: kPrimary),
        ),
      );
    }

    final buttonEnabled = _pinController.text.length == 4 &&
        (_isPinSet || _confirmPinController.text.length == 4);

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
                Text(
                  _isPinSet ? AppLocalizations.of(context)!.loginTitleWelcomeBack : AppLocalizations.of(context)!.loginTitleCreatePin,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPinSet
                      ? AppLocalizations.of(context)!.loginSubWelcomeBack
                      : AppLocalizations.of(context)!.loginSubCreatePin,
                  style: TextStyle(fontSize: 14, color: Colors.blue[200]),
                ),
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
                  
                  // PIN field
                  Text(
                    _isPinSet ? AppLocalizations.of(context)!.loginLabelPin : AppLocalizations.of(context)!.loginLabelEnterPin,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '••••',
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

                  // Confirm PIN field (only in setup mode)
                  if (!_isPinSet) ...[
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context)!.loginLabelConfirmPin,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kForeground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmPinController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: '••••',
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
                  ],

                  // Error Message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: kRed, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],

                  const SizedBox(height: 24),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: buttonEnabled ? _handleAction : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: kPrimary.withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 4,
                        shadowColor: kPrimary.withOpacity(0.4),
                      ),
                      child: Text(
                        _isPinSet ? AppLocalizations.of(context)!.loginButtonUnlock : AppLocalizations.of(context)!.loginButtonSetPin,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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