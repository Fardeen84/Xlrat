import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xlrat/l10n/app_localizations.dart';

import '../../../core/Theme.dart';
import '../../../models/billing_model/BillingCustomer.dart';
import '../../../models/billing_model/BillingVehicle.dart';
import '../../../providers/billing_providers.dart';
import '../../../widgets/QuickAddSheets.dart';
import 'billing_shared.dart';

class BillingVehicleSection extends ConsumerStatefulWidget {
  const BillingVehicleSection({super.key});

  @override
  ConsumerState<BillingVehicleSection> createState() => _BillingVehicleSectionState();
}

class _BillingVehicleSectionState extends ConsumerState<BillingVehicleSection> {
  final _vehNumFocus = FocusNode();
  final _vehNumCtrl = TextEditingController();
  final _vehModelCtrl = TextEditingController();

  List<BillingCustomer> _suggestions = [];
  bool _showSuggestions = false;
  String? _selectedFuel;
  BillingVehicle? _selectedVehicle;

  // Side-map: customerId → BillingVehicle
  Map<String, BillingVehicle> _vehicleSuggestMap = {};

  static const _fuelTypes = ['Petrol', 'Diesel', 'CNG', 'Electric', 'Hybrid'];

  @override
  void initState() {
    super.initState();
    final draft = ref.read(invoiceDraftProvider);
    final v = draft.vehicle;
    if (v != null) {
      _vehNumCtrl.text = v.vehicleNumber;
      _vehModelCtrl.text = v.vehicleModel;
      _selectedFuel = v.fuelType.isEmpty ? null : v.fuelType;
    }
  }

  @override
  void dispose() {
    _vehNumFocus.dispose();
    _vehNumCtrl.dispose();
    _vehModelCtrl.dispose();
    super.dispose();
  }

  void _pushVehicleToDraft() {
    final num = _vehNumCtrl.text.trim().toUpperCase();
    final draft = ref.read(invoiceDraftProvider);
    if (num.isNotEmpty) {
      ref.read(invoiceDraftProvider.notifier).setVehicle(BillingVehicle(
            customerId: draft.customer?.id ?? '',
            vehicleNumber: num,
            vehicleModel: _vehModelCtrl.text.trim(),
            fuelType: _selectedFuel ?? '',
            createdAt: DateTime.now(),
          ));
    } else {
      ref.read(invoiceDraftProvider.notifier).setVehicle(null);
    }
  }

  Future<void> _onVehNumChanged(String val) async {
    _pushVehicleToDraft();
    if (val.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    final repo = ref.read(vehicleRepositoryProvider);
    final vehs = await repo.searchVehicles(val.trim());
    if (!mounted) return;

    _vehicleSuggestMap = {for (final v in vehs) v.customerId: v};
    final custRepo = ref.read(customerRepositoryProvider);
    final custs = await Future.wait(
      vehs.map((v) => custRepo.getCustomer(v.customerId)),
    );
    if (!mounted) return;
    setState(() {
      _suggestions = custs.whereType<BillingCustomer>().toList();
      _showSuggestions = _suggestions.isNotEmpty;
    });
  }

  void _onSuggestionTapped(BillingCustomer c) {
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });
    _vehNumFocus.unfocus();

    ref.read(invoiceDraftProvider.notifier).setCustomer(c);

    if (c.id != null && _vehicleSuggestMap.containsKey(c.id)) {
      final v = _vehicleSuggestMap[c.id]!;
      _vehNumCtrl.text = v.vehicleNumber;
      _vehModelCtrl.text = v.vehicleModel;
      setState(() {
        _selectedFuel = v.fuelType.isEmpty ? null : v.fuelType;
        _selectedVehicle = v;
      });
      ref.read(invoiceDraftProvider.notifier).setVehicle(v);
    } else {
      _vehNumCtrl.clear();
      _vehModelCtrl.clear();
      setState(() {
        _selectedFuel = null;
        _selectedVehicle = null;
      });
      ref.read(invoiceDraftProvider.notifier).setVehicle(null);
    }
  }

  void _onExistingVehicleSelected(BillingVehicle? v) {
    setState(() => _selectedVehicle = v);
    if (v != null) {
      _vehNumCtrl.text = v.vehicleNumber;
      _vehModelCtrl.text = v.vehicleModel;
      setState(() => _selectedFuel = v.fuelType.isEmpty ? null : v.fuelType);
    } else {
      _vehNumCtrl.clear();
      _vehModelCtrl.clear();
      setState(() => _selectedFuel = null);
    }
    ref.read(invoiceDraftProvider.notifier).setVehicle(v);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<InvoiceDraft>(invoiceDraftProvider, (previous, next) {
      if (next.vehicle == null) {
        if (_vehNumCtrl.text.isNotEmpty) _vehNumCtrl.clear();
        if (_vehModelCtrl.text.isNotEmpty) _vehModelCtrl.clear();
        if (_selectedFuel != null) {
          setState(() {
            _selectedFuel = null;
          });
        }
        if (_selectedVehicle != null) {
          setState(() {
            _selectedVehicle = null;
          });
        }
      } else {
        if (_vehNumCtrl.text != next.vehicle!.vehicleNumber) {
          _vehNumCtrl.text = next.vehicle!.vehicleNumber;
        }
        if (_vehModelCtrl.text != next.vehicle!.vehicleModel) {
          _vehModelCtrl.text = next.vehicle!.vehicleModel;
        }
        final fuel = next.vehicle!.fuelType.isEmpty ? null : next.vehicle!.fuelType;
        if (_selectedFuel != fuel) {
          setState(() {
            _selectedFuel = fuel;
          });
        }
      }
    });

    final draft = ref.watch(invoiceDraftProvider);
    final customer = draft.customer;
    final isExisting = customer != null && customer.id != null;

    final vehiclesAsync = isExisting
        ? ref.watch(vehiclesForCustomerProvider(customer.id!))
        : const AsyncValue<List<BillingVehicle>>.data([]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Saved vehicles dropdown
        if (isExisting)
          vehiclesAsync.when(
            data: (vehs) {
              BillingVehicle? safeValue;
              for (final v in vehs) {
                if (v.id == _selectedVehicle?.id) {
                  safeValue = v;
                  break;
                }
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<BillingVehicle>(
                    value: safeValue,
                    isExpanded: true,
                    hint: Text(
                      AppLocalizations.of(context)!.billingHintSavedVehicle,
                      style: TextStyle(color: kMutedForeground, fontSize: 12),
                    ),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.billingLabelSavedVehicles,
                      prefixIcon: Icon(Icons.bookmark_outline_rounded, size: 18, color: kMutedForeground),
                      filled: true,
                      fillColor: kMuted,
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: kBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: kBorder)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    items: [
                      DropdownMenuItem<BillingVehicle>(
                        value: null,
                        child: Text(AppLocalizations.of(context)!.billingLabelNewVehicle, style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
                      ),
                      ...vehs.map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(v.displayLabel, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: _onExistingVehicleSelected,
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        QuickAddSheets.showAddVehicle(
                          context,
                          ref,
                          customerId: customer.id!,
                          onSaved: (newVehicle) {
                            _onExistingVehicleSelected(newVehicle);
                          },
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Quick Add Vehicle'),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())),
            error: (e, _) => const SizedBox.shrink(),
          ),

        // Vehicle Number
        TextField(
          controller: _vehNumCtrl,
          focusNode: _vehNumFocus,
          inputFormatters: [UpperCaseFormatter()],
          onChanged: _onVehNumChanged,
          style: TextStyle(fontSize: 14, color: kForeground),
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.billingLabelVehicleNumber,
            prefixIcon: Icon(Icons.pin_outlined, size: 18, color: kMutedForeground),
            filled: true,
            fillColor: kMuted,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),

        if (_showSuggestions) _buildSuggestionList(),

        const SizedBox(height: 12),

        // Vehicle Model
        BillingField(
          ctrl: _vehModelCtrl,
          label: AppLocalizations.of(context)!.billingLabelVehicleModel,
          icon: Icons.directions_car_filled_outlined,
          onChanged: (_) => _pushVehicleToDraft(),
        ),

        const SizedBox(height: 12),

        // Fuel Row
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.billingLabelFuelType,
              style: TextStyle(fontSize: 11, color: kMutedForeground, fontWeight: FontWeight.w600, letterSpacing: 0.3),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _fuelTypes.map((t) {
                final sel = _selectedFuel == t;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedFuel = sel ? null : t);
                    _pushVehicleToDraft();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? kPrimary : kMuted,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? kPrimary : kBorder),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : kMutedForeground),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
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
        children: _suggestions
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
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kForeground),
                            ),
                            Text(
                              c.mobile,
                              style: TextStyle(fontSize: 11, color: kMutedForeground),
                            ),
                            if (c.id != null && _vehicleSuggestMap.containsKey(c.id))
                              Text(
                                _vehicleSuggestMap[c.id]!.displayLabel,
                                style: const TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.w600),
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.north_west_rounded, size: 14, color: kMutedForeground),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}