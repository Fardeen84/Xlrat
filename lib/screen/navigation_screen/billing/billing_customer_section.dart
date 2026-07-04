import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xlrat/l10n/app_localizations.dart';

import '../../../core/Theme.dart';
import '../../../models/billing_model/BillingCustomer.dart';
import '../../../providers/billing_providers.dart';
import '../../../widgets/QuickAddSheets.dart';
import 'billing_shared.dart';

enum SuggestSource { name, mobile }

class BillingCustomerSection extends ConsumerStatefulWidget {
  const BillingCustomerSection({super.key});

  @override
  ConsumerState<BillingCustomerSection> createState() => _BillingCustomerSectionState();
}

class _BillingCustomerSectionState extends ConsumerState<BillingCustomerSection> {
  final _nameFocus = FocusNode();
  final _mobileFocus = FocusNode();

  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();

  List<BillingCustomer> _suggestions = [];
  bool _showSuggestions = false;
  SuggestSource _suggestSource = SuggestSource.name;
  bool _isExisting = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(invoiceDraftProvider);
    final c = draft.customer;
    if (c != null) {
      _nameCtrl.text = c.name;
      _mobileCtrl.text = c.mobile;
      _isExisting = c.id != null;
    }
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _mobileFocus.dispose();
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  void _clearAll() {
    _nameCtrl.clear();
    _mobileCtrl.clear();
    setState(() {
      _isExisting = false;
      _showSuggestions = false;
      _suggestions = [];
    });
    ref.read(invoiceDraftProvider.notifier).clearCustomer();
  }

  Future<void> _search(String query, SuggestSource src) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    final repo = ref.read(customerRepositoryProvider);
    final result = await repo.searchCustomers(query.trim());
    if (!mounted) return;
    setState(() {
      _suggestions = result;
      _showSuggestions = true;
      _suggestSource = src;
    });
  }

  void _pushNewCustomerToDraft() {
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) {
      ref.read(invoiceDraftProvider.notifier).setCustomer(BillingCustomer(
            name: name,
            mobile: _mobileCtrl.text.trim(),
            createdAt: DateTime.now(),
          ));
    } else {
      ref.read(invoiceDraftProvider.notifier).clearCustomer();
    }
  }

  void _onSuggestionTapped(BillingCustomer c) {
    setState(() {
      _isExisting = true;
      _showSuggestions = false;
      _suggestions = [];
    });
    _nameCtrl.text = c.name;
    _mobileCtrl.text = c.mobile;
    _nameFocus.unfocus();
    _mobileFocus.unfocus();

    ref.read(invoiceDraftProvider.notifier).setCustomer(c);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<InvoiceDraft>(invoiceDraftProvider, (previous, next) {
      if (next.customer == null) {
        if (_nameCtrl.text.isNotEmpty) _nameCtrl.clear();
        if (_mobileCtrl.text.isNotEmpty) _mobileCtrl.clear();
        if (_isExisting || _showSuggestions || _suggestions.isNotEmpty) {
          setState(() {
            _isExisting = false;
            _showSuggestions = false;
            _suggestions = [];
          });
        }
      } else {
        if (_nameCtrl.text != next.customer!.name) {
          _nameCtrl.text = next.customer!.name;
        }
        if (_mobileCtrl.text != next.customer!.mobile) {
          _mobileCtrl.text = next.customer!.mobile;
        }
        final newIsExisting = next.customer!.id != null;
        if (_isExisting != newIsExisting) {
          setState(() {
            _isExisting = newIsExisting;
          });
        }
      }
    });

    final anyInput = _nameCtrl.text.trim().isNotEmpty || _mobileCtrl.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name field
        TextField(
          controller: _nameCtrl,
          focusNode: _nameFocus,
          onChanged: (val) async {
            if (_isExisting) setState(() => _isExisting = false);
            _pushNewCustomerToDraft();
            await _search(val, SuggestSource.name);
          },
          style: const TextStyle(fontSize: 14, color: kForeground),
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.billingLabelCustomerName,
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: kMutedForeground),
            suffixIcon: anyInput
                ? GestureDetector(
                    onTap: _clearAll,
                    child: const Icon(Icons.close_rounded, size: 16, color: kMutedForeground),
                  )
                : null,
            filled: true,
            fillColor: kMuted,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),

        if (_showSuggestions && _suggestSource == SuggestSource.name)
          _buildSuggestionList(),

        const SizedBox(height: 12),

        // Mobile field
        TextField(
          controller: _mobileCtrl,
          focusNode: _mobileFocus,
          keyboardType: TextInputType.phone,
          enabled: !_isExisting,
          onChanged: (val) async {
            if (_isExisting) setState(() => _isExisting = false);
            _pushNewCustomerToDraft();
            await _search(val, SuggestSource.mobile);
          },
          style: TextStyle(fontSize: 14, color: !_isExisting ? kForeground : kMutedForeground),
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.billingLabelMobileNumber,
            prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: kMutedForeground),
            filled: true,
            fillColor: !_isExisting ? kMuted : kMuted.withOpacity(0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),

        if (_showSuggestions && _suggestSource == SuggestSource.mobile)
          _buildSuggestionList(),

        if (_isExisting) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.billingStatusExistingCustomer,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _clearAll,
                child: Text(
                  AppLocalizations.of(context)!.billingActionClear,
                  style: const TextStyle(fontSize: 12, color: kRed, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSuggestionList() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ..._suggestions
              .map(
                (c) => InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _onSuggestionTapped(c),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kPrimary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kForeground),
                              ),
                              Text(
                                c.mobile,
                                style: const TextStyle(fontSize: 11, color: kMutedForeground),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.north_west_rounded, size: 14, color: kMutedForeground),
                      ],
                    ),
                  ),
                ),
              ),
          InkWell(
            onTap: () {
              QuickAddSheets.showAddCustomer(context, ref, onSaved: (newCust) {
                _onSuggestionTapped(newCust);
              });
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.person_add_rounded, size: 18, color: kPrimary),
                  SizedBox(width: 12),
                  Text(
                    'Quick Add Customer',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kPrimary),
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
