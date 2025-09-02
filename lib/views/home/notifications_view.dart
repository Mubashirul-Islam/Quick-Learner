import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final tid = Get.find<AuthController>().firebaseUser.value?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: tid == null
          ? const Center(child: Text('Not signed in'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('session')
                  .where('tid', isEqualTo: tid)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('No notifications yet.'),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data();
                    final sessionId = docs[i].id;
                    final sid = data['sid'] as String?;
                    if (sid == null || sid.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return StreamBuilder<
                      DocumentSnapshot<Map<String, dynamic>>
                    >(
                      stream: FirebaseFirestore.instance
                          .collection('students')
                          .doc(sid)
                          .snapshots(),
                      builder: (context, studentSnap) {
                        String name = '-';
                        if (studentSnap.hasData && studentSnap.data!.exists) {
                          name =
                              (studentSnap.data!.data()?['name'] as String?)
                                      ?.trim()
                                      .isNotEmpty ==
                                  true
                              ? (studentSnap.data!.data()?['name'] as String)
                              : '-';
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
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '$name accepted your application. Please join the video call ASAP.',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: FilledButton(
                                    onPressed: () {
                                      Get.toNamed(
                                        '/call',
                                        arguments: sessionId,
                                      );
                                    },
                                    child: const Text('Join'),
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
