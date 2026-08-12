import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/ServiceItem.dart';
import '../../../providers/servicesProvider.dart';
import '../../../core/Theme.dart';
import '../../../widgets/StatusBadge.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  int? _sortColumnIndex;
  bool _sortAscending = true;
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.text = ref.read(servicesSearchProvider);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    if (value.trim().isEmpty) {
      ref.read(servicesSearchProvider.notifier).state = '';
    } else {
      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        ref.read(servicesSearchProvider.notifier).state = value;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(servicesListStateProvider.notifier).loadMore();
    }
  }

  void _setSort(int index, bool ascending) {
    setState(() {
      _sortColumnIndex = index;
      _sortAscending = ascending;
    });
  }

  List<ServiceItem> _getSortedItems(List<ServiceItem> items) {
    List<ServiceItem> displayList = List.from(items);

    if (_sortColumnIndex != null) {
      displayList.sort((a, b) {
        dynamic aValue;
        dynamic bValue;
        switch (_sortColumnIndex) {
          case 0:
            aValue = a.name;
            bValue = b.name;
            break;
          case 1:
            aValue = a.category;
            bValue = b.category;
            break;
          case 2:
            aValue = a.price;
            bValue = b.price;
            break;
          default:
            return 0;
        }
        if (_sortAscending) {
          return Comparable.compare(aValue, bValue);
        } else {
          return Comparable.compare(bValue, aValue);
        }
      });
    }
    return displayList;
  }

  void _showAddServiceDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '0');
    final descriptionCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: kCard,
          title: Text(
            'Add Service',
            style: TextStyle(fontWeight: FontWeight.w800, color: kForeground),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    enabled: !isSaving,
                    decoration: InputDecoration(
                      labelText: 'Name *',
                      labelStyle: TextStyle(color: kMutedForeground),
                    ),
                    style: TextStyle(color: kForeground),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Please enter name'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: categoryCtrl,
                    enabled: !isSaving,
                    decoration: InputDecoration(
                      labelText: 'Category *',
                      labelStyle: TextStyle(color: kMutedForeground),
                    ),
                    style: TextStyle(color: kForeground),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Please enter category'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: priceCtrl,
                    enabled: !isSaving,
                    decoration: InputDecoration(
                      labelText: 'Price *',
                      labelStyle: TextStyle(color: kMutedForeground),
                    ),
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: kForeground),
                    validator: (value) =>
                        (value == null || int.tryParse(value) == null || int.parse(value) < 0)
                        ? 'Invalid price'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descriptionCtrl,
                    enabled: !isSaving,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      labelStyle: TextStyle(color: kMutedForeground),
                    ),
                    maxLines: 3,
                    style: TextStyle(color: kForeground),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: kMutedForeground)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() {
                          isSaving = true;
                        });
                        try {
                          final name = nameCtrl.text.trim();
                          final existing = await ref.read(serviceRepositoryProvider).findByName(name);
                          if (existing != null) {
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder: (warningContext) => AlertDialog(
                                  backgroundColor: kCard,
                                  title: Text(
                                    'Duplicate Service',
                                    style: TextStyle(fontWeight: FontWeight.w800, color: kForeground),
                                  ),
                                  content: Text(
                                    "A service named '$name' already exists.",
                                    style: TextStyle(color: kForeground),
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimary,
                                        foregroundColor: kPrimaryDark,
                                      ),
                                      onPressed: () {
                                        Navigator.pop(warningContext);
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                            setState(() {
                              isSaving = false;
                            });
                            return;
                          }

                          final newService = ServiceItem(
                            name: name,
                            category: categoryCtrl.text.trim(),
                            price: int.parse(priceCtrl.text.trim()),
                            description: descriptionCtrl.text.trim(),
                            createdAt: DateTime.now(),
                          );

                          await ref.read(serviceRepositoryProvider).createService(newService);
                          ref.read(servicesListStateProvider.notifier).loadFirstPage();

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          setState(() {
                            isSaving = false;
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to add service: $e')),
                            );
                          }
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditServiceDialog(BuildContext context, ServiceItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final categoryCtrl = TextEditingController(text: item.category);
    final priceCtrl = TextEditingController(text: item.price.toString());
    final descriptionCtrl = TextEditingController(text: item.description);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: kCard,
          title: Text(
            'Edit Service',
            style: TextStyle(fontWeight: FontWeight.w800, color: kForeground),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    enabled: !isSaving,
                    decoration: InputDecoration(
                      labelText: 'Name *',
                      labelStyle: TextStyle(color: kMutedForeground),
                    ),
                    style: TextStyle(color: kForeground),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Please enter name'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: categoryCtrl,
                    enabled: !isSaving,
                    decoration: InputDecoration(
                      labelText: 'Category *',
                      labelStyle: TextStyle(color: kMutedForeground),
                    ),
                    style: TextStyle(color: kForeground),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Please enter category'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: priceCtrl,
                    enabled: !isSaving,
                    decoration: InputDecoration(
                      labelText: 'Price *',
                      labelStyle: TextStyle(color: kMutedForeground),
                    ),
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: kForeground),
                    validator: (value) =>
                        (value == null || int.tryParse(value) == null || int.parse(value) < 0)
                        ? 'Invalid price'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descriptionCtrl,
                    enabled: !isSaving,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      labelStyle: TextStyle(color: kMutedForeground),
                    ),
                    maxLines: 3,
                    style: TextStyle(color: kForeground),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: kMutedForeground)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() {
                          isSaving = true;
                        });
                        try {
                          final name = nameCtrl.text.trim();
                          final existing = await ref.read(serviceRepositoryProvider).findByName(name);
                          if (existing != null && existing.id != item.id) {
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder: (warningContext) => AlertDialog(
                                  backgroundColor: kCard,
                                  title: Text(
                                    'Duplicate Service',
                                    style: TextStyle(fontWeight: FontWeight.w800, color: kForeground),
                                  ),
                                  content: Text(
                                    "A service named '$name' already exists.",
                                    style: TextStyle(color: kForeground),
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimary,
                                        foregroundColor: kPrimaryDark,
                                      ),
                                      onPressed: () {
                                        Navigator.pop(warningContext);
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                            setState(() {
                              isSaving = false;
                            });
                            return;
                          }

                          final updatedService = item.copyWith(
                            name: name,
                            category: categoryCtrl.text.trim(),
                            price: int.parse(priceCtrl.text.trim()),
                            description: descriptionCtrl.text.trim(),
                          );

                          await ref.read(serviceRepositoryProvider).updateService(updatedService);
                          ref.read(servicesListStateProvider.notifier).loadFirstPage();

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          setState(() {
                            isSaving = false;
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to update service: $e')),
                            );
                          }
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, ServiceItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kCard,
        title: Text(
          'Delete Service?',
          style: TextStyle(fontWeight: FontWeight.w800, color: kForeground),
        ),
        content: Text(
          'Are you sure you want to delete ${item.name}?',
          style: TextStyle(color: kForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: kMutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kRed),
            onPressed: () async {
              if (item.id == null) {
                Navigator.pop(dialogContext);
                return;
              }
              try {
                await ref.read(serviceRepositoryProvider).deleteService(item.id!);
                ref.read(servicesListStateProvider.notifier).loadFirstPage();
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Service deleted successfully')),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(filteredServicesProvider);
    final servicesState = ref.watch(servicesListStateProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPC = constraints.maxWidth > 900;
        if (isPC) {
          return _buildPCLayout(context, itemsAsync, servicesState);
        } else {
          return _buildMobileLayout(context, itemsAsync, servicesState);
        }
      },
    );
  }

  Widget _buildPCLayout(
    BuildContext context,
    AsyncValue<List<ServiceItem>> itemsAsync,
    ServiceState servicesState,
  ) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: kCard,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Services Catalog',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kForeground,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.sync_rounded, color: kMutedForeground),
                          tooltip: 'Resync All',
                          onPressed: () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('Starting full resync...')),
                            );
                            await ref.read(servicesListStateProvider.notifier).resyncAll();
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('Full resync completed!')),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showAddServiceDialog(context),
                          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                          label: const Text(
                            'Add Service',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GarageSearchBar(
                        controller: _searchController,
                        hint: 'Search by Name, Category...',
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return itemsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Text('Error: $err', style: const TextStyle(color: kRed)),
                  ),
                  data: (items) {
                    final displayItems = _getSortedItems(items);
                    return SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: kCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: kBorder, width: 0.8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Theme(
                                data: Theme.of(context).copyWith(dividerColor: kBorder),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minWidth: constraints.maxWidth - 48),
                                    child: DataTable(
                                      showCheckboxColumn: false,
                                      headingRowColor: WidgetStateProperty.all(kMuted.withOpacity(0.4)),
                                      headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: kForeground),
                                      columnSpacing: 32,
                                      sortColumnIndex: _sortColumnIndex,
                                      sortAscending: _sortAscending,
                                      columns: [
                                        DataColumn(label: const Text('Name'), onSort: (index, asc) => _setSort(index, asc)),
                                        DataColumn(label: const Text('Category'), onSort: (index, asc) => _setSort(index, asc)),
                                        DataColumn(label: const Text('Price'), numeric: true, onSort: (index, asc) => _setSort(index, asc)),
                                        const DataColumn(label: Text('Description')),
                                        const DataColumn(label: Text('Actions')),
                                      ],
                                      rows: displayItems.map((item) {
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              SizedBox(
                                                width: 200,
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.construction_rounded,
                                                      size: 16,
                                                      color: kPrimary,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        item.name,
                                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                                        overflow: TextOverflow.ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            DataCell(Text(item.category)),
                                            DataCell(Text(formatCurrency(item.price))),
                                            DataCell(
                                              SizedBox(
                                                width: 250,
                                                child: Text(
                                                  item.description.isNotEmpty ? item.description : 'N/A',
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(fontSize: 12, color: kMutedForeground),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(Icons.edit_rounded, size: 18, color: kMutedForeground),
                                                    onPressed: () => _showEditServiceDialog(context, item),
                                                    tooltip: 'Edit Service',
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: kRed),
                                                    onPressed: () => _showDeleteConfirmDialog(context, item),
                                                    tooltip: 'Delete Service',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (servicesState.hasMore) ...[
                            const SizedBox(height: 24),
                            if (servicesState.isLoadMore)
                              const Center(child: CircularProgressIndicator())
                            else
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                                onPressed: () => ref.read(servicesListStateProvider.notifier).loadMore(),
                                child: const Text('Load More', style: TextStyle(color: Colors.white)),
                              ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AsyncValue<List<ServiceItem>> itemsAsync,
    ServiceState servicesState,
  ) {
    final items = itemsAsync.value ?? [];
    final footerCount = servicesState.hasMore ? 1 : 0;
    final totalCount = items.length + footerCount;

    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
          Container(
            color: kCard,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              bottom: 12,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Services Catalog',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: kForeground,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.sync_rounded, color: kMutedForeground, size: 20),
                          onPressed: () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('Starting full resync...')),
                            );
                            await ref.read(servicesListStateProvider.notifier).resyncAll();
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('Full resync completed!')),
                            );
                          },
                          tooltip: 'Resync All',
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showAddServiceDialog(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: kPrimary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GarageSearchBar(
                  controller: _searchController,
                  hint: 'Search services...',
                  onChanged: _onSearchChanged,
                ),
              ],
            ),
          ),
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Error: $err', style: const TextStyle(color: kRed)),
              ),
              data: (items) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: totalCount,
                  itemBuilder: (context, index) {
                    if (index == items.length) {
                      if (servicesState.isLoadMore) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                          onPressed: () => ref.read(servicesListStateProvider.notifier).loadMore(),
                          child: const Text('Load More', style: TextStyle(color: Colors.white)),
                        ),
                      );
                    }

                    final item = items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kBorder, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: kPrimary.withOpacity(0.1),
                              child: const Icon(
                                Icons.construction_rounded,
                                color: kPrimary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: TextStyle(fontWeight: FontWeight.w700, color: kForeground, fontSize: 14),
                            ),
                            subtitle: Text(
                              '₹${item.price}',
                              style: TextStyle(
                                color: kMutedForeground,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column(
                                  children: [
                                    Divider(color: kBorder, height: 1),
                                    const SizedBox(height: 12),
                                    _buildDetailRow('Category', item.category),
                                    _buildDetailRow('Price', formatCurrency(item.price)),
                                    _buildDetailRow('Description', item.description.isNotEmpty ? item.description : 'N/A'),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit_rounded, color: kMutedForeground),
                                          onPressed: () => _showEditServiceDialog(context, item),
                                          tooltip: 'Edit Service',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: kRed),
                                          onPressed: () => _showDeleteConfirmDialog(context, item),
                                          tooltip: 'Delete Service',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: kMutedForeground, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(fontSize: 12, color: kForeground, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
