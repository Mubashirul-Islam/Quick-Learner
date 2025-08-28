import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';

class StudentHomeTab extends StatelessWidget {
  const StudentHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final u = auth.profile.value;
    if (u is! Student) {
      return const Center(child: Text('Not a student'));
    }
    final sid = u.sid;
    final query = FirebaseFirestore.instance
        .collection('queries')
        .where('sid', isEqualTo: sid);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                "You have not posted your query yet. Press the '+' icon to post your query.",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final docId = docs[i].id;
            final title = (data['title'] as String?) ?? '(No title)';
            final body = (data['body'] as String?) ?? '';
            final time = data['time'];
            String subtitle = body;
            if (subtitle.length > 80)
              subtitle = '${subtitle.substring(0, 80)}…';
            return ListTile(
              title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: time is Timestamp
                  ? Text(_formatTime(time))
                  : const SizedBox.shrink(),
              onTap: () => Get.toNamed('/query-responses', arguments: docId),
            );
          },
        );
      },
    );
  }

  String _formatTime(Timestamp ts) {
    final dt = ts.toDate();
    return '${dt.year}-${_two(dt.month)}-${_two(dt.day)}';
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}
