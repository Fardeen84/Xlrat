// lib/theme.dart
import 'package:flutter/material.dart';

const kPrimary = Color(0xFF1565C0);
const kPrimaryDark = Color(0xFF0D47A1);
const kAccent = Color(0xFF0288D1);
const kOrange = Color(0xFFFB8C00);
const kGreen = Color(0xFF43A047);
const kBackground = Color(0xFFF5F7FA);
const kCard = Color(0xFFFFFFFF);
const kForeground = Color(0xFF0F1923);
const kMuted = Color(0xFFEEF1F6);
const kMutedForeground = Color(0xFF637083);
const kBorder = Color(0x1A0F1923);
const kRed = Color(0xFFD32F2F);

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimary,
      primary: kPrimary,
      background: kBackground,
      surface: kCard,
    ),
    scaffoldBackgroundColor: kBackground,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: kCard,
      elevation: 0,
      scrolledUnderElevation: 1,
      iconTheme: IconThemeData(color: kForeground),
      titleTextStyle: TextStyle(
        color: kForeground,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
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
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

// ─── Helper Extensions ────────────────────────────────────────────────────────

extension StatusColor on String {
  Color get statusColor {
    switch (this) {
      case 'in-progress': return const Color(0xFF1565C0);
      case 'pending': return kOrange;
      case 'completed': return kGreen;
      default: return kMutedForeground;
    }
  }

  Color get statusBgColor {
    switch (this) {
      case 'in-progress': return const Color(0xFFE8F0FE);
      case 'pending': return const Color(0xFFFFF3E0);
      case 'completed': return const Color(0xFFE8F5E9);
      default: return kMuted;
    }
  }

  String get statusLabel {
    switch (this) {
      case 'in-progress': return 'In Progress';
      case 'pending': return 'Pending';
      case 'completed': return 'Completed';
      default: return this;
    }
  }
}

String formatCurrency(int amount) {
  final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+\d$)'), (m) => '${m[1]},');
  return '₹$formatted';
}