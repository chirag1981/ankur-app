import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../models/models.dart';

class RoomFormDialog extends StatefulWidget {
  final int customerId;
  final Room? initialRoom;
  final Function(Room room) onSave;

  const RoomFormDialog({
    super.key,
    required this.customerId,
    this.initialRoom,
    required this.onSave,
  });

  @override
  State<RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends State<RoomFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _notesController;

  final List<String> _roomPresets = [
    'Living Room',
    'Master Bedroom',
    'Kitchen',
    'Balcony',
    'Bedroom 2',
    'Dining Area',
    'Guest Bedroom',
    'Bathroom / Washroom',
    'Office / Study Room',
    'Terrace',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialRoom?.name ?? '');
    _notesController = TextEditingController(text: widget.initialRoom?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final room = (widget.initialRoom ?? Room(customerId: widget.customerId, name: '')).copyWith(
        name: _nameController.text.trim(),
        notes: _notesController.text.trim(),
      );
      widget.onSave(room);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialRoom != null;

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
                      child: const Icon(Icons.meeting_room_outlined, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Room' : 'Select / Add Room',
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

                // Presets
                const Text(
                  'Quick Select Popular Rooms:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _roomPresets.map((preset) {
                    final isSelected = _nameController.text == preset;
                    return ActionChip(
                      label: Text(preset),
                      avatar: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                      backgroundColor: isSelected ? AppColors.primary : Colors.grey.shade100,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textDark,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onPressed: () {
                        setState(() {
                          _nameController.text = preset;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Room Name *',
                    hintText: 'e.g. Master Bedroom or Living Room',
                    prefixIcon: Icon(Icons.door_sliding_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please select or enter room name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Room Notes (Optional)',
                    hintText: 'e.g. Facing north, requires heavy section',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 20),

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
                        child: Text(isEditing ? 'Save Room' : 'Add Room'),
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
