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
    'Transport',
    'Accessories',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initialMaterial;
    _nameController = TextEditingController(text: init?.name ?? '');
    _priceController = TextEditingController(
      text: init != null && init.unitPrice > 0
          ? (init.unitPrice % 1 == 0 ? init.unitPrice.toInt().toString() : init.unitPrice.toString())
          : '',
    );
    _multiplierController = TextEditingController(
      text: (init?.multiplier ?? 1.0).toString(),
    );
    _manualQtyController = TextEditingController(
      text: init != null && init.manualQuantity > 0 && init.calculationType == 'manual_qty'
          ? (init.manualQuantity % 1 == 0 ? init.manualQuantity.toInt().toString() : init.manualQuantity.toString())
          : '',
    );

    _category = init?.category ?? 'Channel';
    _calculationType = init?.calculationType ?? (_category == 'Channel' ? 'per_ft' : 'per_sq_ft');
    _unit = init?.unit ?? (_category == 'Channel' ? 'Ft' : 'Sq. Ft');
    if (_category == 'Channel' && (_calculationType == 'per_sq_ft' || _calculationType == 'per_window')) {
      _calculationType = 'per_ft';
      _unit = 'Ft';
    }
    final initNameLower = (init?.name ?? '').toLowerCase();
    if (initNameLower.contains('bolt') && (_calculationType == 'per_sq_ft' || _calculationType == 'per_window')) {
      _calculationType = 'per_channel_bolts';
      _unit = 'Pcs';
    }
    if (initNameLower.contains('chokdi') && (_calculationType == 'per_sq_ft' || _calculationType == 'per_window')) {
      _calculationType = 'per_channel_chokdi';
      _unit = 'Pcs';
    }
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
      if (type == 'per_channel_chokdi' || type == 'per_channel_bolts' || type == 'manual_qty') {
        _unit = 'Pcs';
      } else if (type == 'per_ft') {
        _unit = 'Ft';
      } else if (type == 'per_wire_meter') {
        _unit = 'Meter';
      } else if (type == 'per_sq_ft') {
        _unit = 'Sq. Ft';
      } else if (type == 'per_window') {
        _unit = 'Per Window';
      } else if (type == 'fixed') {
        _unit = _category == 'Transport' ? 'Trip' : (_category == 'Hardware' ? 'Pcs' : 'Fixed');
      } else {
        _unit = 'Units / Set';
      }

      if (type == 'manual_qty' && _manualQtyController.text.trim().isEmpty) {
        final lower = _nameController.text.toLowerCase();
        if (lower.contains('bolt')) {
          _manualQtyController.text = '12';
        } else if (lower.contains('chokdi')) {
          _manualQtyController.text = '60';
        } else {
          _manualQtyController.text = '1';
        }
      }
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final mult = double.tryParse(_multiplierController.text.trim()) ?? 1.0;
      final manQty = _calculationType == 'fixed'
          ? 1.0
          : (_calculationType == 'manual_qty'
              ? (double.tryParse(_manualQtyController.text.trim()) ?? 1.0)
              : 1.0);

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
                    hintText: 'e.g. Fitting Labor / Aluminium Track',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  onChanged: (val) {
                    if (widget.initialMaterial == null) {
                      final lower = val.trim().toLowerCase();
                      if (lower.contains('wire')) {
                        setState(() {
                          _category = 'Wire';
                          _calculationType = 'per_wire_meter';
                          _unit = 'Meter';
                          if (_priceController.text.isEmpty) {
                            _priceController.text = '13';
                          }
                        });
                      } else if (lower.contains('channel')) {
                        setState(() {
                          _category = 'Channel';
                          _calculationType = 'per_ft';
                          _unit = 'Ft';
                          if (_priceController.text.isEmpty) {
                            _priceController.text = '90';
                          }
                        });
                      } else if (lower.contains('labor')) {
                        setState(() {
                          _category = 'Labor';
                          _calculationType = 'per_sq_ft';
                          _unit = 'Sq. Ft';
                          if (_priceController.text.isEmpty) {
                            _priceController.text = '20';
                          }
                        });
                      } else if (lower.contains('bolt')) {
                        setState(() {
                          _category = 'Hardware';
                          _calculationType = 'per_channel_bolts';
                          _unit = 'Pcs';
                          if (_priceController.text.isEmpty) {
                            _priceController.text = '5';
                          }
                        });
                      } else if (lower.contains('chokdi')) {
                        setState(() {
                          _category = 'Hardware';
                          _calculationType = 'per_channel_chokdi';
                          _unit = 'Pcs';
                          if (_priceController.text.isEmpty) {
                            _priceController.text = '2';
                          }
                        });
                      } else if (lower.contains('transport')) {
                        setState(() {
                          _category = 'Transport';
                          _calculationType = 'fixed';
                          _unit = 'Trip';
                        });
                      } else if (lower.contains('round hook')) {
                        setState(() {
                          _category = 'Hardware';
                          _calculationType = 'fixed';
                          _unit = 'Pcs';
                        });
                      } else if (lower.contains('self screw')) {
                        setState(() {
                          _category = 'Hardware';
                          _calculationType = 'fixed';
                          _unit = 'Pcs';
                        });
                      }
                    }
                  },
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
                        isExpanded: true,
                        value: _category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: _categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() {
                            _category = val;
                            if (val == 'Wire') {
                              _calculationType = 'per_wire_meter';
                              _unit = 'Meter';
                              if (_priceController.text.isEmpty) {
                                _priceController.text = '13';
                              }
                            } else if (val == 'Channel') {
                              _calculationType = 'per_ft';
                              _unit = 'Ft';
                              if (_priceController.text.isEmpty) {
                                _priceController.text = '90';
                              }
                            } else if (val == 'Labor') {
                              _calculationType = 'per_sq_ft';
                              _unit = 'Sq. Ft';
                              if (_priceController.text.isEmpty) {
                                _priceController.text = '20';
                              }
                            } else if (val == 'Transport') {
                              _calculationType = 'fixed';
                              _unit = 'Trip';
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Rate (₹) *',
                          hintText: _category == 'Wire' ? '13' : '90',
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

                // Quick Wire Thickness Presets
                if (_category == 'Wire' || _calculationType == 'per_wire_meter') ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Wire Thickness & Standard Rates:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('2mm (₹9/m)'),
                        avatar: const Icon(Icons.cable, size: 14),
                        onPressed: () {
                          setState(() {
                            _nameController.text = 'Wire (2mm)';
                            _category = 'Wire';
                            _unit = 'Meter';
                            _calculationType = 'per_wire_meter';
                            _priceController.text = '9';
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('2.5mm (₹13/m)'),
                        avatar: const Icon(Icons.cable, size: 14),
                        onPressed: () {
                          setState(() {
                            _nameController.text = 'Wire (2.5mm)';
                            _category = 'Wire';
                            _unit = 'Meter';
                            _calculationType = 'per_wire_meter';
                            _priceController.text = '13';
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('3mm (₹16/m)'),
                        avatar: const Icon(Icons.cable, size: 14),
                        onPressed: () {
                          setState(() {
                            _nameController.text = 'Wire (3mm)';
                            _category = 'Wire';
                            _unit = 'Meter';
                            _calculationType = 'per_wire_meter';
                            _priceController.text = '16';
                          });
                        },
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),

                // Calculation Basis
                const Text(
                  'Calculation Basis:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                Builder(
                  builder: (context) {
                    final isManualFixed = _calculationType == 'fixed' ||
                        _category == 'Transport' ||
                        _nameController.text.trim().toLowerCase().contains('transport') ||
                        _nameController.text.trim().toLowerCase().contains('round hook') ||
                        _nameController.text.trim().toLowerCase().contains('self screw');

                    if (isManualFixed) {
                      final itemName = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'This item';
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              itemName.toLowerCase().contains('transport')
                                  ? Icons.local_shipping_outlined
                                  : Icons.handyman_outlined,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$itemName is entered as a manual rate (₹) and added directly to the total.',
                                style: const TextStyle(fontSize: 12.5, color: AppColors.textDark, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final nameLower = _nameController.text.trim().toLowerCase();
                    final isBolt = nameLower.contains('bolt') || _calculationType == 'per_channel_bolts';
                    final isChokdi = nameLower.contains('chokdi') || _calculationType == 'per_channel_chokdi';
                    final isChannel = _category == 'Channel' || nameLower.contains('channel');
                    final isWire = _category == 'Wire' || nameLower.contains('wire');

                    // 1. BOLT SPECIFIC OPTIONS
                    if (isBolt) {
                      final parsedPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
                      final parsedQty = double.tryParse(_manualQtyController.text.trim()) ?? 0.0;
                      final totalCost = parsedQty * parsedPrice;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Bolts (12 / Channel)'),
                                selected: _calculationType == 'per_channel_bolts',
                                onSelected: (s) => _onCalcTypeChanged('per_channel_bolts'),
                              ),
                              ChoiceChip(
                                label: const Text('Manual Quantity (Pcs)'),
                                selected: _calculationType == 'manual_qty',
                                onSelected: (s) => _onCalcTypeChanged('manual_qty'),
                              ),
                            ],
                          ),
                          if (_calculationType == 'per_channel_bolts') ...[
                            const SizedBox(height: 6),
                            const Text(
                              'Bolts are automatically counted: 12 bolts for each 10ft channel.',
                              style: TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w500),
                            ),
                          ] else if (_calculationType == 'manual_qty') ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _manualQtyController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Bolt Quantity (Pcs) *',
                                hintText: 'Enter total number of bolts (e.g. 24 or 48)',
                                prefixIcon: Icon(Icons.pin_outlined),
                                suffixText: 'Pcs',
                              ),
                              validator: (val) {
                                if (_calculationType == 'manual_qty') {
                                  final v = double.tryParse(val ?? '');
                                  if (v == null || v <= 0) return 'Please enter a valid bolt quantity';
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                            if (parsedQty > 0 && parsedPrice > 0) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Cost: ${parsedQty.toInt()} Pcs × ₹$parsedPrice',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '₹${totalCost.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ],
                      );
                    }

                    // 2. CHOKDI SPECIFIC OPTIONS
                    if (isChokdi) {
                      final parsedPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
                      final parsedQty = double.tryParse(_manualQtyController.text.trim()) ?? 0.0;
                      final totalCost = parsedQty * parsedPrice;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Chokdi (60 / Channel)'),
                                selected: _calculationType == 'per_channel_chokdi',
                                onSelected: (s) => _onCalcTypeChanged('per_channel_chokdi'),
                              ),
                              ChoiceChip(
                                label: const Text('Manual Quantity (Pcs)'),
                                selected: _calculationType == 'manual_qty',
                                onSelected: (s) => _onCalcTypeChanged('manual_qty'),
                              ),
                            ],
                          ),
                          if (_calculationType == 'per_channel_chokdi') ...[
                            const SizedBox(height: 6),
                            const Text(
                              'Chokdi are automatically counted: 60 chokdi for each 10ft channel.',
                              style: TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w500),
                            ),
                          ] else if (_calculationType == 'manual_qty') ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _manualQtyController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Chokdi Quantity (Pcs) *',
                                hintText: 'Enter total number of chokdi (e.g. 60 or 120)',
                                prefixIcon: Icon(Icons.pin_outlined),
                                suffixText: 'Pcs',
                              ),
                              validator: (val) {
                                if (_calculationType == 'manual_qty') {
                                  final v = double.tryParse(val ?? '');
                                  if (v == null || v <= 0) return 'Please enter a valid chokdi quantity';
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                            if (parsedQty > 0 && parsedPrice > 0) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Cost: ${parsedQty.toInt()} Pcs × ₹$parsedPrice',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '₹${totalCost.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ],
                      );
                    }

                    // 3. OTHER MATERIALS OPTIONS
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (isWire)
                              ChoiceChip(
                                label: const Text('Wire (Sq.Ft × 2.7m)'),
                                selected: _calculationType == 'per_wire_meter',
                                onSelected: (s) => _onCalcTypeChanged('per_wire_meter'),
                              ),
                            if (isChannel)
                              ChoiceChip(
                                label: const Text('In Ft (Width × 2)'),
                                selected: _calculationType == 'per_ft',
                                onSelected: (s) => _onCalcTypeChanged('per_ft'),
                              ),
                            if (!isChannel && !isWire) ...[
                              ChoiceChip(
                                label: const Text('Per Sq.Ft Area'),
                                selected: _calculationType == 'per_sq_ft',
                                onSelected: (s) => _onCalcTypeChanged('per_sq_ft'),
                              ),
                              ChoiceChip(
                                label: const Text('Per Window Unit'),
                                selected: _calculationType == 'per_window',
                                onSelected: (s) => _onCalcTypeChanged('per_window'),
                              ),
                              ChoiceChip(
                                label: const Text('Manual Quantity'),
                                selected: _calculationType == 'manual_qty',
                                onSelected: (s) => _onCalcTypeChanged('manual_qty'),
                              ),
                            ],
                          ],
                        ),
                        if (_calculationType == 'per_wire_meter') ...[
                          const SizedBox(height: 6),
                          const Text(
                            'Wire length is automatically measured as Total Sq. Ft × 2.7 meters. Rates: 2mm @ ₹9/m, 2.5mm @ ₹13/m, 3mm @ ₹16/m.',
                            style: TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w500),
                          ),
                        ] else if (_calculationType == 'per_ft') ...[
                          const SizedBox(height: 6),
                          const Text(
                            'Calculated on width in ft × 2 per window (top & bottom track). One 10ft channel is ₹900 (₹90/ft).',
                            style: TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w500),
                          ),
                        ] else if (_calculationType == 'manual_qty') ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _manualQtyController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Quantity ($_unit) *',
                              hintText: 'Enter quantity',
                              prefixIcon: const Icon(Icons.pin_outlined),
                              suffixText: _unit,
                            ),
                            validator: (val) {
                              if (_calculationType == 'manual_qty') {
                                final v = double.tryParse(val ?? '');
                                if (v == null || v <= 0) return 'Please enter a valid quantity';
                              }
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),

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
