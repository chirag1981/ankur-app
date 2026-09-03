import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/unit_converter.dart';
import '../providers.dart';
import 'material_form_dialog.dart';

class MasterMaterialsScreen extends ConsumerWidget {
  const MasterMaterialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masterAsync = ref.watch(masterMaterialsProvider);
    final controller = ref.read(customerControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Material Catalog & Rates'),
      ),
      body: masterAsync.when(
        data: (materials) {
          if (materials.isEmpty) {
            return const Center(child: Text('No master materials configured'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: AppColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'These are your default shop rates. When you create a new customer, these rates are automatically copied to their estimate.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...materials.map((mat) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.accent.withOpacity(0.12),
                      child: Icon(_getCategoryIcon(mat.category), color: AppColors.accent, size: 20),
                    ),
                    title: Text(mat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                    subtitle: Text(
                      '${mat.category} • Basis: ${_formatCalcType(mat.calculationType)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${UnitConverter.formatCurrency(mat.unitPrice)} / ${mat.unit}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => MaterialFormDialog(
                                customerId: null,
                                initialMaterial: mat,
                                onSave: (updated) => controller.updateMaterial(updated),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => MaterialFormDialog(
              customerId: null,
              onSave: (newMat) => controller.addMaterial(newMat),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Default Rate'),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'channel':
        return Icons.view_column_outlined;
      case 'glass':
        return Icons.window_outlined;
      case 'hardware':
        return Icons.build_outlined;
      case 'labor':
        return Icons.engineering_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  String _formatCalcType(String type) {
    switch (type) {
      case 'per_ft':
        return 'In Ft (Width × 2)';
      case 'per_sq_ft':
        return 'Per Sq. Ft Area';
      case 'per_window':
        return 'Per Window Unit';
      case 'fixed':
        return 'Fixed / Set';
      default:
        return type;
    }
  }
}
