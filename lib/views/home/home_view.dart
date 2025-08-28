import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../profile/profile_router_view.dart';
import '../settings/settings_view.dart';
import 'student_home_tab.dart';
import 'tutor_home_tab.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      final u = auth.profile.value;
      if (u == null) return const SizedBox.shrink();
      if (u is Student) return const _StudentHome();
      if (u is Tutor) return const _TutorHome();
      return const SizedBox.shrink();
    });
  }
}

class _StudentHome extends StatefulWidget {
  const _StudentHome();
  @override
  State<_StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<_StudentHome> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const StudentHomeTab(),
      const ProfileRouterView(),
      const SettingsView(),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('My Queries')),
      body: pages[_index],
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              onPressed: () => Get.toNamed('/post-query'),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Queries',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _TutorHome extends StatefulWidget {
  const _TutorHome();
  @override
  State<_TutorHome> createState() => _TutorHomeState();
}

class _TutorHomeState extends State<_TutorHome> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const TutorHomeTab(),
      const ProfileRouterView(),
      const SettingsView(),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Learner')),
      body: pages[_index],
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              onPressed: () => Get.toNamed('/notifications'),
              child: const Icon(Icons.notifications),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Queries',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
