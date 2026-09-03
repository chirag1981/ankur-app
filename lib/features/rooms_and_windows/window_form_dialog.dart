import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/unit_converter.dart';
import '../../models/models.dart';

class WindowFormDialog extends StatefulWidget {
  final int roomId;
  final int customerId;
  final WindowItem? initialWindow;
  final int defaultWindowIndex;
  final Function(WindowItem window) onSave;

  const WindowFormDialog({
    super.key,
    required this.roomId,
    required this.customerId,
    this.initialWindow,
    this.defaultWindowIndex = 1,
    required this.onSave,
  });

  @override
  State<WindowFormDialog> createState() => _WindowFormDialogState();
}

class _WindowFormDialogState extends State<WindowFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _labelController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;

  String _selectedType = '3-Track Sliding';
  int _quantity = 1;

  final List<String> _windowTypes = [
    '3-Track Sliding',
    '2-Track Sliding',
    'Casement / Openable',
    'Fixed Glass',
    'Ventilator / Louver',
    'Custom Section',
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initialWindow;
    _labelController = TextEditingController(
      text: init?.label ?? 'Window ${widget.defaultWindowIndex}',
    );
    _widthController = TextEditingController(
      text: init != null && init.widthInches > 0
          ? (init.widthInches == init.widthInches.roundToDouble()
              ? init.widthInches.toInt().toString()
              : init.widthInches.toString())
          : '',
    );
    _heightController = TextEditingController(
      text: init != null && init.heightInches > 0
          ? (init.heightInches == init.heightInches.roundToDouble()
              ? init.heightInches.toInt().toString()
              : init.heightInches.toString())
          : '',
    );
    _selectedType = init?.windowType ?? '3-Track Sliding';
    _quantity = init?.quantity ?? 1;

    _widthController.addListener(() => setState(() {}));
    _heightController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _labelController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  double get _currentWidthInches {
    return double.tryParse(_widthController.text.trim()) ?? 0.0;
  }

  double get _currentHeightInches {
    return double.tryParse(_heightController.text.trim()) ?? 0.0;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final width = _currentWidthInches;
      final height = _currentHeightInches;

      if (width <= 0 || height <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter valid width and length')),
        );
        return;
      }

      final window = (widget.initialWindow ??
              WindowItem(
                roomId: widget.roomId,
                customerId: widget.customerId,
                label: '',
                widthInches: 0,
                heightInches: 0,
              ))
          .copyWith(
        label: _labelController.text.trim(),
        windowType: _selectedType,
        widthInches: width,
        heightInches: height,
        quantity: _quantity,
      );

      widget.onSave(window);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialWindow != null;
    final wIn = _currentWidthInches;
    final hIn = _currentHeightInches;
    final wFt = UnitConverter.inchesToFeet(wIn);
    final hFt = UnitConverter.inchesToFeet(hIn);
    final singleSqFt = UnitConverter.calculateSqFt(widthInches: wIn, heightInches: hIn, quantity: 1);
    final totalSqFt = singleSqFt * _quantity;

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
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.window, color: AppColors.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Window' : 'Add New Window',
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

                // Window Label
                TextFormField(
                  controller: _labelController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Window Name / Label',
                    hintText: 'e.g. Window 1, Balcony Door, W2',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Enter window label';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Window Type Selector
                const Text(
                  'Window Track & System Type:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _windowTypes.map((type) {
                    final selected = _selectedType == type;
                    return ChoiceChip(
                      label: Text(type),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.textDark,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedType = type);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Dimensions Input (Inches)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _widthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Width (Inches) *',
                          hintText: '48',
                          suffixText: 'in',
                          prefixIcon: Icon(Icons.swap_horiz),
                        ),
                        validator: (val) {
                          final v = double.tryParse(val ?? '');
                          if (v == null || v <= 0) return 'Required';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Height (Inches) *',
                          hintText: '60',
                          suffixText: 'in',
                          prefixIcon: Icon(Icons.swap_vert),
                        ),
                        validator: (val) {
                          final v = double.tryParse(val ?? '');
                          if (v == null || v <= 0) return 'Required';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Quantity Counter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Window Quantity:',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () => setState(() => _quantity++),
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // LIVE AUTO-CONVERTER CARD
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withOpacity(0.08),
                        AppColors.primary.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.auto_awesome, size: 16, color: AppColors.accent),
                          SizedBox(width: 6),
                          Text(
                            'AUTOMATIC CONVERSION & SQ. FT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatBadge(
                            label: 'Converted Size (Feet)',
                            value: wIn > 0 && hIn > 0
                                ? '${wFt.toStringAsFixed(2)} × ${hFt.toStringAsFixed(2)} ft'
                                : '0.00 × 0.00 ft',
                          ),
                          _buildStatBadge(
                            label: 'Single Window Area',
                            value: '${singleSqFt.toStringAsFixed(2)} sq.ft',
                          ),
                        ],
                      ),
                      const Divider(height: 18, color: AppColors.borderLight),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Total Area ($_quantity Unit${_quantity > 1 ? "s" : ""}):',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                          Text(
                            '${totalSqFt.toStringAsFixed(2)} Sq. Ft',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
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
                        child: Text(isEditing ? 'Save Window' : 'Add Window'),
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

  Widget _buildStatBadge({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ],
    );
  }
}
