import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/Theme.dart';
import '../../../providers/billing_providers.dart';
import 'billing_shared.dart';

class BillingSummarySection extends ConsumerStatefulWidget {
  const BillingSummarySection({super.key});

  @override
  ConsumerState<BillingSummarySection> createState() => _BillingSummarySectionState();
}

class _BillingSummarySectionState extends ConsumerState<BillingSummarySection> {
  final _discCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final draft = ref.read(invoiceDraftProvider);
    if (draft.discount > 0) {
      _discCtrl.text = draft.discount.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _discCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<InvoiceDraft>(invoiceDraftProvider, (previous, next) {
      if (next.discount == 0) {
        if (_discCtrl.text.isNotEmpty) _discCtrl.clear();
      } else {
        final currentVal = double.tryParse(_discCtrl.text) ?? 0.0;
        if (currentVal != next.discount) {
          _discCtrl.text = next.discount.toStringAsFixed(0);
        }
      }
    });

    final draft = ref.watch(invoiceDraftProvider);
    final notifier = ref.read(invoiceDraftProvider.notifier);

    return BillingCard(
      child: Column(
        children: [
          _SummaryRow('Subtotal', formatCurrency(draft.subTotal.round())),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('GST', style: TextStyle(fontSize: 13, color: kMutedForeground)),
                Row(
                  children: [0.0, 5.0, 12.0, 18.0, 28.0].map((g) {
                    final sel = draft.gstPercent == g;
                    return GestureDetector(
                      onTap: () => notifier.setGstPercent(g),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: sel ? kPrimary : kMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${g.toInt()}%',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sel ? Colors.white : kMutedForeground),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Discount (₹)', style: TextStyle(fontSize: 13, color: kMutedForeground)),
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _discCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kForeground),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(color: kMutedForeground),
                      filled: true,
                      fillColor: kMuted,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(color: kMutedForeground, fontSize: 13),
                    ),
                    onChanged: (v) => notifier.setDiscount(double.tryParse(v) ?? 0),
                  ),
                ),
              ],
            ),
          ),
          if (draft.gst > 0) _SummaryRow('GST (${draft.gstPercent.toInt()}%)', formatCurrency(draft.gst.round()), subtle: true),
          if (draft.discount > 0) _SummaryRow('Discount', '- ${formatCurrency(draft.discount.round())}', valueColor: kGreen, subtle: true),
          const SizedBox(height: 8),
          Container(height: 1, color: kBorder),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grand Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kForeground)),
              Text(
                formatCurrency(draft.grandTotal.round()),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kPrimary, letterSpacing: -0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool subtle;
  const _SummaryRow(this.label, this.value, {this.valueColor, this.subtle = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: subtle ? 12 : 13, color: kMutedForeground)),
            Text(
              value,
              style: TextStyle(fontSize: subtle ? 12 : 13, fontWeight: FontWeight.w600, color: valueColor ?? kForeground),
            ),
          ],
        ),
      );
}