import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xlrat/l10n/app_localizations.dart';
import '../providers/profile_provider.dart';

ThemeMode gThemeMode = ThemeMode.light;

// ─── Brand / accent colors — JCB-style safety yellow + industrial black ──────
const kPrimary = Color(
  0xFFE0A500,
); // safety yellow — primary brand/action color
const kPrimaryDark = Color(
  0xFF1A1A1A,
); // near-black — headers, dark panels, button text on yellow
const kAccent = Color(
  0xFF1976D2,
); // utility blue — reserved for "partial payment" status only
const kOrange = Color(
  0xFFE65100,
); // hazard/construction-cone orange — pending/warning
const kGreen = Color(0xFF2E7D32); // workshop-safety green — completed/paid
const kRed = Color(0xFFC62828); // hazard red — error/low stock/deductions

Color get kBackground => gThemeMode == ThemeMode.dark
    ? const Color(0xFF121212)
    : const Color(0xFFF5F5F3);
Color get kCard => gThemeMode == ThemeMode.dark
    ? const Color(0xFF1E1E1E)
    : const Color(0xFFFFFFFF);
Color get kForeground => gThemeMode == ThemeMode.dark
    ? const Color(0xFFE0E0E0)
    : const Color(0xFF1A1A1A);
Color get kMuted => gThemeMode == ThemeMode.dark
    ? const Color(0xFF2C2C2E)
    : const Color(0xFFEFEFEC);
Color get kMutedForeground => gThemeMode == ThemeMode.dark
    ? const Color(0xFF9E9E9E)
    : const Color(0xFF5A5A5A);
Color get kBorder => gThemeMode == ThemeMode.dark
    ? const Color(0x33FFFFFF)
    : const Color(0xFFE0E0DE);

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;
  ThemeModeNotifier(this._prefs) : super(ThemeMode.light) {
    final mode = _prefs.getString('theme_mode') ?? 'light';
    state = mode == 'dark' ? ThemeMode.dark : ThemeMode.light;
    gThemeMode = state;
  }

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _prefs.setString('theme_mode', state == ThemeMode.dark ? 'dark' : 'light');
    gThemeMode = state;
  }
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimary,
      primary: kPrimary,
      brightness: gThemeMode == ThemeMode.dark
          ? Brightness.dark
          : Brightness.light,
      background: kBackground,
      surface: kCard,
    ),
    scaffoldBackgroundColor: kBackground,
    fontFamily: 'Roboto',
    appBarTheme: AppBarTheme(
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
        // Near-black text/icons on the safety-yellow background — white would
        // be low-contrast on yellow. Any button that locally overrides
        // foregroundColor with Colors.white on a kPrimary background should
        // be updated to kPrimaryDark to match.
        foregroundColor: kPrimaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: kPrimaryDark, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        elevation: 0,
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.dragged)) {
          return kPrimary.withOpacity(0.8);
        }
        return kMutedForeground.withOpacity(0.4);
      }),
      thickness: WidgetStateProperty.all(6),
      radius: const Radius.circular(8),
      interactive: true,
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(kMuted),
      headingTextStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: kForeground,
        fontSize: 12,
      ),
      dataRowColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return kMuted.withOpacity(0.5);
        }
        return kCard;
      }),
      dataTextStyle: TextStyle(color: kForeground, fontSize: 12),
      dividerThickness: 0.8,
      horizontalMargin: 16,
      columnSpacing: 16,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kPrimaryDark, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}

// ─── Helper Extensions ────────────────────────────────────────────────────────

extension StatusColor on String {
  Color get statusColor {
    switch (this) {
      case 'in-progress':
        return kPrimaryDark; // dark text on soft-yellow bg for contrast
      case 'pending':
        return kOrange;
      case 'completed':
        return kGreen;
      default:
        return kMutedForeground;
    }
  }

  Color get statusBgColor {
    switch (this) {
      case 'in-progress':
        return const Color(0xFFFFF8E1); // soft safety yellow
      case 'pending':
        return const Color(0xFFFFF3E0);
      case 'completed':
        return const Color(0xFFE8F5E9);
      default:
        return kMuted;
    }
  }

  String statusLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case 'in-progress':
        return l10n.statusInProgress;
      case 'pending':
        return l10n.statusPending;
      case 'completed':
        return l10n.statusCompleted;
      default:
        return this;
    }
  }
}

String formatCurrency(int amount) {
  final formatted = amount.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{2})+\d$)'),
    (m) => '${m[1]},',
  );
  return '₹$formatted';
}
