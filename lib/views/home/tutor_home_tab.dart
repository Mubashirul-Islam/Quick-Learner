import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class TutorHomeTab extends StatelessWidget {
  const TutorHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Current tutor id (same as Firebase Auth uid)
    final currentTid = Get.find<AuthController>().firebaseUser.value?.uid;

    final query = FirebaseFirestore.instance
        .collection('queries')
        .where('active', isEqualTo: true);

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
              child: Text('No active queries at the moment.'),
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
            final sid = data['sid'] as String?;
            final time = data['time'];
            final List<String> appliedBy = ((data['tid'] as List?) ?? const [])
                .map((e) => e?.toString() ?? '')
                .where((e) => e.isNotEmpty)
                .cast<String>()
                .toList();
            final bool hasApplied =
                currentTid != null && appliedBy.contains(currentTid);

            String excerpt = body;
            if (excerpt.length > 80) excerpt = '${excerpt.substring(0, 80)}…';

            if (sid == null || sid.isEmpty) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(child: Icon(Icons.person)),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '-',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (time is Timestamp)
                            Text(
                              _formatTime(time),
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        excerpt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: FilledButton(
                          onPressed: hasApplied
                              ? null
                              : () async {
                                  if (currentTid == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Not signed in'),
                                      ),
                                    );
                                    return;
                                  }
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('queries')
                                        .doc(docId)
                                        .update({
                                          'tid': FieldValue.arrayUnion([
                                            currentTid,
                                          ]),
                                        });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Applied successfully'),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to apply: $e'),
                                      ),
                                    );
                                  }
                                },
                          child: Text(hasApplied ? 'Applied' : 'Apply'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .doc(sid)
                  .snapshots(),
              builder: (context, snap) {
                String name = '-';
                String edu = '';
                if (snap.hasData && snap.data!.exists) {
                  final m = snap.data!.data();
                  if (m != null) {
                    name = (m['name'] as String?) ?? '-';
                    edu = (m['edu'] as String?) ?? '';
                  }
                }
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(child: Icon(Icons.person)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (edu.isNotEmpty)
                                    Text(
                                      edu,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            if (time is Timestamp)
                              Text(
                                _formatTime(time),
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          excerpt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: FilledButton(
                            onPressed: hasApplied
                                ? null
                                : () async {
                                    if (currentTid == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Not signed in'),
                                        ),
                                      );
                                      return;
                                    }
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('queries')
                                          .doc(docId)
                                          .update({
                                            'tid': FieldValue.arrayUnion([
                                              currentTid,
                                            ]),
                                          });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Applied successfully'),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to apply: $e'),
                                        ),
                                      );
                                    }
                                  },
                            child: Text(hasApplied ? 'Applied' : 'Apply'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

String _formatTime(Timestamp ts) {
  final dt = ts.toDate();
  return '${dt.year}-${_two(dt.month)}-${_two(dt.day)}';
}

String _two(int n) => n.toString().padLeft(2, '0');
