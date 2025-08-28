import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/tutor_profile_controller.dart';
import '../../models/user_model.dart';

class TutorProfileView extends StatefulWidget {
  const TutorProfileView({super.key});

  @override
  State<TutorProfileView> createState() => _TutorProfileViewState();
}

class _TutorProfileViewState extends State<TutorProfileView> {
  final c = Get.put(TutorProfileController());
  bool _editing = false;
  late TextEditingController name;
  late TextEditingController edu;
  late TextEditingController fee;
  // Rating is read-only; no controller needed.

  @override
  void initState() {
    super.initState();
    name = TextEditingController();
    edu = TextEditingController();
    fee = TextEditingController();
  }

  @override
  void dispose() {
    name.dispose();
    edu.dispose();
    fee.dispose();
    super.dispose();
  }

  void _enterEdit(Tutor t) {
    name.text = t.name ?? '';
    edu.text = t.edu ?? '';
    fee.text = t.fee?.toString() ?? '';
    setState(() => _editing = true);
  }

  Future<void> _save(Tutor t) async {
    final updated = t.copyWith(
      name: name.text.trim().isEmpty ? null : name.text.trim(),
      edu: edu.text.trim().isEmpty ? null : edu.text.trim(),
      fee: double.tryParse(fee.text.trim()),
      // rating not editable here; preserve existing value
    );
    final err = await c.save(updated);
    if (err != null) {
      Get.snackbar('Save failed', err, snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar(
        'Profile',
        'Changes saved',
        snackPosition: SnackPosition.BOTTOM,
      );
      setState(() => _editing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final Tutor? t = c.tutor.value;
      if (t == null) return const Center(child: Text('No profile'));
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                child: const Icon(Icons.person, size: 40),
              ),
            ),
            const SizedBox(height: 12),
            if (_editing) ...[
              TextField(
                decoration: const InputDecoration(labelText: 'Name'),
                controller: name,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Education'),
                controller: edu,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Fee'),
                controller: fee,
                keyboardType: TextInputType.number,
              ),
            ] else ...[
              _Field(label: 'Name', value: t.name ?? '-'),
              _Field(label: 'Education', value: t.edu ?? '-'),
              _Field(label: 'Email', value: t.email),
              _Field(
                label: 'Rating',
                value: t.rating?.toStringAsFixed(1) ?? '-',
              ),
              _Field(label: 'Fee', value: t.fee?.toStringAsFixed(2) ?? '-'),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_editing) ...[
                  OutlinedButton(
                    onPressed: () => setState(() => _editing = false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => _save(t),
                    child: const Text('Save Changes'),
                  ),
                ] else ...[
                  FilledButton(
                    onPressed: () => _enterEdit(t),
                    child: const Text('Edit Profile'),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  const _Field({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}

// Inline editing removed the dialog; no longer needed.
