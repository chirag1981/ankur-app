import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../models/company_profile.dart';

class CompanyProfileDialog extends StatefulWidget {
  final CompanyProfile initialProfile;
  final ValueChanged<CompanyProfile> onSave;

  const CompanyProfileDialog({
    super.key,
    required this.initialProfile,
    required this.onSave,
  });

  @override
  State<CompanyProfileDialog> createState() => _CompanyProfileDialogState();
}

class _CompanyProfileDialogState extends State<CompanyProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _taglineController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _facebookController;
  late TextEditingController _instagramController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfile.companyName);
    _taglineController = TextEditingController(text: widget.initialProfile.tagline);
    _phoneController = TextEditingController(text: widget.initialProfile.phone);
    _emailController = TextEditingController(text: widget.initialProfile.email);
    _facebookController = TextEditingController(text: widget.initialProfile.facebookId);
    _instagramController = TextEditingController(text: widget.initialProfile.instagramId);
    _addressController = TextEditingController(text: widget.initialProfile.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company name cannot be empty')),
      );
      return;
    }

    final updated = widget.initialProfile.copyWith(
      companyName: name,
      tagline: _taglineController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      facebookId: _facebookController.text.trim(),
      instagramId: _instagramController.text.trim(),
      address: _addressController.text.trim(),
    );

    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.business, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Company & Invoice Profile',
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Printed on Quotations & Tax Invoices',
                          style: TextStyle(color: Colors.white70, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Logo Preview Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 50,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderLight),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Official Company Logo',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Appears on the top of official PDF quotes and invoices',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Company / Business Name *',
                      prefixIcon: Icon(Icons.store),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _taglineController,
                    decoration: const InputDecoration(
                      labelText: 'Tagline / Slogan',
                      hintText: 'e.g. INVISIBLE GRILL - Secure, Stylish & Invisible',
                      prefixIcon: Icon(Icons.subtitles_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Contact Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _instagramController,
                    decoration: const InputDecoration(
                      labelText: 'Instagram ID / Handle',
                      hintText: '@arham_enterprise',
                      prefixIcon: Icon(Icons.camera_alt_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _facebookController,
                    decoration: const InputDecoration(
                      labelText: 'Facebook Page / ID',
                      hintText: 'Arham Invisible Grill',
                      prefixIcon: Icon(Icons.facebook),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Office / Workshop Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Save Details'),
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
