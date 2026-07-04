import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/Theme.dart';

class BillingCard extends StatelessWidget {
  final Widget child;
  const BillingCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        )
      ],
    ),
    child: child,
  );
}

class BillingField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType type;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter> formatter;
  final bool enabled;

  const BillingField({
    super.key,
    required this.ctrl,
    required this.label,
    required this.icon,
    this.type = TextInputType.text,
    this.onChanged,
    this.formatter = const [],
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: type,
    inputFormatters: formatter,
    onChanged: onChanged,
    enabled: enabled,
    style: TextStyle(
      fontSize: 14,
      color: enabled ? kForeground : kMutedForeground,
    ),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18, color: kMutedForeground),
      filled: true,
      fillColor: enabled ? kMuted : kMuted.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );
}

class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) =>
      n.copyWith(text: n.text.toUpperCase());
}
