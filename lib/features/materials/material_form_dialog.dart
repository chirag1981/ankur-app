import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../models/models.dart';

class MaterialFormDialog extends StatefulWidget {
  final int? customerId;
  final MaterialItem? initialMaterial;
  final Function(MaterialItem material) onSave;

  const MaterialFormDialog({
    super.key,
    this.customerId,
    this.initialMaterial,
    required this.onSave,
  });

  @override
  State<MaterialFormDialog> createState() => _MaterialFormDialogState();
}

class _MaterialFormDialogState extends State<MaterialFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _multiplierController;
  late TextEditingController _manualQtyController;

  String _category = 'Channel';
  String _calculationType = 'per_sq_ft';
  String _unit = 'Sq. Ft';
  bool _isEnabled = true;

  final List<String> _categories = [
    'Channel',
    'Wire',
    'Hardware',
    'Labor',
    'Accessories',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initialMaterial;
    _nameController = TextEditingController(text: init?.name ?? '');
    _priceController = TextEditingController(
      text: init != null && init.unitPrice > 0 ? init.unitPrice.toStringAsFixed(0) : '',
    );
    _multiplierController = TextEditingController(
      text: (init?.multiplier ?? 1.0).toString(),
    );
    _manualQtyController = TextEditingController(
      text: (init?.manualQuantity ?? 1.0).toString(),
    );

    _category = init?.category ?? 'Channel';
    _calculationType = init?.calculationType ?? 'per_sq_ft';
    _unit = init?.unit ?? 'Sq. Ft';
    _isEnabled = init?.isEnabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _multiplierController.dispose();
    _manualQtyController.dispose();
    super.dispose();
  }

  void _onCalcTypeChanged(String? type) {
    if (type == null) return;
    setState(() {
      _calculationType = type;
      if (type == 'per_sq_ft') {
        _unit = 'Sq. Ft';
      } else if (type == 'per_window') {
        _unit = 'Per Window';
      } else {
        _unit = 'Units / Set';
      }
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final mult = double.tryParse(_multiplierController.text.trim()) ?? 1.0;
      final manQty = double.tryParse(_manualQtyController.text.trim()) ?? 1.0;

      final material = (widget.initialMaterial ??
              MaterialItem(
                customerId: widget.customerId,
                name: '',
                unitPrice: 0,
              ))
          .copyWith(
        customerId: widget.customerId,
        name: _nameController.text.trim(),
        category: _category,
        unit: _unit,
        unitPrice: price,
        calculationType: _calculationType,
        multiplier: mult,
        manualQuantity: manQty,
        isEnabled: _isEnabled,
      );

      widget.onSave(material);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialMaterial != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Material / Rate' : 'Add Material',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Material Name
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Material / Work Name *',
                    hintText: 'e.g. Aluminium 3-Track Section',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter material name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Category and Unit
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: _categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) => setState(() => _category = val ?? 'Channel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Rate (₹) *',
                          hintText: '140',
                          prefixText: '₹ ',
                        ),
                        validator: (val) {
                          final v = double.tryParse(val ?? '');
                          if (v == null || v < 0) return 'Invalid rate';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Calculation Basis
                const Text(
                  'Calculation Basis:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'per_sq_ft', label: Text('Per Sq.Ft')),
                    ButtonSegment(value: 'per_window', label: Text('Per Window')),
                    ButtonSegment(value: 'fixed', label: Text('Fixed')),
                  ],
                  selected: {_calculationType},
                  onSelectionChanged: (val) => _onCalcTypeChanged(val.first),
                ),
                const SizedBox(height: 14),

                if (_calculationType == 'fixed') ...[
                  TextFormField(
                    controller: _manualQtyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Fixed Quantity',
                      hintText: '1',
                      prefixIcon: Icon(Icons.format_list_numbered),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Switch enabled
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Include in Estimate Calculation', style: TextStyle(fontSize: 14)),
                  value: _isEnabled,
                  activeColor: AppColors.accent,
                  onChanged: (val) => setState(() => _isEnabled = val),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: Text(isEditing ? 'Update' : 'Add Material'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
