import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';

class QueryResponsesView extends StatelessWidget {
  const QueryResponsesView({super.key});

  @override
  Widget build(BuildContext context) {
    final String queryId = Get.arguments as String;
    // Grab current student sid
    final auth = Get.find<AuthController>();
    final profile = auth.profile.value;
    final String? sid = profile is Student ? profile.sid : null;
    final queryDoc = FirebaseFirestore.instance
        .collection('queries')
        .doc(queryId)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Query Responses')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: queryDoc,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(
              child: Text('No response found. Please try again later.'),
            );
          }
          final data = snap.data!.data();
          final List<dynamic>? tidListDyn = data?['tid'] as List<dynamic>?;
          final List<String> tids = (tidListDyn ?? const [])
              .map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .cast<String>()
              .toList();

          if (tids.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No response found. Please try again later.'),
              ),
            );
          }

          return ListView.builder(
            itemCount: tids.length,
            itemBuilder: (context, index) {
              final tid = tids[index];
              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('tutors')
                    .doc(tid)
                    .snapshots(),
                builder: (context, tutorSnap) {
                  if (tutorSnap.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: LinearProgressIndicator(),
                    );
                  }
                  if (!tutorSnap.hasData || !tutorSnap.data!.exists) {
                    return const SizedBox.shrink();
                  }
                  final t = tutorSnap.data!.data()!;
                  final name = (t['name'] as String?)?.trim();
                  final edu = (t['edu'] as String?)?.trim();
                  final fee = (t['fee'] as num?)?.toDouble() ?? 0.0;
                  final rating = (t['rating'] as num?)?.toDouble() ?? 0.0;

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
                                      name?.isNotEmpty == true ? name! : '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (edu != null && edu.isNotEmpty)
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
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text(
                                'Session Fee: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${fee.toStringAsFixed(0)} BDT',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _Stars(rating: rating),
                          const SizedBox(height: 8),
                          Center(
                            child: FilledButton(
                              onPressed: sid == null
                                  ? null
                                  : () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Confirm'),
                                          content: const Text(
                                            "Are you want to accept this tutor? The session fee amount will be deducted from your account if you press 'Yes'.",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(false),
                                              child: const Text('No'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              child: const Text('Yes'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('session')
                                              .add({'sid': sid, 'tid': tid});
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Tutor accepted.'),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to accept: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                              child: const Text('Accept'),
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
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final double rating; // 0..5
  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    // Build 5 icons, filled proportionally based on rating
    return Row(
      children: List.generate(5, (i) {
        final idx = i + 1;
        IconData icon;
        if (rating >= idx) {
          icon = Icons.star;
        } else if (rating >= idx - 0.5) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
        return Icon(icon, color: Colors.amber.shade700, size: 18);
      }),
    );
  }
}
