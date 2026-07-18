// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';

import '../core/Theme.dart';

// ─── Status Badge ─────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.statusBgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.statusLabel(context),
        style: TextStyle(
          color: status.statusColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Avatar Widget ────────────────────────────────────────────────────────────

class AvatarWidget extends StatelessWidget {
  final String initials;
  final double size;
  final Color bgColor;
  final Color textColor;

   AvatarWidget({
    super.key,
    required this.initials,
    this.size = 40,
    this.bgColor = Colors.white,
    this.textColor = kPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: textColor,
            fontSize: size * 0.33,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ─── Vehicle Icon ─────────────────────────────────────────────────────────────

class VehicleIcon extends StatelessWidget {
  final String type;
  final double size;

  const VehicleIcon({super.key, required this.type, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final isCar = type == 'car';
    final isItem = type == 'item';
    
    final Color bgColor;
    final IconData iconData;
    final Color iconColor;
    
    if (isItem) {
      bgColor = const Color(0xFFE8F5E9);
      iconData = Icons.inventory_2_rounded;
      iconColor = kGreen;
    } else if (isCar) {
      bgColor = const Color(0xFFDBEAFE);
      iconData = Icons.directions_car_rounded;
      iconColor = kPrimary;
    } else {
      bgColor = const Color(0xFFFFF3E0);
      iconData = Icons.two_wheeler_rounded;
      iconColor = kOrange;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: size * 0.45,
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: kForeground,
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: const TextStyle(
                fontSize: 12,
                color: kPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Card Container ───────────────────────────────────────────────────────────

class GarageCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;

  const GarageCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? kCard,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: kBorder, width: 0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Gradient Header ──────────────────────────────────────────────────────────

class GradientHeader extends StatelessWidget {
  final Widget child;
  final double height;

  const GradientHeader({super.key, required this.child, this.height = 160});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFDB913), Color(0xFFFDB918)],
        ),
      ),
      child: child,
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class GarageSearchBar extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final String value;
  final TextEditingController? controller;

  const GarageSearchBar({
    super.key,
    required this.hint,
    required this.onChanged,
    this.value = '',
    this.controller,
  });

  @override
  State<GarageSearchBar> createState() => _GarageSearchBarState();
}

class _GarageSearchBarState extends State<GarageSearchBar> {
  TextEditingController? _localController;

  TextEditingController get _effectiveController =>
      widget.controller ?? (_localController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    if (widget.value.isNotEmpty) {
      _effectiveController.text = widget.value;
    }
    _effectiveController.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant GarageSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleTextChanged);
      _effectiveController.addListener(_handleTextChanged);
    }
    if (widget.value != oldWidget.value && widget.value != _effectiveController.text) {
      _effectiveController.text = widget.value;
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_handleTextChanged);
    _localController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _effectiveController.text.isNotEmpty || widget.value.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: kMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder, width: 0.8),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(
              Icons.search_rounded,
              color: kMutedForeground,
              size: 18,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _effectiveController,
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(color: kMutedForeground, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                suffixIcon: hasText
                    ? GestureDetector(
                        onTap: () {
                          _effectiveController.clear();
                          widget.onChanged('');
                        },
                        child: Icon(
                          Icons.close_rounded,
                          color: kMutedForeground,
                          size: 16,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Selector ─────────────────────────────────────────────────────────────

class GarageTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const GarageTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = selectedIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? kCard : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? kPrimary : kMutedForeground,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Chip Filter ─────────────────────────────────────────────────────────────

class FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? kPrimary : kMuted,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : kMutedForeground,
          ),
        ),
      ),
    );
  }
}
