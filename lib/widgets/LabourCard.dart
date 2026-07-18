import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/Theme.dart';
import '../models/billing_model/InvoiceItem.dart';
import '../providers/billing_providers.dart';
import '../screen/navigation_screen/billing/billing_shared.dart';

class LabourCard extends ConsumerStatefulWidget {
  const LabourCard();

  @override
  ConsumerState<LabourCard> createState() => _LabourCardState();
}

class _LabourCardState extends ConsumerState<LabourCard> {
  final _labourCtrl = TextEditingController();

  @override
  void dispose() {
    _labourCtrl.dispose();
    super.dispose();
  }

  void _addLabour() {
    final amount = double.tryParse(_labourCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sahi labour amount daalo'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ref
        .read(invoiceDraftProvider.notifier)
        .addItem(
          InvoiceItem.create(
            productId: null,
            itemName: 'Labour',
            quantity: 1,
            unit: 'service',
            price: amount,
          ),
        );
    _labourCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return BillingCard(
      child: Row(
        children: [
          // Container(
          //   width: 38,
          //   height: 38,
          //   decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)),
          //   child: const Icon(Icons.build_rounded, size: 18, color: Colors.orange),
          // ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _labourCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(fontSize: 14, color: kForeground),
              decoration: InputDecoration(
                labelText: 'Labour Charge (₹)',
                labelStyle: TextStyle(color: kMutedForeground, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _addLabour,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Add',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
