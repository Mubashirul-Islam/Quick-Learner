import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import 'change_password_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const ListTile(
          leading: Icon(Icons.notifications),
          title: Text('Notification'),
        ),
        const Divider(height: 0),
        const ListTile(
          leading: Icon(Icons.payment),
          title: Text('Payment Method'),
        ),
        const Divider(height: 0),
        const ListTile(
          leading: Icon(Icons.brightness_6),
          title: Text('Change Theme'),
        ),
        const Divider(height: 0),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('Change Password'),
          onTap: () => Get.to(() => const ChangePasswordView()),
        ),
        const Divider(height: 0),
        ListTile(
          leading: const Icon(Icons.delete),
          title: const Text('Delete Profile'),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Account'),
                content: const Text(
                  'This will permanently delete your account. Continue?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              final err = await Get.find<AuthController>().deleteAccount();
              if (err != null) {
                Get.snackbar(
                  'Delete failed',
                  err,
                  snackPosition: SnackPosition.BOTTOM,
                );
              } else {
                Get.offAllNamed('/login');
              }
            }
          },
        ),
        const Divider(height: 0),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Log Out'),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (dialogCtx) => AlertDialog(
                title: const Text('Confirm Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx, false),
                    child: const Text('Back'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogCtx, true),
                    child: const Text('Log Out'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await Get.find<AuthController>().logout();
              Get.offAllNamed('/login');
            }
          },
        ),
      ],
    );
  }
}
