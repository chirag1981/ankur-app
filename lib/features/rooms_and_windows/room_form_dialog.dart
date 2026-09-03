import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../models/models.dart';

class RoomFormDialog extends StatefulWidget {
  final int customerId;
  final Room? initialRoom;
  final int defaultRoomIndex;
  final Function(Room room) onSave;

  const RoomFormDialog({
    super.key,
    required this.customerId,
    this.initialRoom,
    this.defaultRoomIndex = 1,
    required this.onSave,
  });

  @override
  State<RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends State<RoomFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialRoom?.name ?? 'Room ${widget.defaultRoomIndex}',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final room = (widget.initialRoom ?? Room(customerId: widget.customerId, name: '')).copyWith(
        name: _nameController.text.trim(),
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
                      isEditing ? 'Edit Room' : 'Add Room',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Room Name *',
                  hintText: 'e.g. Room 1',
                  prefixIcon: Icon(Icons.meeting_room),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter room name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),

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
    );
  }
}
