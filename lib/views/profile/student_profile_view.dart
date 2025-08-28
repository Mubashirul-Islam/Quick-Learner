import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/student_profile_controller.dart';
import '../../models/user_model.dart';

class StudentProfileView extends StatefulWidget {
  const StudentProfileView({super.key});

  @override
  State<StudentProfileView> createState() => _StudentProfileViewState();
}

class _StudentProfileViewState extends State<StudentProfileView> {
  final c = Get.put(StudentProfileController());
  bool _editing = false;
  late TextEditingController name;
  late TextEditingController edu;

  @override
  void initState() {
    super.initState();
    name = TextEditingController();
    edu = TextEditingController();
  }

  @override
  void dispose() {
    name.dispose();
    edu.dispose();
    super.dispose();
  }

  void _enterEdit(Student s) {
    name.text = s.name ?? '';
    edu.text = s.edu ?? '';
    setState(() => _editing = true);
  }

  Future<void> _save(Student s) async {
    final updated = s.copyWith(
      name: name.text.trim().isEmpty ? null : name.text.trim(),
      edu: edu.text.trim().isEmpty ? null : edu.text.trim(),
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
      final Student? s = c.student.value;
      if (s == null) return const Center(child: Text('No profile'));
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
            ] else ...[
              _Field(label: 'Name', value: s.name ?? '-'),
              _Field(label: 'Education', value: s.edu ?? '-'),
              _Field(label: 'Email', value: s.email),
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
                    onPressed: () => _save(s),
                    child: const Text('Save Changes'),
                  ),
                ] else ...[
                  FilledButton(
                    onPressed: () => _enterEdit(s),
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
