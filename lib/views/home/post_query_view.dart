import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';

class PostQueryView extends StatefulWidget {
  const PostQueryView({super.key});

  @override
  State<PostQueryView> createState() => _PostQueryViewState();
}

class _PostQueryViewState extends State<PostQueryView> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final auth = Get.find<AuthController>();
    final u = auth.profile.value;
    if (u is! Student) {
      Get.snackbar(
        'Error',
        'Only students can post queries',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty || body.isEmpty) {
      Get.snackbar(
        'Error',
        'Title and Body are required',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await FirebaseFirestore.instance.collection('queries').add({
        'title': title,
        'body': body,
        'sid': u.sid,
        'active': true,
        'time': FieldValue.serverTimestamp(),
      });
      Get.back();
      Get.snackbar(
        'Success',
        'Query posted',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: const Text('Post Query'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _busy ? null : _post,
            child: const Text('Post'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _body,
                decoration: const InputDecoration(
                  labelText: 'Body',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
