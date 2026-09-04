import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/unit_converter.dart';
import '../../models/models.dart';
import '../materials/master_materials_screen.dart';
import '../providers.dart';
import '../rooms_and_windows/customer_detail_screen.dart';
import 'customer_form_dialog.dart';

import '../company/company_profile_dialog.dart';
import '../../core/database/database_helper.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerListAsync = ref.watch(customerListProvider);
    final statusFilter = ref.watch(customerStatusFilterProvider);
    final controller = ref.read(customerControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Invisible Grills', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Invisible Grills Quotation & Invoicing', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.business),
            tooltip: 'Company & Invoice Profile',
            onPressed: () async {
              final profile = await DatabaseHelper.instance.getCompanyProfile();
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (_) => CompanyProfileDialog(
                    initialProfile: profile,
                    onSave: (updated) => controller.updateCompanyProfile(updated),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Master Rates & Materials',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MasterMaterialsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.white,
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search customer, phone, or address...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(customerSearchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    ref.read(customerSearchQueryProvider.notifier).state = val;
                  },
                ),
                const SizedBox(height: 10),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all', statusFilter),
                      const SizedBox(width: 8),
                      _buildFilterChip('Quotations', 'quotation', statusFilter),
                      const SizedBox(width: 8),
                      _buildFilterChip('Invoiced', 'invoiced', statusFilter),
                      const SizedBox(width: 8),
                      _buildFilterChip('Completed', 'completed', statusFilter),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          // Customer List
          Expanded(
            child: customerListAsync.when(
              data: (customers) {
                if (customers.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  itemCount: customers.length,
                  itemBuilder: (context, idx) {
                    final customer = customers[idx];
                    return _CustomerCard(
                      customer: customer,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CustomerDetailScreen(customerId: customer.id!),
                          ),
                        );
                      },
                      onDelete: () => _confirmDeleteCustomer(customer),
                      onEdit: () {
                        showDialog(
                          context: context,
                          builder: (_) => CustomerFormDialog(
                            initialCustomer: customer,
                            onSave: (updated) => controller.updateCustomer(updated),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading customers: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewCustomerDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Estimate', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String currentFilter) {
    final isSelected = currentFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textDark,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          ref.read(customerStatusFilterProvider.notifier).state = value;
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.window_outlined, size: 48, color: AppColors.accent),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Window Estimates Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap "+ New Estimate" to create a customer estimate. Add rooms, enter window dimensions in inches, and get instant feet & sq. ft calculations with full invoices!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create First Estimate'),
              onPressed: _showNewCustomerDialog,
            ),
          ],
        ),
      ),
    );
  }

  void _showNewCustomerDialog() {
    final controller = ref.read(customerControllerProvider);
    showDialog(
      context: context,
      builder: (_) => CustomerFormDialog(
        onSave: (newCustomer) async {
          final id = await controller.createCustomer(newCustomer);
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CustomerDetailScreen(customerId: id)),
            );
          }
        },
      ),
    );
  }

  void _confirmDeleteCustomer(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${customer.name}"?'),
        content: const Text(
          'This will permanently remove this customer, all their rooms, windows, and quotations.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(customerControllerProvider).deleteCustomer(customer.id!);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends ConsumerWidget {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _CustomerCard({
    required this.customer,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estimateAsync = ref.watch(customerEstimateProvider(customer.id!));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      customer.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  _buildStatusChip(customer.status),
                ],
              ),
              const SizedBox(height: 6),

              // Contact & Address
              if (customer.phone.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(customer.phone, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                  ],
                ),
              if (customer.address.isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        customer.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: 18, color: AppColors.borderLight),

              // Aggregate summary from customer estimate provider
              estimateAsync.when(
                data: (est) {
                  if (est == null) return const SizedBox.shrink();
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${est.totalRoomsCount} Rooms • ${est.totalWindowsCount} Windows',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${est.totalSqFt.toStringAsFixed(1)} Sq.Ft',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        UnitConverter.formatCurrency(est.grandTotal),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 6),

              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Open Estimate', style: TextStyle(fontSize: 12.5)),
                    onPressed: onTap,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                    onSelected: (val) {
                      if (val == 'edit') onEdit();
                      if (val == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit Info')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Estimate', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'invoiced':
        bg = AppColors.accent.withOpacity(0.12);
        fg = AppColors.accent;
        label = 'INVOICED';
        break;
      case 'completed':
        bg = AppColors.success.withOpacity(0.12);
        fg = AppColors.success;
        label = 'COMPLETED';
        break;
      case 'quotation':
      default:
        bg = Colors.amber.withOpacity(0.15);
        fg = Colors.amber.shade900;
        label = 'QUOTATION';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}
