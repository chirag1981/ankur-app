import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/pdf_invoice_generator.dart';
import '../../core/utils/unit_converter.dart';
import '../../core/utils/whatsapp_service.dart';
import '../../models/models.dart';
import '../customers/customer_form_dialog.dart';
import '../materials/material_form_dialog.dart';
import '../providers.dart';
import '../quotation_invoice/pdf_preview_screen.dart';
import 'room_form_dialog.dart';
import 'window_form_dialog.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final int customerId;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
  });

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Quotation & Financial State
  String _discountType = 'flat';
  late TextEditingController _discountController;
  late TextEditingController _advanceController;
  late TextEditingController _taxController;
  bool _isInvoice = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _discountController = TextEditingController();
    _advanceController = TextEditingController();
    _taxController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _discountController.dispose();
    _advanceController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  void _syncFinancialInputs(Customer customer) {
    if (_discountController.text.isEmpty) {
      _discountType = customer.discountType;
      _discountController.text = customer.discountValue > 0
          ? (customer.discountValue == customer.discountValue.roundToDouble()
              ? customer.discountValue.toInt().toString()
              : customer.discountValue.toString())
          : '';
      _advanceController.text = customer.advanceAmount > 0
          ? (customer.advanceAmount == customer.advanceAmount.roundToDouble()
              ? customer.advanceAmount.toInt().toString()
              : customer.advanceAmount.toString())
          : '';
      _taxController.text = customer.taxRate > 0 ? customer.taxRate.toString() : '';
      _isInvoice = customer.status == 'invoiced';
    }
  }

  @override
  Widget build(BuildContext context) {
    final estimateAsync = ref.watch(customerEstimateProvider(widget.customerId));
    final controller = ref.read(customerControllerProvider);

    return estimateAsync.when(
      data: (estimate) {
        if (estimate == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Estimate Details')),
            body: const Center(child: Text('Customer not found')),
          );
        }

        _syncFinancialInputs(estimate.customer);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(estimate.customer.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                Text(
                  '${estimate.customer.phone} ${estimate.customer.address.isNotEmpty ? "• ${estimate.customer.address}" : ""}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note),
                tooltip: 'Edit Customer Info',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => CustomerFormDialog(
                      initialCustomer: estimate.customer,
                      onSave: (updated) => controller.updateCustomer(updated),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Quick Share to WhatsApp',
                onPressed: () => _handleShareWhatsApp(estimate),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accentLight,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: [
                Tab(
                  icon: const Icon(Icons.meeting_room, size: 20),
                  text: 'Rooms & Windows (${estimate.allWindows.length})',
                ),
                Tab(
                  icon: const Icon(Icons.inventory_2, size: 20),
                  text: 'Materials (${estimate.materials.where((m) => m.isEnabled).length})',
                ),
                const Tab(
                  icon: Icon(Icons.receipt_long, size: 20),
                  text: 'Quotation & Invoice',
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Top Quick KPI Summary Banner
              _buildTopKpiBanner(estimate),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRoomsAndWindowsTab(estimate, controller),
                    _buildMaterialsTab(estimate, controller),
                    _buildQuotationTab(estimate, controller),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading Estimate...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $err')),
      ),
    );
  }

  // ==========================================
  // TOP KPI SUMMARY BANNER
  // ==========================================
  Widget _buildTopKpiBanner(CustomerEstimate estimate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.primary.withOpacity(0.04),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildKpiItem('Rooms', estimate.totalRoomsCount.toString()),
          _buildKpiItem('Windows', '${estimate.totalWindowsCount} Units'),
          _buildKpiItem('Total Sq. Ft', estimate.totalSqFt.toStringAsFixed(2), isHighlight: true),
          _buildKpiItem('Grand Total', UnitConverter.formatCurrency(estimate.grandTotal), isBold: true),
        ],
      ),
    );
  }

  Widget _buildKpiItem(String label, String value, {bool isHighlight = false, bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold || isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? AppColors.accent : (isBold ? AppColors.primary : AppColors.textDark),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 1: ROOMS & WINDOWS (Customer -> Rooms -> Windows)
  // ==========================================
  Widget _buildRoomsAndWindowsTab(CustomerEstimate estimate, CustomerController controller) {
    if (estimate.rooms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.door_sliding_outlined, size: 64, color: AppColors.primary.withOpacity(0.3)),
              const SizedBox(height: 16),
              const Text(
                'No Rooms Added Yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Start by adding rooms (e.g. Living Room, Master Bedroom, Kitchen) and then add windows with their inch measurements.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add First Room'),
                onPressed: () => _showAddRoomDialog(estimate.customer.id!),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Quick Room Add Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ROOMS & WINDOW MEASUREMENTS (${estimate.rooms.length})',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Room'),
              onPressed: () => _showAddRoomDialog(estimate.customer.id!),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Room Cards
        ...estimate.rooms.map((room) {
          final roomWindows = estimate.windowsByRoom[room.id] ?? [];
          final roomSqFt = estimate.getRoomTotalSqFt(room.id!);
          final roomWinCount = estimate.getRoomWindowsCount(room.id!);

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.borderLight, width: 1.2),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: true,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.meeting_room, color: AppColors.primary, size: 22),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        room.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${roomSqFt.toStringAsFixed(2)} Sq.Ft',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  '$roomWinCount Windows • ${room.notes.isNotEmpty ? room.notes : "Tap to manage windows"}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (action) {
                    if (action == 'edit') {
                      showDialog(
                        context: context,
                        builder: (_) => RoomFormDialog(
                          customerId: estimate.customer.id!,
                          initialRoom: room,
                          onSave: (updated) => controller.updateRoom(updated),
                        ),
                      );
                    } else if (action == 'delete') {
                      _confirmDeleteRoom(room);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit Room Name')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Room', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
                children: [
                  const Divider(height: 1, color: AppColors.borderLight),
                  if (roomWindows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      child: Center(
                        child: Column(
                          children: [
                            const Text(
                              'No windows added to this room yet.',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Window to Room'),
                              onPressed: () => _showAddWindowDialog(
                                roomId: room.id!,
                                customerId: estimate.customer.id!,
                                defaultIndex: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Windows List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: roomWindows.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, idx) {
                        final win = roomWindows[idx];
                        return _buildWindowListTile(win, room, controller);
                      },
                    ),
                    // Add Another Window in this room button
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: Text('Add Another Window in ${room.name}'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                        onPressed: () => _showAddWindowDialog(
                          roomId: room.id!,
                          customerId: estimate.customer.id!,
                          defaultIndex: roomWindows.length + 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildWindowListTile(WindowItem win, Room room, CustomerController controller) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.window, color: AppColors.accent, size: 22),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              win.label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              win.windowType,
              style: const TextStyle(fontSize: 10, color: AppColors.textDark),
            ),
          ),
          if (win.quantity > 1) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Qty: ${win.quantity}',
                style: const TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          // Dimensions display with inches and auto-feet
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12.5, color: AppColors.textDark),
              children: [
                TextSpan(
                  text: '${UnitConverter.formatInches(win.widthInches)} × ${UnitConverter.formatInches(win.heightInches)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: ' (${win.widthFeet.toStringAsFixed(2)} × ${win.heightFeet.toStringAsFixed(2)} ft)',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Area: ${win.sqFtPerUnit.toStringAsFixed(2)} sq.ft ${win.quantity > 1 ? "× ${win.quantity} = ${win.totalSqFt.toStringAsFixed(2)} sq.ft" : ""}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Edit Window',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => WindowFormDialog(
                  roomId: room.id!,
                  customerId: win.customerId,
                  initialWindow: win,
                  onSave: (updated) => controller.updateWindow(updated),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
            tooltip: 'Delete Window',
            onPressed: () => controller.deleteWindow(win.id!, win.customerId),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: MATERIALS & AUTO CALCULATIONS
  // ==========================================
  Widget _buildMaterialsTab(CustomerEstimate estimate, CustomerController controller) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Auto Calculation Explainer Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.08),
                AppColors.accent.withOpacity(0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.calculate_outlined, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'AUTOMATIC MATERIAL COMPUTATION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Materials like Channels, Glass, and Fitting Labor are automatically calculated based on your total measurement (${estimate.totalSqFt.toStringAsFixed(2)} Sq. Ft across ${estimate.totalWindowsCount} Windows). You can adjust rates, toggle items, or add custom materials below.',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textDark, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'SPECIFICATIONS & RATES',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textMuted),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Material'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => MaterialFormDialog(
                    customerId: estimate.customer.id,
                    onSave: (newMat) => controller.addMaterial(newMat),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Materials List
        ...estimate.materials.map((mat) {
          final effectiveQty = mat.getEffectiveQuantity(
            totalSqFt: estimate.totalSqFt,
            totalWindows: estimate.totalWindowsCount,
          );
          final lineCost = mat.getTotalCost(
            totalSqFt: estimate.totalSqFt,
            totalWindows: estimate.totalWindowsCount,
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: mat.isEnabled ? AppColors.borderLight : Colors.grey.shade200,
                width: 1,
              ),
            ),
            color: mat.isEnabled ? Colors.white : Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Checkbox(
                    value: mat.isEnabled,
                    activeColor: AppColors.accent,
                    onChanged: (val) {
                      controller.updateMaterial(mat.copyWith(isEnabled: val ?? false));
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                mat.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: mat.isEnabled ? AppColors.textDark : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${mat.category} • Rate: ${UnitConverter.formatCurrency(mat.unitPrice)} / ${mat.unit}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Calculated Qty: ${effectiveQty.toStringAsFixed(2)} ${mat.unit}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: mat.isEnabled ? AppColors.accent : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        UnitConverter.formatCurrency(lineCost),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: mat.isEnabled ? AppColors.primary : Colors.grey,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => MaterialFormDialog(
                              customerId: estimate.customer.id,
                              initialMaterial: mat,
                              onSave: (updated) => controller.updateMaterial(updated),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 14),

        // Materials Subtotal Tile
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Estimated Material & Labor Cost:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
              Text(
                UnitConverter.formatCurrency(estimate.materialsCost),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ==========================================
  // TAB 3: QUOTATION, INVOICE & WHATSAPP
  // ==========================================
  Widget _buildQuotationTab(CustomerEstimate estimate, CustomerController controller) {
    final subtotal = estimate.subtotal;
    final discountVal = double.tryParse(_discountController.text.trim()) ?? 0.0;
    final advanceVal = double.tryParse(_advanceController.text.trim()) ?? 0.0;
    final taxRateVal = double.tryParse(_taxController.text.trim()) ?? 0.0;

    double calculatedDiscount = 0.0;
    if (_discountType == 'percentage') {
      calculatedDiscount = subtotal * (discountVal / 100.0);
    } else {
      calculatedDiscount = discountVal;
    }

    final netAmount = (subtotal - calculatedDiscount) > 0 ? (subtotal - calculatedDiscount) : 0.0;
    final taxAmount = netAmount * (taxRateVal / 100.0);
    final grandTotal = netAmount + taxAmount;
    final balanceDue = (grandTotal - advanceVal) > 0 ? (grandTotal - advanceVal) : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Mode Selector: Quotation vs Tax Invoice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Document Format:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Quotation / Estimate')),
                      selected: !_isInvoice,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: !_isInvoice ? Colors.white : AppColors.textDark,
                        fontWeight: !_isInvoice ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _isInvoice = false);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Tax Invoice')),
                      selected: _isInvoice,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _isInvoice ? Colors.white : AppColors.textDark,
                        fontWeight: _isInvoice ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _isInvoice = true);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Financial Inputs Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Pricing, Discounts & Payments',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),

                // Subtotal display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Material & Work Subtotal:', style: TextStyle(fontSize: 14)),
                    Text(
                      UnitConverter.formatCurrency(subtotal),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Discount Controls
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _discountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Discount',
                          hintText: '0',
                          prefixText: _discountType == 'flat' ? '₹ ' : '',
                          suffixText: _discountType == 'percentage' ? '%' : '',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 'flat', label: Text('₹ Flat', style: TextStyle(fontSize: 12))),
                          ButtonSegment(value: 'percentage', label: Text('%', style: TextStyle(fontSize: 12))),
                        ],
                        selected: {_discountType},
                        onSelectionChanged: (val) => setState(() => _discountType = val.first),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // GST / Tax (if Invoice mode)
                if (_isInvoice) ...[
                  TextFormField(
                    controller: _taxController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'GST Rate (%)',
                      hintText: 'e.g. 18',
                      suffixText: '%',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                ],

                // Advance Payment
                TextFormField(
                  controller: _advanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Advance Payment Received',
                    hintText: '0',
                    prefixText: '₹ ',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 18),

                // Save Pricing Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Update & Save Pricing Settings'),
                  onPressed: () {
                    controller.updatePricing(
                      customer: estimate.customer,
                      discountType: _discountType,
                      discountValue: discountVal,
                      advanceAmount: advanceVal,
                      status: _isInvoice ? 'invoiced' : 'quotation',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pricing updated successfully!')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Net Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSummaryLine('Subtotal', UnitConverter.formatCurrency(subtotal), color: Colors.white70),
              if (calculatedDiscount > 0)
                _buildSummaryLine(
                  'Discount Applied',
                  '- ${UnitConverter.formatCurrency(calculatedDiscount)}',
                  color: Colors.amberAccent,
                ),
              if (taxAmount > 0)
                _buildSummaryLine(
                  'GST ($taxRateVal%)',
                  '+ ${UnitConverter.formatCurrency(taxAmount)}',
                  color: Colors.white70,
                ),
              const Divider(color: Colors.white24, height: 20),
              _buildSummaryLine(
                'Grand Total',
                UnitConverter.formatCurrency(grandTotal),
                isBold: true,
                fontSize: 18,
                color: Colors.white,
              ),
              if (advanceVal > 0) ...[
                const SizedBox(height: 6),
                _buildSummaryLine(
                  'Advance Received',
                  UnitConverter.formatCurrency(advanceVal),
                  color: Colors.greenAccent,
                ),
                _buildSummaryLine(
                  'Balance Payable',
                  UnitConverter.formatCurrency(balanceDue),
                  isBold: true,
                  fontSize: 16,
                  color: Colors.amberAccent,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ACTION BUTTON 1: DIRECT WHATSAPP SHARE
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366), // WhatsApp Green
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.share, size: 22),
          label: const Text(
            'Share Quotation / Invoice on WhatsApp',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          onPressed: () => _handleShareWhatsApp(estimate),
        ),
        const SizedBox(height: 12),

        // ACTION BUTTON 2: VIEW / PRINT PDF
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text(
            'Preview & Print Official PDF',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PdfPreviewScreen(
                  estimate: estimate,
                  isInvoice: _isInvoice,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSummaryLine(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 14,
    Color color = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color),
          ),
          Text(
            value,
            style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ACTIONS & DIALOGS
  // ==========================================
  void _showAddRoomDialog(int customerId) {
    final controller = ref.read(customerControllerProvider);
    showDialog(
      context: context,
      builder: (_) => RoomFormDialog(
        customerId: customerId,
        onSave: (room) => controller.addRoom(
          customerId: customerId,
          name: room.name,
          notes: room.notes,
        ),
      ),
    );
  }

  void _showAddWindowDialog({
    required int roomId,
    required int customerId,
    required int defaultIndex,
  }) {
    final controller = ref.read(customerControllerProvider);
    showDialog(
      context: context,
      builder: (_) => WindowFormDialog(
        roomId: roomId,
        customerId: customerId,
        defaultWindowIndex: defaultIndex,
        onSave: (win) => controller.addWindow(win),
      ),
    );
  }

  void _confirmDeleteRoom(Room room) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${room.name}"?'),
        content: const Text(
          'This will permanently delete this room and all windows inside it.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(customerControllerProvider).deleteRoom(room.id!, room.customerId);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleShareWhatsApp(CustomerEstimate estimate) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF and opening WhatsApp...'), duration: Duration(seconds: 2)),
      );

      final pdfFile = await PdfInvoiceGenerator.generateEstimatePdf(
        estimate: estimate,
        isInvoice: _isInvoice,
      );

      await WhatsAppService.sharePdf(
        pdfFile: pdfFile,
        estimate: estimate,
        isInvoice: _isInvoice,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }
}
